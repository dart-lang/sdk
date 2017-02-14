// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.enqueue;

import 'dart:collection' show Queue;

import 'cache_strategy.dart';
import 'common/backend_api.dart' show Backend;
import 'common/resolution.dart' show Resolution;
import 'common/tasks.dart' show CompilerTask;
import 'common/work.dart' show WorkItem;
import 'common.dart';
import 'compiler.dart' show Compiler, GlobalDependencyRegistry;
import 'options.dart';
import 'elements/elements.dart'
    show
        AnalyzableElement,
        ClassElement,
        ConstructorElement,
        Element,
        Entity,
        MemberElement;
import 'elements/entities.dart';
import 'elements/resolution_types.dart'
    show ResolutionDartType, ResolutionInterfaceType;
import 'native/native.dart' as native;
import 'universe/world_builder.dart';
import 'universe/use.dart'
    show DynamicUse, StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import 'universe/world_impact.dart'
    show ImpactStrategy, ImpactUseCase, WorldImpact, WorldImpactVisitor;
import 'util/enumset.dart';
import 'util/util.dart' show Setlet;

class EnqueueTask extends CompilerTask {
  ResolutionEnqueuer _resolution;
  Enqueuer _codegen;
  final Compiler compiler;

  String get name => 'Enqueue';

  EnqueueTask(Compiler compiler)
      : this.compiler = compiler,
        super(compiler.measurer) {
    _resolution = new ResolutionEnqueuer(
        this,
        compiler.options,
        compiler.resolution,
        compiler.options.analyzeOnly && compiler.options.analyzeMain
            ? const DirectEnqueuerStrategy()
            : const TreeShakingEnqueuerStrategy(),
        compiler.globalDependencies,
        compiler.backend,
        compiler.cacheStrategy);
    _codegen = compiler.backend.createCodegenEnqueuer(this, compiler);
  }

  ResolutionEnqueuer get resolution => _resolution;
  Enqueuer get codegen => _codegen;

  void forgetEntity(Entity entity) {
    resolution.forgetEntity(entity, compiler);
    codegen.forgetEntity(entity, compiler);
  }
}

abstract class Enqueuer {
  WorldBuilder get worldBuilder;
  native.NativeEnqueuer get nativeEnqueuer;
  void forgetEntity(Entity entity, Compiler compiler);

  // TODO(johnniwinther): Initialize [_impactStrategy] to `null`.
  ImpactStrategy _impactStrategy = const ImpactStrategy();

  ImpactStrategy get impactStrategy => _impactStrategy;

  void open(ImpactStrategy impactStrategy) {
    _impactStrategy = impactStrategy;
  }

  void close() {
    // TODO(johnniwinther): Set [_impactStrategy] to `null` and [queueIsClosed]
    // to `true` here.
    _impactStrategy = const ImpactStrategy();
  }

  /// Returns [:true:] if this enqueuer is the resolution enqueuer.
  bool get isResolutionQueue;

  bool queueIsClosed;

  bool get queueIsEmpty;

  ImpactUseCase get impactUse;

  void forEach(void f(WorkItem work));

  /// Apply the [worldImpact] to this enqueuer. If the [impactSource] is
  /// provided the impact strategy will remove it from the element impact cache,
  /// if it is no longer needed.
  void applyImpact(WorldImpact worldImpact, {var impactSource});
  bool checkNoEnqueuedInvokedInstanceMethods();
  void logSummary(log(message));

  Iterable<Entity> get processedEntities;

  Iterable<ClassEntity> get processedClasses;
}

abstract class EnqueuerImpl extends Enqueuer {
  CompilerTask get task;
  EnqueuerStrategy get strategy;
  void checkClass(ClassEntity cls);
  void processStaticUse(StaticUse staticUse);
  void processTypeUse(TypeUse typeUse);
  void processDynamicUse(DynamicUse dynamicUse);
}

/// [Enqueuer] which is specific to resolution.
class ResolutionEnqueuer extends EnqueuerImpl {
  static const ImpactUseCase IMPACT_USE =
      const ImpactUseCase('ResolutionEnqueuer');

  final CompilerTask task;
  final String name;
  final Resolution _resolution;
  final CompilerOptions _options;
  final Backend backend;
  final GlobalDependencyRegistry _globalDependencies;
  final native.NativeEnqueuer nativeEnqueuer;

  final EnqueuerStrategy strategy;
  final Set<ClassEntity> _recentClasses = new Setlet<ClassEntity>();
  final ResolutionWorldBuilderImpl _universe;
  final WorkItemBuilder _workItemBuilder;

  bool queueIsClosed = false;

  WorldImpactVisitor _impactVisitor;

  /// All declaration elements that have been processed by the resolver.
  final Set<Entity> _processedEntities = new Set<Entity>();

  final Queue<WorkItem> _queue = new Queue<WorkItem>();

  /// Queue of deferred resolution actions to execute when the resolution queue
  /// has been emptied.
  final Queue<_DeferredAction> _deferredQueue = new Queue<_DeferredAction>();

  ResolutionEnqueuer(
      this.task,
      this._options,
      Resolution resolution,
      this.strategy,
      this._globalDependencies,
      Backend backend,
      CacheStrategy cacheStrategy,
      [this.name = 'resolution enqueuer'])
      : this.backend = backend,
        this._resolution = resolution,
        this.nativeEnqueuer = backend.nativeResolutionEnqueuer(),
        _universe = new ResolutionWorldBuilderImpl(
            backend, resolution, cacheStrategy, const OpenWorldStrategy()),
        _workItemBuilder = new ResolutionWorkItemBuilder(resolution) {
    _impactVisitor = new EnqueuerImplImpactVisitor(this);
  }

  ResolutionWorldBuilder get worldBuilder => _universe;

  bool get queueIsEmpty => _queue.isEmpty;

  DiagnosticReporter get _reporter => _resolution.reporter;

  Iterable<ClassEntity> get processedClasses => _universe.processedClasses;

  void applyImpact(WorldImpact worldImpact, {var impactSource}) {
    if (worldImpact.isEmpty) return;
    impactStrategy.visitImpact(
        impactSource, worldImpact, _impactVisitor, impactUse);
  }

  void _registerInstantiatedType(ResolutionInterfaceType type,
      {ConstructorElement constructor,
      bool mirrorUsage: false,
      bool nativeUsage: false,
      bool globalDependency: false,
      bool isRedirection: false}) {
    task.measure(() {
      _universe.registerTypeInstantiation(type, _applyClassUse,
          constructor: constructor,
          byMirrors: mirrorUsage,
          isRedirection: isRedirection);
      if (globalDependency && !mirrorUsage) {
        _globalDependencies.registerDependency(type.element);
      }
      if (nativeUsage) {
        nativeEnqueuer.onInstantiatedType(type);
      }
      backend.registerInstantiatedType(type);
    });
  }

  bool checkNoEnqueuedInvokedInstanceMethods() {
    return strategy.checkEnqueuerConsistency(this);
  }

  void checkClass(ClassEntity cls) {
    _universe.processClassMembers(cls,
        (MemberEntity member, EnumSet<MemberUse> useSet) {
      if (useSet.isNotEmpty) {
        _reporter.internalError(member,
            'Unenqueued use of $member: ${useSet.iterable(MemberUse.values)}');
      }
    });
  }

  /// Callback for applying the use of a [member].
  void _applyMemberUse(Entity member, EnumSet<MemberUse> useSet) {
    if (useSet.contains(MemberUse.NORMAL)) {
      _addToWorkList(member);
    }
    if (useSet.contains(MemberUse.CLOSURIZE_INSTANCE)) {
      _registerClosurizedMember(member);
    }
    if (useSet.contains(MemberUse.CLOSURIZE_STATIC)) {
      applyImpact(backend.registerGetOfStaticFunction());
    }
  }

  /// Callback for applying the use of a [cls].
  void _applyClassUse(ClassEntity cls, EnumSet<ClassUse> useSet) {
    if (useSet.contains(ClassUse.INSTANTIATED)) {
      _recentClasses.add(cls);
      _universe.processClassMembers(cls, _applyMemberUse);
      // We only tell the backend once that [cls] was instantiated, so
      // any additional dependencies must be treated as global
      // dependencies.
      applyImpact(backend.registerInstantiatedClass(cls, forResolution: true));
    }
    if (useSet.contains(ClassUse.IMPLEMENTED)) {
      applyImpact(backend.registerImplementedClass(cls, forResolution: true));
    }
  }

  void processDynamicUse(DynamicUse dynamicUse) {
    task.measure(() {
      _universe.registerDynamicUse(dynamicUse, _applyMemberUse);
    });
  }

  void processStaticUse(StaticUse staticUse) {
    _universe.registerStaticUse(staticUse, _applyMemberUse);
    // TODO(johnniwinther): Add `ResolutionWorldBuilder.registerConstructorUse`
    // for these:
    switch (staticUse.kind) {
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        _registerInstantiatedType(staticUse.type,
            constructor: staticUse.element, globalDependency: false);
        break;
      case StaticUseKind.REDIRECTION:
        _registerInstantiatedType(staticUse.type,
            constructor: staticUse.element,
            globalDependency: false,
            isRedirection: true);
        break;
      default:
        break;
    }
  }

  void processTypeUse(TypeUse typeUse) {
    ResolutionDartType type = typeUse.type;
    switch (typeUse.kind) {
      case TypeUseKind.INSTANTIATION:
        _registerInstantiatedType(type, globalDependency: false);
        break;
      case TypeUseKind.MIRROR_INSTANTIATION:
        _registerInstantiatedType(type,
            mirrorUsage: true, globalDependency: false);
        break;
      case TypeUseKind.NATIVE_INSTANTIATION:
        _registerInstantiatedType(type,
            nativeUsage: true, globalDependency: true);
        break;
      case TypeUseKind.IS_CHECK:
      case TypeUseKind.AS_CAST:
      case TypeUseKind.CATCH_TYPE:
        _registerIsCheck(type);
        break;
      case TypeUseKind.CHECKED_MODE_CHECK:
        if (_options.enableTypeAssertions) {
          _registerIsCheck(type);
        }
        break;
      case TypeUseKind.TYPE_LITERAL:
        if (type.isTypedef) {
          worldBuilder.registerTypedef(type.element);
        }
        break;
    }
  }

  void _registerIsCheck(ResolutionDartType type) {
    type = _universe.registerIsCheck(type);
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    assert(!type.isTypeVariable || !type.element.enclosingElement.isTypedef);
  }

  void _registerClosurizedMember(MemberElement element) {
    assert(element.isInstanceMember);
    if (element.type.containsTypeVariables) {
      applyImpact(backend.registerClosureWithFreeTypeVariables(element,
          forResolution: true));
      _universe.closuresWithFreeTypeVariables.add(element);
    }
    applyImpact(backend.registerBoundClosure());
    _universe.closurizedMembers.add(element);
  }

  void forEach(void f(WorkItem work)) {
    do {
      while (_queue.isNotEmpty) {
        // TODO(johnniwinther): Find an optimal process order.
        WorkItem work = _queue.removeLast();
        if (!_processedEntities.contains(work.element)) {
          strategy.processWorkItem(f, work);
          _processedEntities.add(work.element);
        }
      }
      List recents = _recentClasses.toList(growable: false);
      _recentClasses.clear();
      if (!_onQueueEmpty(recents)) {
        _recentClasses.addAll(recents);
      }
    } while (_queue.isNotEmpty || _recentClasses.isNotEmpty);
  }

  void logSummary(log(message)) {
    log('Resolved ${_processedEntities.length} elements.');
    nativeEnqueuer.logSummary(log);
  }

  String toString() => 'Enqueuer($name)';

  Iterable<Entity> get processedEntities => _processedEntities;

  ImpactUseCase get impactUse => IMPACT_USE;

  bool get isResolutionQueue => true;

  /// Returns `true` if [element] has been processed by the resolution enqueuer.
  // TODO(johnniwinther): Move this to the [OpenWorld]/[ResolutionWorldBuilder].
  bool hasBeenProcessed(MemberElement element) {
    assert(invariant(element, element == element.analyzableElement.declaration,
        message: "Unexpected element $element"));
    return _processedEntities.contains(element);
  }

  /// Registers [entity] as processed by the resolution enqueuer. Used only for
  /// testing.
  void registerProcessedElementInternal(Entity entity) {
    _processedEntities.add(entity);
  }

  /// Create a [WorkItem] for [entity] and add it to the work list if it has not
  /// already been processed.
  void _addToWorkList(MemberEntity entity) {
    if (hasBeenProcessed(entity)) return;
    WorkItem workItem = _workItemBuilder.createWorkItem(entity);
    if (workItem == null) return;

    if (queueIsClosed) {
      throw new SpannableAssertionFailure(
          entity, "Resolution work list is closed. Trying to add $entity.");
    }

    applyImpact(backend.registerUsedElement(entity, forResolution: true));
    _universe.registerUsedElement(entity);
    _queue.add(workItem);
  }

  /// Adds an action to the deferred task queue.
  /// The action is performed the next time the resolution queue has been
  /// emptied.
  ///
  /// The queue is processed in FIFO order.
  void addDeferredAction(Entity entity, void action()) {
    if (queueIsClosed) {
      throw new SpannableAssertionFailure(
          entity,
          "Resolution work list is closed. "
          "Trying to add deferred action for $entity");
    }
    _deferredQueue.add(new _DeferredAction(entity, action));
  }

  /// [_onQueueEmpty] is called whenever the queue is drained. [recentClasses]
  /// contains the set of all classes seen for the first time since
  /// [_onQueueEmpty] was called last. A return value of [true] indicates that
  /// the [recentClasses] have been processed and may be cleared. If [false] is
  /// returned, [_onQueueEmpty] will be called once the queue is empty again (or
  /// still empty) and [recentClasses] will be a superset of the current value.
  bool _onQueueEmpty(Iterable<ClassEntity> recentClasses) {
    _emptyDeferredQueue();

    return backend.onQueueEmpty(this, recentClasses);
  }

  void emptyDeferredQueueForTesting() => _emptyDeferredQueue();

  void _emptyDeferredQueue() {
    while (!_deferredQueue.isEmpty) {
      _DeferredAction task = _deferredQueue.removeFirst();
      _reporter.withCurrentElement(task.element, task.action);
    }
  }

  void forgetEntity(Entity entity, Compiler compiler) {
    _universe.forgetEntity(entity, compiler);
    _processedEntities.remove(entity);
  }
}

/// Strategy used by the enqueuer to populate the world.
class EnqueuerStrategy {
  const EnqueuerStrategy();

  /// Process a static use of and element in live code.
  void processStaticUse(EnqueuerImpl enqueuer, StaticUse staticUse) {}

  /// Process a type use in live code.
  void processTypeUse(EnqueuerImpl enqueuer, TypeUse typeUse) {}

  /// Process a dynamic use for a call site in live code.
  void processDynamicUse(EnqueuerImpl enqueuer, DynamicUse dynamicUse) {}

  /// Check enqueuer consistency after the queue has been closed.
  bool checkEnqueuerConsistency(EnqueuerImpl enqueuer) => true;

  /// Process [work] using [f].
  void processWorkItem(void f(WorkItem work), WorkItem work) {
    f(work);
  }
}

/// Strategy that only enqueues directly used elements.
class DirectEnqueuerStrategy extends EnqueuerStrategy {
  const DirectEnqueuerStrategy();
  void processStaticUse(EnqueuerImpl enqueuer, StaticUse staticUse) {
    if (staticUse.kind == StaticUseKind.DIRECT_USE) {
      enqueuer.processStaticUse(staticUse);
    }
  }
}

/// Strategy used for tree-shaking.
class TreeShakingEnqueuerStrategy extends EnqueuerStrategy {
  const TreeShakingEnqueuerStrategy();

  @override
  void processStaticUse(EnqueuerImpl enqueuer, StaticUse staticUse) {
    enqueuer.processStaticUse(staticUse);
  }

  @override
  void processTypeUse(EnqueuerImpl enqueuer, TypeUse typeUse) {
    enqueuer.processTypeUse(typeUse);
  }

  @override
  void processDynamicUse(EnqueuerImpl enqueuer, DynamicUse dynamicUse) {
    enqueuer.processDynamicUse(dynamicUse);
  }

  /// Check enqueuer consistency after the queue has been closed.
  bool checkEnqueuerConsistency(EnqueuerImpl enqueuer) {
    enqueuer.task.measure(() {
      // Run through the classes and see if we need to enqueue more methods.
      for (ClassElement classElement
          in enqueuer.worldBuilder.directlyInstantiatedClasses) {
        for (ClassElement currentClass = classElement;
            currentClass != null;
            currentClass = currentClass.superclass) {
          enqueuer.checkClass(currentClass);
        }
      }
    });
    return true;
  }
}

class EnqueuerImplImpactVisitor implements WorldImpactVisitor {
  final EnqueuerImpl enqueuer;

  EnqueuerImplImpactVisitor(this.enqueuer);

  @override
  void visitDynamicUse(DynamicUse dynamicUse) {
    enqueuer.strategy.processDynamicUse(enqueuer, dynamicUse);
  }

  @override
  void visitStaticUse(StaticUse staticUse) {
    enqueuer.strategy.processStaticUse(enqueuer, staticUse);
  }

  @override
  void visitTypeUse(TypeUse typeUse) {
    enqueuer.strategy.processTypeUse(enqueuer, typeUse);
  }
}

typedef void _DeferredActionFunction();

class _DeferredAction {
  final Element element;
  final _DeferredActionFunction action;

  _DeferredAction(this.element, this.action);
}

/// Interface for creating work items for enqueued member entities.
abstract class WorkItemBuilder {
  WorkItem createWorkItem(MemberEntity entity);
}

/// Builder that creates work item necessary for the resolution of a
/// [MemberElement].
class ResolutionWorkItemBuilder extends WorkItemBuilder {
  final Resolution _resolution;

  ResolutionWorkItemBuilder(this._resolution);

  @override
  WorkItem createWorkItem(MemberElement element) {
    assert(invariant(element, element.isDeclaration));
    if (element.isMalformed) return null;

    assert(invariant(element, element is AnalyzableElement,
        message: 'Element $element is not analyzable.'));
    return _resolution.createWorkItem(element);
  }
}
