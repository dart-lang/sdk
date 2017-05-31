// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_load;

import 'common/tasks.dart' show CompilerTask;
import 'common.dart';
import 'compiler.dart' show Compiler;
import 'constants/expressions.dart' show ConstantExpression;
import 'constants/values.dart'
    show
        ConstantValue,
        ConstructedConstantValue,
        DeferredConstantValue,
        StringConstantValue;
import 'elements/resolution_types.dart';
import 'elements/elements.dart'
    show
        AccessorElement,
        AstElement,
        ClassElement,
        Element,
        Elements,
        ExportElement,
        FunctionElement,
        ImportElement,
        LibraryElement,
        MemberElement,
        MethodElement,
        MetadataAnnotation,
        PrefixElement,
        ResolvedAstKind,
        TypedefElement;
import 'elements/entities.dart';
import 'js_backend/js_backend.dart' show JavaScriptBackend;
import 'resolution/resolution.dart' show AnalyzableElementX;
import 'resolution/tree_elements.dart' show TreeElements;
import 'tree/tree.dart' as ast;
import 'universe/use.dart' show StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import 'universe/world_impact.dart'
    show ImpactUseCase, WorldImpact, WorldImpactVisitorImpl;
import 'util/setlet.dart' show Setlet;
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
/// OutputUnits are equal if their [imports] are equal.
class OutputUnit {
  /// The deferred imports that will load this output unit when one of them is
  /// loaded.
  final Setlet<_DeferredImport> imports = new Setlet<_DeferredImport>();

  /// `true` if this output unit is for the main output file.
  final bool isMainOutput;

  /// A unique name representing this [OutputUnit].
  String name;

  OutputUnit({this.isMainOutput: false});

  String toString() => "OutputUnit($name)";

  bool operator ==(OutputUnit other) {
    return imports.length == other.imports.length &&
        imports.containsAll(other.imports);
  }

  int get hashCode {
    int sum = 0;
    for (_DeferredImport import in imports) {
      sum = (sum + import.hashCode) & 0x3FFFFFFF; // Stay in 30 bit range.
    }
    return sum;
  }
}

/// For each deferred import, find elements and constants to be loaded when that
/// import is loaded. Elements that are used by several deferred imports are in
/// shared OutputUnits.
class DeferredLoadTask extends CompilerTask {
  /// The name of this task.
  String get name => 'Deferred Loading';

  /// DeferredLibrary from dart:async
  ClassElement get deferredLibraryClass =>
      compiler.commonElements.deferredLibraryClass;

  /// A synthetic import representing the loading of the main program.
  final _DeferredImport _fakeMainImport = const _DeferredImport();

  /// The OutputUnit that will be loaded when the program starts.
  final OutputUnit mainOutputUnit = new OutputUnit(isMainOutput: true);

  /// A set containing (eventually) all output units that will result from the
  /// program.
  final Set<OutputUnit> allOutputUnits = new Set<OutputUnit>();

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
  final Map<_DeferredImport, String> importDeferName =
      <_DeferredImport, String>{};

  /// A mapping from elements and constants to their output unit. Query this via
  /// [outputUnitForElement]
  final Map<Element, OutputUnit> _elementToOutputUnit =
      new Map<Element, OutputUnit>();

  /// A mapping from constants to their output unit. Query this via
  /// [outputUnitForConstant]
  final Map<ConstantValue, OutputUnit> _constantToOutputUnit =
      new Map<ConstantValue, OutputUnit>();

  /// All the imports with a [DeferredLibrary] annotation, mapped to the
  /// [LibraryElement] they import.
  /// The main library is included in this set for convenience.
  final Map<_DeferredImport, LibraryElement> _allDeferredImports =
      new Map<_DeferredImport, LibraryElement>();

  /// Because the token-stream is forgotten later in the program, we cache a
  /// description of each deferred import.
  final Map<_DeferredImport, ImportDescription> _deferredImportDescriptions =
      <_DeferredImport, ImportDescription>{};

  // For each deferred import we want to know exactly what elements have to
  // be loaded.
  Map<_DeferredImport, Set<Element>> _importedDeferredBy = null;
  Map<_DeferredImport, Set<ConstantValue>> _constantsDeferredBy = null;

  Set<Element> _mainElements = new Set<Element>();

  final Compiler compiler;
  DeferredLoadTask(Compiler compiler)
      : compiler = compiler,
        super(compiler.measurer) {
    mainOutputUnit.imports.add(_fakeMainImport);
  }

  JavaScriptBackend get backend => compiler.backend;
  DiagnosticReporter get reporter => compiler.reporter;

  /// Returns the [OutputUnit] where [element] belongs.
  OutputUnit outputUnitForElement(Entity entity) {
    // TODO(johnniwinther): Support use of entities by splitting maps by
    // entity kind.
    if (!isProgramSplit) return mainOutputUnit;
    Element element = entity;
    element = element.implementation;
    while (!_elementToOutputUnit.containsKey(element)) {
      // TODO(21051): workaround: it looks like we output annotation constants
      // for classes that we don't include in the output. This seems to happen
      // when we have reflection but can see that some classes are not needed.
      // We still add the annotation but don't run through it below (where we
      // assign every element to its output unit).
      if (element.enclosingElement == null) {
        _elementToOutputUnit[element] = mainOutputUnit;
        break;
      }
      element = element.enclosingElement.implementation;
    }
    return _elementToOutputUnit[element];
  }

  /// Returns the [OutputUnit] where [element] belongs.
  OutputUnit outputUnitForClass(ClassEntity element) {
    return outputUnitForElement(element);
  }

  /// Returns the [OutputUnit] where [element] belongs.
  OutputUnit outputUnitForMember(MemberEntity element) {
    return outputUnitForElement(element);
  }

  /// Direct access to the output-unit to element relation used for testing.
  OutputUnit getOutputUnitForElementForTesting(Element element) {
    return _elementToOutputUnit[element];
  }

  /// Returns the [OutputUnit] where [constant] belongs.
  OutputUnit outputUnitForConstant(ConstantValue constant) {
    if (!isProgramSplit) return mainOutputUnit;
    return _constantToOutputUnit[constant];
  }

  /// Direct access to the output-unit to constants map used for testing.
  Map<ConstantValue, OutputUnit> get outputUnitForConstantsForTesting {
    return _constantToOutputUnit;
  }

  bool isDeferred(Element element) {
    return outputUnitForElement(element) != mainOutputUnit;
  }

  bool isDeferredClass(ClassElement element) {
    return outputUnitForElement(element) != mainOutputUnit;
  }

  /// Returns the unique name for the deferred import of [prefix].
  String getImportDeferName(Spannable node, PrefixElement prefix) {
    String name =
        importDeferName[new _DeclaredDeferredImport(prefix.deferredImport)];
    if (name == null) {
      reporter.internalError(node, "No deferred name for $prefix.");
    }
    return name;
  }

  /// Returns `true` if element [to] is reachable from element [from] without
  /// crossing a deferred import.
  ///
  /// For example, if we have two deferred libraries `A` and `B` that both
  /// import a library `C`, then even though elements from `A` and `C` end up in
  /// different output units, there is a non-deferred path between `A` and `C`.
  bool hasOnlyNonDeferredImportPaths(Element from, Element to) {
    OutputUnit outputUnitFrom = outputUnitForElement(from);
    OutputUnit outputUnitTo = outputUnitForElement(to);
    return outputUnitTo.imports.containsAll(outputUnitFrom.imports);
  }

  // TODO(het): use a union-find to canonicalize output units
  OutputUnit _getCanonicalUnit(OutputUnit outputUnit) {
    OutputUnit representative = allOutputUnits.lookup(outputUnit);
    if (representative == null) {
      representative = outputUnit;
      allOutputUnits.add(representative);
    }
    return representative;
  }

  void registerConstantDeferredUse(
      DeferredConstantValue constant, PrefixElement prefix) {
    OutputUnit outputUnit = new OutputUnit();
    outputUnit.imports.add(new _DeclaredDeferredImport(prefix.deferredImport));

    // Check to see if there is already a canonical output unit registered.
    _constantToOutputUnit[constant] = _getCanonicalUnit(outputUnit);
  }

  /// Answers whether [element] is explicitly deferred when referred to from
  /// [library].
  bool _isExplicitlyDeferred(Element element, LibraryElement library) {
    Iterable<ImportElement> imports = _getImports(element, library);
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
  Iterable<ImportElement> _getImports(Element element, LibraryElement library) {
    if (element.isClassMember) {
      element = element.enclosingClass;
    }
    if (element.isAccessor) {
      element = (element as AccessorElement).abstractField;
    }
    return library.getImportsFor(element);
  }

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

    /// Recursively collects all the dependencies of [type].
    void collectTypeDependencies(ResolutionDartType type) {
      // TODO(het): we would like to separate out types that are only needed for
      // rti from types that are needed for their members.
      if (type is GenericType) {
        type.typeArguments.forEach(collectTypeDependencies);
      }
      if (type is ResolutionFunctionType) {
        for (ResolutionDartType argumentType in type.parameterTypes) {
          collectTypeDependencies(argumentType);
        }
        for (ResolutionDartType argumentType in type.optionalParameterTypes) {
          collectTypeDependencies(argumentType);
        }
        for (ResolutionDartType argumentType in type.namedParameterTypes) {
          collectTypeDependencies(argumentType);
        }
        collectTypeDependencies(type.returnType);
      } else if (type is ResolutionTypedefType) {
        elements.add(type.element);
        collectTypeDependencies(type.unaliased);
      } else if (type is ResolutionInterfaceType) {
        elements.add(type.element);
      }
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
        collectTypeDependencies(typdef.thisType);
      } else {
        // TODO(sigurdm): We want to be more specific about this - need a better
        // way to query "liveness".
        MemberElement analyzableElement = element.analyzableElement.declaration;
        if (!compiler.resolutionWorldBuilder.isMemberUsed(analyzableElement)) {
          return;
        }

        WorldImpact worldImpact =
            compiler.resolution.getWorldImpact(analyzableElement);
        compiler.impactStrategy.visitImpact(
            analyzableElement,
            worldImpact,
            new WorldImpactVisitorImpl(visitStaticUse: (StaticUse staticUse) {
              elements.add(staticUse.element);
              switch (staticUse.kind) {
                case StaticUseKind.CONSTRUCTOR_INVOKE:
                case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
                  collectTypeDependencies(staticUse.type);
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
                  collectTypeDependencies(type);
                  break;
                case TypeUseKind.CHECKED_MODE_CHECK:
                  if (compiler.options.enableTypeAssertions) {
                    collectTypeDependencies(type);
                  }
                  break;
              }
            }),
            IMPACT_USE);

        if (analyzableElement.resolvedAst.kind != ResolvedAstKind.PARSED) {
          return;
        }

        TreeElements treeElements = analyzableElement.resolvedAst.elements;
        assert(treeElements != null);

        // TODO(johnniwinther): Add only expressions that are actually needed.
        // Currently we have some noise here: Some potential expressions are
        // seen that should never be added (for instance field initializers
        // in constant constructors, like `this.field = parameter`). And some
        // implicit constant expression are seen that we should be able to add
        // (like primitive constant literals like `true`, `"foo"` and `0`).
        // See dartbug.com/26406 for context.
        treeElements.forEachConstantNode(
            (ast.Node node, ConstantExpression expression) {
          if (compiler.serialization.isDeserialized(analyzableElement)) {
            if (!expression.isPotential) {
              // Enforce evaluation of [expression].
              backend.constants.getConstantValue(expression);
            }
          }

          // Explicitly depend on the backend constants.
          if (backend.constants.hasConstantValue(expression)) {
            ConstantValue value =
                backend.constants.getConstantValue(expression);
            assert(
                value != null,
                failedAt(
                    node,
                    "Constant expression without value: "
                    "${expression.toStructuredText()}."));
            constants.add(value);
          } else {
            assert(
                expression.isImplicit || expression.isPotential,
                failedAt(
                    node,
                    "Unexpected unevaluated constant expression: "
                    "${expression.toStructuredText()}."));
          }
        });
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
      collectTypeDependencies(element.type);
    }

    if (element.isClass) {
      // If we see a class, add everything its live instance members refer
      // to.  Static members are not relevant, unless we are processing
      // extra dependencies due to mirrors.
      void addLiveInstanceMember(_, MemberElement element) {
        if (!compiler.resolutionWorldBuilder.isMemberUsed(element)) return;
        if (!isMirrorUsage && !element.isInstanceMember) return;
        elements.add(element);
        collectDependencies(element);
      }

      ClassElement cls = element.declaration;
      cls.implementation.forEachMember(addLiveInstanceMember);
      for (ResolutionInterfaceType type in cls.implementation.allSupertypes) {
        elements.add(type.element.implementation);
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

  /// Returns the transitive closure of all libraries that are imported
  /// from root without DeferredLibrary annotations.
  Set<LibraryElement> _nonDeferredReachableLibraries(LibraryElement root) {
    Set<LibraryElement> result = new Set<LibraryElement>();

    void traverseLibrary(LibraryElement library) {
      if (result.contains(library)) return;
      result.add(library);

      iterateTags(LibraryElement library) {
        // TODO(sigurdm): Make helper getLibraryDependencyTags when tags is
        // changed to be a List instead of a Link.
        for (ImportElement import in library.imports) {
          if (!import.isDeferred) {
            LibraryElement importedLibrary = import.importedLibrary;
            traverseLibrary(importedLibrary);
          }
        }
        for (ExportElement export in library.exports) {
          LibraryElement exportedLibrary = export.exportedLibrary;
          traverseLibrary(exportedLibrary);
        }
      }

      iterateTags(library);
      if (library.isPatched) {
        iterateTags(library.implementation);
      }
    }

    traverseLibrary(root);
    result.add(compiler.commonElements.coreLibrary);
    return result;
  }

  /// Add all dependencies of [constant] to the mapping of [import].
  void _mapConstantDependencies(
      ConstantValue constant, _DeferredImport import) {
    Set<ConstantValue> constants = _constantsDeferredBy.putIfAbsent(
        import, () => new Set<ConstantValue>());
    if (constants.contains(constant)) return;
    constants.add(constant);
    if (constant is ConstructedConstantValue) {
      ClassElement cls = constant.type.element;
      _mapDependencies(element: cls, import: import);
    }
    constant.getDependencies().forEach((ConstantValue dependency) {
      _mapConstantDependencies(dependency, import);
    });
  }

  /// Recursively traverses the graph of dependencies from one of [element]
  /// or [constant], mapping deferred imports to each dependency it needs in the
  /// sets [_importedDeferredBy] and [_constantsDeferredBy].
  /// Only one of [element] and [constant] should be given.
  void _mapDependencies(
      {Element element, _DeferredImport import, isMirrorUsage: false}) {
    Set<Element> elements =
        _importedDeferredBy.putIfAbsent(import, () => new Set<Element>());

    Set<Element> dependentElements = new Set<Element>();
    Set<ConstantValue> dependentConstants = new Set<ConstantValue>();

    LibraryElement library;

    if (element != null) {
      // Only process elements once, unless we are doing dependencies due to
      // mirrors, which are added in additional traversals.
      if (!isMirrorUsage && elements.contains(element)) return;
      // Anything used directly by main will be loaded from the start
      // We do not need to traverse it again.
      if (import != _fakeMainImport && _mainElements.contains(element)) return;
      elements.add(element);

      // This call can modify [dependentElements] and [dependentConstants].
      _collectAllElementsAndConstantsResolvedFrom(
          element, dependentElements, dependentConstants, isMirrorUsage);

      library = element.library;
    }

    for (Element dependency in dependentElements) {
      if (_isExplicitlyDeferred(dependency, library)) {
        for (ImportElement deferredImport in _getImports(dependency, library)) {
          _mapDependencies(
              element: dependency,
              import: new _DeclaredDeferredImport(deferredImport));
        }
      } else {
        _mapDependencies(element: dependency, import: import);
      }
    }

    for (ConstantValue dependency in dependentConstants) {
      if (dependency is DeferredConstantValue) {
        PrefixElement prefix = dependency.prefix;
        _mapConstantDependencies(
            dependency, new _DeclaredDeferredImport(prefix.deferredImport));
      } else {
        _mapConstantDependencies(dependency, import);
      }
    }
  }

  /// Adds extra dependencies coming from mirror usage.
  ///
  /// The elements are added with [_mapDependencies].
  void _addMirrorElements() {
    void mapDependenciesIfResolved(
        Element element, _DeferredImport deferredImport) {
      // If an element is the target of a MirrorsUsed annotation but never used
      // It will not be resolved, and we should not call isNeededForReflection.
      // TODO(sigurdm): Unresolved elements should just answer false when
      // asked isNeededForReflection. Instead an internal error is triggered.
      // So we have to filter them out here.
      if (element is AnalyzableElementX && !element.hasTreeElements) return;
      if (compiler.backend.mirrorsData.isAccessibleByReflection(element)) {
        _mapDependencies(
            element: element, import: deferredImport, isMirrorUsage: true);
      }
    }

    // For each deferred import we analyze all elements reachable from the
    // imported library through non-deferred imports.
    void handleLibrary(LibraryElement library, _DeferredImport deferredImport) {
      library.implementation.forEachLocalMember((Element element) {
        mapDependenciesIfResolved(element, deferredImport);
      });

      void processMetadata(Element element) {
        for (MetadataAnnotation metadata in element.metadata) {
          ConstantValue constant =
              backend.constants.getConstantValueForMetadata(metadata);
          if (constant != null) {
            _mapConstantDependencies(constant, deferredImport);
          }
        }
      }

      processMetadata(library);
      library.imports.forEach(processMetadata);
      library.exports.forEach(processMetadata);
    }

    for (_DeferredImport deferredImport in _allDeferredImports.keys) {
      LibraryElement deferredLibrary = _allDeferredImports[deferredImport];
      for (LibraryElement library
          in _nonDeferredReachableLibraries(deferredLibrary)) {
        handleLibrary(library, deferredImport);
      }
    }
  }

  /// Computes a unique string for the name field for each outputUnit.
  ///
  /// Also sets up the [hunksToLoad] mapping.
  void _assignNamesToOutputUnits(Set<OutputUnit> allOutputUnits) {
    Set<String> usedImportNames = new Set<String>();

    void computeImportDeferName(_DeferredImport import) {
      String result = import.computeImportDeferName(compiler);
      assert(result != null);
      importDeferName[import] = makeUnique(result, usedImportNames);
    }

    int counter = 1;

    for (_DeferredImport import in _allDeferredImports.keys) {
      computeImportDeferName(import);
    }

    for (OutputUnit outputUnit in allOutputUnits) {
      if (outputUnit == mainOutputUnit) {
        outputUnit.name = "main";
      } else {
        outputUnit.name = "$counter";
        ++counter;
      }
    }

    List sortedOutputUnits = new List.from(allOutputUnits);
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
    sortedOutputUnits.sort((a, b) => b.imports.length - a.imports.length);

    // For each deferred import we find out which outputUnits to load.
    for (_DeferredImport import in _allDeferredImports.keys) {
      if (import == _fakeMainImport) continue;
      hunksToLoad[importDeferName[import]] = new List<OutputUnit>();
      for (OutputUnit outputUnit in sortedOutputUnits) {
        if (outputUnit == mainOutputUnit) continue;
        if (outputUnit.imports.contains(import)) {
          hunksToLoad[importDeferName[import]].add(outputUnit);
        }
      }
    }
  }

  void onResolutionComplete(FunctionEntity main, ClosedWorld closedWorld) {
    if (!isProgramSplit) {
      allOutputUnits.add(mainOutputUnit);
      return;
    }
    if (main == null) return;
    MethodElement mainMethod = main;
    LibraryElement mainLibrary = mainMethod.library;
    _importedDeferredBy = new Map<_DeferredImport, Set<Element>>();
    _constantsDeferredBy = new Map<_DeferredImport, Set<ConstantValue>>();
    _importedDeferredBy[_fakeMainImport] = _mainElements;

    reporter.withCurrentElement(
        mainLibrary,
        () => measure(() {
              // Starting from main, traverse the program and find all
              // dependencies.
              _mapDependencies(element: mainMethod, import: _fakeMainImport);

              // Also add "global" dependencies to the main OutputUnit.  These
              // are things that the backend needs but cannot associate with a
              // particular element, for example, startRootIsolate.  This set
              // also contains elements for which we lack precise information.
              for (MethodElement element
                  in closedWorld.backendUsage.globalFunctionDependencies) {
                _mapDependencies(
                    element: element.implementation, import: _fakeMainImport);
              }
              for (ClassElement element
                  in closedWorld.backendUsage.globalClassDependencies) {
                _mapDependencies(
                    element: element.implementation, import: _fakeMainImport);
              }

              // Now check to see if we have to add more elements due to
              // mirrors.
              if (compiler.commonElements.mirrorsLibrary != null) {
                _addMirrorElements();
              }

              // Build the OutputUnits using these two maps.
              Map<Element, OutputUnit> elementToOutputUnitBuilder =
                  new Map<Element, OutputUnit>();
              Map<ConstantValue, OutputUnit> constantToOutputUnitBuilder =
                  new Map<ConstantValue, OutputUnit>();

              // Add all constants that may have been registered during
              // resolution with [registerConstantDeferredUse].
              constantToOutputUnitBuilder.addAll(_constantToOutputUnit);
              _constantToOutputUnit.clear();

              // Reverse the mappings. For each element record an OutputUnit
              // collecting all deferred imports mapped to this element. Same
              // for constants.
              for (_DeferredImport import in _importedDeferredBy.keys) {
                for (Element element in _importedDeferredBy[import]) {
                  // Only one file should be loaded when the program starts, so
                  // make sure that only one OutputUnit is created for
                  // [fakeMainImport].
                  if (import == _fakeMainImport) {
                    elementToOutputUnitBuilder[element] = mainOutputUnit;
                  } else {
                    elementToOutputUnitBuilder
                        .putIfAbsent(element, () => new OutputUnit())
                        .imports
                        .add(import);
                  }
                }
              }
              for (_DeferredImport import in _constantsDeferredBy.keys) {
                for (ConstantValue constant in _constantsDeferredBy[import]) {
                  // Only one file should be loaded when the program starts, so
                  // make sure that only one OutputUnit is created for
                  // [fakeMainImport].
                  if (import == _fakeMainImport) {
                    constantToOutputUnitBuilder[constant] = mainOutputUnit;
                  } else {
                    constantToOutputUnitBuilder
                        .putIfAbsent(constant, () => new OutputUnit())
                        .imports
                        .add(import);
                  }
                }
              }

              // Release maps;
              _importedDeferredBy = null;
              _constantsDeferredBy = null;

              // Find all the output units elements/constants have been mapped
              // to, and canonicalize them.
              elementToOutputUnitBuilder
                  .forEach((Element element, OutputUnit outputUnit) {
                _elementToOutputUnit[element] = _getCanonicalUnit(outputUnit);
              });
              constantToOutputUnitBuilder
                  .forEach((ConstantValue constant, OutputUnit outputUnit) {
                _constantToOutputUnit[constant] = _getCanonicalUnit(outputUnit);
              });

              // Generate a unique name for each OutputUnit.
              _assignNamesToOutputUnits(allOutputUnits);
            }));
    // Notify the impact strategy impacts are no longer needed for deferred
    // load.
    compiler.impactStrategy.onImpactUsed(IMPACT_USE);
  }

  void beforeResolution(Compiler compiler) {
    if (compiler.mainApp == null) return;
    // TODO(johnniwinther): Support deferred load for kernel based elements.
    if (compiler.options.loadFromDill) return;
    _allDeferredImports[_fakeMainImport] = compiler.mainApp;
    var lastDeferred;
    // When detecting duplicate prefixes of deferred libraries there are 4
    // cases of duplicate prefixes:
    // 1.
    // import "lib.dart" deferred as a;
    // import "lib2.dart" deferred as a;
    // 2.
    // import "lib.dart" deferred as a;
    // import "lib2.dart" as a;
    // 3.
    // import "lib.dart" as a;
    // import "lib2.dart" deferred as a;
    // 4.
    // import "lib.dart" as a;
    // import "lib2.dart" as a;
    // We must be able to signal error for case 1, 2, 3, but accept case 4.

    // The prefixes that have been used by any imports in this library.
    Setlet<String> usedPrefixes = new Setlet<String>();
    // The last deferred import we saw with a given prefix (if any).
    Map<String, ImportElement> prefixDeferredImport =
        new Map<String, ImportElement>();
    for (LibraryElement library in compiler.libraryLoader.libraries) {
      reporter.withCurrentElement(library, () {
        prefixDeferredImport.clear();
        usedPrefixes.clear();
        // TODO(sigurdm): Make helper getLibraryImportTags when tags is a List
        // instead of a Link.
        for (ImportElement import in library.imports) {
          /// Give an error if the old annotation-based syntax has been used.
          List<MetadataAnnotation> metadataList = import.metadata;
          if (metadataList != null) {
            for (MetadataAnnotation metadata in metadataList) {
              metadata.ensureResolved(compiler.resolution);
              ConstantValue value =
                  compiler.constants.getConstantValue(metadata.constant);
              ResolutionDartType type = value.getType(compiler.commonElements);
              Element element = type.element;
              if (element == deferredLibraryClass) {
                reporter.reportErrorMessage(
                    import, MessageKind.DEFERRED_OLD_SYNTAX);
              }
            }
          }

          String prefix = (import.prefix != null) ? import.prefix.name : null;
          // The last import we saw with the same prefix.
          ImportElement previousDeferredImport = prefixDeferredImport[prefix];
          if (import.isDeferred) {
            _DeferredImport key = new _DeclaredDeferredImport(import);
            LibraryElement importedLibrary = import.importedLibrary;
            _allDeferredImports[key] = importedLibrary;

            if (prefix == null) {
              reporter.reportErrorMessage(
                  import, MessageKind.DEFERRED_LIBRARY_WITHOUT_PREFIX);
            } else {
              prefixDeferredImport[prefix] = import;
              _deferredImportDescriptions[key] =
                  new ImportDescription(import, library, compiler);
            }
            isProgramSplit = true;
            lastDeferred = import;
          }
          if (prefix != null) {
            if (previousDeferredImport != null ||
                (import.isDeferred && usedPrefixes.contains(prefix))) {
              ImportElement failingImport = (previousDeferredImport != null)
                  ? previousDeferredImport
                  : import;
              reporter.reportErrorMessage(failingImport.prefix,
                  MessageKind.DEFERRED_LIBRARY_DUPLICATE_PREFIX);
            }
            usedPrefixes.add(prefix);
          }
        }
      });
    }
    if (isProgramSplit) {
      isProgramSplit =
          compiler.backend.enableDeferredLoadingIfSupported(lastDeferred);
    }
  }

  /// If [send] is a static send with a deferred element, returns the
  /// [PrefixElement] that the first prefix of the send resolves to.
  /// Otherwise returns null.
  ///
  /// Precondition: send must be static.
  ///
  /// Example:
  ///
  /// import "a.dart" deferred as a;
  ///
  /// main() {
  ///   print(a.loadLibrary.toString());
  ///   a.loadLibrary().then((_) {
  ///     a.run();
  ///     a.foo.method();
  ///   });
  /// }
  ///
  /// Returns null for a.loadLibrary() (the special
  /// function loadLibrary is not deferred). And returns the PrefixElement for
  /// a.run() and a.foo.
  /// a.loadLibrary.toString() and a.foo.method() are dynamic sends - and
  /// this functions should not be called on them.
  PrefixElement deferredPrefixElement(ast.Send send, TreeElements elements) {
    Element element = elements[send];
    // The DeferredLoaderGetter is not deferred, therefore we do not return the
    // prefix.
    if (element != null && element.isDeferredLoaderGetter) return null;

    ast.Node firstNode(ast.Node node) {
      if (node is! ast.Send) {
        return node;
      } else {
        ast.Send send = node;
        ast.Node receiver = send.receiver;
        ast.Node receiverFirst = firstNode(receiver);
        if (receiverFirst != null) {
          return receiverFirst;
        } else {
          return firstNode(send.selector);
        }
      }
    }

    ast.Node first = firstNode(send);
    ast.Node identifier = first.asIdentifier();
    if (identifier == null) return null;
    Element maybePrefix = elements[identifier];
    if (maybePrefix != null && maybePrefix.isPrefix) {
      PrefixElement prefixElement = maybePrefix;
      if (prefixElement.isDeferred) {
        return prefixElement;
      }
    }
    return null;
  }

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
    _deferredImportDescriptions.keys.forEach((_DeferredImport import) {
      List<OutputUnit> outputUnits = hunksToLoad[importDeferName[import]];
      ImportDescription description = _deferredImportDescriptions[import];
      Map<String, dynamic> libraryMap = mapping.putIfAbsent(
          description.importingUri,
          () => <String, dynamic>{
                "name": description.importingLibraryName,
                "imports": <String, List<String>>{}
              });

      libraryMap["imports"][importDeferName[import]] =
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
    _elementToOutputUnit.forEach((Element element, OutputUnit output) {
      elementMap.putIfAbsent(output, () => <String>[]).add('$element');
    });
    _constantToOutputUnit.forEach((ConstantValue value, OutputUnit output) {
      constantMap
          .putIfAbsent(output, () => <String>[])
          .add(value.toStructuredText());
    });

    StringBuffer sb = new StringBuffer();
    for (OutputUnit outputUnit in allOutputUnits) {
      sb.write('\n-------------------------------\n');
      sb.write('Output unit: ${outputUnit.name}');
      List<String> elements = elementMap[outputUnit];
      if (elements != null) {
        sb.write('\n elements:');
        for (String element in elements..sort()) {
          sb.write('\n  $element');
        }
      }
      List<String> constants = constantMap[outputUnit];
      if (constants != null) {
        sb.write('\n constants:');
        for (String value in constants..sort()) {
          sb.write('\n  $value');
        }
      }
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
      ImportElement import, LibraryElement importingLibrary, Compiler compiler)
      : importingUri = uri_extras.relativize(compiler.mainApp.canonicalUri,
            importingLibrary.canonicalUri, false),
        prefix = import.prefix.name,
        _importingLibrary = importingLibrary;

  String get importingLibraryName {
    return _importingLibrary.hasLibraryName
        ? _importingLibrary.libraryName
        : "<unnamed>";
  }
}

/// A node in the deferred import graph.
///
/// This class serves as the root node; the 'import' of the main library.
class _DeferredImport {
  const _DeferredImport();

  /// Computes a suggestive name for this import.
  String computeImportDeferName(Compiler compiler) => 'main';

  ImportElement get declaration => null;

  String toString() => 'main';
}

/// A node in the deferred import graph defined by a deferred import directive.
class _DeclaredDeferredImport implements _DeferredImport {
  final ImportElement declaration;

  _DeclaredDeferredImport(this.declaration);

  @override
  String computeImportDeferName(Compiler compiler) {
    String result;
    if (declaration.isDeferred) {
      if (declaration.prefix != null) {
        result = declaration.prefix.name;
      } else {
        // This happens when the deferred import isn't declared with a prefix.
        assert(compiler.compilationFailed);
        result = '';
      }
    } else {
      // Finds the first argument to the [DeferredLibrary] annotation
      List<MetadataAnnotation> metadatas = declaration.metadata;
      assert(metadatas != null);
      for (MetadataAnnotation metadata in metadatas) {
        metadata.ensureResolved(compiler.resolution);
        ConstantValue value =
            compiler.constants.getConstantValue(metadata.constant);
        ResolutionDartType type = value.getType(compiler.commonElements);
        Element element = type.element;
        if (element == compiler.commonElements.deferredLibraryClass) {
          ConstructedConstantValue constant = value;
          StringConstantValue s = constant.fields.values.single;
          result = s.primitiveValue;
          break;
        }
      }
    }
    assert(result != null);
    return result;
  }

  bool operator ==(other) {
    if (other is! _DeclaredDeferredImport) return false;
    return declaration == other.declaration;
  }

  int get hashCode => declaration.hashCode * 17;

  String toString() => '$declaration';
}
