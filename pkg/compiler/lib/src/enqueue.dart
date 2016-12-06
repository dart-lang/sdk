// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.enqueue;

import 'dart:collection' show Queue;

import 'cache_strategy.dart';
import 'common/backend_api.dart' show Backend;
import 'common/names.dart' show Identifiers;
import 'common/resolution.dart' show Resolution, ResolutionWorkItem;
import 'common/tasks.dart' show CompilerTask;
import 'common/work.dart' show WorkItem;
import 'common.dart';
import 'compiler.dart' show Compiler, GlobalDependencyRegistry;
import 'core_types.dart' show CommonElements;
import 'options.dart';
import 'dart_types.dart' show DartType, InterfaceType;
import 'elements/elements.dart'
    show
        AnalyzableElement,
        AstElement,
        ClassElement,
        ConstructorElement,
        Element,
        Entity,
        LibraryElement,
        LocalFunctionElement,
        MemberElement;
import 'elements/entities.dart';
import 'native/native.dart' as native;
import 'types/types.dart' show TypeMaskStrategy;
import 'universe/world_builder.dart';
import 'universe/use.dart'
    show DynamicUse, StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import 'universe/world_impact.dart'
    show ImpactStrategy, ImpactUseCase, WorldImpact, WorldImpactVisitor;
import 'util/enumset.dart';
import 'util/util.dart' show Setlet;
import 'world.dart' show OpenWorld;

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
        compiler.coreClasses,
        compiler.cacheStrategy);
    _codegen = compiler.backend.createCodegenEnqueuer(this, compiler);
  }

  ResolutionEnqueuer get resolution => _resolution;
  Enqueuer get codegen => _codegen;

  void forgetElement(Element element) {
    resolution.forgetElement(element, compiler);
    codegen.forgetElement(element, compiler);
  }
}

abstract class Enqueuer {
  WorldBuilder get universe;
  native.NativeEnqueuer get nativeEnqueuer;
  void forgetElement(Element element, Compiler compiler);

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
  void applyImpact(WorldImpact worldImpact, {Element impactSource});
  bool checkNoEnqueuedInvokedInstanceMethods();
  void logSummary(log(message));

  /// Returns [:true:] if [member] has been processed by this enqueuer.
  bool isProcessed(Element member);

  Iterable<Entity> get processedEntities;

  Iterable<ClassElement> get processedClasses;
}

abstract class EnqueuerImpl extends Enqueuer {
  CompilerTask get task;
  EnqueuerStrategy get strategy;
  void checkClass(ClassElement cls);
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
  final CommonElements _commonElements;
  final native.NativeEnqueuer nativeEnqueuer;

  final EnqueuerStrategy strategy;
  final Set<ClassElement> _processedClasses = new Set<ClassElement>();
  Set<ClassElement> _recentClasses = new Setlet<ClassElement>();
  final ResolutionWorldBuilderImpl _universe;

  bool queueIsClosed = false;

  WorldImpactVisitor _impactVisitor;

  /// All declaration elements that have been processed by the resolver.
  final Set<AstElement> processedElements = new Set<AstElement>();

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
      this._commonElements,
      CacheStrategy cacheStrategy,
      [this.name = 'resolution enqueuer'])
      : this.backend = backend,
        this._resolution = resolution,
        this.nativeEnqueuer = backend.nativeResolutionEnqueuer(),
        _universe = new ResolutionWorldBuilderImpl(
            backend, resolution, cacheStrategy, const TypeMaskStrategy()) {
    _impactVisitor = new EnqueuerImplImpactVisitor(this);
  }

  ResolutionWorldBuilder get universe => _universe;

  OpenWorld get _openWorld => universe.openWorld;

  bool get queueIsEmpty => _queue.isEmpty;

  DiagnosticReporter get _reporter => _resolution.reporter;

  Iterable<ClassElement> get processedClasses => _processedClasses;

  void applyImpact(WorldImpact worldImpact, {Element impactSource}) {
    if (worldImpact.isEmpty) return;
    impactStrategy.visitImpact(
        impactSource, worldImpact, _impactVisitor, impactUse);
  }

  void _registerInstantiatedType(InterfaceType type,
      {ConstructorElement constructor,
      bool mirrorUsage: false,
      bool nativeUsage: false,
      bool globalDependency: false,
      bool isRedirection: false}) {
    task.measure(() {
      ClassElement cls = type.element;
      cls.ensureResolved(_resolution);
      bool isNative = backend.isNative(cls);
      _universe.registerTypeInstantiation(type,
          constructor: constructor,
          isNative: isNative,
          byMirrors: mirrorUsage,
          isRedirection: isRedirection, onImplemented: (ClassElement cls) {
        applyImpact(backend.registerImplementedClass(cls, forResolution: true));
      });
      if (globalDependency && !mirrorUsage) {
        _globalDependencies.registerDependency(type.element);
      }
      if (nativeUsage) {
        nativeEnqueuer.onInstantiatedType(type);
      }
      backend.registerInstantiatedType(type);
      // TODO(johnniwinther): Share this reasoning with [Universe].
      if (!cls.isAbstract || isNative || mirrorUsage) {
        _processInstantiatedClass(cls);
      }
    });
  }

  bool checkNoEnqueuedInvokedInstanceMethods() {
    return strategy.checkEnqueuerConsistency(this);
  }

  void checkClass(ClassElement cls) {
    _processClassMembers(cls,
        (MemberElement member, EnumSet<MemberUse> useSet) {
      if (useSet.isNotEmpty) {
        _reporter.internalError(member,
            'Unenqueued use of $member: ${useSet.iterable(MemberUse.values)}');
      }
    });
  }

  /// Callback for applying the first seen use of a [member].
  void _applyFirstUse(MemberElement member, EnumSet<MemberUse> useSet) {
    ClassElement cls = member.enclosingClass;
    if (member.isFunction) {
      MemberElement function = member;
      if (function.name == Identifiers.noSuchMethod_) {
        _registerNoSuchMethod(function);
      }
      if (function.name == Identifiers.call && !cls.typeVariables.isEmpty) {
        _registerCallMethodWithFreeTypeVariables(function);
      }
    }
    _applyUse(member, useSet);
  }

  /// Callback for applying the use of a [member].
  void _applyUse(Entity member, EnumSet<MemberUse> useSet) {
    if (useSet.contains(MemberUse.NORMAL)) {
      _addToWorkList(member);
    }
    if (useSet.contains(MemberUse.CLOSURIZE)) {
      _registerClosurizedMember(member);
    }
  }

  /// TODO(johnniwinther): Move this to [ResolutionWorldBuilderImpl].
  void _processInstantiatedClass(ClassElement cls) {
    task.measure(() {
      if (_processedClasses.contains(cls)) return;
      // The class must be resolved to compute the set of all
      // supertypes.
      cls.ensureResolved(_resolution);

      void processClass(ClassElement superclass) {
        if (_processedClasses.contains(superclass)) return;

        _processedClasses.add(superclass);
        _recentClasses.add(superclass);
        superclass.ensureResolved(_resolution);
        _processClassMembers(superclass, _applyFirstUse);
        _resolution.ensureClassMembers(superclass);
        // We only tell the backend once that [superclass] was instantiated, so
        // any additional dependencies must be treated as global
        // dependencies.
        applyImpact(
            backend.registerInstantiatedClass(superclass, forResolution: true));
      }

      ClassElement superclass = cls;
      while (superclass != null) {
        processClass(superclass);
        superclass = superclass.superclass;
      }
    });
  }

  /// TODO(johnniwinther): Move this to [ResolutionWorldBuilderImpl].
  void _processClassMembers(ClassElement cls, MemberUsed memberUsed) {
    cls.implementation.forEachMember((ClassElement cls, MemberElement member) {
      _universe.processInstantiatedClassMember(cls, member, memberUsed);
    });
  }

  void processDynamicUse(DynamicUse dynamicUse) {
    task.measure(() {
      _universe.registerDynamicUse(dynamicUse, _applyUse);
    });
  }

  void processStaticUse(StaticUse staticUse) {
    Element element = staticUse.element;
    assert(invariant(element, element.isDeclaration,
        message: "Element ${element} is not the declaration."));
    _universe.registerStaticUse(staticUse);
    applyImpact(backend.registerStaticUse(element, forResolution: true));
    bool addElement = true;
    switch (staticUse.kind) {
      case StaticUseKind.STATIC_TEAR_OFF:
        applyImpact(backend.registerGetOfStaticFunction());
        break;
      case StaticUseKind.FIELD_GET:
      case StaticUseKind.FIELD_SET:
      case StaticUseKind.CLOSURE:
        // TODO(johnniwinther): Avoid this. Currently [FIELD_GET] and
        // [FIELD_SET] contains [BoxFieldElement]s which we cannot enqueue.
        // Also [CLOSURE] contains [LocalFunctionElement] which we cannot
        // enqueue.
        LocalFunctionElement closure = staticUse.element;
        if (closure.type.containsTypeVariables) {
          _universe.closuresWithFreeTypeVariables.add(closure);
        }
        addElement = false;
        break;
      case StaticUseKind.SUPER_FIELD_SET:
      case StaticUseKind.SUPER_TEAR_OFF:
      case StaticUseKind.GENERAL:
      case StaticUseKind.DIRECT_USE:
        break;
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
      case StaticUseKind.DIRECT_INVOKE:
        invariant(
            element, 'Direct static use is not supported for resolution.');
        break;
    }
    if (addElement) {
      _addToWorkList(element);
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
        break;
    }
  }

  void _registerIsCheck(DartType type) {
    type = _universe.registerIsCheck(type, _resolution);
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    assert(!type.isTypeVariable || !type.element.enclosingElement.isTypedef);
  }

  void _registerCallMethodWithFreeTypeVariables(Element element) {
    applyImpact(backend.registerCallMethodWithFreeTypeVariables(element,
        forResolution: true));
    _universe.callMethodsWithFreeTypeVariables.add(element);
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
        if (!isProcessed(work.element)) {
          strategy.processWorkItem(f, work);
          registerProcessedElement(work.element);
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
    log('Resolved ${processedElements.length} elements.');
    nativeEnqueuer.logSummary(log);
  }

  String toString() => 'Enqueuer($name)';

  Iterable<Entity> get processedEntities => processedElements;

  ImpactUseCase get impactUse => IMPACT_USE;

  bool get isResolutionQueue => true;

  bool isProcessed(Element member) => processedElements.contains(member);

  /// Returns `true` if [element] has been processed by the resolution enqueuer.
  bool hasBeenProcessed(Element element) {
    return processedElements.contains(element.analyzableElement.declaration);
  }

  /// Registers [element] as processed by the resolution enqueuer.
  void registerProcessedElement(AstElement element) {
    processedElements.add(element);
    backend.onElementResolved(element);
  }

  /// Adds [element] to the work list if it has not already been processed.
  ///
  /// Invariant: [element] must be a declaration element.
  void _addToWorkList(Element element) {
    assert(invariant(element, element.isDeclaration));
    if (element.isMalformed) return;

    assert(invariant(element, element is AnalyzableElement,
        message: 'Element $element is not analyzable.'));
    if (hasBeenProcessed(element)) return;
    if (queueIsClosed) {
      throw new SpannableAssertionFailure(
          element, "Resolution work list is closed. Trying to add $element.");
    }

    _openWorld.registerUsedElement(element);

    ResolutionWorkItem workItem = _resolution.createWorkItem(element);
    _queue.add(workItem);

    // Enable isolate support if we start using something from the isolate
    // library, or timers for the async library.  We exclude constant fields,
    // which are ending here because their initializing expression is compiled.
    LibraryElement library = element.library;
    if (!universe.hasIsolateSupport && (!element.isField || !element.isConst)) {
      String uri = library.canonicalUri.toString();
      if (uri == 'dart:isolate') {
        _enableIsolateSupport();
      } else if (uri == 'dart:async') {
        if (element.name == '_createTimer' ||
            element.name == '_createPeriodicTimer') {
          // The [:Timer:] class uses the event queue of the isolate
          // library, so we make sure that event queue is generated.
          _enableIsolateSupport();
        }
      }
    }

    if (element.isGetter && element.name == Identifiers.runtimeType_) {
      // Enable runtime type support if we discover a getter called runtimeType.
      // We have to enable runtime type before hitting the codegen, so
      // that constructors know whether they need to generate code for
      // runtime type.
      _universe.hasRuntimeTypeSupport = true;
      // TODO(ahe): Record precise dependency here.
      applyImpact(backend.registerRuntimeType());
    } else if (_commonElements.isFunctionApplyMethod(element)) {
      _universe.hasFunctionApplySupport = true;
    }
  }

  void _registerNoSuchMethod(Element element) {
    backend.registerNoSuchMethod(element);
  }

  void _enableIsolateSupport() {
    _universe.hasIsolateSupport = true;
    applyImpact(backend.enableIsolateSupport(forResolution: true));
  }

  /**
   * Adds an action to the deferred task queue.
   *
   * The action is performed the next time the resolution queue has been
   * emptied.
   *
   * The queue is processed in FIFO order.
   */
  void addDeferredAction(Element element, void action()) {
    if (queueIsClosed) {
      throw new SpannableAssertionFailure(
          element,
          "Resolution work list is closed. "
          "Trying to add deferred action for $element");
    }
    _deferredQueue.add(new _DeferredAction(element, action));
  }

  /// [_onQueueEmpty] is called whenever the queue is drained. [recentClasses]
  /// contains the set of all classes seen for the first time since
  /// [_onQueueEmpty] was called last. A return value of [true] indicates that
  /// the [recentClasses] have been processed and may be cleared. If [false] is
  /// returned, [_onQueueEmpty] will be called once the queue is empty again (or
  /// still empty) and [recentClasses] will be a superset of the current value.
  bool _onQueueEmpty(Iterable<ClassElement> recentClasses) {
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

  void forgetElement(Element element, Compiler compiler) {
    _universe.forgetElement(element, compiler);
    _processedClasses.remove(element);
    processedElements.remove(element);
  }
}

void removeFromSet(Map<String, Set<Element>> map, Element element) {
  Set<Element> set = map[element.name];
  if (set == null) return;
  set.remove(element);
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
          in enqueuer.universe.directlyInstantiatedClasses) {
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
