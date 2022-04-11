// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show Queue;

import '../common.dart';
import '../common/elements.dart' show ElementEnvironment;
import '../common/tasks.dart' show CompilerTask;
import '../common/work.dart' show WorkItem;
import '../enqueue.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/annotations.dart';
import '../universe/member_usage.dart';
import '../universe/resolution_world_builder.dart';
import '../universe/use.dart'
    show
        ConstantUse,
        DynamicUse,
        StaticUse,
        StaticUseKind,
        TypeUse,
        TypeUseKind;
import '../universe/world_impact.dart' show WorldImpactVisitor;
import '../util/enumset.dart';
import '../util/util.dart' show Setlet;

/// [Enqueuer] which is specific to resolution.
class ResolutionEnqueuer extends Enqueuer {
  @override
  final CompilerTask task;
  final String name;
  @override
  final EnqueuerListener listener;

  final Set<ClassEntity> _recentClasses = Setlet<ClassEntity>();
  bool _recentConstants = false;
  final ResolutionWorldBuilder worldBuilder;
  WorkItemBuilder _workItemBuilder;
  final DiagnosticReporter _reporter;
  final AnnotationsData _annotationsData;

  @override
  bool queueIsClosed = false;

  @override
  WorldImpactVisitor impactVisitor;

  final Queue<WorkItem> _queue = Queue<WorkItem>();

  // If not `null` this is called when the queue has been emptied. It allows for
  // applying additional impacts before re-emptying the queue.
  void Function() onEmptyForTesting;

  ResolutionEnqueuer(this.task, this._reporter, this.listener,
      this.worldBuilder, this._workItemBuilder, this._annotationsData,
      [this.name = 'resolution enqueuer']) {
    impactVisitor = EnqueuerImpactVisitor(this);
  }

  @override
  Iterable<ClassEntity> get directlyInstantiatedClasses =>
      worldBuilder.directlyInstantiatedClasses;

  @override
  bool get queueIsEmpty => _queue.isEmpty;

  @override
  void checkQueueIsEmpty() {
    if (_queue.isNotEmpty) {
      failedAt(_queue.first.element, "$name queue is not empty.");
    }
  }

  void _registerInstantiatedType(InterfaceType type,
      {ConstructorEntity constructor,
      bool nativeUsage = false,
      bool globalDependency = false}) {
    task.measureSubtask('resolution.typeUse', () {
      worldBuilder.registerTypeInstantiation(type, _applyClassUse,
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
    worldBuilder.processClassMembers(cls,
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
      applyImpact(listener.registerGetOfStaticFunction());
    }
  }

  /// Callback for applying the use of a [cls].
  void _applyClassUse(ClassEntity cls, EnumSet<ClassUse> useSet) {
    if (useSet.contains(ClassUse.INSTANTIATED)) {
      _recentClasses.add(cls);
      worldBuilder.processClassMembers(cls, _applyMemberUse);
      // We only tell the backend once that [cls] was instantiated, so
      // any additional dependencies must be treated as global
      // dependencies.
      applyImpact(listener.registerInstantiatedClass(cls));
    }
    if (useSet.contains(ClassUse.IMPLEMENTED)) {
      applyImpact(listener.registerImplementedClass(cls));
    }
  }

  @override
  void processDynamicUse(DynamicUse dynamicUse) {
    task.measureSubtask('resolution.dynamicUse', () {
      worldBuilder.registerDynamicUse(dynamicUse, _applyMemberUse);
    });
  }

  @override
  void processConstantUse(ConstantUse constantUse) {
    task.measureSubtask('resolution.constantUse', () {
      if (worldBuilder.registerConstantUse(constantUse)) {
        applyImpact(listener.registerUsedConstant(constantUse.value));
        _recentConstants = true;
      }
    });
  }

  @override
  void processStaticUse(MemberEntity member, StaticUse staticUse) {
    task.measureSubtask('resolution.staticUse', () {
      worldBuilder.registerStaticUse(staticUse, _applyMemberUse);
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
          worldBuilder.registerTypeVariableTypeLiteral(type);
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
    worldBuilder.registerIsCheck(type);
  }

  void _registerNamedTypeVariableNewRti(TypeVariableType type) {
    worldBuilder.registerNamedTypeVariableNewRti(type);
  }

  void _registerClosurizedMember(MemberEntity element) {
    assert(element.isInstanceMember);
    applyImpact(listener.registerClosurizedMember(element));
    worldBuilder.registerClosurizedMember(element);
  }

  void _forEach(void f(WorkItem work)) {
    do {
      while (_queue.isNotEmpty) {
        // TODO(johnniwinther): Find an optimal process order.
        WorkItem work = _queue.removeLast();
        if (!worldBuilder.isMemberProcessed(work.element)) {
          f(work);
          worldBuilder.registerProcessedMember(work.element);
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
  Iterable<MemberEntity> get processedEntities => worldBuilder.processedMembers;

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
    worldBuilder.registerProcessedMember(entity);
  }

  /// Create a [WorkItem] for [entity] and add it to the work list if it has not
  /// already been processed.
  void _addToWorkList(MemberEntity entity) {
    if (worldBuilder.isMemberProcessed(entity)) return;
    WorkItem workItem = _workItemBuilder.createWorkItem(entity);
    if (workItem == null) return;

    if (queueIsClosed) {
      failedAt(
          entity, "Resolution work list is closed. Trying to add $entity.");
    }

    applyImpact(listener.registerUsedElement(entity));
    worldBuilder.registerUsedElement(entity);
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
