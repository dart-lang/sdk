// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js.enqueue;

import 'dart:collection' show Queue;

import '../common.dart';
import '../common/elements.dart' show ElementEnvironment;
import '../common/tasks.dart' show CompilerTask;
import '../common/work.dart' show WorkItem;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../enqueue.dart';
import '../js_backend/annotations.dart';
import '../universe/codegen_world_builder.dart';
import '../universe/member_usage.dart';
import '../universe/use.dart'
    show
        ConstantUse,
        DynamicUse,
        StaticUse,
        StaticUseKind,
        TypeUse,
        TypeUseKind;
import '../util/enumset.dart';
import '../util/util.dart' show Setlet;

/// [Enqueuer] which is specific to code generation.
class CodegenEnqueuer extends Enqueuer {
  final String name;
  final Set<ClassEntity> _recentClasses = Setlet();
  bool _recentConstants = false;
  final CodegenWorldBuilderImpl worldBuilder;
  final WorkItemBuilder _workItemBuilder;

  @override
  bool queueIsClosed = false;
  @override
  final CompilerTask task;
  @override
  final EnqueuerListener listener;
  final AnnotationsData _annotationsData;

  final Queue<WorkItem> _queue = Queue<WorkItem>();

  // If not `null` this is called when the queue has been emptied. It allows for
  // applying additional impacts before re-emptying the queue.
  void Function()? onEmptyForTesting;

  CodegenEnqueuer(this.task, this.worldBuilder, this._workItemBuilder,
      this.listener, this._annotationsData)
      : this.name = 'codegen enqueuer';

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

  /// Create a [WorkItem] for [entity] and add it to the work list if it has not
  /// already been processed.
  void _addToWorkList(MemberEntity entity) {
    if (worldBuilder.processedEntities.contains(entity)) return;

    final workItem = _workItemBuilder.createWorkItem(entity);
    if (workItem == null) return;

    if (queueIsClosed) {
      failedAt(entity, "Codegen work list is closed. Trying to add $entity");
    }

    applyImpact(listener.registerUsedElement(entity));
    _queue.add(workItem);
  }

  void _registerInstantiatedType(InterfaceType type,
      {bool nativeUsage = false}) {
    task.measureSubtask('codegen.typeUse', () {
      worldBuilder.registerTypeInstantiation(type, _applyClassUse);
      listener.registerInstantiatedType(type, nativeUsage: nativeUsage);
    });
  }

  @override
  bool checkNoEnqueuedInvokedInstanceMethods(
      ElementEnvironment elementEnvironment) {
    return checkEnqueuerConsistency(elementEnvironment);
  }

  @override
  void checkClass(ClassEntity cls) {
    worldBuilder.processClassMembers(cls,
        (MemberEntity member, EnumSet<MemberUse> useSet) {
      if (useSet.isNotEmpty) {
        failedAt(member,
            'Unenqueued use of $member: ${useSet.iterable(MemberUse.values)}');
      }
    }, checkEnqueuerConsistency: true);
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

  /// Callback for applying the use of a [member].
  void _applyMemberUse(MemberEntity member, EnumSet<MemberUse> useSet) {
    if (useSet.contains(MemberUse.NORMAL)) {
      _addToWorkList(member);
    }
    if (useSet.contains(MemberUse.CLOSURIZE_INSTANCE)) {
      _registerClosurizedMember(member as FunctionEntity);
    }
    if (useSet.contains(MemberUse.CLOSURIZE_STATIC)) {
      applyImpact(listener.registerGetOfStaticFunction());
    }
  }

  @override
  void processDynamicUse(DynamicUse dynamicUse) {
    task.measureSubtask('codegen.dynamicUse', () {
      worldBuilder.registerDynamicUse(dynamicUse, _applyMemberUse);
    });
  }

  @override
  void processStaticUse(MemberEntity? member, StaticUse staticUse) {
    task.measureSubtask('codegen.staticUse', () {
      worldBuilder.registerStaticUse(staticUse, _applyMemberUse);
      switch (staticUse.kind) {
        case StaticUseKind.CONSTRUCTOR_INVOKE:
        case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
          processTypeUse(member, TypeUse.instantiation(staticUse.type!));
          break;
        case StaticUseKind.INLINING:
          // TODO(johnniwinther): Should this be tracked with _MemberUsage ?
          listener.registerUsedElement(staticUse.element as MemberEntity);
          break;
        default:
          break;
      }
    });
  }

  @override
  void processTypeUse(MemberEntity? member, TypeUse typeUse) {
    DartType type = typeUse.type;
    switch (typeUse.kind) {
      case TypeUseKind.INSTANTIATION:
        _registerInstantiatedType(type as InterfaceType);
        break;
      case TypeUseKind.NATIVE_INSTANTIATION:
        _registerInstantiatedType(type as InterfaceType, nativeUsage: true);
        break;
      case TypeUseKind.RECORD_INSTANTIATION:
        // TODO(49718): Collect record types for conversion to classes.
        throw UnimplementedError('processTypeUse  $member  $typeUse');
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
        worldBuilder.registerConstTypeLiteral(type);
        break;
      case TypeUseKind.TYPE_ARGUMENT:
        worldBuilder.registerTypeArgument(type);
        break;
      case TypeUseKind.CONSTRUCTOR_REFERENCE:
        worldBuilder.registerConstructorReference(type as InterfaceType);
        break;
      case TypeUseKind.CONST_INSTANTIATION:
        failedAt(CURRENT_ELEMENT_SPANNABLE, "Unexpected type use: $typeUse.");
      case TypeUseKind.NAMED_TYPE_VARIABLE_NEW_RTI:
        _registerNamedTypeVariableNewRti(type as TypeVariableType);
        break;
    }
  }

  @override
  void processConstantUse(ConstantUse constantUse) {
    task.measureSubtask('codegen.constantUse', () {
      if (worldBuilder.registerConstantUse(constantUse)) {
        applyImpact(listener.registerUsedConstant(constantUse.value));
        _recentConstants = true;
      }
    });
  }

  void _registerIsCheck(DartType type) {
    worldBuilder.registerIsCheck(type);
  }

  void _registerNamedTypeVariableNewRti(TypeVariableType type) {
    worldBuilder.registerNamedTypeVariableNewRti(type);
  }

  void _registerClosurizedMember(FunctionEntity element) {
    assert(element.isInstanceMember);
    applyImpact(listener.registerClosurizedMember(element));
  }

  void _forEach(void f(WorkItem work)) {
    do {
      while (_queue.isNotEmpty) {
        // TODO(johnniwinther): Find an optimal process order.
        WorkItem work = _queue.removeLast();
        if (!worldBuilder.processedEntities.contains(work.element)) {
          f(work);
          // TODO(johnniwinther): Register the processed element here. This
          // is currently a side-effect of calling `work.run`.
          worldBuilder.processedEntities.add(work.element);
        }
      }
      List<ClassEntity> recents = _recentClasses.toList(growable: false);
      _recentClasses.clear();
      _recentConstants = false;
      if (!_onQueueEmpty(recents)) _recentClasses.addAll(recents);
    } while (
        _queue.isNotEmpty || _recentClasses.isNotEmpty || _recentConstants);
  }

  @override
  void forEach(void f(WorkItem work)) {
    _forEach(f);
    if (onEmptyForTesting != null) {
      onEmptyForTesting!();
      _forEach(f);
    }
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

  @override
  void logSummary(void log(String message)) {
    log('Compiled ${processedEntities.length} methods.');
    listener.logSummary(log);
  }

  @override
  String toString() => 'Enqueuer($name)';

  @override
  Iterable<MemberEntity> get processedEntities =>
      worldBuilder.processedEntities;
}
