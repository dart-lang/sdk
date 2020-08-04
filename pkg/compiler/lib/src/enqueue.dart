// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.enqueue;

import 'dart:collection' show Queue;

import 'common/codegen.dart';
import 'common/tasks.dart' show CompilerTask;
import 'common/work.dart' show WorkItem;
import 'common.dart';
import 'common_elements.dart' show ElementEnvironment;
import 'constants/values.dart';
import 'compiler.dart' show Compiler;
import 'elements/entities.dart';
import 'elements/types.dart';
import 'inferrer/types.dart';
import 'js_backend/annotations.dart';
import 'js_backend/backend.dart' show CodegenInputs;
import 'js_backend/enqueuer.dart';
import 'universe/member_usage.dart';
import 'universe/resolution_world_builder.dart';
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
import 'world.dart' show JClosedWorld;

class EnqueueTask extends CompilerTask {
  ResolutionEnqueuer resolutionEnqueuerForTesting;
  bool _resolutionEnqueuerCreated = false;
  CodegenEnqueuer codegenEnqueuerForTesting;
  final Compiler compiler;

  @override
  String get name => 'Enqueue';

  EnqueueTask(Compiler compiler)
      : this.compiler = compiler,
        super(compiler.measurer);

  ResolutionEnqueuer createResolutionEnqueuer() {
    assert(!_resolutionEnqueuerCreated);
    _resolutionEnqueuerCreated = true;
    ResolutionEnqueuer enqueuer = compiler.frontendStrategy
        .createResolutionEnqueuer(this, compiler)
          ..onEmptyForTesting = compiler.onResolutionQueueEmptyForTesting;
    if (retainDataForTesting) {
      resolutionEnqueuerForTesting = enqueuer;
    }
    return enqueuer;
  }

  Enqueuer createCodegenEnqueuer(
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults,
      CodegenInputs codegenInputs,
      CodegenResults codegenResults) {
    Enqueuer enqueuer = compiler.backendStrategy.createCodegenEnqueuer(this,
        closedWorld, globalInferenceResults, codegenInputs, codegenResults)
      ..onEmptyForTesting = compiler.onCodegenQueueEmptyForTesting;
    if (retainDataForTesting) {
      codegenEnqueuerForTesting = enqueuer;
    }
    return enqueuer;
  }
}

abstract class Enqueuer {
  /// If `true` the checking for unenqueued members is skipped. The current
  /// implementation registers parameter usages as a side-effect so unit
  /// testing of member usage we need to test both with and without the
  /// enqueuer check.
  // TODO(johnniwinther): [checkEnqueuerConsistency] should not have
  // side-effects.
  static bool skipEnqueuerCheckForTesting = false;

  WorldBuilder get worldBuilder;

  void open(ImpactStrategy impactStrategy, FunctionEntity mainMethod,
      Iterable<Uri> libraries);
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

  void onQueueOpen(
      Enqueuer enqueuer, FunctionEntity mainMethod, Iterable<Uri> libraries);

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
  void checkClass(ClassEntity cls);
  void processStaticUse(MemberEntity member, StaticUse staticUse);
  void processTypeUse(MemberEntity member, TypeUse typeUse);
  void processDynamicUse(DynamicUse dynamicUse);
  void processConstantUse(ConstantUse constantUse);
  EnqueuerListener get listener;

  // TODO(johnniwinther): Initialize [_impactStrategy] to `null`.
  ImpactStrategy _impactStrategy = const ImpactStrategy();

  ImpactStrategy get impactStrategy => _impactStrategy;

  @override
  void open(ImpactStrategy impactStrategy, FunctionEntity mainMethod,
      Iterable<Uri> libraries) {
    _impactStrategy = impactStrategy;
    listener.onQueueOpen(this, mainMethod, libraries);
  }

  @override
  void close() {
    // TODO(johnniwinther): Set [_impactStrategy] to `null` and [queueIsClosed]
    // to `true` here.
    _impactStrategy = const ImpactStrategy();
    listener.onQueueClosed();
  }

  /// Check enqueuer consistency after the queue has been closed.
  bool checkEnqueuerConsistency(ElementEnvironment elementEnvironment) {
    task.measureSubtask('resolution.check', () {
      // Run through the classes and see if we need to enqueue more methods.
      for (ClassEntity classElement
          in worldBuilder.directlyInstantiatedClasses) {
        for (ClassEntity currentClass = classElement;
            currentClass != null;
            currentClass = elementEnvironment.getSuperClass(currentClass)) {
          checkClass(currentClass);
        }
      }
    });
    return true;
  }
}

/// [Enqueuer] which is specific to resolution.
class ResolutionEnqueuer extends EnqueuerImpl {
  static const ImpactUseCase IMPACT_USE =
      const ImpactUseCase('ResolutionEnqueuer');

  @override
  final CompilerTask task;
  final String name;
  @override
  final EnqueuerListener listener;

  final Set<ClassEntity> _recentClasses = new Setlet<ClassEntity>();
  bool _recentConstants = false;
  final ResolutionEnqueuerWorldBuilder _worldBuilder;
  WorkItemBuilder _workItemBuilder;
  final DiagnosticReporter _reporter;
  final AnnotationsData _annotationsData;

  @override
  bool queueIsClosed = false;

  WorldImpactVisitor _impactVisitor;

  final Queue<WorkItem> _queue = new Queue<WorkItem>();

  // If not `null` this is called when the queue has been emptied. It allows for
  // applying additional impacts before re-emptying the queue.
  void Function() onEmptyForTesting;

  ResolutionEnqueuer(this.task, this._reporter, this.listener,
      this._worldBuilder, this._workItemBuilder, this._annotationsData,
      [this.name = 'resolution enqueuer']) {
    _impactVisitor = new EnqueuerImplImpactVisitor(this);
  }

  @override
  ResolutionWorldBuilder get worldBuilder => _worldBuilder;

  @override
  bool get queueIsEmpty => _queue.isEmpty;

  @override
  void checkQueueIsEmpty() {
    if (_queue.isNotEmpty) {
      failedAt(_queue.first.element, "$name queue is not empty.");
    }
  }

  @override
  Iterable<ClassEntity> get processedClasses => _worldBuilder.processedClasses;

  @override
  void applyImpact(WorldImpact worldImpact, {var impactSource}) {
    if (worldImpact.isEmpty) return;
    impactStrategy.visitImpact(
        impactSource, worldImpact, _impactVisitor, impactUse);
  }

  void _registerInstantiatedType(InterfaceType type,
      {ConstructorEntity constructor,
      bool nativeUsage: false,
      bool globalDependency: false}) {
    task.measureSubtask('resolution.typeUse', () {
      _worldBuilder.registerTypeInstantiation(type, _applyClassUse,
          constructor: constructor);
      listener.registerInstantiatedType(type,
          isGlobal: globalDependency, nativeUsage: nativeUsage);
    });
  }

  @override
  bool checkNoEnqueuedInvokedInstanceMethods(
      ElementEnvironment elementEnvironment) {
    if (Enqueuer.skipEnqueuerCheckForTesting) return true;
    return checkEnqueuerConsistency(elementEnvironment);
  }

  @override
  void checkClass(ClassEntity cls) {
    _worldBuilder.processClassMembers(cls,
        (MemberEntity member, EnumSet<MemberUse> useSet) {
      if (useSet.isNotEmpty) {
        _reporter.internalError(member,
            'Unenqueued use of $member: ${useSet.iterable(MemberUse.values)}');
      }
    }, checkEnqueuerConsistency: true);
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

  @override
  void processDynamicUse(DynamicUse dynamicUse) {
    task.measureSubtask('resolution.dynamicUse', () {
      _worldBuilder.registerDynamicUse(dynamicUse, _applyMemberUse);
    });
  }

  @override
  void processConstantUse(ConstantUse constantUse) {
    task.measureSubtask('resolution.constantUse', () {
      if (_worldBuilder.registerConstantUse(constantUse)) {
        applyImpact(listener.registerUsedConstant(constantUse.value),
            impactSource: 'constant use');
        _recentConstants = true;
      }
    });
  }

  @override
  void processStaticUse(MemberEntity member, StaticUse staticUse) {
    task.measureSubtask('resolution.staticUse', () {
      _worldBuilder.registerStaticUse(staticUse, _applyMemberUse);
      // TODO(johnniwinther): Add `ResolutionWorldBuilder.registerConstructorUse`
      // for these:
      switch (staticUse.kind) {
        case StaticUseKind.CONSTRUCTOR_INVOKE:
        case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
          _registerInstantiatedType(staticUse.type,
              constructor: staticUse.element, globalDependency: false);
          break;
        default:
          break;
      }
    });
  }

  @override
  void processTypeUse(MemberEntity member, TypeUse typeUse) {
    DartType type = typeUse.type;
    switch (typeUse.kind) {
      case TypeUseKind.INSTANTIATION:
      case TypeUseKind.CONST_INSTANTIATION:
        _registerInstantiatedType(type, globalDependency: false);
        break;
      case TypeUseKind.NATIVE_INSTANTIATION:
        _registerInstantiatedType(type,
            nativeUsage: true, globalDependency: true);
        break;
      case TypeUseKind.IS_CHECK:
      case TypeUseKind.CATCH_TYPE:
        _registerIsCheck(type);
        break;
      case TypeUseKind.AS_CAST:
        if (_annotationsData.getExplicitCastCheckPolicy(member).isEmitted) {
          _registerIsCheck(type);
        }
        break;
      case TypeUseKind.IMPLICIT_CAST:
        if (_annotationsData.getImplicitDowncastCheckPolicy(member).isEmitted) {
          _registerIsCheck(type);
        }
        break;
      case TypeUseKind.PARAMETER_CHECK:
      case TypeUseKind.TYPE_VARIABLE_BOUND_CHECK:
        if (_annotationsData.getParameterCheckPolicy(member).isEmitted) {
          _registerIsCheck(type);
        }
        break;
      case TypeUseKind.TYPE_LITERAL:
        if (type is TypeVariableType) {
          _worldBuilder.registerTypeVariableTypeLiteral(type);
        }
        break;
      case TypeUseKind.RTI_VALUE:
      case TypeUseKind.TYPE_ARGUMENT:
      case TypeUseKind.CONSTRUCTOR_REFERENCE:
        failedAt(CURRENT_ELEMENT_SPANNABLE, "Unexpected type use: $typeUse.");
        break;
      case TypeUseKind.NAMED_TYPE_VARIABLE_NEW_RTI:
        assert(type is TypeVariableType);
        _registerNamedTypeVariableNewRti(type);
        break;
    }
  }

  void _registerIsCheck(DartType type) {
    _worldBuilder.registerIsCheck(type);
  }

  void _registerNamedTypeVariableNewRti(TypeVariableType type) {
    _worldBuilder.registerNamedTypeVariableNewRti(type);
  }

  void _registerClosurizedMember(MemberEntity element) {
    assert(element.isInstanceMember);
    applyImpact(listener.registerClosurizedMember(element),
        impactSource: 'closurized member');
    _worldBuilder.registerClosurizedMember(element);
  }

  void _forEach(void f(WorkItem work)) {
    do {
      while (_queue.isNotEmpty) {
        // TODO(johnniwinther): Find an optimal process order.
        WorkItem work = _queue.removeLast();
        if (!_worldBuilder.isMemberProcessed(work.element)) {
          f(work);
          _worldBuilder.registerProcessedMember(work.element);
        }
      }
      List<ClassEntity> recents = _recentClasses.toList(growable: false);
      _recentClasses.clear();
      _recentConstants = false;
      if (!_onQueueEmpty(recents)) {
        _recentClasses.addAll(recents);
      }
    } while (
        _queue.isNotEmpty || _recentClasses.isNotEmpty || _recentConstants);
  }

  @override
  void forEach(void f(WorkItem work)) {
    _forEach(f);
    if (onEmptyForTesting != null) {
      onEmptyForTesting();
      _forEach(f);
    }
  }

  @override
  void logSummary(void log(String message)) {
    log('Resolved ${processedEntities.length} elements.');
    listener.logSummary(log);
  }

  @override
  String toString() => 'Enqueuer($name)';

  @override
  Iterable<MemberEntity> get processedEntities =>
      _worldBuilder.processedMembers;

  @override
  ImpactUseCase get impactUse => IMPACT_USE;

  @override
  bool get isResolutionQueue => true;

  @override
  void close() {
    super.close();
    // Null out _workItemBuilder to release memory (it internally holds large
    // data-structures unnecessary after resolution.)
    _workItemBuilder = null;
  }

  /// Registers [entity] as processed by the resolution enqueuer. Used only for
  /// testing.
  void registerProcessedElementInternal(MemberEntity entity) {
    _worldBuilder.registerProcessedMember(entity);
  }

  /// Create a [WorkItem] for [entity] and add it to the work list if it has not
  /// already been processed.
  void _addToWorkList(MemberEntity entity) {
    if (_worldBuilder.isMemberProcessed(entity)) return;
    WorkItem workItem = _workItemBuilder.createWorkItem(entity);
    if (workItem == null) return;

    if (queueIsClosed) {
      failedAt(
          entity, "Resolution work list is closed. Trying to add $entity.");
    }

    applyImpact(listener.registerUsedElement(entity),
        impactSource: 'used element');
    _worldBuilder.registerUsedElement(entity);
    _queue.add(workItem);
  }

  /// [_onQueueEmpty] is called whenever the queue is drained. [recentClasses]
  /// contains the set of all classes seen for the first time since
  /// [_onQueueEmpty] was called last. A return value of [true] indicates that
  /// the [recentClasses] have been processed and may be cleared. If [false] is
  /// returned, [_onQueueEmpty] will be called once the queue is empty again (or
  /// still empty) and [recentClasses] will be a superset of the current value.
  bool _onQueueEmpty(Iterable<ClassEntity> recentClasses) {
    return listener.onQueueEmpty(this, recentClasses);
  }
}

class EnqueuerImplImpactVisitor implements WorldImpactVisitor {
  final EnqueuerImpl enqueuer;

  EnqueuerImplImpactVisitor(this.enqueuer);

  @override
  void visitDynamicUse(MemberEntity member, DynamicUse dynamicUse) {
    enqueuer.processDynamicUse(dynamicUse);
  }

  @override
  void visitStaticUse(MemberEntity member, StaticUse staticUse) {
    enqueuer.processStaticUse(member, staticUse);
  }

  @override
  void visitTypeUse(MemberEntity member, TypeUse typeUse) {
    enqueuer.processTypeUse(member, typeUse);
  }

  @override
  void visitConstantUse(MemberEntity member, ConstantUse constantUse) {
    enqueuer.processConstantUse(constantUse);
  }
}

/// Interface for creating work items for enqueued member entities.
abstract class WorkItemBuilder {
  WorkItem createWorkItem(covariant MemberEntity entity);
}
