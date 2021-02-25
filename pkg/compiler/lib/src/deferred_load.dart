// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_load;

import 'dart:collection' show Queue;

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import 'common/metrics.dart' show Metric, Metrics, CountMetric, DurationMetric;
import 'common/tasks.dart' show CompilerTask;
import 'common.dart';
import 'common_elements.dart'
    show CommonElements, ElementEnvironment, KElementEnvironment;
import 'compiler.dart' show Compiler;
import 'constants/values.dart'
    show
        ConstantValue,
        ConstructedConstantValue,
        DeferredGlobalConstantValue,
        InstantiationConstantValue;
import 'elements/types.dart';
import 'elements/entities.dart';
import 'ir/util.dart';
import 'kernel/kelements.dart' show KLocalFunction;
import 'kernel/element_map.dart';
import 'serialization/serialization.dart';
import 'options.dart';
import 'universe/use.dart';
import 'universe/world_impact.dart'
    show ImpactUseCase, WorldImpact, WorldImpactVisitorImpl;
import 'util/maplet.dart';
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

  @override
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

  void merge(OutputUnit that) {
    assert(this != that);
    // We don't currently support merging code into the main output unit.
    assert(!isMainOutput);
    this._imports.addAll(that._imports);
  }

  @override
  String toString() => "OutputUnit($name, $_imports)";
}

class _DeferredLoadTaskMetrics implements Metrics {
  @override
  String get namespace => 'deferred_load';

  DurationMetric time = DurationMetric('time');
  CountMetric hunkListElements = CountMetric('hunkListElements');

  @override
  Iterable<Metric> get primary => [time];

  @override
  Iterable<Metric> get secondary => [hunkListElements];
}

/// For each deferred import, find elements and constants to be loaded when that
/// import is loaded. Elements that are used by several deferred imports are in
/// shared OutputUnits.
class DeferredLoadTask extends CompilerTask {
  @override
  String get name => 'Deferred Loading';

  /// The OutputUnit that will be loaded when the program starts.
  OutputUnit _mainOutputUnit;

  /// A set containing (eventually) all output units that will result from the
  /// program.
  final List<OutputUnit> _allOutputUnits = [];

  /// Will be `true` if the program contains deferred libraries.
  bool isProgramSplit = false;

  static const ImpactUseCase IMPACT_USE = const ImpactUseCase('Deferred load');

  /// A cache of the result of calling `computeImportDeferName` on the keys of
  /// this map.
  final Map<ImportEntity, String> _importDeferName = {};

  /// A mapping from classes to their import set.
  Map<ClassEntity, ImportSet> _classToSet = {};

  /// A mapping from interface types (keyed by classes) to their import set.
  Map<ClassEntity, ImportSet> _classTypeToSet = {};

  /// A mapping from members to their import set.
  Map<MemberEntity, ImportSet> _memberToSet = {};

  /// A mapping from local functions to their import set.
  Map<Local, ImportSet> _localFunctionToSet = {};

  /// A mapping from constants to their import set.
  Map<ConstantValue, ImportSet> _constantToSet = {};

  Iterable<ImportEntity> get _allDeferredImports =>
      _deferredImportDescriptions.keys;

  /// Because the token-stream is forgotten later in the program, we cache a
  /// description of each deferred import.
  final Map<ImportEntity, ImportDescription> _deferredImportDescriptions = {};

  /// A lattice to compactly represent multiple subsets of imports.
  ImportSetLattice importSets = ImportSetLattice();

  final Compiler compiler;

  KernelToElementMap _elementMap;

  @override
  final _DeferredLoadTaskMetrics metrics = _DeferredLoadTaskMetrics();

  bool get disableProgramSplit => compiler.options.disableProgramSplit;

  DeferredLoadTask(this.compiler, this._elementMap) : super(compiler.measurer) {
    _mainOutputUnit = OutputUnit(true, 'main', {});
    importSets.mainSet.unit = _mainOutputUnit;
    _allOutputUnits.add(_mainOutputUnit);
  }

  KElementEnvironment get elementEnvironment =>
      compiler.frontendStrategy.elementEnvironment;

  CommonElements get commonElements => compiler.frontendStrategy.commonElements;
  DartTypes get dartTypes => commonElements.dartTypes;

  DiagnosticReporter get reporter => compiler.reporter;

  /// Collects all direct dependencies of [element].
  ///
  /// The collected dependent elements and constants are are added to
  /// [elements] and [constants] respectively.
  void _collectDirectMemberDependencies(KClosedWorld closedWorld,
      MemberEntity element, Dependencies dependencies) {
    // TODO(sigurdm): We want to be more specific about this - need a better
    // way to query "liveness".
    if (!closedWorld.isMemberUsed(element)) {
      return;
    }
    _collectDependenciesFromImpact(closedWorld, element, dependencies);
    collectConstantsInBody(element, dependencies);
  }

  /// Finds all elements and constants that [element] depends directly on.
  /// (not the transitive closure.)
  ///
  /// Adds the results to [elements] and [constants].
  void _collectAllElementsAndConstantsResolvedFromClass(
      KClosedWorld closedWorld,
      ClassEntity element,
      Dependencies dependencies) {
    // If we see a class, add everything its live instance members refer
    // to.  Static members are not relevant, unless we are processing
    // extra dependencies due to mirrors.
    void addLiveInstanceMember(MemberEntity member) {
      if (!closedWorld.isMemberUsed(member)) return;
      if (!member.isInstanceMember) return;
      dependencies.addMember(member);
      _collectDirectMemberDependencies(closedWorld, member, dependencies);
    }

    void addClassAndMaybeAddEffectiveMixinClass(ClassEntity cls) {
      dependencies.addClass(cls);
      if (elementEnvironment.isMixinApplication(cls)) {
        dependencies.addClass(elementEnvironment.getEffectiveMixinClass(cls));
      }
    }

    ClassEntity cls = element;
    elementEnvironment.forEachLocalClassMember(cls, addLiveInstanceMember);
    elementEnvironment.forEachSupertype(cls, (InterfaceType type) {
      _collectTypeDependencies(type, dependencies);
    });
    elementEnvironment.forEachSuperClass(cls, (superClass) {
      addClassAndMaybeAddEffectiveMixinClass(superClass);
      _collectTypeDependencies(
          elementEnvironment.getThisType(superClass), dependencies);
    });
    addClassAndMaybeAddEffectiveMixinClass(cls);
  }

  /// Finds all elements and constants that [element] depends directly on.
  /// (not the transitive closure.)
  ///
  /// Adds the results to [elements] and [constants].
  void _collectAllElementsAndConstantsResolvedFromMember(
      KClosedWorld closedWorld,
      MemberEntity element,
      Dependencies dependencies) {
    if (element is FunctionEntity) {
      _collectTypeDependencies(
          elementEnvironment.getFunctionType(element), dependencies);
    }
    if (element.isStatic || element.isTopLevel || element.isConstructor) {
      dependencies.addMember(element);
      _collectDirectMemberDependencies(closedWorld, element, dependencies);
    }
    if (element is ConstructorEntity && element.isGenerativeConstructor) {
      // When instantiating a class, we record a reference to the
      // constructor, not the class itself.  We must add all the
      // instance members of the constructor's class.
      ClassEntity cls = element.enclosingClass;
      _collectAllElementsAndConstantsResolvedFromClass(
          closedWorld, cls, dependencies);
    }

    // Other elements, in particular instance members, are ignored as
    // they are processed as part of the class.
  }

  /// Extract the set of constants that are used in the body of [element].
  void collectConstantsInBody(MemberEntity element, Dependencies dependencies) {
    ir.Member node = _elementMap.getMemberNode(element);

    // Fetch the internal node in order to skip annotations on the member.
    // TODO(sigmund): replace this pattern when the kernel-ast provides a better
    // way to skip annotations (issue 31565).
    var visitor = new ConstantCollector(
        _elementMap, _elementMap.getStaticTypeContext(element), dependencies);
    if (node is ir.Field) {
      node.initializer?.accept(visitor);
      return;
    }

    if (node is ir.Constructor) {
      node.initializers.forEach((i) => i.accept(visitor));
    }
    node.function?.accept(visitor);
  }

  /// Recursively collects all the dependencies of [type].
  void _collectTypeDependencies(DartType type, Dependencies dependencies,
      [ImportEntity import]) {
    TypeDependencyVisitor(dependencies, import, commonElements).visit(type);
  }

  void _collectTypeArgumentDependencies(
      Iterable<DartType> typeArguments, Dependencies dependencies,
      [ImportEntity import]) {
    if (typeArguments == null) return;
    TypeDependencyVisitor(dependencies, import, commonElements)
        .visitList(typeArguments);
  }

  /// Extract any dependencies that are known from the impact of [element].
  void _collectDependenciesFromImpact(KClosedWorld closedWorld,
      MemberEntity element, Dependencies dependencies) {
    WorldImpact worldImpact = compiler.impactCache[element];
    compiler.impactStrategy.visitImpact(
        element,
        worldImpact,
        WorldImpactVisitorImpl(
            visitStaticUse: (MemberEntity member, StaticUse staticUse) {
          void processEntity() {
            Entity usedEntity = staticUse.element;
            if (usedEntity is MemberEntity) {
              dependencies.addMember(usedEntity, staticUse.deferredImport);
            } else {
              assert(usedEntity is KLocalFunction,
                  failedAt(usedEntity, "Unexpected static use $staticUse."));
              KLocalFunction localFunction = usedEntity;
              // TODO(sra): Consult KClosedWorld to see if signature is needed.
              _collectTypeDependencies(
                  localFunction.functionType, dependencies);
              dependencies.localFunctions.add(localFunction);
            }
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
              processEntity();
              break;
            case StaticUseKind.STATIC_INVOKE:
            case StaticUseKind.CLOSURE_CALL:
            case StaticUseKind.DIRECT_INVOKE:
              // TODO(johnniwinther): Use rti need data to skip unneeded type
              // arguments.
              _collectTypeArgumentDependencies(
                  staticUse.typeArguments, dependencies);
              processEntity();
              break;
            case StaticUseKind.STATIC_TEAR_OFF:
            case StaticUseKind.CLOSURE:
            case StaticUseKind.STATIC_GET:
            case StaticUseKind.STATIC_SET:
              processEntity();
              break;
            case StaticUseKind.SUPER_TEAR_OFF:
            case StaticUseKind.SUPER_FIELD_SET:
            case StaticUseKind.SUPER_GET:
            case StaticUseKind.SUPER_SETTER_SET:
            case StaticUseKind.SUPER_INVOKE:
            case StaticUseKind.INSTANCE_FIELD_GET:
            case StaticUseKind.INSTANCE_FIELD_SET:
            case StaticUseKind.FIELD_INIT:
            case StaticUseKind.FIELD_CONSTANT_INIT:
              // These static uses are not relevant for this algorithm.
              break;
            case StaticUseKind.CALL_METHOD:
            case StaticUseKind.INLINING:
              failedAt(element, "Unexpected static use: $staticUse.");
              break;
          }
        }, visitTypeUse: (MemberEntity member, TypeUse typeUse) {
          void addClassIfInterfaceType(DartType t, [ImportEntity import]) {
            var typeWithoutNullability = t.withoutNullability;
            if (typeWithoutNullability is InterfaceType) {
              dependencies.addClass(typeWithoutNullability.element, import);
            }
          }

          DartType type = typeUse.type;
          switch (typeUse.kind) {
            case TypeUseKind.TYPE_LITERAL:
              _collectTypeDependencies(
                  type, dependencies, typeUse.deferredImport);
              break;
            case TypeUseKind.CONST_INSTANTIATION:
              addClassIfInterfaceType(type, typeUse.deferredImport);
              _collectTypeDependencies(
                  type, dependencies, typeUse.deferredImport);
              break;
            case TypeUseKind.INSTANTIATION:
            case TypeUseKind.NATIVE_INSTANTIATION:
              addClassIfInterfaceType(type);
              _collectTypeDependencies(type, dependencies);
              break;
            case TypeUseKind.IS_CHECK:
            case TypeUseKind.CATCH_TYPE:
              _collectTypeDependencies(type, dependencies);
              break;
            case TypeUseKind.AS_CAST:
              if (closedWorld.annotationsData
                  .getExplicitCastCheckPolicy(element)
                  .isEmitted) {
                _collectTypeDependencies(type, dependencies);
              }
              break;
            case TypeUseKind.IMPLICIT_CAST:
              if (closedWorld.annotationsData
                  .getImplicitDowncastCheckPolicy(element)
                  .isEmitted) {
                _collectTypeDependencies(type, dependencies);
              }
              break;
            case TypeUseKind.PARAMETER_CHECK:
            case TypeUseKind.TYPE_VARIABLE_BOUND_CHECK:
              if (closedWorld.annotationsData
                  .getParameterCheckPolicy(element)
                  .isEmitted) {
                _collectTypeDependencies(type, dependencies);
              }
              break;
            case TypeUseKind.RTI_VALUE:
            case TypeUseKind.TYPE_ARGUMENT:
            case TypeUseKind.NAMED_TYPE_VARIABLE_NEW_RTI:
            case TypeUseKind.CONSTRUCTOR_REFERENCE:
              failedAt(element, "Unexpected type use: $typeUse.");
              break;
          }
        }, visitDynamicUse: (MemberEntity member, DynamicUse dynamicUse) {
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
  void _updateConstantRecursive(
      KClosedWorld closedWorld,
      ConstantValue constant,
      ImportSet oldSet,
      ImportSet newSet,
      WorkQueue queue) {
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
        _updateClassRecursive(closedWorld, cls, oldSet, newSet, queue);
      }
      if (constant is InstantiationConstantValue) {
        for (DartType type in constant.typeArguments) {
          type = type.withoutNullability;
          if (type is InterfaceType) {
            _updateClassRecursive(
                closedWorld, type.element, oldSet, newSet, queue);
          }
        }
      }
      constant.getDependencies().forEach((ConstantValue dependency) {
        // Constants are not allowed to refer to deferred constants, so
        // no need to check for a deferred type literal here.
        _updateConstantRecursive(
            closedWorld, dependency, oldSet, newSet, queue);
      });
    } else {
      assert(
          // Invariant: we must mark main before we mark any deferred import.
          newSet != importSets.mainSet || oldSet != null,
          failedAt(
              NO_LOCATION_SPANNABLE,
              "Tried to assign ${constant.toDartText(closedWorld.dartTypes)} "
              "to the main output unit, but it was assigned to $currentSet."));
      queue.addConstant(constant, newSet);
    }
  }

  void _updateClassRecursive(KClosedWorld closedWorld, ClassEntity element,
      ImportSet oldSet, ImportSet newSet, WorkQueue queue) {
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

      Dependencies dependencies = Dependencies();
      _collectAllElementsAndConstantsResolvedFromClass(
          closedWorld, element, dependencies);
      LibraryEntity library = element.library;
      _processDependencies(
          closedWorld, library, dependencies, oldSet, newSet, queue, element);
    } else {
      queue.addClass(element, newSet);
    }
  }

  void _updateClassTypeRecursive(KClosedWorld closedWorld, ClassEntity element,
      ImportSet oldSet, ImportSet newSet, WorkQueue queue) {
    if (element == null) return;

    ImportSet currentSet = _classTypeToSet[element];

    // Already visited. We may visit some root nodes a second time with
    // [isMirrorUsage] in order to mark static members used reflectively.
    if (currentSet == newSet) return;

    // Elements in the main output unit always remain there.
    if (currentSet == importSets.mainSet) return;

    if (currentSet == oldSet) {
      // Continue recursively updating from [oldSet] to [newSet].
      _classTypeToSet[element] = newSet;

      Dependencies dependencies = Dependencies();
      dependencies.addClassType(element);
      LibraryEntity library = element.library;
      _processDependencies(
          closedWorld, library, dependencies, oldSet, newSet, queue, element);
    } else {
      queue.addClassType(element, newSet);
    }
  }

  void _updateMemberRecursive(KClosedWorld closedWorld, MemberEntity element,
      ImportSet oldSet, ImportSet newSet, WorkQueue queue) {
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

      Dependencies dependencies = Dependencies();
      _collectAllElementsAndConstantsResolvedFromMember(
          closedWorld, element, dependencies);

      LibraryEntity library = element.library;
      _processDependencies(
          closedWorld, library, dependencies, oldSet, newSet, queue, element);
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

  void _processDependencies(
      KClosedWorld closedWorld,
      LibraryEntity library,
      Dependencies dependencies,
      ImportSet oldSet,
      ImportSet newSet,
      WorkQueue queue,
      Spannable context) {
    dependencies.classes.forEach((ClassEntity cls, DependencyInfo info) {
      if (info.isDeferred) {
        if (_shouldAddDeferredDependency(newSet)) {
          for (ImportEntity deferredImport in info.imports) {
            queue.addClass(cls, importSets.singleton(deferredImport));
          }
        }
      } else {
        _updateClassRecursive(closedWorld, cls, oldSet, newSet, queue);
      }
    });

    dependencies.classType.forEach((ClassEntity cls, DependencyInfo info) {
      if (info.isDeferred) {
        if (_shouldAddDeferredDependency(newSet)) {
          for (ImportEntity deferredImport in info.imports) {
            queue.addClassType(cls, importSets.singleton(deferredImport));
          }
        }
      } else {
        _updateClassTypeRecursive(closedWorld, cls, oldSet, newSet, queue);
      }
    });

    dependencies.members.forEach((MemberEntity member, DependencyInfo info) {
      if (info.isDeferred) {
        if (_shouldAddDeferredDependency(newSet)) {
          for (ImportEntity deferredImport in info.imports) {
            queue.addMember(member, importSets.singleton(deferredImport));
          }
        }
      } else {
        _updateMemberRecursive(closedWorld, member, oldSet, newSet, queue);
      }
    });

    for (Local localFunction in dependencies.localFunctions) {
      _updateLocalFunction(localFunction, oldSet, newSet);
    }

    dependencies.constants
        .forEach((ConstantValue constant, DependencyInfo info) {
      if (info.isDeferred) {
        if (_shouldAddDeferredDependency(newSet)) {
          for (ImportEntity deferredImport in info.imports) {
            queue.addConstant(constant, importSets.singleton(deferredImport));
          }
        }
      } else {
        _updateConstantRecursive(closedWorld, constant, oldSet, newSet, queue);
      }
    });
  }

  /// Computes a unique string for the name field for each outputUnit.
  void _createOutputUnits() {
    int counter = 1;
    void addUnit(ImportSet importSet) {
      if (importSet.unit != null) return;
      var unit = OutputUnit(false, '$counter',
          importSet._collectImports().map((i) => i.declaration).toSet());
      counter++;
      importSet.unit = unit;
      _allOutputUnits.add(unit);
    }

    // Generate an output unit for all import sets that are associated with an
    // element or constant.
    _classToSet.values.forEach(addUnit);
    _classTypeToSet.values.forEach(addUnit);
    _memberToSet.values.forEach(addUnit);
    _localFunctionToSet.values.forEach(addUnit);
    _constantToSet.values.forEach(addUnit);

    // Sort output units to make the output of the compiler more stable.
    _allOutputUnits.sort();
  }

  Map<String, List<OutputUnit>> _setupHunksToLoad() {
    Map<String, List<OutputUnit>> hunksToLoad = {};
    Set<String> usedImportNames = {};

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
      hunksToLoad[_importDeferName[import]] = [];
      for (OutputUnit outputUnit in sortedOutputUnits) {
        if (outputUnit == _mainOutputUnit) continue;
        if (outputUnit._imports.contains(import)) {
          hunksToLoad[_importDeferName[import]].add(outputUnit);
          metrics.hunkListElements.add(1);
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
    return metrics.time.measure(() => _run(main, closedWorld));
  }

  OutputUnitData _run(FunctionEntity main, KClosedWorld closedWorld) {
    if (!isProgramSplit || main == null || disableProgramSplit) {
      return _buildResult();
    }

    work() {
      var queue = WorkQueue(this.importSets);

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
          item.update(this, closedWorld, queue);
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
    Map<ClassEntity, OutputUnit> classMap = {};
    Map<ClassEntity, OutputUnit> classTypeMap = {};
    Map<MemberEntity, OutputUnit> memberMap = {};
    Map<Local, OutputUnit> localFunctionMap = {};
    Map<ConstantValue, OutputUnit> constantMap = {};
    _classToSet.forEach((cls, s) => classMap[cls] = s.unit);
    _classTypeToSet.forEach((cls, s) => classTypeMap[cls] = s.unit);
    _memberToSet.forEach((member, s) => memberMap[member] = s.unit);
    _localFunctionToSet.forEach(
        (localFunction, s) => localFunctionMap[localFunction] = s.unit);
    _constantToSet.forEach((constant, s) => constantMap[constant] = s.unit);

    _classToSet = null;
    _classTypeToSet = null;
    _memberToSet = null;
    _localFunctionToSet = null;
    _constantToSet = null;
    importSets = null;
    return OutputUnitData(
        this.isProgramSplit && !disableProgramSplit,
        this._mainOutputUnit,
        classMap,
        classTypeMap,
        memberMap,
        localFunctionMap,
        constantMap,
        _allOutputUnits,
        _importDeferName,
        hunksToLoad,
        _deferredImportDescriptions);
  }

  void beforeResolution(Uri rootLibraryUri, Iterable<Uri> libraries) {
    measureSubtask('prepare', () {
      for (Uri uri in libraries) {
        LibraryEntity library = elementEnvironment.lookupLibrary(uri);
        reporter.withCurrentElement(library, () {
          for (ImportEntity import in elementEnvironment.getImports(library)) {
            if (import.isDeferred) {
              _deferredImportDescriptions[import] =
                  ImportDescription(import, library, rootLibraryUri);
              isProgramSplit = true;
            }
          }
        });
      }
    });
  }

  bool ignoreEntityInDump(Entity element) => false;

  /// Creates a textual representation of the output unit content.
  String dump() {
    Map<OutputUnit, List<String>> elementMap = {};
    Map<OutputUnit, List<String>> constantMap = {};
    _classToSet.forEach((ClassEntity element, ImportSet importSet) {
      if (ignoreEntityInDump(element)) return;
      var elements = elementMap.putIfAbsent(importSet.unit, () => <String>[]);
      var id = element.name ?? '$element';
      id = '$id cls';
      elements.add(id);
    });
    _classTypeToSet.forEach((ClassEntity element, ImportSet importSet) {
      if (ignoreEntityInDump(element)) return;
      var elements = elementMap.putIfAbsent(importSet.unit, () => <String>[]);
      var id = element.name ?? '$element';
      id = '$id type';
      elements.add(id);
    });
    _memberToSet.forEach((MemberEntity element, ImportSet importSet) {
      if (ignoreEntityInDump(element)) return;
      var elements = elementMap.putIfAbsent(importSet.unit, () => []);
      var id = element.name ?? '$element';
      var cls = element.enclosingClass?.name;
      if (cls != null) id = '$cls.$id';
      if (element.isSetter) id = '$id=';
      id = '$id member';
      elements.add(id);
    });
    _localFunctionToSet.forEach((Local element, ImportSet importSet) {
      if (ignoreEntityInDump(element)) return;
      var elements = elementMap.putIfAbsent(importSet.unit, () => []);
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
          .putIfAbsent(importSet.unit, () => [])
          .add(value.toStructuredText(dartTypes));
    });

    Map<OutputUnit, String> text = {};
    for (OutputUnit outputUnit in _allOutputUnits) {
      StringBuffer unitText = StringBuffer();
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

    StringBuffer sb = StringBuffer();
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
            fe.relativizeUri(
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
  ImportSet _emptySet = ImportSet.empty();

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
    if (a == null || a.isEmpty) return b;
    if (b == null || b.isEmpty) return a;

    // Create the union by merging the imports in canonical order. The sets are
    // basically lists linked by the `_previous` field in reverse order. We do a
    // merge-like scan 'backwards' removing the biggest element until we hit an
    // empty set or a common prefix, and the add the 'merge-sorted' elements
    // back onto the prefix.
    ImportSet result;
    // 'removed' imports in decreasing canonical order.
    List<_DeferredImport> imports = [];

    while (true) {
      if (a.isEmpty) {
        result = b;
        break;
      }
      if (b.isEmpty || identical(a, b)) {
        result = a;
        break;
      }
      if (a._import.index > b._import.index) {
        imports.add(a._import);
        a = a._previous;
      } else if (b._import.index > a._import.index) {
        imports.add(b._import);
        b = b._previous;
      } else {
        assert(identical(a._import, b._import));
        imports.add(a._import);
        a = a._previous;
        b = b._previous;
      }
    }

    // Add merged elements back in reverse order. It is tempting to pop them off
    // with `removeLast()` but that causes measurable shrinking reallocations.
    for (int i = imports.length - 1; i >= 0; i--) {
      result = result._add(imports[i]);
    }
    return result;
  }

  /// Get the index for an [import] according to the canonical order.
  _DeferredImport _wrap(ImportEntity import) {
    return _importIndex[import] ??=
        _DeferredImport(import, _importIndex.length);
  }
}

/// A canonical set of deferred imports.
class ImportSet {
  /// Last element added to set.
  ///
  /// This set comprises [_import] appended onto [_previous]. *Note*: [_import]
  /// is the last element in the set in the canonical order imposed by
  /// [ImportSetLattice].
  final _DeferredImport _import; // `null` for empty ImportSet
  /// The set containing all previous elements.
  final ImportSet _previous;
  final int length;

  bool get isEmpty => _import == null;
  bool get isNotEmpty => _import != null;

  /// Returns an iterable over the imports in this set in canonical order.
  Iterable<_DeferredImport> _collectImports() {
    List<_DeferredImport> result = [];
    ImportSet current = this;
    while (current.isNotEmpty) {
      result.add(current._import);
      current = current._previous;
    }
    assert(result.length == this.length);
    return result.reversed;
  }

  /// Links to other import sets in the lattice by adding one import.
  final Map<_DeferredImport, ImportSet> _transitions = Maplet();

  ImportSet.empty()
      : _import = null,
        _previous = null,
        length = 0;

  ImportSet(this._import, this._previous, this.length);

  /// The output unit corresponding to this set of imports, if any.
  OutputUnit unit;

  /// Create an import set that adds [import] to all the imports on this set.
  /// This assumes that import's canonical order comes after all imports in
  /// this current set. This should only be called from [ImportSetLattice],
  /// since it is where we preserve this invariant.
  ImportSet _add(_DeferredImport import) {
    assert(_import == null || import.index > _import.index);
    return _transitions[import] ??= ImportSet(import, this, length + 1);
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('ImportSet(size: $length, ');
    for (var import in _collectImports()) {
      sb.write('${import.declaration.name} ');
    }
    sb.write(')');
    return '$sb';
  }
}

/// The algorithm work queue.
class WorkQueue {
  /// The actual queue of work that needs to be done.
  final Queue<WorkItem> queue = Queue();

  /// An index to find work items in the queue corresponding to a class.
  final Map<ClassEntity, WorkItem> pendingClasses = {};

  /// An index to find work items in the queue corresponding to an
  /// [InterfaceType] represented here by its [ClassEntitiy].
  final Map<ClassEntity, WorkItem> pendingClassType = {};

  /// An index to find work items in the queue corresponding to a member.
  final Map<MemberEntity, WorkItem> pendingMembers = {};

  /// An index to find work items in the queue corresponding to a constant.
  final Map<ConstantValue, WorkItem> pendingConstants = {};

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
      item = ClassWorkItem(element, importSet);
      pendingClasses[element] = item;
      queue.add(item);
    } else {
      item.importsToAdd = _importSets.union(item.importsToAdd, importSet);
    }
  }

  /// Add to the queue that class type (represented by [element]) should be
  /// updated to include all imports in [importSet]. If there is already a
  /// work item in the queue for [element], this makes sure that the work
  /// item now includes the union of [importSet] and the existing work
  /// item's import set.
  void addClassType(ClassEntity element, ImportSet importSet) {
    var item = pendingClassType[element];
    if (item == null) {
      item = ClassTypeWorkItem(element, importSet);
      pendingClassType[element] = item;
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
      item = MemberWorkItem(element, importSet);
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
      item = ConstantWorkItem(constant, importSet);
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

  void update(DeferredLoadTask task, KClosedWorld closedWorld, WorkQueue queue);
}

/// Summary of the work that needs to be done on a class.
class ClassWorkItem extends WorkItem {
  /// Class to be recursively updated.
  final ClassEntity cls;

  ClassWorkItem(this.cls, ImportSet newSet) : super(newSet);

  @override
  void update(
      DeferredLoadTask task, KClosedWorld closedWorld, WorkQueue queue) {
    queue.pendingClasses.remove(cls);
    ImportSet oldSet = task._classToSet[cls];
    ImportSet newSet = task.importSets.union(oldSet, importsToAdd);
    task._updateClassRecursive(closedWorld, cls, oldSet, newSet, queue);
  }
}

/// Summary of the work that needs to be done on a class.
class ClassTypeWorkItem extends WorkItem {
  /// Class to be recursively updated.
  final ClassEntity cls;

  ClassTypeWorkItem(this.cls, ImportSet newSet) : super(newSet);

  @override
  void update(
      DeferredLoadTask task, KClosedWorld closedWorld, WorkQueue queue) {
    queue.pendingClassType.remove(cls);
    ImportSet oldSet = task._classTypeToSet[cls];
    ImportSet newSet = task.importSets.union(oldSet, importsToAdd);
    task._updateClassTypeRecursive(closedWorld, cls, oldSet, newSet, queue);
  }
}

/// Summary of the work that needs to be done on a member.
class MemberWorkItem extends WorkItem {
  /// Member to be recursively updated.
  final MemberEntity member;

  MemberWorkItem(this.member, ImportSet newSet) : super(newSet);

  @override
  void update(
      DeferredLoadTask task, KClosedWorld closedWorld, WorkQueue queue) {
    queue.pendingMembers.remove(member);
    ImportSet oldSet = task._memberToSet[member];
    ImportSet newSet = task.importSets.union(oldSet, importsToAdd);
    task._updateMemberRecursive(closedWorld, member, oldSet, newSet, queue);
  }
}

/// Summary of the work that needs to be done on a constant.
class ConstantWorkItem extends WorkItem {
  /// Constant to be recursively updated.
  final ConstantValue constant;

  ConstantWorkItem(this.constant, ImportSet newSet) : super(newSet);

  @override
  void update(
      DeferredLoadTask task, KClosedWorld closedWorld, WorkQueue queue) {
    queue.pendingConstants.remove(constant);
    ImportSet oldSet = task._constantToSet[constant];
    ImportSet newSet = task.importSets.union(oldSet, importsToAdd);
    task._updateConstantRecursive(closedWorld, constant, oldSet, newSet, queue);
  }
}

/// Interface for updating an [OutputUnitData] object with data for late
/// members, that is, members created on demand during code generation.
class LateOutputUnitDataBuilder {
  final OutputUnitData _outputUnitData;

  LateOutputUnitDataBuilder(this._outputUnitData);

  /// Registers [newEntity] to be emitted in the same output unit as
  /// [existingEntity];
  void registerColocatedMembers(
      MemberEntity existingEntity, MemberEntity newEntity) {
    assert(_outputUnitData._memberToUnit[newEntity] == null);
    _outputUnitData._memberToUnit[newEntity] =
        _outputUnitData.outputUnitForMember(existingEntity);
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
  final Map<ClassEntity, OutputUnit> _classTypeToUnit;
  final Map<MemberEntity, OutputUnit> _memberToUnit;
  final Map<Local, OutputUnit> _localFunctionToUnit;
  final Map<ConstantValue, OutputUnit> _constantToUnit;
  final List<OutputUnit> outputUnits;
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
      this._classTypeToUnit,
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
    Map<ClassEntity, OutputUnit> classTypeToUnit =
        convertClassMap(other._classTypeToUnit, other._localFunctionToUnit);
    Map<MemberEntity, OutputUnit> memberToUnit =
        convertMemberMap(other._memberToUnit, other._localFunctionToUnit);
    Map<ConstantValue, OutputUnit> constantToUnit =
        convertConstantMap(other._constantToUnit);
    Map<ImportEntity, ImportDescription> deferredImportDescriptions = {};
    other._deferredImportDescriptions
        .forEach((ImportEntity import, ImportDescription description) {
      deferredImportDescriptions[import] = ImportDescription.internal(
          description.importingUri,
          description.prefix,
          convertLibrary(description._importingLibrary));
    });

    return OutputUnitData(
        other.isProgramSplit,
        other.mainOutputUnit,
        classToUnit,
        classTypeToUnit,
        memberToUnit,
        // Local functions only make sense in the K-world model.
        const {},
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
      return OutputUnit(isMainOutput, name, importSet);
    });
    OutputUnit mainOutputUnit = outputUnits[source.readInt()];

    Map<ClassEntity, OutputUnit> classToUnit = source.readClassMap(() {
      return outputUnits[source.readInt()];
    });
    Map<ClassEntity, OutputUnit> classTypeToUnit = source.readClassMap(() {
      return outputUnits[source.readInt()];
    });
    Map<MemberEntity, OutputUnit> memberToUnit =
        source.readMemberMap((MemberEntity member) {
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
      return ImportDescription.internal(importingUri, prefix, importingLibrary);
    });
    source.end(tag);
    return OutputUnitData(
        isProgramSplit,
        mainOutputUnit,
        classToUnit,
        classTypeToUnit,
        memberToUnit,
        // Local functions only make sense in the K-world model.
        const {},
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
    sink.writeClassMap(_classTypeToUnit, (OutputUnit outputUnit) {
      sink.writeInt(outputUnitIndices[outputUnit]);
    });
    sink.writeMemberMap(_memberToUnit,
        (MemberEntity member, OutputUnit outputUnit) {
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
  // TODO(johnniwinther): Remove the need for [allowNull]. Dump-info currently
  // needs it.
  OutputUnit outputUnitForClass(ClassEntity cls, {bool allowNull: false}) {
    if (!isProgramSplit) return mainOutputUnit;
    OutputUnit unit = _classToUnit[cls];
    assert(allowNull || unit != null, 'No output unit for class $cls');
    return unit ?? mainOutputUnit;
  }

  OutputUnit outputUnitForClassForTesting(ClassEntity cls) => _classToUnit[cls];

  /// Returns the [OutputUnit] where [cls]'s type belongs.
  // TODO(joshualitt): see above TODO regarding allowNull.
  OutputUnit outputUnitForClassType(ClassEntity cls, {bool allowNull: false}) {
    if (!isProgramSplit) return mainOutputUnit;
    OutputUnit unit = _classTypeToUnit[cls];
    assert(allowNull || unit != null, 'No output unit for type $cls');
    return unit ?? mainOutputUnit;
  }

  OutputUnit outputUnitForClassTypeForTesting(ClassEntity cls) =>
      _classTypeToUnit[cls];

  /// Returns the [OutputUnit] where [member] belongs.
  OutputUnit outputUnitForMember(MemberEntity member) {
    if (!isProgramSplit) return mainOutputUnit;
    OutputUnit unit = _memberToUnit[member];
    assert(unit != null, 'No output unit for member $member');
    return unit ?? mainOutputUnit;
  }

  OutputUnit outputUnitForMemberForTesting(MemberEntity member) =>
      _memberToUnit[member];

  /// Direct access to the output-unit to constants map used for testing.
  Iterable<ConstantValue> get constantsForTesting => _constantToUnit.keys;

  /// Returns the [OutputUnit] where [constant] belongs.
  OutputUnit outputUnitForConstant(ConstantValue constant) {
    if (!isProgramSplit) return mainOutputUnit;
    OutputUnit unit = _constantToUnit[constant];
    // TODO(sigmund): enforce unit is not null: it is sometimes null on some
    // corner cases on internal apps.
    return unit ?? mainOutputUnit;
  }

  OutputUnit outputUnitForConstantForTesting(ConstantValue constant) =>
      _constantToUnit[constant];

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

  /// Returns `true` if constant [to] is reachable from element [from] without
  /// crossing a deferred import.
  ///
  /// For example, if we have two deferred libraries `A` and `B` that both
  /// import a library `C`, then even though elements from `A` and `C` end up in
  /// different output units, there is a non-deferred path between `A` and `C`.
  bool hasOnlyNonDeferredImportPathsToConstant(
      MemberEntity from, ConstantValue to) {
    OutputUnit outputUnitFrom = outputUnitForMember(from);
    OutputUnit outputUnitTo = outputUnitForConstant(to);
    if (outputUnitTo == mainOutputUnit) return true;
    if (outputUnitFrom == mainOutputUnit) return false;
    return outputUnitTo._imports.containsAll(outputUnitFrom._imports);
  }

  /// Returns `true` if class [to] is reachable from element [from] without
  /// crossing a deferred import.
  ///
  /// For example, if we have two deferred libraries `A` and `B` that both
  /// import a library `C`, then even though elements from `A` and `C` end up in
  /// different output units, there is a non-deferred path between `A` and `C`.
  bool hasOnlyNonDeferredImportPathsToClass(MemberEntity from, ClassEntity to) {
    OutputUnit outputUnitFrom = outputUnitForMember(from);
    OutputUnit outputUnitTo = outputUnitForClass(to);
    if (outputUnitTo == mainOutputUnit) return true;
    if (outputUnitFrom == mainOutputUnit) return false;
    return outputUnitTo._imports.containsAll(outputUnitFrom._imports);
  }

  /// Registers that a constant is used in the same deferred output unit as
  /// [field].
  void registerConstantDeferredUse(DeferredGlobalConstantValue constant) {
    if (!isProgramSplit) return;
    OutputUnit unit = constant.unit;
    assert(
        _constantToUnit[constant] == null || _constantToUnit[constant] == unit);
    _constantToUnit[constant] = unit;
  }

  /// Returns the unique name for the given deferred [import].
  String getImportDeferName(Spannable node, ImportEntity import) {
    String name = _importDeferName[import];
    if (name == null) {
      throw SpannableAssertionFailure(node, "No deferred name for $import.");
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
          () =>
              {"name": getName(description._importingLibrary), "imports": {}});

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
  final Map<ClassEntity, DependencyInfo> classType = {};
  final Map<MemberEntity, DependencyInfo> members = {};
  final Set<Local> localFunctions = {};
  final Map<ConstantValue, DependencyInfo> constants = {};

  void addClass(ClassEntity cls, [ImportEntity import]) {
    (classes[cls] ??= DependencyInfo()).registerImport(import);

    // Add a classType dependency as well just in case we optimize out
    // the class later.
    addClassType(cls, import);
  }

  void addClassType(ClassEntity cls, [ImportEntity import]) {
    (classType[cls] ??= DependencyInfo()).registerImport(import);
  }

  void addMember(MemberEntity m, [ImportEntity import]) {
    (members[m] ??= DependencyInfo()).registerImport(import);
  }

  void addConstant(ConstantValue c, [ImportEntity import]) {
    (constants[c] ??= DependencyInfo()).registerImport(import);
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

class TypeDependencyVisitor implements DartTypeVisitor<void, Null> {
  final Dependencies _dependencies;
  final ImportEntity _import;
  final CommonElements _commonElements;

  TypeDependencyVisitor(this._dependencies, this._import, this._commonElements);

  @override
  void visit(DartType type, [_]) {
    type.accept(this, null);
  }

  void visitList(List<DartType> types) {
    types.forEach(visit);
  }

  @override
  void visitLegacyType(LegacyType type, Null argument) {
    visit(type.baseType);
  }

  @override
  void visitNullableType(NullableType type, Null argument) {
    visit(type.baseType);
  }

  @override
  void visitFutureOrType(FutureOrType type, Null argument) {
    _dependencies.addClassType(_commonElements.futureClass);
    visit(type.typeArgument);
  }

  @override
  void visitNeverType(NeverType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitDynamicType(DynamicType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitErasedType(ErasedType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitAnyType(AnyType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitInterfaceType(InterfaceType type, Null argument) {
    visitList(type.typeArguments);
    _dependencies.addClassType(type.element, _import);
  }

  @override
  void visitFunctionType(FunctionType type, Null argument) {
    for (FunctionTypeVariable typeVariable in type.typeVariables) {
      visit(typeVariable.bound);
    }
    visitList(type.parameterTypes);
    visitList(type.optionalParameterTypes);
    visitList(type.namedParameterTypes);
    visit(type.returnType);
  }

  @override
  void visitFunctionTypeVariable(FunctionTypeVariable type, Null argument) {
    // Nothing to add. Handled in [visitFunctionType].
  }

  @override
  void visitTypeVariableType(TypeVariableType type, Null argument) {
    // TODO(johnniwinther): Do we need to collect the bound?
  }

  @override
  void visitVoidType(VoidType type, Null argument) {
    // Nothing to add.
  }
}

class ConstantCollector extends ir.RecursiveVisitor {
  final KernelToElementMap elementMap;
  final Dependencies dependencies;
  final ir.StaticTypeContext staticTypeContext;

  ConstantCollector(this.elementMap, this.staticTypeContext, this.dependencies);

  CommonElements get commonElements => elementMap.commonElements;

  void add(ir.Expression node, {bool required: true}) {
    ConstantValue constant = elementMap
        .getConstantValue(staticTypeContext, node, requireConstant: required);
    if (constant != null) {
      dependencies.addConstant(
          constant, elementMap.getImport(getDeferredImport(node)));
    }
  }

  @override
  void visitIntLiteral(ir.IntLiteral literal) {}

  @override
  void visitDoubleLiteral(ir.DoubleLiteral literal) {}

  @override
  void visitBoolLiteral(ir.BoolLiteral literal) {}

  @override
  void visitStringLiteral(ir.StringLiteral literal) {}

  @override
  void visitSymbolLiteral(ir.SymbolLiteral literal) => add(literal);

  @override
  void visitNullLiteral(ir.NullLiteral literal) {}

  @override
  void visitListLiteral(ir.ListLiteral literal) {
    if (literal.isConst) {
      add(literal);
    } else {
      super.visitListLiteral(literal);
    }
  }

  @override
  void visitSetLiteral(ir.SetLiteral literal) {
    if (literal.isConst) {
      add(literal);
    } else {
      super.visitSetLiteral(literal);
    }
  }

  @override
  void visitMapLiteral(ir.MapLiteral literal) {
    if (literal.isConst) {
      add(literal);
    } else {
      super.visitMapLiteral(literal);
    }
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation node) {
    if (node.isConst) {
      add(node);
    } else {
      super.visitConstructorInvocation(node);
    }
  }

  @override
  void visitTypeParameter(ir.TypeParameter node) {
    // We avoid visiting metadata on the type parameter declaration. The bound
    // cannot hold constants so we skip that as well.
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration node) {
    // We avoid visiting metadata on the parameter declaration by only visiting
    // the initializer. The type cannot hold constants so can kan skip that
    // as well.
    node.initializer?.accept(this);
  }

  @override
  void visitTypeLiteral(ir.TypeLiteral node) {
    if (node.type is! ir.TypeParameterType) add(node);
  }

  @override
  void visitInstantiation(ir.Instantiation node) {
    // TODO(johnniwinther): The CFE should mark constant instantiations as
    // constant.
    add(node, required: false);
    super.visitInstantiation(node);
  }

  @override
  void visitConstantExpression(ir.ConstantExpression node) {
    add(node);
  }
}
