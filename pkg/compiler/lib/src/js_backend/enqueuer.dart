// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js.enqueue;

import 'dart:collection' show Queue;

import '../cache_strategy.dart' show CacheStrategy;
import '../common/backend_api.dart' show Backend;
import '../common/codegen.dart' show CodegenWorkItem;
import '../common/tasks.dart' show CompilerTask;
import '../common/work.dart' show WorkItem;
import '../common.dart';
import '../compiler.dart' show Compiler;
import '../elements/resolution_types.dart'
    show ResolutionDartType, ResolutionInterfaceType;
import '../elements/elements.dart' show Entity, MemberElement, TypedElement;
import '../elements/entities.dart';
import '../enqueue.dart';
import '../native/native.dart' as native;
import '../options.dart';
import '../types/types.dart' show TypeMaskStrategy;
import '../universe/world_builder.dart';
import '../universe/use.dart'
    show DynamicUse, StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import '../universe/world_impact.dart'
    show ImpactUseCase, WorldImpact, WorldImpactVisitor;
import '../util/enumset.dart';
import '../util/util.dart' show Setlet;

/// [Enqueuer] which is specific to code generation.
class CodegenEnqueuer extends EnqueuerImpl {
  final String name;
  final EnqueuerStrategy strategy;

  Set<ClassEntity> _recentClasses = new Setlet<ClassEntity>();
  final CodegenWorldBuilderImpl _universe;
  final WorkItemBuilder _workItemBuilder;

  bool queueIsClosed = false;
  final CompilerTask task;
  final native.NativeEnqueuer nativeEnqueuer;
  final Backend _backend;
  final CompilerOptions _options;

  WorldImpactVisitor _impactVisitor;

  final Queue<WorkItem> _queue = new Queue<WorkItem>();

  /// All declaration elements that have been processed by codegen.
  final Set<Entity> _processedEntities = new Set<Entity>();

  final Set<Entity> newlyEnqueuedElements;

  final Set<DynamicUse> newlySeenSelectors;

  static const ImpactUseCase IMPACT_USE =
      const ImpactUseCase('CodegenEnqueuer');

  CodegenEnqueuer(this.task, CacheStrategy cacheStrategy, Backend backend,
      CompilerOptions options, this.strategy)
      : _universe =
            new CodegenWorldBuilderImpl(backend, const TypeMaskStrategy()),
        _workItemBuilder = new CodegenWorkItemBuilder(backend, options),
        newlyEnqueuedElements = cacheStrategy.newSet(),
        newlySeenSelectors = cacheStrategy.newSet(),
        nativeEnqueuer = backend.nativeCodegenEnqueuer(),
        this._backend = backend,
        this._options = options,
        this.name = 'codegen enqueuer' {
    _impactVisitor = new EnqueuerImplImpactVisitor(this);
  }

  CodegenWorldBuilder get worldBuilder => _universe;

  bool get queueIsEmpty => _queue.isEmpty;

  /// Returns [:true:] if this enqueuer is the resolution enqueuer.
  bool get isResolutionQueue => false;

  /// Create a [WorkItem] for [entity] and add it to the work list if it has not
  /// already been processed.
  void _addToWorkList(MemberEntity entity) {
    if (_processedEntities.contains(entity)) return;

    WorkItem workItem = _workItemBuilder.createWorkItem(entity);
    if (workItem == null) return;

    if (_options.hasIncrementalSupport) {
      newlyEnqueuedElements.add(entity);
    }

    if (queueIsClosed) {
      throw new SpannableAssertionFailure(
          entity, "Codegen work list is closed. Trying to add $entity");
    }

    applyImpact(_backend.registerUsedElement(entity, forResolution: false));
    _queue.add(workItem);
  }

  void applyImpact(WorldImpact worldImpact, {var impactSource}) {
    if (worldImpact.isEmpty) return;
    impactStrategy.visitImpact(
        impactSource, worldImpact, _impactVisitor, impactUse);
  }

  void _registerInstantiatedType(ResolutionInterfaceType type,
      {bool mirrorUsage: false, bool nativeUsage: false}) {
    task.measure(() {
      _universe.registerTypeInstantiation(type, _applyClassUse,
          byMirrors: mirrorUsage);
      if (nativeUsage) {
        nativeEnqueuer.onInstantiatedType(type);
      }
      _backend.registerInstantiatedType(type);
    });
  }

  bool checkNoEnqueuedInvokedInstanceMethods() {
    return strategy.checkEnqueuerConsistency(this);
  }

  void checkClass(ClassEntity cls) {
    _universe.processClassMembers(cls, (MemberEntity member, useSet) {
      if (useSet.isNotEmpty) {
        _backend.compiler.reporter.internalError(member,
            'Unenqueued use of $member: ${useSet.iterable(MemberUse.values)}');
      }
    });
  }

  /// Callback for applying the use of a [cls].
  void _applyClassUse(ClassEntity cls, EnumSet<ClassUse> useSet) {
    if (useSet.contains(ClassUse.INSTANTIATED)) {
      _recentClasses.add(cls);
      _universe.processClassMembers(cls, _applyMemberUse);
      // We only tell the backend once that [cls] was instantiated, so
      // any additional dependencies must be treated as global
      // dependencies.
      applyImpact(
          _backend.registerInstantiatedClass(cls, forResolution: false));
    }
    if (useSet.contains(ClassUse.IMPLEMENTED)) {
      applyImpact(_backend.registerImplementedClass(cls, forResolution: false));
    }
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
      applyImpact(_backend.registerGetOfStaticFunction());
    }
  }

  void processDynamicUse(DynamicUse dynamicUse) {
    task.measure(() {
      if (_universe.registerDynamicUse(dynamicUse, _applyMemberUse)) {
        if (_options.hasIncrementalSupport) {
          newlySeenSelectors.add(dynamicUse);
        }
      }
    });
  }

  void processStaticUse(StaticUse staticUse) {
    _universe.registerStaticUse(staticUse, _applyMemberUse);
    switch (staticUse.kind) {
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
      case StaticUseKind.REDIRECTION:
        processTypeUse(new TypeUse.instantiation(staticUse.type));
        break;
      default:
        break;
    }
  }

  void processTypeUse(TypeUse typeUse) {
    ResolutionDartType type = typeUse.type;
    switch (typeUse.kind) {
      case TypeUseKind.INSTANTIATION:
        _registerInstantiatedType(type);
        break;
      case TypeUseKind.MIRROR_INSTANTIATION:
        _registerInstantiatedType(type, mirrorUsage: true);
        break;
      case TypeUseKind.NATIVE_INSTANTIATION:
        _registerInstantiatedType(type, nativeUsage: true);
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

  void _registerClosurizedMember(TypedElement element) {
    assert(element.isInstanceMember);
    if (element.type.containsTypeVariables) {
      applyImpact(_backend.registerClosureWithFreeTypeVariables(element,
          forResolution: false));
    }
    applyImpact(_backend.registerBoundClosure());
  }

  void forEach(void f(WorkItem work)) {
    do {
      while (_queue.isNotEmpty) {
        // TODO(johnniwinther): Find an optimal process order.
        WorkItem work = _queue.removeLast();
        if (!_processedEntities.contains(work.element)) {
          strategy.processWorkItem(f, work);
          // TODO(johnniwinther): Register the processed element here. This
          // is currently a side-effect of calling `work.run`.
          _processedEntities.add(work.element);
        }
      }
      List recents = _recentClasses.toList(growable: false);
      _recentClasses.clear();
      if (!_onQueueEmpty(recents)) _recentClasses.addAll(recents);
    } while (_queue.isNotEmpty || _recentClasses.isNotEmpty);
  }

  /// [_onQueueEmpty] is called whenever the queue is drained. [recentClasses]
  /// contains the set of all classes seen for the first time since
  /// [_onQueueEmpty] was called last. A return value of [true] indicates that
  /// the [recentClasses] have been processed and may be cleared. If [false] is
  /// returned, [_onQueueEmpty] will be called once the queue is empty again (or
  /// still empty) and [recentClasses] will be a superset of the current value.
  bool _onQueueEmpty(Iterable<ClassEntity> recentClasses) {
    return _backend.onQueueEmpty(this, recentClasses);
  }

  void logSummary(log(message)) {
    log('Compiled ${_processedEntities.length} methods.');
    nativeEnqueuer.logSummary(log);
  }

  String toString() => 'Enqueuer($name)';

  ImpactUseCase get impactUse => IMPACT_USE;

  void forgetEntity(Entity entity, Compiler compiler) {
    _universe.forgetElement(entity, compiler);
    _processedEntities.remove(entity);
  }

  @override
  Iterable<Entity> get processedEntities => _processedEntities;

  @override
  Iterable<ClassEntity> get processedClasses => _universe.processedClasses;
}

/// Builder that creates the work item necessary for the code generation of a
/// [MemberElement].
class CodegenWorkItemBuilder extends WorkItemBuilder {
  Backend _backend;
  CompilerOptions _options;

  CodegenWorkItemBuilder(this._backend, this._options);

  @override
  WorkItem createWorkItem(MemberElement element) {
    assert(invariant(element, element.isDeclaration));
    // Don't generate code for foreign elements.
    if (_backend.isForeign(element)) return null;
    if (element.isAbstract) return null;

    // Codegen inlines field initializers. It only needs to generate
    // code for checked setters.
    if (element.isField && element.isInstanceMember) {
      if (!_options.enableTypeAssertions ||
          element.enclosingElement.isClosure) {
        return null;
      }
    }
    return new CodegenWorkItem(_backend, element);
  }
}
