// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_load;

import 'dart:collection' show Queue;

import 'common/tasks.dart' show CompilerTask;
import 'common.dart';
import 'common_elements.dart' show ElementEnvironment, KElementEnvironment;
import 'compiler.dart' show Compiler;
import 'constants/values.dart'
    show
        ConstantValue,
        ConstructedConstantValue,
        TypeConstantValue,
        DeferredGlobalConstantValue,
        InstantiationConstantValue;
import 'elements/types.dart';
import 'elements/entities.dart';
import 'kernel/kelements.dart' show KLocalFunction;
import 'serialization/serialization.dart';
import 'options.dart';
import 'universe/use.dart';
import 'universe/world_impact.dart'
    show ImpactUseCase, WorldImpact, WorldImpactVisitorImpl;
import 'util/uri_extras.dart' as uri_extras;
import 'util/util.dart' show makeUnique;
import 'world.dart' show KClosedWorld;

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
  final Set<ImportEntity> _imports;

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

  Set<ImportEntity> get importsForTesting => _imports;

  String toString() => "OutputUnit($name, $_imports)";
}

/// For each deferred import, find elements and constants to be loaded when that
/// import is loaded. Elements that are used by several deferred imports are in
/// shared OutputUnits.
abstract class DeferredLoadTask extends CompilerTask {
  /// The name of this task.
  String get name => 'Deferred Loading';

  /// The OutputUnit that will be loaded when the program starts.
  OutputUnit _mainOutputUnit;

  /// A set containing (eventually) all output units that will result from the
  /// program.
  final List<OutputUnit> _allOutputUnits = new List<OutputUnit>();

  /// Will be `true` if the program contains deferred libraries.
  bool isProgramSplit = false;

  static const ImpactUseCase IMPACT_USE = const ImpactUseCase('Deferred load');

  /// A cache of the result of calling `computeImportDeferName` on the keys of
  /// this map.
  final Map<ImportEntity, String> _importDeferName = <ImportEntity, String>{};

  /// A mapping from classes to their import set.
  Map<ClassEntity, ImportSet> _classToSet = new Map<ClassEntity, ImportSet>();

  /// A mapping from members to their import set.
  Map<MemberEntity, ImportSet> _memberToSet =
      new Map<MemberEntity, ImportSet>();

  /// A mapping from local functions to their import set.
  Map<Local, ImportSet> _localFunctionToSet = new Map<Local, ImportSet>();

  /// A mapping from constants to their import set.
  Map<ConstantValue, ImportSet> _constantToSet =
      new Map<ConstantValue, ImportSet>();

  Iterable<ImportEntity> get _allDeferredImports =>
      _deferredImportDescriptions.keys;

  /// Because the token-stream is forgotten later in the program, we cache a
  /// description of each deferred import.
  final Map<ImportEntity, ImportDescription> _deferredImportDescriptions =
      <ImportEntity, ImportDescription>{};

  /// A lattice to compactly represent multiple subsets of imports.
  final ImportSetLattice importSets = new ImportSetLattice();

  final Compiler compiler;

  bool get disableProgramSplit => compiler.options.disableProgramSplit;
  bool get newDeferredSplit => compiler.options.newDeferredSplit;
  bool get reportInvalidInferredDeferredTypes =>
      compiler.options.reportInvalidInferredDeferredTypes;

  DeferredLoadTask(this.compiler) : super(compiler.measurer) {
    _mainOutputUnit = new OutputUnit(true, 'main', new Set<ImportEntity>());
    importSets.mainSet.unit = _mainOutputUnit;
    _allOutputUnits.add(_mainOutputUnit);
  }

  KElementEnvironment get elementEnvironment =>
      compiler.frontendStrategy.elementEnvironment;
  DiagnosticReporter get reporter => compiler.reporter;

  /// Given [imports] that refer to an element from a library, determine whether
  /// the element is explicitly deferred.
  static bool _isExplicitlyDeferred(Iterable<ImportEntity> imports) {
    // If the element is not imported explicitly, it is implicitly imported
    // not deferred.
    if (imports.isEmpty) return false;
    // An element could potentially be loaded by several imports. If all of them
    // is explicitly deferred, we say the element is explicitly deferred.
    // TODO(sigurdm): We might want to give a warning if the imports do not
    // agree.
    return imports.every((ImportEntity import) => import.isDeferred);
  }

  /// Returns every [ImportEntity] that imports [element] into [library].
  Iterable<ImportEntity> classImportsTo(
      ClassEntity element, LibraryEntity library);

  /// Returns every [ImportEntity] that imports [element] into [library].
  Iterable<ImportEntity> memberImportsTo(
      MemberEntity element, LibraryEntity library);

  /// Returns every [ImportEntity] that imports [element] into [library].
  Iterable<ImportEntity> typedefImportsTo(
      TypedefEntity element, LibraryEntity library);

  /// Collects all direct dependencies of [element].
  ///
  /// The collected dependent elements and constants are are added to
  /// [elements] and [constants] respectively.
  void _collectDirectMemberDependencies(
      MemberEntity element, Dependencies dependencies) {
    // TODO(sigurdm): We want to be more specific about this - need a better
    // way to query "liveness".
    if (!compiler.resolutionWorldBuilder.isMemberUsed(element)) {
      return;
    }
    _collectDependenciesFromImpact(element, dependencies);
    collectConstantsInBody(element, dependencies);
  }

  /// Finds all elements and constants that [element] depends directly on.
  /// (not the transitive closure.)
  ///
  /// Adds the results to [elements] and [constants].
  void _collectAllElementsAndConstantsResolvedFromClass(
      ClassEntity element, Dependencies dependencies) {
    // If we see a class, add everything its live instance members refer
    // to.  Static members are not relevant, unless we are processing
    // extra dependencies due to mirrors.
    void addLiveInstanceMember(MemberEntity member) {
      if (!compiler.resolutionWorldBuilder.isMemberUsed(member)) return;
      if (!member.isInstanceMember) return;
      dependencies.addMember(member);
      _collectDirectMemberDependencies(member, dependencies);
    }

    ClassEntity cls = element;
    elementEnvironment.forEachLocalClassMember(cls, addLiveInstanceMember);
    elementEnvironment.forEachSupertype(cls, (InterfaceType type) {
      _collectTypeDependencies(type, dependencies);
    });
    dependencies.addClass(cls);
  }

  /// Finds all elements and constants that [element] depends directly on.
  /// (not the transitive closure.)
  ///
  /// Adds the results to [elements] and [constants].
  void _collectAllElementsAndConstantsResolvedFromMember(
      MemberEntity element, Dependencies dependencies) {
    if (element is FunctionEntity) {
      _collectTypeDependencies(
          elementEnvironment.getFunctionType(element), dependencies);
    }
    if (element.isStatic || element.isTopLevel || element.isConstructor) {
      dependencies.addMember(element);
      _collectDirectMemberDependencies(element, dependencies);
    }
    if (element is ConstructorEntity && element.isGenerativeConstructor) {
      // When instantiating a class, we record a reference to the
      // constructor, not the class itself.  We must add all the
      // instance members of the constructor's class.
      ClassEntity cls = element.enclosingClass;
      _collectAllElementsAndConstantsResolvedFromClass(cls, dependencies);
    }

    // Other elements, in particular instance members, are ignored as
    // they are processed as part of the class.
  }

  /// Extract the set of constants that are used in annotations of [element].
  ///
  /// If the underlying system doesn't support mirrors, then no constants are
  /// added.
  void collectConstantsFromMetadata(
      Entity element, Set<ConstantValue> constants);

  /// Extract the set of constants that are used in the body of [element].
  void collectConstantsInBody(MemberEntity element, Dependencies dependencies);

  /// Recursively collects all the dependencies of [type].
  void _collectTypeDependencies(DartType type, Dependencies dependencies) {
    if (type is FunctionType) {
      _collectFunctionTypeDependencies(type, dependencies);
    } else if (type is TypedefType) {
      _collectTypeArgumentDependencies(type.typeArguments, dependencies);
      _collectTypeDependencies(type.unaliased, dependencies);
    } else if (type is InterfaceType) {
      _collectTypeArgumentDependencies(type.typeArguments, dependencies);
      // TODO(sigmund): when we are able to split classes from types in our
      // runtime-type representation, this should track type.element as a type
      // dependency instead.
      dependencies.addClass(type.element);
    }
  }

  void _collectTypeArgumentDependencies(
      Iterable<DartType> typeArguments, Dependencies dependencies) {
    if (typeArguments == null) return;
    typeArguments.forEach((t) => _collectTypeDependencies(t, dependencies));
  }

  void _collectFunctionTypeDependencies(
      FunctionType type, Dependencies dependencies) {
    for (FunctionTypeVariable typeVariable in type.typeVariables) {
      _collectTypeDependencies(typeVariable.bound, dependencies);
    }
    for (DartType argumentType in type.parameterTypes) {
      _collectTypeDependencies(argumentType, dependencies);
    }
    for (DartType argumentType in type.optionalParameterTypes) {
      _collectTypeDependencies(argumentType, dependencies);
    }
    for (DartType argumentType in type.namedParameterTypes) {
      _collectTypeDependencies(argumentType, dependencies);
    }
    _collectTypeDependencies(type.returnType, dependencies);
  }

  /// Extract any dependencies that are known from the impact of [element].
  void _collectDependenciesFromImpact(
      MemberEntity element, Dependencies dependencies) {
    WorldImpact worldImpact = compiler.impactCache[element];
    compiler.impactStrategy.visitImpact(
        element,
        worldImpact,
        new WorldImpactVisitorImpl(visitStaticUse: (StaticUse staticUse) {
          Entity usedEntity = staticUse.element;
          if (usedEntity is MemberEntity) {
            dependencies.addMember(usedEntity, staticUse.deferredImport);
          } else {
            assert(usedEntity is KLocalFunction,
                failedAt(usedEntity, "Unexpected static use $staticUse."));
            KLocalFunction localFunction = usedEntity;
            // TODO(sra): Consult KClosedWorld to see if signature is needed.
            _collectFunctionTypeDependencies(
                localFunction.functionType, dependencies);
            dependencies.localFunctions.add(localFunction);
          }
          switch (staticUse.kind) {
            case StaticUseKind.CONSTRUCTOR_INVOKE:
            case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
              // The receiver type of generative constructors is a dependency of
              // the constructor (handled by `addMember` above) and not a
              // dependency at the call site.
              // Factory methods, on the other hand, are like static methods so
              // the target type is not relevant.
              // TODO(johnniwinther): Use rti need data to skip unneeded type
              // arguments.
              _collectTypeArgumentDependencies(
                  staticUse.type.typeArguments, dependencies);
              break;
            case StaticUseKind.INVOKE:
            case StaticUseKind.CLOSURE_CALL:
            case StaticUseKind.DIRECT_INVOKE:
              // TODO(johnniwinther): Use rti need data to skip unneeded type
              // arguments.
              _collectTypeArgumentDependencies(
                  staticUse.typeArguments, dependencies);
              break;
            default:
          }
        }, visitTypeUse: (TypeUse typeUse) {
          DartType type = typeUse.type;
          switch (typeUse.kind) {
            case TypeUseKind.TYPE_LITERAL:
              if (type.isInterfaceType) {
                InterfaceType interface = type;
                dependencies.addClass(
                    interface.element, typeUse.deferredImport);
              }
              break;
            case TypeUseKind.INSTANTIATION:
            case TypeUseKind.NATIVE_INSTANTIATION:
            case TypeUseKind.IS_CHECK:
            case TypeUseKind.CATCH_TYPE:
              _collectTypeDependencies(type, dependencies);
              break;
            case TypeUseKind.AS_CAST:
              if (!compiler.options.omitAsCasts) {
                _collectTypeDependencies(type, dependencies);
              }
              break;
            case TypeUseKind.IMPLICIT_CAST:
              if (compiler.options.implicitDowncastCheckPolicy.isEmitted) {
                _collectTypeDependencies(type, dependencies);
              }
              break;
            case TypeUseKind.PARAMETER_CHECK:
              if (compiler.options.parameterCheckPolicy.isEmitted) {
                _collectTypeDependencies(type, dependencies);
              }
              break;
            case TypeUseKind.RTI_VALUE:
            case TypeUseKind.TYPE_ARGUMENT:
              failedAt(element, "Unexpected type use: $typeUse.");
              break;
          }
        }, visitDynamicUse: (DynamicUse dynamicUse) {
          // TODO(johnniwinther): Use rti need data to skip unneeded type
          // arguments.
          _collectTypeArgumentDependencies(
              dynamicUse.typeArguments, dependencies);
        }),
        DeferredLoadTask.IMPACT_USE);
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
        ClassEntity cls = constant.type.element;
        _updateClassRecursive(cls, oldSet, newSet, queue);
      }
      if (constant is InstantiationConstantValue) {
        for (DartType type in constant.typeArguments) {
          if (type is InterfaceType) {
            _updateClassRecursive(type.element, oldSet, newSet, queue);
          }
        }
      }
      constant.getDependencies().forEach((ConstantValue dependency) {
        // Constants are not allowed to refer to deferred constants, so
        // no need to check for a deferred type literal here.
        _updateConstantRecursive(dependency, oldSet, newSet, queue);
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

  void _updateClassRecursive(ClassEntity element, ImportSet oldSet,
      ImportSet newSet, WorkQueue queue) {
    if (element == null) return;

    ImportSet currentSet = _classToSet[element];

    // Already visited. We may visit some root nodes a second time with
    // [isMirrorUsage] in order to mark static members used reflectively.
    if (currentSet == newSet) return;

    // Elements in the main output unit always remain there.
    if (currentSet == importSets.mainSet) return;

    if (currentSet == oldSet) {
      // Continue recursively updating from [oldSet] to [newSet].
      _classToSet[element] = newSet;

      Dependencies dependencies = new Dependencies();
      _collectAllElementsAndConstantsResolvedFromClass(element, dependencies);
      LibraryEntity library = element.library;
      _processDependencies(
          library, dependencies, oldSet, newSet, queue, element);
    } else {
      queue.addClass(element, newSet);
    }
  }

  void _updateMemberRecursive(MemberEntity element, ImportSet oldSet,
      ImportSet newSet, WorkQueue queue) {
    if (element == null) return;

    ImportSet currentSet = _memberToSet[element];

    // Already visited. We may visit some root nodes a second time with
    // [isMirrorUsage] in order to mark static members used reflectively.
    if (currentSet == newSet) return;

    // Elements in the main output unit always remain there.
    if (currentSet == importSets.mainSet) return;

    if (currentSet == oldSet) {
      // Continue recursively updating from [oldSet] to [newSet].
      _memberToSet[element] = newSet;

      Dependencies dependencies = new Dependencies();
      _collectAllElementsAndConstantsResolvedFromMember(element, dependencies);

      LibraryEntity library = element.library;
      _processDependencies(
          library, dependencies, oldSet, newSet, queue, element);
    } else {
      queue.addMember(element, newSet);
    }
  }

  void _updateLocalFunction(
      Local localFunction, ImportSet oldSet, ImportSet newSet) {
    ImportSet currentSet = _localFunctionToSet[localFunction];
    if (currentSet == newSet) return;

    // Elements in the main output unit always remain there.
    if (currentSet == importSets.mainSet) return;

    if (currentSet == oldSet) {
      _localFunctionToSet[localFunction] = newSet;
    } else {
      _localFunctionToSet[localFunction] = importSets.union(currentSet, newSet);
    }
    // Note: local functions are not updated recursively because the
    // dependencies are already visited as dependencies of the enclosing member.
  }

  /// Whether to enqueue a deferred dependency.
  ///
  /// Due to the nature of the algorithm, some dependencies may be visited more
  /// than once. However, we know that new deferred-imports are only discovered
  /// when we are visiting the main output unit (size == 0) or code reachable
  /// from a deferred import (size == 1). After that, we are rediscovering the
  /// same nodes we have already seen.
  _shouldAddDeferredDependency(ImportSet newSet) => newSet.length <= 1;

  void _fixDependencyInfo(DependencyInfo info, List<ImportEntity> imports,
      String prefix, String name, Spannable context) {
    var isDeferred = _isExplicitlyDeferred(imports);
    if (isDeferred) {
      if (!newDeferredSplit) {
        info.isDeferred = true;
        info.imports = imports;
      }
      if (reportInvalidInferredDeferredTypes) {
        reporter.reportErrorMessage(context, MessageKind.GENERIC, {
          'text': "$prefix '$name' is deferred but appears to be inferred as"
              " a return type or a type parameter (dartbug.com/35311)."
        });
      }
    }
  }

  // The following 3 methods are used to check whether the new deferred split
  // algorithm and the old one match. Because of a soundness bug in the old
  // algorithm the new algorithm can pull in a lot of code to the main output
  // unit. This logic detects it and will make it easier for us to migrate code
  // off it incrementally.
  // Note: we only expect discrepancies on class-dependency-info due to how
  // inferred types expose deferred types in type-variables and return types
  // (Issue #35311). We added the other two methods to test our transition, but
  // we don't expect to detect any mismatches there.
  //
  // TODO(sigmund): delete once the new implementation is on by default.
  void _fixClassDependencyInfo(DependencyInfo info, ClassEntity cls,
      LibraryEntity library, Spannable context) {
    if (info.isDeferred) return;
    if (newDeferredSplit && !reportInvalidInferredDeferredTypes) return;
    var imports = classImportsTo(cls, library);
    _fixDependencyInfo(info, imports, "Class", cls.name, context);
  }

  void _fixMemberDependencyInfo(DependencyInfo info, MemberEntity member,
      LibraryEntity library, Spannable context) {
    if (info.isDeferred || compiler.options.newDeferredSplit) return;
    var imports = memberImportsTo(member, library);
    _fixDependencyInfo(info, imports, "Member", member.name, context);
  }

  void _fixConstantDependencyInfo(DependencyInfo info, ConstantValue constant,
      LibraryEntity library, Spannable context) {
    if (info.isDeferred || compiler.options.newDeferredSplit) return;
    if (constant is TypeConstantValue) {
      var type = constant.representedType;
      if (type is InterfaceType) {
        var imports = classImportsTo(type.element, library);
        _fixDependencyInfo(
            info, imports, "Class (in constant) ", type.element.name, context);
      } else if (type is TypedefType) {
        var imports = typedefImportsTo(type.element, library);
        _fixDependencyInfo(
            info, imports, "Typedef ", type.element.name, context);
      }
    }
  }

  void _processDependencies(LibraryEntity library, Dependencies dependencies,
      ImportSet oldSet, ImportSet newSet, WorkQueue queue, Spannable context) {
    dependencies.classes.forEach((ClassEntity cls, DependencyInfo info) {
      _fixClassDependencyInfo(info, cls, library, context);
      if (info.isDeferred) {
        if (_shouldAddDeferredDependency(newSet)) {
          for (ImportEntity deferredImport in info.imports) {
            queue.addClass(cls, importSets.singleton(deferredImport));
          }
        }
      } else {
        _updateClassRecursive(cls, oldSet, newSet, queue);
      }
    });

    dependencies.members.forEach((MemberEntity member, DependencyInfo info) {
      _fixMemberDependencyInfo(info, member, library, context);
      if (info.isDeferred) {
        if (_shouldAddDeferredDependency(newSet)) {
          for (ImportEntity deferredImport in info.imports) {
            queue.addMember(member, importSets.singleton(deferredImport));
          }
        }
      } else {
        _updateMemberRecursive(member, oldSet, newSet, queue);
      }
    });

    for (Local localFunction in dependencies.localFunctions) {
      _updateLocalFunction(localFunction, oldSet, newSet);
    }

    dependencies.constants
        .forEach((ConstantValue constant, DependencyInfo info) {
      _fixConstantDependencyInfo(info, constant, library, context);
      if (info.isDeferred) {
        if (_shouldAddDeferredDependency(newSet)) {
          for (ImportEntity deferredImport in info.imports) {
            queue.addConstant(constant, importSets.singleton(deferredImport));
          }
        }
      } else {
        _updateConstantRecursive(constant, oldSet, newSet, queue);
      }
    });
  }

  /// Adds extra dependencies coming from mirror usage.
  void addDeferredMirrorElements(WorkQueue queue);

  /// Add extra dependencies coming from mirror usage in [root] marking it with
  /// [newSet].
  void addMirrorElementsForLibrary(
      WorkQueue queue, LibraryEntity root, ImportSet newSet);

  /// Computes a unique string for the name field for each outputUnit.
  void _createOutputUnits() {
    int counter = 1;
    void addUnit(ImportSet importSet) {
      if (importSet.unit != null) return;
      var unit = new OutputUnit(false, '$counter',
          importSet._imports.map((i) => i.declaration).toSet());
      counter++;
      importSet.unit = unit;
      _allOutputUnits.add(unit);
    }

    // Generate an output unit for all import sets that are associated with an
    // element or constant.
    _classToSet.values.forEach(addUnit);
    _memberToSet.values.forEach(addUnit);
    _localFunctionToSet.values.forEach(addUnit);
    _constantToSet.values.forEach(addUnit);

    // Sort output units to make the output of the compiler more stable.
    _allOutputUnits.sort();
  }

  Map<String, List<OutputUnit>> _setupHunksToLoad() {
    Map<String, List<OutputUnit>> hunksToLoad = {};
    Set<String> usedImportNames = new Set<String>();

    for (ImportEntity import in _allDeferredImports) {
      String result = computeImportDeferName(import, compiler);
      assert(result != null);
      // Note: tools that process the json file to build multi-part initial load
      // bundles depend on the fact that makeUnique appends only digits, or a
      // period followed by digits.
      _importDeferName[import] = makeUnique(result, usedImportNames, '.');
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
    List<OutputUnit> sortedOutputUnits = _allOutputUnits.reversed.toList();

    // For each deferred import we find out which outputUnits to load.
    for (ImportEntity import in _allDeferredImports) {
      // We expect to find an entry for any call to `loadLibrary`, even if
      // there is no code to load. In that case, the entry will be an empty
      // list.
      hunksToLoad[_importDeferName[import]] = new List<OutputUnit>();
      for (OutputUnit outputUnit in sortedOutputUnits) {
        if (outputUnit == _mainOutputUnit) continue;
        if (outputUnit._imports.contains(import)) {
          hunksToLoad[_importDeferName[import]].add(outputUnit);
        }
      }
    }
    return hunksToLoad;
  }

  /// Returns a name for a deferred import.
  String computeImportDeferName(ImportEntity declaration, Compiler compiler) {
    assert(declaration.isDeferred);
    if (declaration.name != null) {
      return declaration.name;
    } else {
      // This happens when the deferred import isn't declared with a prefix.
      assert(compiler.compilationFailed);
      return '';
    }
  }

  /// Performs the deferred loading algorithm.
  ///
  /// The deferred loading algorithm maps elements and constants to an output
  /// unit. Each output unit is identified by a subset of deferred imports (an
  /// [ImportSet]), and they will contain the elements that are inherently used
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
  OutputUnitData run(FunctionEntity main, KClosedWorld closedWorld) {
    if (!isProgramSplit || main == null || disableProgramSplit) {
      return _buildResult();
    }

    work() {
      var queue = new WorkQueue(this.importSets);

      // Add `main` and their recursive dependencies to the main output unit.
      // We do this upfront to avoid wasting time visiting these elements when
      // analyzing deferred imports.
      queue.addMember(main, importSets.mainSet);

      // Also add "global" dependencies to the main output unit.  These are
      // things that the backend needs but cannot associate with a particular
      // element. This set also contains elements for which we lack precise
      // information.
      for (MemberEntity element
          in closedWorld.backendUsage.globalFunctionDependencies) {
        queue.addMember(element, importSets.mainSet);
      }
      for (ClassEntity element
          in closedWorld.backendUsage.globalClassDependencies) {
        queue.addClass(element, importSets.mainSet);
      }

      void emptyQueue() {
        while (queue.isNotEmpty) {
          WorkItem item = queue.nextItem();
          item.update(this, queue);
        }
      }

      emptyQueue();
    }

    reporter.withCurrentElement(main.library, () => measure(work));

    // Notify that we no longer need impacts for deferred load, so they can be
    // discarded at this time.
    compiler.impactStrategy.onImpactUsed(DeferredLoadTask.IMPACT_USE);
    return _buildResult();
  }

  OutputUnitData _buildResult() {
    _createOutputUnits();
    Map<String, List<OutputUnit>> hunksToLoad = _setupHunksToLoad();
    Map<ClassEntity, OutputUnit> classMap = <ClassEntity, OutputUnit>{};
    Map<MemberEntity, OutputUnit> memberMap = <MemberEntity, OutputUnit>{};
    Map<Local, OutputUnit> localFunctionMap = <Local, OutputUnit>{};
    Map<ConstantValue, OutputUnit> constantMap = <ConstantValue, OutputUnit>{};
    _classToSet.forEach((cls, s) => classMap[cls] = s.unit);
    _memberToSet.forEach((member, s) => memberMap[member] = s.unit);
    _localFunctionToSet.forEach(
        (localFunction, s) => localFunctionMap[localFunction] = s.unit);
    _constantToSet.forEach((constant, s) => constantMap[constant] = s.unit);

    _classToSet = null;
    _memberToSet = null;
    _localFunctionToSet = null;
    _constantToSet = null;
    cleanup();
    return new OutputUnitData(
        this.isProgramSplit && !disableProgramSplit,
        this._mainOutputUnit,
        classMap,
        memberMap,
        localFunctionMap,
        constantMap,
        _allOutputUnits,
        _importDeferName,
        hunksToLoad,
        _deferredImportDescriptions);
  }

  /// Frees up strategy-specific temporary data.
  void cleanup() {}

  void beforeResolution(Uri rootLibraryUri, Iterable<Uri> libraries) {
    measureSubtask('prepare', () {
      for (Uri uri in libraries) {
        LibraryEntity library = elementEnvironment.lookupLibrary(uri);
        reporter.withCurrentElement(library, () {
          checkForDeferredErrorCases(library);
          for (ImportEntity import in elementEnvironment.getImports(library)) {
            if (import.isDeferred) {
              _deferredImportDescriptions[import] =
                  new ImportDescription(import, library, rootLibraryUri);
              isProgramSplit = true;
            }
          }
        });
      }
    });
  }

  /// Detects errors like duplicate uses of a prefix or using the old deferred
  /// loading syntax.
  ///
  /// These checks are already done by the shared front-end, so they can be
  /// skipped by the new compiler pipeline.
  void checkForDeferredErrorCases(LibraryEntity library);

  bool ignoreEntityInDump(Entity element) => false;

  /// Creates a textual representation of the output unit content.
  String dump() {
    Map<OutputUnit, List<String>> elementMap = <OutputUnit, List<String>>{};
    Map<OutputUnit, List<String>> constantMap = <OutputUnit, List<String>>{};
    _classToSet.forEach((ClassEntity element, ImportSet importSet) {
      if (ignoreEntityInDump(element)) return;
      var elements = elementMap.putIfAbsent(importSet.unit, () => <String>[]);
      var id = element.name ?? '$element';
      id = '$id cls';
      elements.add(id);
    });
    _memberToSet.forEach((MemberEntity element, ImportSet importSet) {
      if (ignoreEntityInDump(element)) return;
      var elements = elementMap.putIfAbsent(importSet.unit, () => <String>[]);
      var id = element.name ?? '$element';
      var cls = element.enclosingClass?.name;
      if (cls != null) id = '$cls.$id';
      if (element.isSetter) id = '$id=';
      id = '$id member';
      elements.add(id);
    });
    _localFunctionToSet.forEach((Local element, ImportSet importSet) {
      if (ignoreEntityInDump(element)) return;
      var elements = elementMap.putIfAbsent(importSet.unit, () => <String>[]);
      var id = element.name ?? '$element';
      var context = (element as dynamic).memberContext.name;
      id = element.name == null || element.name == '' ? '<anonymous>' : id;
      id = '$context.$id';
      id = '$id local';
      elements.add(id);
    });
    _constantToSet.forEach((ConstantValue value, ImportSet importSet) {
      // Skip primitive values: they are not stored in the constant tables and
      // if they are shared, they end up duplicated anyways across output units.
      if (value.isPrimitive) return;
      constantMap
          .putIfAbsent(importSet.unit, () => <String>[])
          .add(value.toStructuredText());
    });

    Map<OutputUnit, String> text = {};
    for (OutputUnit outputUnit in _allOutputUnits) {
      StringBuffer unitText = new StringBuffer();
      if (outputUnit.isMainOutput) {
        unitText.write(' <MAIN UNIT>');
      } else {
        unitText.write(' imports:');
        var imports = outputUnit._imports
            .map((i) => '${i.enclosingLibraryUri.resolveUri(i.uri)}')
            .toList();
        for (var i in imports..sort()) {
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
    for (OutputUnit outputUnit in _allOutputUnits.toList()
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

  final LibraryEntity _importingLibrary;

  ImportDescription.internal(
      this.importingUri, this.prefix, this._importingLibrary);

  ImportDescription(
      ImportEntity import, LibraryEntity importingLibrary, Uri mainLibraryUri)
      : this.internal(
            uri_extras.relativize(
                mainLibraryUri, importingLibrary.canonicalUri, false),
            import.name,
            importingLibrary);
}

/// Indirectly represents a deferred import in an [ImportSet].
///
/// We could directly store the [declaration] in [ImportSet], but adding this
/// class makes some of the import set operations more efficient.
class _DeferredImport {
  final ImportEntity declaration;

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
  Map<ImportEntity, _DeferredImport> _importIndex = {};

  /// The canonical instance representing the empty import set.
  ImportSet _emptySet = new ImportSet();

  /// The import set representing the main output unit, which happens to be
  /// implemented as an empty set in our algorithm.
  ImportSet get mainSet => _emptySet;

  /// Get the singleton import set that only contains [import].
  ImportSet singleton(ImportEntity import) {
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
  _DeferredImport _wrap(ImportEntity import) {
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
    ImportSet result = _transitions[import];
    if (result == null) {
      result = new ImportSet(new List.from(_imports)..add(import));
      result._transitions[import] = result;
      _transitions[import] = result;
    }
    return result;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('ImportSet(size: $length, ');
    for (var import in _imports) {
      sb.write('${import.declaration.name} ');
    }
    sb.write(')');
    return '$sb';
  }
}

/// The algorithm work queue.
class WorkQueue {
  /// The actual queue of work that needs to be done.
  final Queue<WorkItem> queue = new Queue<WorkItem>();

  /// An index to find work items in the queue corresponding to a class.
  final Map<ClassEntity, WorkItem> pendingClasses = <ClassEntity, WorkItem>{};

  /// An index to find work items in the queue corresponding to a member.
  final Map<MemberEntity, WorkItem> pendingMembers = <MemberEntity, WorkItem>{};

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
    return queue.removeFirst();
  }

  /// Add to the queue that [element] should be updated to include all imports
  /// in [importSet]. If there is already a work item in the queue for
  /// [element], this makes sure that the work item now includes the union of
  /// [importSet] and the existing work item's import set.
  void addClass(ClassEntity element, ImportSet importSet) {
    var item = pendingClasses[element];
    if (item == null) {
      item = new ClassWorkItem(element, importSet);
      pendingClasses[element] = item;
      queue.add(item);
    } else {
      item.importsToAdd = _importSets.union(item.importsToAdd, importSet);
    }
  }

  /// Add to the queue that [element] should be updated to include all imports
  /// in [importSet]. If there is already a work item in the queue for
  /// [element], this makes sure that the work item now includes the union of
  /// [importSet] and the existing work item's import set.
  void addMember(MemberEntity element, ImportSet importSet) {
    var item = pendingMembers[element];
    if (item == null) {
      item = new MemberWorkItem(element, importSet);
      pendingMembers[element] = item;
      queue.add(item);
    } else {
      item.importsToAdd = _importSets.union(item.importsToAdd, importSet);
    }
  }

  /// Add to the queue that [constant] should be updated to include all imports
  /// in [importSet]. If there is already a work item in the queue for
  /// [constant], this makes sure that the work item now includes the union of
  /// [importSet] and the existing work item's import set.
  void addConstant(ConstantValue constant, ImportSet importSet) {
    var item = pendingConstants[constant];
    if (item == null) {
      item = new ConstantWorkItem(constant, importSet);
      pendingConstants[constant] = item;
      queue.add(item);
    } else {
      item.importsToAdd = _importSets.union(item.importsToAdd, importSet);
    }
  }
}

/// Summary of the work that needs to be done on a class, member, or constant.
abstract class WorkItem {
  /// Additional imports that use [element] or [value] and need to be added by
  /// the algorithm.
  ///
  /// This is non-final in case we add more deferred imports to the set before
  /// the work item is applied (see [WorkQueue.addElement] and
  /// [WorkQueue.addConstant]).
  ImportSet importsToAdd;

  WorkItem(this.importsToAdd);

  void update(DeferredLoadTask task, WorkQueue queue);
}

/// Summary of the work that needs to be done on a class.
class ClassWorkItem extends WorkItem {
  /// Class to be recursively updated.
  final ClassEntity cls;

  ClassWorkItem(this.cls, ImportSet newSet) : super(newSet);

  void update(DeferredLoadTask task, WorkQueue queue) {
    queue.pendingClasses.remove(cls);
    ImportSet oldSet = task._classToSet[cls];
    ImportSet newSet = task.importSets.union(oldSet, importsToAdd);
    task._updateClassRecursive(cls, oldSet, newSet, queue);
  }
}

/// Summary of the work that needs to be done on a member.
class MemberWorkItem extends WorkItem {
  /// Member to be recursively updated.
  final MemberEntity member;

  MemberWorkItem(this.member, ImportSet newSet) : super(newSet);

  void update(DeferredLoadTask task, WorkQueue queue) {
    queue.pendingMembers.remove(member);
    ImportSet oldSet = task._memberToSet[member];
    ImportSet newSet = task.importSets.union(oldSet, importsToAdd);
    task._updateMemberRecursive(member, oldSet, newSet, queue);
  }
}

/// Summary of the work that needs to be done on a constant.
class ConstantWorkItem extends WorkItem {
  /// Constant to be recursively updated.
  final ConstantValue constant;

  ConstantWorkItem(this.constant, ImportSet newSet) : super(newSet);

  void update(DeferredLoadTask task, WorkQueue queue) {
    queue.pendingConstants.remove(constant);
    ImportSet oldSet = task._constantToSet[constant];
    ImportSet newSet = task.importSets.union(oldSet, importsToAdd);
    task._updateConstantRecursive(constant, oldSet, newSet, queue);
  }
}

/// Results of the deferred loading algorithm.
///
/// Provides information about the output unit associated with entities and
/// constants, as well as other helper methods.
// TODO(sigmund): consider moving here every piece of data used as a result of
// deferred loading (including hunksToLoad, etc).
class OutputUnitData {
  /// Tag used for identifying serialized [OutputUnitData] objects in a
  /// debugging data stream.
  static const String tag = 'output-unit-data';

  final bool isProgramSplit;
  final OutputUnit mainOutputUnit;
  final Map<ClassEntity, OutputUnit> _classToUnit;
  final Map<MemberEntity, OutputUnit> _memberToUnit;
  final Map<Local, OutputUnit> _localFunctionToUnit;
  final Map<ConstantValue, OutputUnit> _constantToUnit;
  final Iterable<OutputUnit> outputUnits;
  final Map<ImportEntity, String> _importDeferName;

  /// A mapping from the name of a defer import to all the output units it
  /// depends on in a list of lists to be loaded in the order they appear.
  ///
  /// For example {"lib1": [[lib1_lib2_lib3], [lib1_lib2, lib1_lib3],
  /// [lib1]]} would mean that in order to load "lib1" first the hunk
  /// lib1_lib2_lib2 should be loaded, then the hunks lib1_lib2 and lib1_lib3
  /// can be loaded in parallel. And finally lib1 can be loaded.
  final Map<String, List<OutputUnit>> hunksToLoad;

  /// Because the token-stream is forgotten later in the program, we cache a
  /// description of each deferred import.
  final Map<ImportEntity, ImportDescription> _deferredImportDescriptions;

  OutputUnitData(
      this.isProgramSplit,
      this.mainOutputUnit,
      this._classToUnit,
      this._memberToUnit,
      this._localFunctionToUnit,
      this._constantToUnit,
      this.outputUnits,
      this._importDeferName,
      this.hunksToLoad,
      this._deferredImportDescriptions);

  // Creates J-world data from the K-world data.
  factory OutputUnitData.from(
      OutputUnitData other,
      LibraryEntity convertLibrary(LibraryEntity library),
      Map<ClassEntity, OutputUnit> Function(
              Map<ClassEntity, OutputUnit>, Map<Local, OutputUnit>)
          convertClassMap,
      Map<MemberEntity, OutputUnit> Function(
              Map<MemberEntity, OutputUnit>, Map<Local, OutputUnit>)
          convertMemberMap,
      Map<ConstantValue, OutputUnit> Function(Map<ConstantValue, OutputUnit>)
          convertConstantMap) {
    Map<ClassEntity, OutputUnit> classToUnit =
        convertClassMap(other._classToUnit, other._localFunctionToUnit);
    Map<MemberEntity, OutputUnit> memberToUnit =
        convertMemberMap(other._memberToUnit, other._localFunctionToUnit);
    Map<ConstantValue, OutputUnit> constantToUnit =
        convertConstantMap(other._constantToUnit);
    Map<ImportEntity, ImportDescription> deferredImportDescriptions = {};
    other._deferredImportDescriptions
        .forEach((ImportEntity import, ImportDescription description) {
      deferredImportDescriptions[import] = new ImportDescription.internal(
          description.importingUri,
          description.prefix,
          convertLibrary(description._importingLibrary));
    });

    return new OutputUnitData(
        other.isProgramSplit,
        other.mainOutputUnit,
        classToUnit,
        memberToUnit,
        // Local functions only make sense in the K-world model.
        const <Local, OutputUnit>{},
        constantToUnit,
        other.outputUnits,
        other._importDeferName,
        other.hunksToLoad,
        deferredImportDescriptions);
  }

  /// Deserializes an [OutputUnitData] object from [source].
  factory OutputUnitData.readFromDataSource(DataSource source) {
    source.begin(tag);
    bool isProgramSplit = source.readBool();
    List<OutputUnit> outputUnits = source.readList(() {
      bool isMainOutput = source.readBool();
      String name = source.readString();
      Set<ImportEntity> importSet = source.readImports().toSet();
      return new OutputUnit(isMainOutput, name, importSet);
    });
    OutputUnit mainOutputUnit = outputUnits[source.readInt()];

    Map<ClassEntity, OutputUnit> classToUnit = source.readClassMap(() {
      return outputUnits[source.readInt()];
    });
    Map<MemberEntity, OutputUnit> memberToUnit = source.readMemberMap(() {
      return outputUnits[source.readInt()];
    });
    Map<ConstantValue, OutputUnit> constantToUnit = source.readConstantMap(() {
      return outputUnits[source.readInt()];
    });
    Map<ImportEntity, String> importDeferName =
        source.readImportMap(source.readString);
    Map<String, List<OutputUnit>> hunksToLoad = source.readStringMap(() {
      return source.readList(() {
        return outputUnits[source.readInt()];
      });
    });
    Map<ImportEntity, ImportDescription> deferredImportDescriptions =
        source.readImportMap(() {
      String importingUri = source.readString();
      String prefix = source.readString();
      LibraryEntity importingLibrary = source.readLibrary();
      return new ImportDescription.internal(
          importingUri, prefix, importingLibrary);
    });
    source.end(tag);
    return new OutputUnitData(
        isProgramSplit,
        mainOutputUnit,
        classToUnit,
        memberToUnit,
        // Local functions only make sense in the K-world model.
        const <Local, OutputUnit>{},
        constantToUnit,
        outputUnits,
        importDeferName,
        hunksToLoad,
        deferredImportDescriptions);
  }

  /// Serializes this [OutputUnitData] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeBool(isProgramSplit);
    Map<OutputUnit, int> outputUnitIndices = {};
    sink.writeList(outputUnits, (OutputUnit outputUnit) {
      outputUnitIndices[outputUnit] = outputUnitIndices.length;
      sink.writeBool(outputUnit.isMainOutput);
      sink.writeString(outputUnit.name);
      sink.writeImports(outputUnit._imports);
    });
    sink.writeInt(outputUnitIndices[mainOutputUnit]);
    sink.writeClassMap(_classToUnit, (OutputUnit outputUnit) {
      sink.writeInt(outputUnitIndices[outputUnit]);
    });
    sink.writeMemberMap(_memberToUnit, (OutputUnit outputUnit) {
      sink.writeInt(outputUnitIndices[outputUnit]);
    });
    sink.writeConstantMap(_constantToUnit, (OutputUnit outputUnit) {
      sink.writeInt(outputUnitIndices[outputUnit]);
    });
    sink.writeImportMap(_importDeferName, sink.writeString);
    sink.writeStringMap(hunksToLoad, (List<OutputUnit> outputUnits) {
      sink.writeList(
          outputUnits,
          (OutputUnit outputUnit) =>
              sink.writeInt(outputUnitIndices[outputUnit]));
    });
    sink.writeImportMap(_deferredImportDescriptions,
        (ImportDescription importDescription) {
      sink.writeString(importDescription.importingUri);
      sink.writeString(importDescription.prefix);
      sink.writeLibrary(importDescription._importingLibrary);
    });
    sink.end(tag);
  }

  /// Returns the [OutputUnit] where [cls] belongs.
  OutputUnit outputUnitForClass(ClassEntity cls) {
    if (!isProgramSplit) return mainOutputUnit;
    OutputUnit unit = _classToUnit[cls];
    return unit ?? mainOutputUnit;
  }

  /// Returns the [OutputUnit] where [member] belongs.
  OutputUnit outputUnitForMember(MemberEntity member) {
    if (!isProgramSplit) return mainOutputUnit;
    OutputUnit unit = _memberToUnit[member];
    if (unit != null) return unit;
    if (member.isInstanceMember) {
      return outputUnitForClass(member.enclosingClass);
    }

    return mainOutputUnit;
  }

  /// Direct access to the output-unit to constants map used for testing.
  Iterable<ConstantValue> get constantsForTesting => _constantToUnit.keys;

  /// Returns the [OutputUnit] where [constant] belongs.
  OutputUnit outputUnitForConstant(ConstantValue constant) {
    if (!isProgramSplit) return mainOutputUnit;
    return _constantToUnit[constant];
  }

  /// Indicates whether [element] is deferred.
  bool isDeferredClass(ClassEntity element) {
    return outputUnitForClass(element) != mainOutputUnit;
  }

  /// Returns `true` if element [to] is reachable from element [from] without
  /// crossing a deferred import.
  ///
  /// For example, if we have two deferred libraries `A` and `B` that both
  /// import a library `C`, then even though elements from `A` and `C` end up in
  /// different output units, there is a non-deferred path between `A` and `C`.
  bool hasOnlyNonDeferredImportPaths(MemberEntity from, MemberEntity to) {
    OutputUnit outputUnitFrom = outputUnitForMember(from);
    OutputUnit outputUnitTo = outputUnitForMember(to);
    if (outputUnitTo == mainOutputUnit) return true;
    if (outputUnitFrom == mainOutputUnit) return false;
    return outputUnitTo._imports.containsAll(outputUnitFrom._imports);
  }

  /// Registers that a constant is used in the same deferred output unit as
  /// [field].
  void registerConstantDeferredUse(
      DeferredGlobalConstantValue constant, OutputUnit unit) {
    if (!isProgramSplit) return;
    assert(
        _constantToUnit[constant] == null || _constantToUnit[constant] == unit);
    _constantToUnit[constant] = unit;
  }

  /// Registers [newEntity] to be emitted in the same output unit as
  /// [existingEntity];
  void registerColocatedMembers(
      MemberEntity existingEntity, MemberEntity newEntity) {
    assert(_memberToUnit[newEntity] == null);
    _memberToUnit[newEntity] = outputUnitForMember(existingEntity);
  }

  /// Returns the unique name for the given deferred [import].
  String getImportDeferName(Spannable node, ImportEntity import) {
    String name = _importDeferName[import];
    if (name == null) {
      throw new SpannableAssertionFailure(
          node, "No deferred name for $import.");
    }
    return name;
  }

  /// Returns the names associated with each deferred import in [unit].
  Iterable<String> getImportNames(OutputUnit unit) {
    return unit._imports.map((i) => _importDeferName[i]);
  }

  /// Returns a json-style map for describing what files that are loaded by a
  /// given deferred import.
  /// The mapping is structured as:
  /// library uri -> {"name": library name, "files": (prefix -> list of files)}
  /// Where
  ///
  /// - <library uri> is the relative uri of the library making a deferred
  ///   import.
  /// - <library name> is the name of the library, or "<unnamed>" if it is
  ///   unnamed.
  /// - <prefix> is the `as` prefix used for a given deferred import.
  /// - <list of files> is a list of the filenames the must be loaded when that
  ///   import is loaded.
  Map<String, Map<String, dynamic>> computeDeferredMap(
      CompilerOptions options, ElementEnvironment elementEnvironment,
      {Set<OutputUnit> omittedUnits}) {
    omittedUnits ??= Set();
    Map<String, Map<String, dynamic>> mapping = {};

    _deferredImportDescriptions.keys.forEach((ImportEntity import) {
      List<OutputUnit> outputUnits = hunksToLoad[_importDeferName[import]];
      ImportDescription description = _deferredImportDescriptions[import];
      String getName(LibraryEntity library) {
        var name = elementEnvironment.getLibraryName(library);
        return name == '' ? '<unnamed>' : name;
      }

      Map<String, dynamic> libraryMap = mapping.putIfAbsent(
          description.importingUri,
          () => <String, dynamic>{
                "name": getName(description._importingLibrary),
                "imports": <String, List<String>>{}
              });

      List<String> partFileNames = outputUnits
          .where((outputUnit) => !omittedUnits.contains(outputUnit))
          .map((outputUnit) => deferredPartFileName(options, outputUnit.name))
          .toList();
      libraryMap["imports"][_importDeferName[import]] = partFileNames;
    });
    return mapping;
  }
}

/// Returns the filename for the output-unit named [name].
///
/// The filename is of the form "<main output file>_<name>.part.js".
/// If [addExtension] is false, the ".part.js" suffix is left out.
String deferredPartFileName(CompilerOptions options, String name,
    {bool addExtension: true}) {
  assert(name != "");
  String outPath = options.outputUri != null ? options.outputUri.path : "out";
  String outName = outPath.substring(outPath.lastIndexOf('/') + 1);
  String extension = addExtension ? ".part.js" : "";
  return "${outName}_$name$extension";
}

class Dependencies {
  final Map<ClassEntity, DependencyInfo> classes = {};
  final Map<MemberEntity, DependencyInfo> members = {};
  final Set<Local> localFunctions = new Set<Local>();
  final Map<ConstantValue, DependencyInfo> constants = {};

  void addClass(ClassEntity cls, [ImportEntity import]) {
    (classes[cls] ??= new DependencyInfo()).registerImport(import);
  }

  void addMember(MemberEntity m, [ImportEntity import]) {
    (members[m] ??= new DependencyInfo()).registerImport(import);
  }

  void addConstant(ConstantValue c, [ImportEntity import]) {
    (constants[c] ??= new DependencyInfo()).registerImport(import);
  }
}

class DependencyInfo {
  bool isDeferred = true;
  List<ImportEntity> imports;

  registerImport(ImportEntity import) {
    if (!isDeferred) return;
    // A null import represents a direct non-deferred dependency.
    if (import != null) {
      (imports ??= []).add(import);
    } else {
      imports = null;
      isDeferred = false;
    }
  }
}
