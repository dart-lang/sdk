// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// *Overview of deferred loading*
///
/// Deferred loading allows developers to specify deferred imports. These
/// imports represent explicit asynchronous splits of the application that
/// allows code to be delivered in pieces.
///
/// The initial download of an application will exclude code used only by
/// deferred imports. As the application reaches a
/// `deferred_import.loadLibrary()` instruction, it will download and initialize
/// any code needed by that deferred import.
///
/// Very often separate deferred imports access common code.  When that happens,
/// the compiler places the shared code in separate files. At runtime, the
/// application will only download shared code once when the first deferred
/// import that needs that code gets loaded. To achieve this, the compiler
/// generates _load lists_: a list of JavaScript files that need to be
/// downloaded for every deferred import in the program.
///
/// Each generated JavaScript file has an initialzation within it. The files can
/// be concatenated together in a bundle without affecting the initialization
/// logic. This is used by customers to reduce the download latency when they
/// know that multiple files will be loaded at once.
///
/// *The code splitting algorithm*
///
/// The goal of this library and the [DeferredLoadingTask] is to determine how
/// to best split code in multiple files according to the principles described
/// above.
///
/// We do so by partitioning code into output units ([OutputUnit]s in our
/// implementation). The partitioning reflects how code is shared between
/// different deferred imports. Each output unit is associated a set of deferred
/// imports (an [ImportSet] in our implementation). These are the deferred
/// imports that need the code that is stored in that output unit. Code that is
/// needed by a single deferred import, will be associated with a set containing
/// that deferred import only (a singleton set), but code that is shared by 10
/// deferred imports will be associated with a set containing all of those
/// imports instead.  We determine whether code is shared based on how code is
/// accessed in the program. An element is considered to be accessed by a
/// deferred import if it is either loaded and invoked from that import or
/// transitively accessed by an element that was invoked by that import.
///
/// In theory, there could be an exponential number of output units: one per
/// subset of deferred imports in the program. In practice, large apps do have a
/// large number of output units, but the result is not exponential. This is
/// both because not all deferred imports have code in common and because many
/// deferred imports end up having the same code in common.
///
/// *Main output unit*:
///
/// The main output unit contains any code accessed directly from main. Such
/// code may be accessed by deferred imports too, but because it is accessed
/// from the main entrypoint of the program, possibly synchronously, we do not
/// split out the code or defer it. Our current implementation uses an empty
/// import-set as a sentinel value to represent this output unit.
///
/// *Dependency graph*:
///
/// We use the element model to discover dependencies between elements.
/// We distinguish two kinds of dependencies: deferred or direct (aka.
/// non-deferred):
///
///   * Deferred dependencies are only used to discover root elements. Roots
///   are elements immediately loaded and used from deferred import prefixes in
///   a program.
///
///   * Direct dependencies are used to recursively update which output unit
///   should be associated with an element.
///
/// *Algorithm Principle*:
///
/// Conceptually the algorithm consists of associating an element with an
/// import-set. When we discover a root, we mark it and everything it can reach
/// as being used by that import. Marking elements as used by that import
/// consists of adding the import to the import-set of all those reachable
/// elements.
///
/// An earlier version of this algorithm was implemented with this simple
/// approach: we kept a map from entities to a [Set] of imports and updated the
/// sets iteratively. However, as customer applications grew, we needed a more
/// specialized and efficient implementation.
///
/// *ImportSet representation and related optimizations*:
///
/// The most important change to scale the algorithm was to use an efficient
/// representation of entity to import-set associations. For large apps there
/// are a lot of entities, and the simple representation of having a [Set] per
/// entity was too expensive. We observed that many of such sets had the same
/// imports (which makes sense given that many elements ended up together in the
/// same output units). This led us to design the [ImportSet] abstraction: a
/// representation of import-sets that guarantees that each import-set has a
/// canonical representation. Memory-wise this was a big win: we now bounded
/// the heap utilization to one [ImportSet] instance per unique import-set.
///
/// This representation is not perfect. Simple operations, like adding an import
/// to an import-set, are now worse-case linear. So it was important to add a
/// few optimizations in the algorithm in order to adapt to the new
/// representation.
///
/// The principle of our optimizations is to make bulk updates. Rather than
/// adding an import at a time for all reachable elements, we changed the
/// algorithm to make updates in bulk in two ways:
///
///   * Batch unions: when possible add more than one import at once, and
///
///   * Update elements in segments: when an element and its reachable
///   dependencies would change in the same way, update them all together.
///
/// To achieve these bulk updates, the algorithm uses a two tier algorithm:
///
///   * The top tier uses a worklist to track the start of a bulk update, either
///   from a root (entities that dominate code used by a single deferred import)
///   or from a merge point in the dependency graph (entities that dominate
///   shared code between multiple imports).
///
///   * The second tier is where bulk updates are made, these don't use a
///   worklist, but simply a DFS recursive traversal of the dependency graph.
///   The DFS traversal stops at merge points and makes note of them by
///   updating the top tier worklist.
///
///
/// *Example*:
///
/// Consider this dependency graph (ignoring elements in the main output unit):
///
///   deferred import A: a1 ---> s1 ---> s2  -> s3
///                              ^       ^
///                              |       |
///   deferred import B: b1 -----+       |
///                                      |
///   deferred import C: c1 ---> c2 ---> c3
///
/// Here a1, b1, and c1 are roots, while s1 and s2 are merge points. The
/// algorithm will compute a result with 5 deferred output units:
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
///   * We update a1, s1, s2, s3 in bulk, from no mapping to {A}.
///   * We update b1 from no mapping to {B}, and when we find s1 we notice
///     that s1 is already associated with another import set {A}. This is a
///     merge point that can't be updated in bulk, so we make
///     note of additional work for later to mark s1 with {A, B}
///   * We update in bulk c1, c2, c3 to {C}, and make a note to update s2 with
///     {A, C} (another merge point).
///   * We update s1 to {A, B}, and update the existing note to update s2, now
///     with {A, B, C}
///   * Finally we update s2 and s3 with {A, B, C} in bulk, without ever
///     updating them to the intermediate state {A, C}.
///
/// *How bulk segment updates work?*
///
/// The principle of the bulk segment update is similar to memoizing the result
/// of a union operation. We replace a union operation with a cached result if
/// we can tell that the inputs to the operation are the same.
///
/// Our implementation doesn't use a cache table to memoize arbitrary unions.
/// Instead it only memoizes one union at a time: it tries to reuse the result
/// of a union applied to one entity, when updating the import-sets of its
/// transitive dependencies.
///
/// Consider a modification of the example above where we add s4 and s5 as
/// additional dependencies of s3. Conceptually, we are applying this sequence
/// of union operations:
///
///    importSet[s2] = importSet[s2] UNION {B, C}
///    importSet[s3] = importSet[s3] UNION {B, C}
///    importSet[s4] = importSet[s4] UNION {B, C}
///    importSet[s5] = importSet[s5] UNION {B, C}
///
/// When the algorithm is updating s2, it checks whether any of the entities
/// reachable from s2 also have the same import-set as s2, and if so, we know
/// that the union result is the same.
///
/// Our implementation uses the term `oldSet` to represent the first input of
/// the memoized union operation, and `newSet` to represent the result:
///
///    oldSet = importSet[s2]        // = A
///    newSet = oldSet UNION {B, C}  // = {A, B, C}
///
/// Then the updates are encoded as:
///
///    update(s2, oldSet, newSet);
///    update(s3, oldSet, newSet);
///    update(s4, oldSet, newSet);
///    update(s5, oldSet, newSet);
///
/// where:
///
///    update(s5, oldSet, newSet) {
///      var currentSet = importSet[s];
///      if (currentSet == oldSet) {
///        // Use the memoized result, whohoo!
///        importSet[s] = newSet;
///      } else {
///        // Don't use the memoized result, instead use the worklist to later
///        // update `s` with the appropriate union operation.
///      }
///    }
///
/// As a result of this, the update to the import set for s2, s3, s4 and s5
/// becomes a single if-check and an assignment, but the union operation was
/// only executed once.
///
/// *Constraints*:
///
/// By default our algorithm considers all deferred imports equally and
/// potentially occurring at any time in the application lifetime. In practice,
/// apps use deferred imports to layer the load of their application and, often,
/// developers know how imports will be loaded over time.
///
/// Dart2js accepts a configuration file to specify constraints about deferred
/// imports. There are many kinds of constraints that help developers encode how
/// their applications work.
///
/// To model constraints, the deferred loading algorithm was changed to include
/// _set transitions_: these are changes made to import-sets to effectively
/// encode the constraints.
///
/// Consider, for example, a program with two deferred imports `A` and `B`. Our
/// unconstrained algorithm will split the code in 3 files:
///
///   * code unique to `A` (represented by the import set `{A}`)
///
///   * code unique to `B` (represented by the import set `{B}`)
///
///   * code shared between `A and `B (represented by the import set `{A, B}`)
///
/// When an end-user loads the user journey corresponding to `A`, the code for
/// `{A}` and `{A,B}` gets loaded. When they load the user journey corresponding
/// to `B`, `{B}` and `{A, B}` gets loaded.
///
/// An ordering constraint saying that `B` always loads after `A` tells our
/// algorithm that, even though there exists code that is unique to `A`, we
/// could merge it together with the shared code between `A` and `B`, since the
/// user never intends to load `B` first. The result would be to have two files
/// instead:
///
///   * code unique to `B` (represented by the import set `{B}`)
///
///   * code unique to A and code shared between A and B (represented by the
///   import set `{A, B}`)
///
///
/// In this example, the set transition is to convert any set containing `{A}`
/// into a set containing `{A, B}`.
///
// TODO(joshualitt): update doc above when main is represented by a set
// containing an implict import corresponding to `main`.
// TODO(sigmund): investigate different heuristics for how to select the next
// work item (e.g. we might converge faster if we pick first the update that
// contains a bigger delta.)
library deferred_load;

import 'dart:collection' show Queue;

import 'package:kernel/ast.dart' as ir;

import 'dependencies.dart';
import 'import_set.dart';
import 'output_unit.dart';

import '../../compiler_new.dart' show OutputType;
import '../common/metrics.dart' show Metric, Metrics, CountMetric, DurationMetric;
import '../common/tasks.dart' show CompilerTask;
import '../common.dart';
import '../common_elements.dart' show CommonElements, KElementEnvironment;
import '../compiler.dart' show Compiler;
import '../constants/values.dart'
    show
        ConstantValue,
        ConstructedConstantValue,
        InstantiationConstantValue;
import '../elements/types.dart';
import '../elements/entities.dart';
import '../kernel/kelements.dart' show KLocalFunction;
import '../kernel/element_map.dart';
import '../universe/use.dart';
import '../universe/world_impact.dart'
    show ImpactUseCase, WorldImpact, WorldImpactVisitorImpl;
import '../util/util.dart' show makeUnique;
import '../world.dart' show KClosedWorld;

// TODO(joshualitt): Refactor logic out of DeferredLoadTask so work_queue.dart
// can be its own independent library.
part 'work_queue.dart';

class _DeferredLoadTaskMetrics implements Metrics {
  @override
  String get namespace => 'deferred_load';

  DurationMetric time = DurationMetric('time');
  CountMetric outputUnitElements = CountMetric('outputUnitElements');

  @override
  Iterable<Metric> get primary => [time];

  @override
  Iterable<Metric> get secondary => [outputUnitElements];
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

  static const ImpactUseCase IMPACT_USE = ImpactUseCase('Deferred load');

  /// A cache of the result of calling `computeImportDeferName` on the keys of
  /// this map.
  final Map<ImportEntity, String> importDeferName = {};

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
    var visitor = ConstantCollector(
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
          importSet.collectImports().map((i) => i.declaration).toSet());
      counter++;
      importSet.unit = unit;
      _allOutputUnits.add(unit);
      metrics.outputUnitElements.add(1);
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

  void _setupImportNames() {
    // If useSimpleLoadIds is true then we use a monotonically increasing number
    // to generate loadIds. Otherwise, we will use the user provided names.
    bool useIds = compiler.options.useSimpleLoadIds;
    var allDeferredImports = _allDeferredImports.toList();
    if (useIds) {
      // Sort for a canonical order of [ImportEntity]s.
      allDeferredImports.sort(compareImportEntities);
    }
    int nextDeferId = 0;
    Set<String> usedImportNames = {};
    for (ImportEntity import in allDeferredImports) {
      String result = computeImportDeferName(import, compiler);
      assert(result != null);
      if (useIds) {
        importDeferName[import] = (++nextDeferId).toString();
      } else {
        // Note: tools that process the json file to build multi-part initial load
        // bundles depend on the fact that makeUnique appends only digits, or a
        // period followed by digits.
        importDeferName[import] = makeUnique(result, usedImportNames, '.');
      }
    }
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
  /// See the top-level library comment for details.
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

  // Dumps a graph as a list of strings of 0 and 1. There is one 'bit' for each
  // import entity in the graph, and each string in the list represents an
  // output unit.
  void _dumpDeferredGraph() {
    int id = 0;
    Map<ImportEntity, int> importMap = {};
    var entities = _deferredImportDescriptions.keys.toList();
    entities.sort(compareImportEntities);
    entities = entities.reversed.toList();
    for (var key in entities) {
      importMap[key] = id++;
    }
    List<String> graph = [];
    for (var outputUnit in _allOutputUnits) {
      if (!outputUnit.isMainOutput) {
        List<int> representation = List.filled(id, 0);
        for (var entity in outputUnit.imports) {
          representation[importMap[entity]] = 1;
        }
        graph.add(representation.join());
      }
    }
    compiler.outputProvider.createOutputSink(
        compiler.options.deferredGraphUri.path, '', OutputType.debug)
      ..add(graph.join('\n'))
      ..close();
  }

  OutputUnitData _buildResult() {
    _createOutputUnits();
    _setupImportNames();
    if (compiler.options.deferredGraphUri != null) {
      _dumpDeferredGraph();
    }
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
        importDeferName,
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
        var imports = outputUnit.imports
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
