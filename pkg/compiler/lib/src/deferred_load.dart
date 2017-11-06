// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_load;

import 'dart:collection' show Queue;

import 'common/tasks.dart' show CompilerTask;
import 'common.dart';
import 'compiler.dart' show Compiler;
import 'constants/values.dart'
    show ConstantValue, ConstructedConstantValue, DeferredConstantValue;
import 'elements/resolution_types.dart';
import 'elements/elements.dart'
    show
        AstElement,
        ClassElement,
        Element,
        Elements,
        FunctionElement,
        ImportElement,
        LibraryElement,
        MemberElement,
        MethodElement,
        MetadataAnnotation,
        PrefixElement,
        TypedefElement;
import 'elements/entities.dart';
import 'js_backend/js_backend.dart' show JavaScriptBackend;
import 'universe/use.dart' show StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import 'universe/world_impact.dart'
    show ImpactUseCase, WorldImpact, WorldImpactVisitorImpl;
import 'util/uri_extras.dart' as uri_extras;
import 'util/util.dart' show makeUnique;
import 'world.dart' show ClosedWorld;

/// A "hunk" of the program that will be loaded whenever one of its [imports]
/// are loaded.
///
/// Elements that are only used in one deferred import, is in an OutputUnit with
/// the deferred import as single element in the [imports] set.
///
/// Whenever a deferred Element is shared between several deferred imports it is
/// in an output unit with those imports in the [imports] Set.
///
/// We never create two OutputUnits sharing the same set of [imports].
class OutputUnit implements Comparable<OutputUnit> {
  /// `true` if this output unit is for the main output file.
  final bool isMainOutput;

  /// A unique name representing this [OutputUnit].
  final String name;

  /// The deferred imports that use the elements in this output unit.
  final Set<ImportElement> _imports;

  OutputUnit(this.isMainOutput, this.name, this._imports);

  int compareTo(OutputUnit other) {
    if (identical(this, other)) return 0;
    if (isMainOutput && !other.isMainOutput) return -1;
    if (!isMainOutput && other.isMainOutput) return 1;
    var size = _imports.length;
    var otherSize = other._imports.length;
    if (size != otherSize) return size.compareTo(otherSize);
    var imports = _imports.toList();
    var otherImports = other._imports.toList();
    for (var i = 0; i < size; i++) {
      if (imports[i] == otherImports[i]) continue;
      var a = imports[i].uri.path;
      var b = otherImports[i].uri.path;
      var cmp = a.compareTo(b);
      if (cmp != 0) return cmp;
    }
    // TODO(sigmund): make compare stable.  If we hit this point, all imported
    // libraries are the same, however [this] and [other] use different deferred
    // imports in the program. We can make this stable if we sort based on the
    // deferred imports themselves (e.g. their declaration location).
    return name.compareTo(other.name);
  }

  String toString() => "OutputUnit($name, $_imports)";
}

/// For each deferred import, find elements and constants to be loaded when that
/// import is loaded. Elements that are used by several deferred imports are in
/// shared OutputUnits.
abstract class DeferredLoadTask extends CompilerTask {
  /// The name of this task.
  String get name => 'Deferred Loading';

  /// The OutputUnit that will be loaded when the program starts.
  OutputUnit mainOutputUnit;

  /// A set containing (eventually) all output units that will result from the
  /// program.
  final List<OutputUnit> allOutputUnits = new List<OutputUnit>();

  /// Will be `true` if the program contains deferred libraries.
  bool isProgramSplit = false;

  static const ImpactUseCase IMPACT_USE = const ImpactUseCase('Deferred load');

  /// A mapping from the name of a defer import to all the output units it
  /// depends on in a list of lists to be loaded in the order they appear.
  ///
  /// For example {"lib1": [[lib1_lib2_lib3], [lib1_lib2, lib1_lib3],
  /// [lib1]]} would mean that in order to load "lib1" first the hunk
  /// lib1_lib2_lib2 should be loaded, then the hunks lib1_lib2 and lib1_lib3
  /// can be loaded in parallel. And finally lib1 can be loaded.
  final Map<String, List<OutputUnit>> hunksToLoad =
      new Map<String, List<OutputUnit>>();

  /// A cache of the result of calling `computeImportDeferName` on the keys of
  /// this map.
  final Map<ImportElement, String> _importDeferName = <ImportElement, String>{};

  /// A mapping from elements and constants to their import set.
  Map<Entity, ImportSet> _elementToSet = new Map<Entity, ImportSet>();

  /// A mapping from constants to their import set.
  Map<ConstantValue, ImportSet> _constantToSet =
      new Map<ConstantValue, ImportSet>();

  Iterable<ImportElement> get allDeferredImports =>
      _deferredImportDescriptions.keys;

  /// Because the token-stream is forgotten later in the program, we cache a
  /// description of each deferred import.
  final Map<ImportElement, ImportDescription> _deferredImportDescriptions =
      <ImportElement, ImportDescription>{};

  /// A lattice to compactly represent multiple subsets of imports.
  final ImportSetLattice importSets = new ImportSetLattice();

  final Compiler compiler;
  DeferredLoadTask(Compiler compiler)
      : compiler = compiler,
        super(compiler.measurer) {
    mainOutputUnit = new OutputUnit(true, 'main', new Set<ImportElement>());
    importSets.mainSet.unit = mainOutputUnit;
    allOutputUnits.add(mainOutputUnit);
  }

  JavaScriptBackend get backend => compiler.backend;
  DiagnosticReporter get reporter => compiler.reporter;

  /// Returns the unique name for the deferred import of [prefix].
  String getImportDeferName(Spannable node, PrefixElement prefix) {
    String name = _importDeferName[prefix.deferredImport];
    if (name == null) {
      reporter.internalError(node, "No deferred name for $prefix.");
    }
    return name;
  }

  /// Returns the names associated with each deferred import in [unit].
  Iterable<String> getImportNames(OutputUnit unit) {
    return unit._imports.map((i) => _importDeferName[i]);
  }

  void registerConstantDeferredUse(
      DeferredConstantValue constant, PrefixElement prefix) {
    var newSet = importSets.singleton(prefix.deferredImport);
    assert(
        _constantToSet[constant] == null || _constantToSet[constant] == newSet);
    _constantToSet[constant] = newSet;
  }

  /// Given [imports] that refer to an element from a library, determine whether
  /// the element is explicitly deferred.
  static bool _isExplicitlyDeferred(Iterable<ImportElement> imports) {
    // If the element is not imported explicitly, it is implicitly imported
    // not deferred.
    if (imports.isEmpty) return false;
    // An element could potentially be loaded by several imports. If all of them
    // is explicitly deferred, we say the element is explicitly deferred.
    // TODO(sigurdm): We might want to give a warning if the imports do not
    // agree.
    return imports.every((ImportElement import) => import.isDeferred);
  }

  /// Returns every [ImportElement] that imports [element] into [library].
  Iterable<ImportElement> importsTo(Element element, LibraryElement library);

  /// Finds all elements and constants that [element] depends directly on.
  /// (not the transitive closure.)
  ///
  /// Adds the results to [elements] and [constants].
  void _collectAllElementsAndConstantsResolvedFrom(Element element,
      Set<Element> elements, Set<ConstantValue> constants, isMirrorUsage) {
    if (element.isMalformed) {
      // Malformed elements are ignored.
      return;
    }

    /// Collects all direct dependencies of [element].
    ///
    /// The collected dependent elements and constants are are added to
    /// [elements] and [constants] respectively.
    void collectDependencies(Element element) {
      // TODO(johnniwinther): Remove this when [AbstractFieldElement] has been
      // removed.
      if (element is! AstElement) return;

      if (element.isTypedef) {
        TypedefElement typdef = element;
        _collectTypeDependencies(typdef.thisType, elements);
      } else {
        // TODO(sigurdm): We want to be more specific about this - need a better
        // way to query "liveness".
        MemberElement analyzableElement = element.analyzableElement.declaration;
        if (!compiler.resolutionWorldBuilder.isMemberUsed(analyzableElement)) {
          return;
        }

        _collectDependenciesFromImpact(analyzableElement, elements);
        collectConstantsInBody(analyzableElement, constants);
      }
    }

    // TODO(sigurdm): How is metadata on a patch-class handled?
    for (MetadataAnnotation metadata in element.metadata) {
      ConstantValue constant =
          backend.constants.getConstantValueForMetadata(metadata);
      if (constant != null) {
        constants.add(constant);
      }
    }

    if (element is FunctionElement) {
      _collectTypeDependencies(element.type, elements);
    }

    if (element.isClass) {
      // If we see a class, add everything its live instance members refer
      // to.  Static members are not relevant, unless we are processing
      // extra dependencies due to mirrors.
      void addLiveInstanceMember(_, _element) {
        MemberElement element = _element;
        if (!compiler.resolutionWorldBuilder.isMemberUsed(element)) return;
        if (!isMirrorUsage && !element.isInstanceMember) return;
        elements.add(element);
        collectDependencies(element);
      }

      ClassElement cls = element.declaration;
      cls.implementation.forEachMember(addLiveInstanceMember);
      for (ResolutionInterfaceType type in cls.implementation.allSupertypes) {
        _collectTypeDependencies(type, elements);
      }
      elements.add(cls.implementation);
    } else if (Elements.isStaticOrTopLevel(element) || element.isConstructor) {
      elements.add(element);
      collectDependencies(element);
    }
    if (element.isGenerativeConstructor) {
      // When instantiating a class, we record a reference to the
      // constructor, not the class itself.  We must add all the
      // instance members of the constructor's class.
      ClassElement implementation = element.enclosingClass.implementation;
      _collectAllElementsAndConstantsResolvedFrom(
          implementation, elements, constants, isMirrorUsage);
    }

    // Other elements, in particular instance members, are ignored as
    // they are processed as part of the class.
  }

  /// Extract the set of constants that are used in the body of [element].
  void collectConstantsInBody(Element element, Set<ConstantValue> constants);

  /// Recursively collects all the dependencies of [type].
  void _collectTypeDependencies(ResolutionDartType type, Set<Entity> elements) {
    // TODO(het): we would like to separate out types that are only needed for
    // rti from types that are needed for their members.
    if (type is GenericType) {
      type.typeArguments.forEach((t) => _collectTypeDependencies(t, elements));
    }
    if (type is ResolutionFunctionType) {
      for (ResolutionDartType argumentType in type.parameterTypes) {
        _collectTypeDependencies(argumentType, elements);
      }
      for (ResolutionDartType argumentType in type.optionalParameterTypes) {
        _collectTypeDependencies(argumentType, elements);
      }
      for (ResolutionDartType argumentType in type.namedParameterTypes) {
        _collectTypeDependencies(argumentType, elements);
      }
      _collectTypeDependencies(type.returnType, elements);
    } else if (type is ResolutionTypedefType) {
      elements.add(type.element);
      _collectTypeDependencies(type.unaliased, elements);
    } else if (type is ResolutionInterfaceType) {
      elements.add(type.element);
    }
  }

  /// Extract any dependencies that are known from the impact of [element].
  void _collectDependenciesFromImpact(Element element, Set<Element> elements) {
    WorldImpact worldImpact = compiler.impactCache[element];
    compiler.impactStrategy.visitImpact(
        element,
        worldImpact,
        new WorldImpactVisitorImpl(visitStaticUse: (StaticUse staticUse) {
          elements.add(staticUse.element);
          switch (staticUse.kind) {
            case StaticUseKind.CONSTRUCTOR_INVOKE:
            case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
              _collectTypeDependencies(staticUse.type, elements);
              break;
            default:
          }
        }, visitTypeUse: (TypeUse typeUse) {
          ResolutionDartType type = typeUse.type;
          switch (typeUse.kind) {
            case TypeUseKind.TYPE_LITERAL:
              if (type.isTypedef || type.isInterfaceType) {
                elements.add(type.element);
              }
              break;
            case TypeUseKind.INSTANTIATION:
            case TypeUseKind.MIRROR_INSTANTIATION:
            case TypeUseKind.NATIVE_INSTANTIATION:
            case TypeUseKind.IS_CHECK:
            case TypeUseKind.AS_CAST:
            case TypeUseKind.CATCH_TYPE:
              _collectTypeDependencies(type, elements);
              break;
            case TypeUseKind.CHECKED_MODE_CHECK:
              if (compiler.options.enableTypeAssertions) {
                _collectTypeDependencies(type, elements);
              }
              break;
          }
        }),
        IMPACT_USE);
  }

  /// Update the import set of all constants reachable from [constant], as long
  /// as they had the [oldSet]. As soon as we see a constant with a different
  /// import set, we stop and enqueue a new recursive update in [queue].
  ///
  /// Invariants: oldSet is either null or a subset of newSet.
  void _updateConstantRecursive(ConstantValue constant, ImportSet oldSet,
      ImportSet newSet, WorkQueue queue) {
    if (constant == null) return;
    var currentSet = _constantToSet[constant];

    // Already visited.
    if (currentSet == newSet) return;

    // Elements in the main output unit always remain there.
    if (currentSet == importSets.mainSet) return;

    if (currentSet == oldSet) {
      _constantToSet[constant] = newSet;
      if (constant is ConstructedConstantValue) {
        ClassElement cls = constant.type.element;
        _updateElementRecursive(cls, oldSet, newSet, queue);
      }
      constant.getDependencies().forEach((ConstantValue dependency) {
        if (dependency is DeferredConstantValue) {
          /// New deferred-imports are only discovered when we are visiting the
          /// main output unit (size == 0) or code reachable from a deferred
          /// import (size == 1). After that, we are rediscovering the
          /// same nodes we have already seen.
          if (newSet.length <= 1) {
            PrefixElement prefix = dependency.prefix;
            queue.addConstant(
                dependency, importSets.singleton(prefix.deferredImport));
          }
        } else {
          _updateConstantRecursive(dependency, oldSet, newSet, queue);
        }
      });
    } else {
      assert(
          // Invariant: we must mark main before we mark any deferred import.
          newSet != importSets.mainSet || oldSet != null,
          failedAt(
              NO_LOCATION_SPANNABLE,
              "Tried to assign ${constant.toDartText()} to the main output "
              "unit, but it was assigned to $currentSet."));
      queue.addConstant(constant, newSet);
    }
  }

  /// Update the import set of all elements reachable from [element], as long as
  /// they had the [oldSet]. As soon as we see an element with a different
  /// import set, we stop and enqueue a new recursive update in [queue].
  void _updateElementRecursive(
      Element element, ImportSet oldSet, ImportSet newSet, WorkQueue queue,
      {bool isMirrorUsage: false}) {
    if (element == null) return;
    var currentSet = _elementToSet[element];

    // Already visited. We may visit some root nodes a second time with
    // [isMirrorUsage] in order to mark static members used reflectively.
    if (currentSet == newSet && !isMirrorUsage) return;

    // Elements in the main output unit always remain there.
    if (currentSet == importSets.mainSet) return;

    if (currentSet == oldSet) {
      // Continue recursively updating from [oldSet] to [newSet].
      _elementToSet[element] = newSet;

      Set<Element> dependentElements = new Set<Element>();
      Set<ConstantValue> dependentConstants = new Set<ConstantValue>();
      _collectAllElementsAndConstantsResolvedFrom(
          element, dependentElements, dependentConstants, isMirrorUsage);

      LibraryElement library = element.library;
      for (Element dependency in dependentElements) {
        Iterable<ImportElement> imports = importsTo(dependency, library);
        if (_isExplicitlyDeferred(imports)) {
          /// New deferred-imports are only discovered when we are visiting the
          /// main output unit (size == 0) or code reachable from a deferred
          /// import (size == 1). After that, we are rediscovering the
          /// same nodes we have already seen.
          if (newSet.length <= 1) {
            for (ImportElement deferredImport in imports) {
              queue.addElement(
                  dependency, importSets.singleton(deferredImport));
            }
          }
        } else {
          _updateElementRecursive(dependency, oldSet, newSet, queue);
        }
      }

      for (ConstantValue dependency in dependentConstants) {
        if (dependency is DeferredConstantValue) {
          if (newSet.length <= 1) {
            PrefixElement prefix = dependency.prefix;
            queue.addConstant(
                dependency, importSets.singleton(prefix.deferredImport));
          }
        } else {
          _updateConstantRecursive(dependency, oldSet, newSet, queue);
        }
      }
    } else {
      queue.addElement(element, newSet);
    }
  }

  /// Adds extra dependencies coming from mirror usage.
  void addDeferredMirrorElements(WorkQueue queue);

  /// Add extra dependencies coming from mirror usage in [root] marking it with
  /// [newSet].
  void addMirrorElementsForLibrary(
      WorkQueue queue, LibraryElement root, ImportSet newSet);

  /// Computes a unique string for the name field for each outputUnit.
  void _createOutputUnits() {
    int counter = 1;
    void addUnit(ImportSet importSet) {
      if (importSet.unit != null) return;
      var unit = new OutputUnit(false, '$counter',
          importSet._imports.map((i) => i.declaration).toSet());
      counter++;
      importSet.unit = unit;
      allOutputUnits.add(unit);
    }

    // Generate an output unit for all import sets that are associated with an
    // element or constant.
    _elementToSet.values.forEach(addUnit);
    _constantToSet.values.forEach(addUnit);

    // Sort output units to make the output of the compiler more stable.
    allOutputUnits.sort();
  }

  void _setupHunksToLoad() {
    Set<String> usedImportNames = new Set<String>();

    for (ImportElement import in allDeferredImports) {
      String result = computeImportDeferName(import, compiler);
      assert(result != null);
      _importDeferName[import] = makeUnique(result, usedImportNames);
    }

    // Sort the output units in descending order of the number of imports they
    // include.

    // The loading of the output units must be ordered because a superclass
    // needs to be initialized before its subclass.
    // But a class can only depend on another class in an output unit shared by
    // a strict superset of the imports:
    // By contradiction: Assume a class C in output unit shared by imports in
    // the set S1 = (lib1,.., lib_n) depends on a class D in an output unit
    // shared by S2 such that S2 not a superset of S1. Let lib_s be a library in
    // S1 not in S2. lib_s must depend on C, and then in turn on D. Therefore D
    // is not in the right output unit.
    List sortedOutputUnits = allOutputUnits.reversed.toList();

    // For each deferred import we find out which outputUnits to load.
    for (ImportElement import in allDeferredImports) {
      // We expect to find an entry for any call to `loadLibrary`, even if
      // there is no code to load. In that case, the entry will be an empty
      // list.
      hunksToLoad[_importDeferName[import]] = new List<OutputUnit>();
      for (OutputUnit outputUnit in sortedOutputUnits) {
        if (outputUnit == mainOutputUnit) continue;
        if (outputUnit._imports.contains(import)) {
          hunksToLoad[_importDeferName[import]].add(outputUnit);
        }
      }
    }
  }

  /// Returns a name for a deferred import.
  String computeImportDeferName(ImportElement declaration, Compiler compiler);

  /// Performs the deferred loading algorithm.
  ///
  /// The deferred loading algorithm maps elements and constants to an output
  /// unit. Each output unit is identified by a subset of deferred imports (an
  /// [ImportSet]), and they will contain the elements that are inheretly used
  /// by all those deferred imports. An element is used by a deferred import if
  /// it is either loaded by that import or transitively accessed by an element
  /// that the import loads.  An empty set represents the main output unit,
  /// which contains any elements that are accessed directly and are not
  /// deferred.
  ///
  /// The algorithm traverses the element model recursively looking for
  /// dependencies between elements. These dependencies may be deferred or
  /// non-deferred. Deferred dependencies are mainly used to discover the root
  /// elements that are loaded from deferred imports, while non-deferred
  /// dependencies are used to recursively associate more elements to output
  /// units.
  ///
  /// Naively, the algorithm traverses each root of a deferred import and marks
  /// everything it can reach as being used by that import. To reduce how many
  /// times we visit an element, we use an algorithm that works in segments: it
  /// marks elements with a subset of deferred imports at a time, until it
  /// detects a merge point where more deferred imports could be considered at
  /// once.
  ///
  /// For example, consider this dependency graph (ignoring elements in the main
  /// output unit):
  ///
  ///   deferred import A: a1 ---> s1 ---> s2  -> s3
  ///                              ^       ^
  ///                              |       |
  ///   deferred import B: b1 -----+       |
  ///                                      |
  ///   deferred import C: c1 ---> c2 ---> c3
  ///
  /// The algorithm will compute a result with 5 deferred output units:
  //
  ///   * unit {A}:        contains a1
  ///   * unit {B}:        contains b1
  ///   * unit {C}:        contains c1, c2, and c3
  ///   * unit {A, B}:     contains s1
  ///   * unit {A, B, C}:  contains s2, and s3
  ///
  /// After marking everything reachable from main as part of the main output
  /// unit, our algorithm will work as follows:
  ///
  ///   * Initially all deferred elements have no mapping.
  ///   * We make note of work to do, initially to mark the root of each
  ///     deferred import:
  ///        * a1 with A, and recurse from there.
  ///        * b1 with B, and recurse from there.
  ///        * c1 with C, and recurse from there.
  ///   * we update a1, s1, s2, s3 from no mapping to {A}
  ///   * we update b1 from no mapping to {B}, and when we find s1 we notice
  ///     that s1 is already associated with another import set {A}, so we make
  ///     note of additional work for later to mark s1 with {A, B}
  ///   * we update c1, c2, c3 to {C}, and make a note to update s2 with {A, C}
  ///   * we update s1 to {A, B}, and update the existing note to update s2, now
  ///     with {A, B, C}
  ///   * finally we update s2 and s3 with {A, B, C} in one go, without ever
  ///     updating them to the intermediate state {A, C}.
  ///
  /// The implementation below does atomic updates from one import-set to
  /// another.  At first we add one deferred import at a time, but as the
  /// algorithm progesses it may update a small import-set with a larger
  /// import-set in one go. The key of this algorithm is to detect when sharing
  /// begins, so we can update those elements more efficently.
  ///
  /// To detect these merge points where sharing begins, the implementation
  /// below uses `a swap operation`: we first compare what the old import-set
  /// is, and if it matches our expectation, the swap is done and we recurse,
  /// otherwise a merge root was detected and we enqueue a new segment of
  /// updates for later.
  ///
  /// TODO(sigmund): investigate different heuristics for how to select the next
  /// work item (e.g. we might converge faster if we pick first the update that
  /// contains a bigger delta.)
  OutputUnitData run(FunctionEntity main, ClosedWorld closedWorld) {
    if (!isProgramSplit || main == null) return _buildResult();

    work() {
      var queue = new WorkQueue(this.importSets);

      // Add `main` and their recursive dependencies to the main output unit.
      // We do this upfront to avoid wasting time visiting these elements when
      // analyzing deferred imports.
      queue.addElement(main, importSets.mainSet);

      // Also add "global" dependencies to the main output unit.  These are
      // things that the backend needs but cannot associate with a particular
      // element, for example, startRootIsolate.  This set also contains
      // elements for which we lack precise information.
      for (MethodElement element
          in closedWorld.backendUsage.globalFunctionDependencies) {
        queue.addElement(element.implementation, importSets.mainSet);
      }
      for (ClassElement element
          in closedWorld.backendUsage.globalClassDependencies) {
        queue.addElement(element.implementation, importSets.mainSet);
      }
      if (closedWorld.backendUsage.isMirrorsUsed) {
        addMirrorElementsForLibrary(queue, main.library, importSets.mainSet);
      }

      void emptyQueue() {
        while (queue.isNotEmpty) {
          var item = queue.nextItem();
          if (item.element != null) {
            var oldSet = _elementToSet[item.element];
            var newSet = importSets.union(oldSet, item.newSet);
            _updateElementRecursive(item.element, oldSet, newSet, queue,
                isMirrorUsage: item.isMirrorUsage);
          } else if (item.value != null) {
            var oldSet = _constantToSet[item.value];
            var newSet = importSets.union(oldSet, item.newSet);
            _updateConstantRecursive(item.value, oldSet, newSet, queue);
          }
        }
      }

      emptyQueue();
      if (closedWorld.backendUsage.isMirrorsUsed) {
        addDeferredMirrorElements(queue);
        emptyQueue();
      }

      _createOutputUnits();
      _setupHunksToLoad();
    }

    reporter.withCurrentElement(main.library, () => measure(work));

    // Notify that we no longer need impacts for deferred load, so they can be
    // discarded at this time.
    compiler.impactStrategy.onImpactUsed(IMPACT_USE);
    return _buildResult();
  }

  OutputUnitData _buildResult() {
    Map<Entity, OutputUnit> entityMap = <Entity, OutputUnit>{};
    Map<ConstantValue, OutputUnit> constantMap = <ConstantValue, OutputUnit>{};
    _elementToSet.forEach((entity, s) => entityMap[entity] = s.unit);
    _constantToSet.forEach((constant, s) => constantMap[constant] = s.unit);

    _elementToSet = null;
    _constantToSet = null;
    return new OutputUnitData(this.isProgramSplit, this.mainOutputUnit,
        entityMap, constantMap, importSets);
  }

  void beforeResolution(LibraryEntity mainLibrary) {
    if (mainLibrary == null) return;
    // TODO(johnniwinther): Support deferred load for kernel based elements.
    if (compiler.options.useKernel) return;
    for (LibraryElement library in compiler.libraryLoader.libraries) {
      reporter.withCurrentElement(library, () {
        checkForDeferredErrorCases(library);
        for (ImportElement import in library.imports) {
          if (import.isDeferred) {
            Uri mainLibraryUri = compiler.mainLibraryUri;
            _deferredImportDescriptions[import] =
                new ImportDescription(import, library, mainLibraryUri);
            isProgramSplit = true;
          }
        }
      });
    }
  }

  /// Detects errors like duplicate uses of a prefix or using the old
  /// loading syntax.
  ///
  /// These checks are already done by the shared front-end, so they can be
  /// skipped by the new compiler pipeline.
  void checkForDeferredErrorCases(LibraryElement library);

  /// Returns a json-style map for describing what files that are loaded by a
  /// given deferred import.
  /// The mapping is structured as:
  /// library uri -> {"name": library name, "files": (prefix -> list of files)}
  /// Where
  ///
  /// - <library uri> is the relative uri of the library making a deferred
  ///   import.
  /// - <library name> is the name of the library, and "<unnamed>" if it is
  ///   unnamed.
  /// - <prefix> is the `as` prefix used for a given deferred import.
  /// - <list of files> is a list of the filenames the must be loaded when that
  ///   import is loaded.
  Map<String, Map<String, dynamic>> computeDeferredMap() {
    Map<String, Map<String, dynamic>> mapping =
        new Map<String, Map<String, dynamic>>();
    _deferredImportDescriptions.keys.forEach((ImportElement import) {
      List<OutputUnit> outputUnits = hunksToLoad[_importDeferName[import]];
      ImportDescription description = _deferredImportDescriptions[import];
      Map<String, dynamic> libraryMap = mapping.putIfAbsent(
          description.importingUri,
          () => <String, dynamic>{
                "name": description.importingLibraryName,
                "imports": <String, List<String>>{}
              });

      libraryMap["imports"][_importDeferName[import]] =
          outputUnits.map((OutputUnit outputUnit) {
        return deferredPartFileName(outputUnit.name);
      }).toList();
    });
    return mapping;
  }

  /// Returns the filename for the output-unit named [name].
  ///
  /// The filename is of the form "<main output file>_<name>.part.js".
  /// If [addExtension] is false, the ".part.js" suffix is left out.
  String deferredPartFileName(String name, {bool addExtension: true}) {
    assert(name != "");
    String outPath = compiler.options.outputUri != null
        ? compiler.options.outputUri.path
        : "out";
    String outName = outPath.substring(outPath.lastIndexOf('/') + 1);
    String extension = addExtension ? ".part.js" : "";
    return "${outName}_$name$extension";
  }

  /// Creates a textual representation of the output unit content.
  String dump() {
    Map<OutputUnit, List<String>> elementMap = <OutputUnit, List<String>>{};
    Map<OutputUnit, List<String>> constantMap = <OutputUnit, List<String>>{};
    _elementToSet.forEach((Entity element, ImportSet importSet) {
      elementMap.putIfAbsent(importSet.unit, () => <String>[]).add('$element');
    });
    _constantToSet.forEach((ConstantValue value, ImportSet importSet) {
      constantMap
          .putIfAbsent(importSet.unit, () => <String>[])
          .add(value.toStructuredText());
    });

    Map<OutputUnit, String> text = {};
    for (OutputUnit outputUnit in allOutputUnits) {
      StringBuffer unitText = new StringBuffer();
      if (outputUnit.isMainOutput) {
        unitText.write(' <MAIN UNIT>');
      } else {
        unitText.write(' imports:');
        var imports = outputUnit._imports.map((i) => '${i.uri}').toList()
          ..sort();
        for (var i in imports) {
          unitText.write('\n   $i:');
        }
      }
      List<String> elements = elementMap[outputUnit];
      if (elements != null) {
        unitText.write('\n elements:');
        for (String element in elements..sort()) {
          unitText.write('\n  $element');
        }
      }
      List<String> constants = constantMap[outputUnit];
      if (constants != null) {
        unitText.write('\n constants:');
        for (String value in constants..sort()) {
          unitText.write('\n  $value');
        }
      }
      text[outputUnit] = '$unitText';
    }

    StringBuffer sb = new StringBuffer();
    for (OutputUnit outputUnit in allOutputUnits.toList()
      ..sort((a, b) => text[a].compareTo(text[b]))) {
      sb.write('\n\n-------------------------------\n');
      sb.write('Output unit: ${outputUnit.name}');
      sb.write('\n ${text[outputUnit]}');
    }
    return sb.toString();
  }
}

class ImportDescription {
  /// Relative uri to the importing library.
  final String importingUri;

  /// The prefix this import is imported as.
  final String prefix;
  final LibraryElement _importingLibrary;

  ImportDescription(
      ImportElement import, LibraryElement importingLibrary, Uri mainLibraryUri)
      : importingUri = uri_extras.relativize(
            mainLibraryUri, importingLibrary.canonicalUri, false),
        prefix = import.prefix.name,
        _importingLibrary = importingLibrary;

  String get importingLibraryName {
    return _importingLibrary.hasLibraryName
        ? _importingLibrary.libraryName
        : "<unnamed>";
  }
}

/// Indirectly represents a deferred import in an [ImportSet].
///
/// We could directly store the [declaration] in [ImportSet], but adding this
/// class makes some of the import set operations more efficient.
class _DeferredImport {
  final ImportElement declaration;

  /// Canonical index associated with [declaration]. This is used to efficiently
  /// implement [ImportSetLattice.union].
  final int index;

  _DeferredImport(this.declaration, this.index);
}

/// A compact lattice representation of import sets and subsets.
///
/// We use a graph of nodes to represent elements of the lattice, but only
/// create new nodes on-demand as they are needed by the deferred loading
/// algorithm.
///
/// The constructions of nodes is carefully done by storing imports in a
/// specific order. This ensures that we have a unique and canonical
/// representation for each subset.
class ImportSetLattice {
  /// Index of deferred imports that defines the canonical order used by the
  /// operations below.
  Map<ImportElement, _DeferredImport> _importIndex = {};

  /// The canonical instance representing the empty import set.
  ImportSet _emptySet = new ImportSet();

  /// The import set representing the main output unit, which happens to be
  /// implemented as an empty set in our algorithm.
  ImportSet get mainSet => _emptySet;

  /// Get the singleton import set that only contains [import].
  ImportSet singleton(ImportElement import) {
    // Ensure we have import in the index.
    return _emptySet._add(_wrap(import));
  }

  /// Get the import set that includes the union of [a] and [b].
  ImportSet union(ImportSet a, ImportSet b) {
    if (a == null || a == _emptySet) return b;
    if (b == null || b == _emptySet) return a;

    // We create the union by merging the imports in canonical order first, and
    // then getting (or creating) the canonical sets by adding an import at a
    // time.
    List<_DeferredImport> aImports = a._imports;
    List<_DeferredImport> bImports = b._imports;
    int i = 0, j = 0, lastAIndex = 0, lastBIndex = 0;
    var result = _emptySet;
    while (i < aImports.length && j < bImports.length) {
      var importA = aImports[i];
      var importB = bImports[j];
      assert(lastAIndex <= importA.index);
      assert(lastBIndex <= importB.index);
      if (importA.index < importB.index) {
        result = result._add(importA);
        i++;
      } else {
        result = result._add(importB);
        j++;
      }
    }
    for (; i < aImports.length; i++) {
      result = result._add(aImports[i]);
    }
    for (; j < bImports.length; j++) {
      result = result._add(bImports[j]);
    }

    return result;
  }

  /// Get the index for an [import] according to the canonical order.
  _DeferredImport _wrap(ImportElement import) {
    return _importIndex.putIfAbsent(
        import, () => new _DeferredImport(import, _importIndex.length));
  }
}

/// A canonical set of deferred imports.
class ImportSet {
  /// Imports that are part of this set.
  ///
  /// Invariant: the order in which elements are added must respect the
  /// canonical order of all imports in [ImportSetLattice].
  final List<_DeferredImport> _imports;

  /// Links to other import sets in the lattice by adding one import.
  final Map<_DeferredImport, ImportSet> _transitions =
      <_DeferredImport, ImportSet>{};

  ImportSet([this._imports = const <_DeferredImport>[]]);

  /// The output unit corresponding to this set of imports, if any.
  OutputUnit unit;

  int get length => _imports.length;

  /// Create an import set that adds [import] to all the imports on this set.
  /// This assumes that import's canonical order comes after all imports in
  /// this current set. This should only be called from [ImportSetLattice],
  /// since it is where we preserve this invariant.
  ImportSet _add(_DeferredImport import) {
    return _transitions.putIfAbsent(import, () {
      var result = new ImportSet(new List.from(_imports)..add(import));
      result._transitions[import] = result;
      return result;
    });
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('ImportSet(size: $length, ');
    for (var import in _imports) {
      sb.write('${import.declaration.prefix} ');
    }
    sb.write(')');
    return '$sb';
  }
}

/// The algorithm work queue.
class WorkQueue {
  /// The actual queue of work that needs to be done.
  final Queue<WorkItem> queue = new Queue<WorkItem>();

  /// An index to find work items in the queue corresponding to an entity.
  final Map<Entity, WorkItem> pendingElements = <Entity, WorkItem>{};

  /// An index to find work items in the queue corresponding to a constant.
  final Map<ConstantValue, WorkItem> pendingConstants =
      <ConstantValue, WorkItem>{};

  /// Lattice used to compute unions of [ImportSet]s.
  final ImportSetLattice _importSets;

  WorkQueue(this._importSets);

  /// Whether there are no more work items in the queue.
  bool get isNotEmpty => queue.isNotEmpty;

  /// Pop the next element in the queue.
  WorkItem nextItem() {
    assert(isNotEmpty);
    var item = queue.removeFirst();
    if (item.element != null) pendingElements.remove(item.element);
    if (item.value != null) pendingConstants.remove(item.value);
    return item;
  }

  /// Add to the queue that [element] should be updated to include all imports
  /// in [importSet]. If there is already a work item in the queue for
  /// [element], this makes sure that the work item now includes the union of
  /// [importSet] and the existing work item's import set.
  void addElement(Entity element, ImportSet importSet, {isMirrorUsage: false}) {
    var item = pendingElements[element];
    if (item == null) {
      item = new WorkItem(element, importSet);
      pendingElements[element] = item;
      queue.add(item);
    } else {
      item.newSet = _importSets.union(item.newSet, importSet);
    }
    if (isMirrorUsage) item.isMirrorUsage = true;
  }

  /// Add to the queue that [constant] should be updated to include all imports
  /// in [importSet]. If there is already a work item in the queue for
  /// [constant], this makes sure that the work item now includes the union of
  /// [importSet] and the existing work item's import set.
  void addConstant(ConstantValue constant, ImportSet importSet) {
    var item = pendingConstants[constant];
    if (item == null) {
      item = new WorkItem.constant(constant, importSet);
      pendingConstants[constant] = item;
      queue.add(item);
    } else {
      item.newSet = _importSets.union(item.newSet, importSet);
    }
  }
}

/// Summary of the work that needs to be done on an entity or constant.
class WorkItem {
  /// Entity to be recursively updated.
  final Entity element;

  /// Constant to be recursively updated.
  final ConstantValue value;

  /// Additional imports that use [element] or [value] and need to be added by
  /// the algorithm.
  ///
  /// This is non-final in case we add more deferred imports to the set before
  /// the work item is applied (see [WorkQueue.addElement] and
  /// [WorkQueue.addConstant]).
  ImportSet newSet;

  /// Whether [element] is used via mirrors.
  ///
  /// This is non-final in case we later discover that the same [element] is
  /// used via mirrors (but before the work item is applied).
  bool isMirrorUsage = false;

  WorkItem(this.element, this.newSet) : value = null;
  WorkItem.constant(this.value, this.newSet) : element = null;
}

/// Results of the deferred loading algorithm.
///
/// Provides information about the output unit associated with entities and
/// constants, as well as other helper methods.
// TODO(sigmund): consider moving here every piece of data used as a result of
// deferred loading (including hunksToLoad, etc).
class OutputUnitData {
  final bool isProgramSplit;
  final OutputUnit mainOutputUnit;
  final Map<Entity, OutputUnit> _entityToUnit;
  final Map<ConstantValue, OutputUnit> _constantToUnit;
  final ImportSetLattice _importSets;

  OutputUnitData(this.isProgramSplit, this.mainOutputUnit, this._entityToUnit,
      this._constantToUnit, this._importSets);

  OutputUnitData.from(OutputUnitData other,
      Map<Entity, OutputUnit> Function(Map<Entity, OutputUnit>) convertMap)
      : isProgramSplit = other.isProgramSplit,
        mainOutputUnit = other.mainOutputUnit,
        _entityToUnit = convertMap(other._entityToUnit),
        _constantToUnit = other._constantToUnit,
        _importSets = other._importSets;

  /// Returns the [OutputUnit] where [entity] belongs.
  OutputUnit outputUnitForEntity(Entity entity) {
    // TODO(johnniwinther): Support use of entities by splitting maps by
    // entity kind.
    if (!isProgramSplit) return mainOutputUnit;
    Element element = entity;
    element = element.implementation;
    while (!_entityToUnit.containsKey(element)) {
      // TODO(21051): workaround: it looks like we output annotation constants
      // for classes that we don't include in the output. This seems to happen
      // when we have reflection but can see that some classes are not needed.
      // We still add the annotation but don't run through it below (where we
      // assign every element to its output unit).
      if (element.enclosingElement == null) {
        _entityToUnit[element] = mainOutputUnit;
        break;
      }
      element = element.enclosingElement.implementation;
    }
    return _entityToUnit[element];
  }

  /// Direct access to the output-unit to element relation used for testing.
  OutputUnit outputUnitForEntityForTesting(Entity entity) {
    return _entityToUnit[entity];
  }

  /// Direct access to the output-unit to constants map used for testing.
  Iterable<ConstantValue> get constantsForTesting => _constantToUnit.keys;

  /// Returns the [OutputUnit] where [element] belongs.
  OutputUnit outputUnitForClass(ClassEntity element) {
    return outputUnitForEntity(element);
  }

  /// Returns the [OutputUnit] where [element] belongs.
  OutputUnit outputUnitForMember(MemberEntity element) {
    return outputUnitForEntity(element);
  }

  /// Returns the [OutputUnit] where [constant] belongs.
  OutputUnit outputUnitForConstant(ConstantValue constant) {
    if (!isProgramSplit) return mainOutputUnit;
    return _constantToUnit[constant];
  }

  /// Indicates whether [element] is deferred.
  bool isDeferred(Entity element) {
    return outputUnitForEntity(element) != mainOutputUnit;
  }

  /// Indicates whether [element] is deferred.
  bool isDeferredClass(ClassEntity element) {
    return outputUnitForEntity(element) != mainOutputUnit;
  }

  /// Returns `true` if element [to] is reachable from element [from] without
  /// crossing a deferred import.
  ///
  /// For example, if we have two deferred libraries `A` and `B` that both
  /// import a library `C`, then even though elements from `A` and `C` end up in
  /// different output units, there is a non-deferred path between `A` and `C`.
  bool hasOnlyNonDeferredImportPaths(Entity from, Entity to) {
    OutputUnit outputUnitFrom = outputUnitForEntity(from);
    OutputUnit outputUnitTo = outputUnitForEntity(to);
    if (outputUnitTo == mainOutputUnit) return true;
    if (outputUnitFrom == mainOutputUnit) return false;
    return outputUnitTo._imports.containsAll(outputUnitFrom._imports);
  }

  /// Registers that a constant is used in a deferred library.
  void registerConstantDeferredUse(
      DeferredConstantValue constant, PrefixElement prefix) {
    if (!isProgramSplit) return;
    var unit = _importSets.singleton(prefix.deferredImport).unit;
    assert(
        _constantToUnit[constant] == null || _constantToUnit[constant] == unit);
    _constantToUnit[constant] = unit;
  }
}
