// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.enqueue;

import 'dart:collection' show Queue;

import 'common/tasks.dart' show CompilerTask;
import 'common/work.dart' show WorkItem;
import 'common.dart';
import 'common_elements.dart' show ElementEnvironment;
import 'constants/values.dart';
import 'compiler.dart' show Compiler;
import 'options.dart';
import 'elements/entities.dart';
import 'elements/resolution_types.dart' show ResolutionTypedefType;
import 'elements/types.dart';
import 'js_backend/enqueuer.dart';
import 'universe/world_builder.dart';
import 'universe/use.dart'
    show
        ConstantUse,
        DynamicUse,
        StaticUse,
        StaticUseKind,
        TypeUse,
        TypeUseKind;
import 'universe/world_impact.dart'
    show ImpactStrategy, ImpactUseCase, WorldImpact, WorldImpactVisitor;
import 'util/enumset.dart';
import 'util/util.dart' show Setlet;
import 'world.dart' show ClosedWorld;

class EnqueueTask extends CompilerTask {
  ResolutionEnqueuer _resolution;
  CodegenEnqueuer codegenEnqueuerForTesting;
  final Compiler compiler;

  String get name => 'Enqueue';

  EnqueueTask(Compiler compiler)
      : this.compiler = compiler,
        super(compiler.measurer);

  // TODO(johnniwinther): Remove the need for this.
  bool get hasResolution => _resolution != null;

  // TODO(johnniwinther): Remove the need for this.
  ResolutionEnqueuer get resolution {
    assert(
        _resolution != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "ResolutionEnqueuer has not been created yet."));
    return _resolution;
  }

  ResolutionEnqueuer createResolutionEnqueuer() {
    return _resolution ??=
        compiler.backend.createResolutionEnqueuer(this, compiler);
  }

  Enqueuer createCodegenEnqueuer(ClosedWorld closedWorld) {
    return codegenEnqueuerForTesting =
        compiler.backend.createCodegenEnqueuer(this, compiler, closedWorld);
  }
}

abstract class Enqueuer {
  WorldBuilder get worldBuilder;

  void open(ImpactStrategy impactStrategy, FunctionEntity mainMethod,
      Iterable<LibraryEntity> libraries);
  void close();

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
  bool checkNoEnqueuedInvokedInstanceMethods(
      ElementEnvironment elementEnvironment);

  /// Check the enqueuer queue is empty or fail otherwise.
  void checkQueueIsEmpty();
  void logSummary(void log(String message));

  Iterable<MemberEntity> get processedEntities;

  Iterable<ClassEntity> get processedClasses;
}

abstract class EnqueuerListener {
  /// Called to instruct to the backend that [type] has been instantiated.
  void registerInstantiatedType(InterfaceType type,
      {bool isGlobal: false, bool nativeUsage: false});

  /// Called to notify to the backend that a class is being instantiated. Any
  /// backend specific [WorldImpact] of this is returned.
  WorldImpact registerInstantiatedClass(ClassEntity cls);

  /// Called to notify to the backend that a class is implemented by an
  /// instantiated class. Any backend specific [WorldImpact] of this is
  /// returned.
  WorldImpact registerImplementedClass(ClassEntity cls);

  /// Called to register that a static function has been closurized. Any backend
  /// specific [WorldImpact] of this is returned.
  WorldImpact registerGetOfStaticFunction();

  /// Called to register that [function] has been closurized. Any backend
  /// specific [WorldImpact] of this is returned.
  WorldImpact registerClosurizedMember(FunctionEntity function);

  /// Called to register that [element] is statically known to be used. Any
  /// backend specific [WorldImpact] of this is returned.
  WorldImpact registerUsedElement(MemberEntity member);

  /// Called to register that [value] is statically known to be used. Any
  /// backend specific [WorldImpact] of this is returned.
  WorldImpact registerUsedConstant(ConstantValue value);

  void onQueueOpen(Enqueuer enqueuer, FunctionEntity mainMethod,
      Iterable<LibraryEntity> libraries);

  /// Called when [enqueuer]'s queue is empty, but before it is closed.
  ///
  /// This is used, for example, by the JS backend to enqueue additional
  /// elements needed for reflection. [recentClasses] is a collection of
  /// all classes seen for the first time by the [enqueuer] since the last call
  /// to [onQueueEmpty].
  ///
  /// A return value of `true` indicates that [recentClasses] has been
  /// processed and its elements do not need to be seen in the next round. When
  /// `false` is returned, [onQueueEmpty] will be called again once the
  /// resolution queue has drained and [recentClasses] will be a superset of the
  /// current value.
  ///
  /// There is no guarantee that a class is only present once in
  /// [recentClasses], but every class seen by the [enqueuer] will be present in
  /// [recentClasses] at least once.
  bool onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses);

  /// Called when to the queue has been closed.
  void onQueueClosed();

  /// Called after the queue has been emptied.
  void logSummary(void log(String message));
}

abstract class EnqueuerImpl extends Enqueuer {
  CompilerTask get task;
  EnqueuerStrategy get strategy;
  void checkClass(ClassEntity cls);
  void processStaticUse(StaticUse staticUse);
  void processTypeUse(TypeUse typeUse);
  void processDynamicUse(DynamicUse dynamicUse);
  void processConstantUse(ConstantUse constantUse);
  EnqueuerListener get listener;

  // TODO(johnniwinther): Initialize [_impactStrategy] to `null`.
  ImpactStrategy _impactStrategy = const ImpactStrategy();

  ImpactStrategy get impactStrategy => _impactStrategy;

  void open(ImpactStrategy impactStrategy, FunctionEntity mainMethod,
      Iterable<LibraryEntity> libraries) {
    _impactStrategy = impactStrategy;
    listener.onQueueOpen(this, mainMethod, libraries);
  }

  void close() {
    // TODO(johnniwinther): Set [_impactStrategy] to `null` and [queueIsClosed]
    // to `true` here.
    _impactStrategy = const ImpactStrategy();
    listener.onQueueClosed();
  }
}

/// [Enqueuer] which is specific to resolution.
class ResolutionEnqueuer extends EnqueuerImpl {
  static const ImpactUseCase IMPACT_USE =
      const ImpactUseCase('ResolutionEnqueuer');

  final CompilerTask task;
  final String name;
  final CompilerOptions _options;
  final EnqueuerListener listener;

  final EnqueuerStrategy strategy;
  final Set<ClassEntity> _recentClasses = new Setlet<ClassEntity>();
  bool _recentConstants = false;
  final ResolutionEnqueuerWorldBuilder _worldBuilder;
  final WorkItemBuilder _workItemBuilder;
  final DiagnosticReporter _reporter;

  bool queueIsClosed = false;

  WorldImpactVisitor _impactVisitor;

  /// All declaration elements that have been processed by the resolver.
  final Set<MemberEntity> _processedEntities = new Set<MemberEntity>();

  final Queue<WorkItem> _queue = new Queue<WorkItem>();

  /// Queue of deferred resolution actions to execute when the resolution queue
  /// has been emptied.
  final Queue<DeferredAction> _deferredQueue = new Queue<DeferredAction>();

  ResolutionEnqueuer(this.task, this._options, this._reporter, this.strategy,
      this.listener, this._worldBuilder, this._workItemBuilder,
      [this.name = 'resolution enqueuer']) {
    _impactVisitor = new EnqueuerImplImpactVisitor(this);
  }

  ResolutionWorldBuilder get worldBuilder => _worldBuilder;

  bool get queueIsEmpty => _queue.isEmpty;

  @override
  void checkQueueIsEmpty() {
    if (_queue.isNotEmpty) {
      throw new SpannableAssertionFailure(
          _queue.first.element, "$name queue is not empty.");
    }
  }

  Iterable<ClassEntity> get processedClasses => _worldBuilder.processedClasses;

  void applyImpact(WorldImpact worldImpact, {var impactSource}) {
    if (worldImpact.isEmpty) return;
    impactStrategy.visitImpact(
        impactSource, worldImpact, _impactVisitor, impactUse);
  }

  void _registerInstantiatedType(InterfaceType type,
      {ConstructorEntity constructor,
      bool mirrorUsage: false,
      bool nativeUsage: false,
      bool globalDependency: false,
      bool isRedirection: false}) {
    task.measure(() {
      _worldBuilder.registerTypeInstantiation(type, _applyClassUse,
          constructor: constructor,
          byMirrors: mirrorUsage,
          isRedirection: isRedirection);
      listener.registerInstantiatedType(type,
          isGlobal: globalDependency && !mirrorUsage, nativeUsage: nativeUsage);
    });
  }

  bool checkNoEnqueuedInvokedInstanceMethods(
      ElementEnvironment elementEnvironment) {
    return strategy.checkEnqueuerConsistency(this, elementEnvironment);
  }

  void checkClass(ClassEntity cls) {
    _worldBuilder.processClassMembers(cls,
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
      applyImpact(listener.registerGetOfStaticFunction(),
          impactSource: 'get of static function');
    }
  }

  /// Callback for applying the use of a [cls].
  void _applyClassUse(ClassEntity cls, EnumSet<ClassUse> useSet) {
    if (useSet.contains(ClassUse.INSTANTIATED)) {
      _recentClasses.add(cls);
      _worldBuilder.processClassMembers(cls, _applyMemberUse);
      // We only tell the backend once that [cls] was instantiated, so
      // any additional dependencies must be treated as global
      // dependencies.
      applyImpact(listener.registerInstantiatedClass(cls),
          impactSource: 'instantiated class');
    }
    if (useSet.contains(ClassUse.IMPLEMENTED)) {
      applyImpact(listener.registerImplementedClass(cls),
          impactSource: 'implemented class');
    }
  }

  void processDynamicUse(DynamicUse dynamicUse) {
    task.measure(() {
      _worldBuilder.registerDynamicUse(dynamicUse, _applyMemberUse);
    });
  }

  void processConstantUse(ConstantUse constantUse) {
    task.measure(() {
      if (_worldBuilder.registerConstantUse(constantUse)) {
        applyImpact(listener.registerUsedConstant(constantUse.value),
            impactSource: 'constant use');
        _recentConstants = true;
      }
    });
  }

  void processStaticUse(StaticUse staticUse) {
    _worldBuilder.registerStaticUse(staticUse, _applyMemberUse);
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
    DartType type = typeUse.type;
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
          ResolutionTypedefType typedef = type;
          worldBuilder.registerTypedef(typedef.element);
        }
        break;
    }
  }

  void _registerIsCheck(DartType type) {
    _worldBuilder.registerIsCheck(type);
  }

  void _registerClosurizedMember(MemberEntity element) {
    assert(element.isInstanceMember);
    applyImpact(listener.registerClosurizedMember(element),
        impactSource: 'closurized member');
    _worldBuilder.registerClosurizedMember(element);
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
      List<ClassEntity> recents = _recentClasses.toList(growable: false);
      _recentClasses.clear();
      _recentConstants = false;
      if (!_onQueueEmpty(recents)) {
        _recentClasses.addAll(recents);
      }
    } while (_queue.isNotEmpty ||
        _recentClasses.isNotEmpty ||
        _deferredQueue.isNotEmpty ||
        _recentConstants);
  }

  void logSummary(void log(String message)) {
    log('Resolved ${_processedEntities.length} elements.');
    listener.logSummary(log);
  }

  String toString() => 'Enqueuer($name)';

  Iterable<MemberEntity> get processedEntities => _processedEntities;

  ImpactUseCase get impactUse => IMPACT_USE;

  bool get isResolutionQueue => true;

  /// Registers [entity] as processed by the resolution enqueuer. Used only for
  /// testing.
  void registerProcessedElementInternal(MemberEntity entity) {
    _processedEntities.add(entity);
  }

  /// Create a [WorkItem] for [entity] and add it to the work list if it has not
  /// already been processed.
  void _addToWorkList(MemberEntity entity) {
    if (_processedEntities.contains(entity)) return;
    WorkItem workItem = _workItemBuilder.createWorkItem(entity);
    if (workItem == null) return;

    if (queueIsClosed) {
      throw new SpannableAssertionFailure(
          entity, "Resolution work list is closed. Trying to add $entity.");
    }

    applyImpact(listener.registerUsedElement(entity),
        impactSource: 'used element');
    _worldBuilder.registerUsedElement(entity);
    _queue.add(workItem);
  }

  /// Adds an action to the deferred task queue.
  /// The action is performed the next time the resolution queue has been
  /// emptied.
  ///
  /// The queue is processed in FIFO order.
  void addDeferredAction(DeferredAction deferredAction) {
    if (queueIsClosed) {
      throw new SpannableAssertionFailure(
          deferredAction.element,
          "Resolution work list is closed. "
          "Trying to add deferred action for ${deferredAction.element}");
    }
    _deferredQueue.add(deferredAction);
  }

  void addDeferredActions(Iterable<DeferredAction> deferredActions) {
    deferredActions.forEach(addDeferredAction);
  }

  /// [_onQueueEmpty] is called whenever the queue is drained. [recentClasses]
  /// contains the set of all classes seen for the first time since
  /// [_onQueueEmpty] was called last. A return value of [true] indicates that
  /// the [recentClasses] have been processed and may be cleared. If [false] is
  /// returned, [_onQueueEmpty] will be called once the queue is empty again (or
  /// still empty) and [recentClasses] will be a superset of the current value.
  bool _onQueueEmpty(Iterable<ClassEntity> recentClasses) {
    _emptyDeferredQueue();

    return listener.onQueueEmpty(this, recentClasses);
  }

  void emptyDeferredQueueForTesting() => _emptyDeferredQueue();

  void _emptyDeferredQueue() {
    while (!_deferredQueue.isEmpty) {
      DeferredAction task = _deferredQueue.removeFirst();
      _reporter.withCurrentElement(task.element, task.action);
    }
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

  /// Process a constant use in live code.
  void processConstantUse(EnqueuerImpl enqueuer, ConstantUse constantUse) {}

  /// Check enqueuer consistency after the queue has been closed.
  bool checkEnqueuerConsistency(
          EnqueuerImpl enqueuer, ElementEnvironment elementEnvironment) =>
      true;

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

  @override
  void processConstantUse(EnqueuerImpl enqueuer, ConstantUse constantUse) {
    enqueuer.processConstantUse(constantUse);
  }

  /// Check enqueuer consistency after the queue has been closed.
  bool checkEnqueuerConsistency(
      EnqueuerImpl enqueuer, ElementEnvironment elementEnvironment) {
    enqueuer.task.measure(() {
      // Run through the classes and see if we need to enqueue more methods.
      for (ClassEntity classElement
          in enqueuer.worldBuilder.directlyInstantiatedClasses) {
        for (ClassEntity currentClass = classElement;
            currentClass != null;
            currentClass = elementEnvironment.getSuperClass(currentClass)) {
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

  @override
  void visitConstantUse(ConstantUse constantUse) {
    enqueuer.strategy.processConstantUse(enqueuer, constantUse);
  }
}

typedef void DeferredActionFunction();

class DeferredAction {
  final Entity element;
  final DeferredActionFunction action;

  DeferredAction(this.element, this.action);
}

/// Interface for creating work items for enqueued member entities.
abstract class WorkItemBuilder {
  WorkItem createWorkItem(MemberEntity entity);
}
