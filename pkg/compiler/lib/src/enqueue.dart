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
        FunctionElement,
        LibraryElement,
        LocalFunctionElement,
        TypedElement;
import 'native/native.dart' as native;
import 'types/types.dart' show TypeMaskStrategy;
import 'universe/selector.dart' show Selector;
import 'universe/world_builder.dart';
import 'universe/use.dart'
    show DynamicUse, StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import 'universe/world_impact.dart'
    show ImpactStrategy, ImpactUseCase, WorldImpact, WorldImpactVisitor;
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
  void processInstantiatedClassMembers(ClassElement cls);
  void processInstantiatedClassMember(ClassElement cls, Element member);
  void registerStaticUse(StaticUse staticUse);
  void registerStaticUseInternal(StaticUse staticUse);
  void registerTypeUse(TypeUse typeUse);
  void registerTypeUseInternal(TypeUse typeUse);
  void registerDynamicUse(DynamicUse dynamicUse);
  void handleUnseenSelectorInternal(DynamicUse dynamicUse);
}

/// [Enqueuer] which is specific to resolution.
class ResolutionEnqueuer extends EnqueuerImpl {
  final CompilerTask task;
  final String name;
  final Resolution resolution;
  final CompilerOptions options;
  final Backend backend;
  final GlobalDependencyRegistry globalDependencies;
  final CommonElements commonElements;
  final native.NativeEnqueuer nativeEnqueuer;

  final EnqueuerStrategy strategy;
  final Map<String, Set<Element>> instanceMembersByName =
      new Map<String, Set<Element>>();
  final Map<String, Set<Element>> instanceFunctionsByName =
      new Map<String, Set<Element>>();
  final Set<ClassElement> _processedClasses = new Set<ClassElement>();
  Set<ClassElement> recentClasses = new Setlet<ClassElement>();
  final ResolutionWorldBuilderImpl _universe;

  bool queueIsClosed = false;

  WorldImpactVisitor impactVisitor;

  ResolutionEnqueuer(
      this.task,
      this.options,
      this.resolution,
      this.strategy,
      this.globalDependencies,
      Backend backend,
      CommonElements commonElements,
      CacheStrategy cacheStrategy,
      [this.name = 'resolution enqueuer'])
      : this.backend = backend,
        this.commonElements = commonElements,
        this.nativeEnqueuer = backend.nativeResolutionEnqueuer(),
        processedElements = new Set<AstElement>(),
        queue = new Queue<ResolutionWorkItem>(),
        deferredQueue = new Queue<_DeferredAction>(),
        _universe = new ResolutionWorldBuilderImpl(
            backend, commonElements, cacheStrategy, const TypeMaskStrategy()) {
    impactVisitor = new EnqueuerImplImpactVisitor(this);
  }

  ResolutionWorldBuilder get universe => _universe;

  OpenWorld get openWorld => universe.openWorld;

  bool get queueIsEmpty => queue.isEmpty;

  DiagnosticReporter get reporter => resolution.reporter;

  bool isClassProcessed(ClassElement cls) => _processedClasses.contains(cls);

  Iterable<ClassElement> get processedClasses => _processedClasses;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void addToWorkList(Element element) {
    assert(invariant(element, element.isDeclaration));
    internalAddToWorkList(element);
  }

  void applyImpact(WorldImpact worldImpact, {Element impactSource}) {
    if (worldImpact.isEmpty) return;
    impactStrategy.visitImpact(
        impactSource, worldImpact, impactVisitor, impactUse);
  }

  void registerInstantiatedType(InterfaceType type) {
    _registerInstantiatedType(type, globalDependency: true);
  }

  void _registerInstantiatedType(InterfaceType type,
      {ConstructorElement constructor,
      bool mirrorUsage: false,
      bool nativeUsage: false,
      bool globalDependency: false,
      bool isRedirection: false}) {
    task.measure(() {
      ClassElement cls = type.element;
      cls.ensureResolved(resolution);
      bool isNative = backend.isNative(cls);
      _universe.registerTypeInstantiation(type,
          constructor: constructor,
          isNative: isNative,
          byMirrors: mirrorUsage,
          isRedirection: isRedirection, onImplemented: (ClassElement cls) {
        applyImpact(backend.registerImplementedClass(cls, forResolution: true));
      });
      if (globalDependency && !mirrorUsage) {
        globalDependencies.registerDependency(type.element);
      }
      if (nativeUsage) {
        nativeEnqueuer.onInstantiatedType(type);
      }
      backend.registerInstantiatedType(type);
      // TODO(johnniwinther): Share this reasoning with [Universe].
      if (!cls.isAbstract || isNative || mirrorUsage) {
        processInstantiatedClass(cls);
      }
    });
  }

  bool checkNoEnqueuedInvokedInstanceMethods() {
    return strategy.checkEnqueuerConsistency(this);
  }

  void processInstantiatedClassMembers(ClassElement cls) {
    strategy.processInstantiatedClass(this, cls);
  }

  void processInstantiatedClassMember(ClassElement cls, Element member) {
    assert(invariant(member, member.isDeclaration));
    if (isProcessed(member)) return;
    if (!member.isInstanceMember) return;
    String memberName = member.name;

    if (member.isField) {
      // The obvious thing to test here would be "member.isNative",
      // however, that only works after metadata has been parsed/analyzed,
      // and that may not have happened yet.
      // So instead we use the enclosing class, which we know have had
      // its metadata parsed and analyzed.
      // Note: this assumes that there are no non-native fields on native
      // classes, which may not be the case when a native class is subclassed.
      if (backend.isNative(cls)) {
        openWorld.registerUsedElement(member);
        if (_universe.hasInvokedGetter(member, openWorld) ||
            _universe.hasInvocation(member, openWorld)) {
          addToWorkList(member);
          return;
        }
        if (_universe.hasInvokedSetter(member, openWorld)) {
          addToWorkList(member);
          return;
        }
        // Native fields need to go into instanceMembersByName as they
        // are virtual instantiation points and escape points.
      } else {
        // All field initializers must be resolved as they could
        // have an observable side-effect (and cannot be tree-shaken
        // away).
        addToWorkList(member);
        return;
      }
    } else if (member.isFunction) {
      FunctionElement function = member;
      function.computeType(resolution);
      if (function.name == Identifiers.noSuchMethod_) {
        registerNoSuchMethod(function);
      }
      if (function.name == Identifiers.call && !cls.typeVariables.isEmpty) {
        _registerCallMethodWithFreeTypeVariables(function);
      }
      // If there is a property access with the same name as a method we
      // need to emit the method.
      if (_universe.hasInvokedGetter(function, openWorld)) {
        registerClosurizedMember(function);
        addToWorkList(function);
        return;
      }
      // Store the member in [instanceFunctionsByName] to catch
      // getters on the function.
      instanceFunctionsByName
          .putIfAbsent(memberName, () => new Set<Element>())
          .add(member);
      if (_universe.hasInvocation(function, openWorld)) {
        addToWorkList(function);
        return;
      }
    } else if (member.isGetter) {
      FunctionElement getter = member;
      getter.computeType(resolution);
      if (_universe.hasInvokedGetter(getter, openWorld)) {
        addToWorkList(getter);
        return;
      }
      // We don't know what selectors the returned closure accepts. If
      // the set contains any selector we have to assume that it matches.
      if (_universe.hasInvocation(getter, openWorld)) {
        addToWorkList(getter);
        return;
      }
    } else if (member.isSetter) {
      FunctionElement setter = member;
      setter.computeType(resolution);
      if (_universe.hasInvokedSetter(setter, openWorld)) {
        addToWorkList(setter);
        return;
      }
    }

    // The element is not yet used. Add it to the list of instance
    // members to still be processed.
    instanceMembersByName
        .putIfAbsent(memberName, () => new Set<Element>())
        .add(member);
  }

  void processInstantiatedClass(ClassElement cls) {
    task.measure(() {
      if (_processedClasses.contains(cls)) return;
      // The class must be resolved to compute the set of all
      // supertypes.
      cls.ensureResolved(resolution);

      void processClass(ClassElement superclass) {
        if (_processedClasses.contains(superclass)) return;

        _processedClasses.add(superclass);
        recentClasses.add(superclass);
        superclass.ensureResolved(resolution);
        superclass.implementation.forEachMember(processInstantiatedClassMember);
        resolution.ensureClassMembers(superclass);
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

  void registerDynamicUse(DynamicUse dynamicUse) {
    task.measure(() {
      if (_universe.registerDynamicUse(dynamicUse)) {
        handleUnseenSelector(dynamicUse);
      }
    });
  }

  void processSet(
      Map<String, Set<Element>> map, String memberName, bool f(Element e)) {
    Set<Element> members = map[memberName];
    if (members == null) return;
    // [f] might add elements to [: map[memberName] :] during the loop below
    // so we create a new list for [: map[memberName] :] and prepend the
    // [remaining] members after the loop.
    map[memberName] = new Set<Element>();
    Set<Element> remaining = new Set<Element>();
    for (Element member in members) {
      if (!f(member)) remaining.add(member);
    }
    map[memberName].addAll(remaining);
  }

  processInstanceMembers(String n, bool f(Element e)) {
    processSet(instanceMembersByName, n, f);
  }

  processInstanceFunctions(String n, bool f(Element e)) {
    processSet(instanceFunctionsByName, n, f);
  }

  void handleUnseenSelector(DynamicUse universeSelector) {
    strategy.processDynamicUse(this, universeSelector);
  }

  void handleUnseenSelectorInternal(DynamicUse dynamicUse) {
    Selector selector = dynamicUse.selector;
    String methodName = selector.name;
    processInstanceMembers(methodName, (Element member) {
      if (dynamicUse.appliesUnnamed(member, openWorld)) {
        if (member.isFunction && selector.isGetter) {
          registerClosurizedMember(member);
        }
        addToWorkList(member);
        return true;
      }
      return false;
    });
    if (selector.isGetter) {
      processInstanceFunctions(methodName, (Element member) {
        if (dynamicUse.appliesUnnamed(member, openWorld)) {
          registerClosurizedMember(member);
          return true;
        }
        return false;
      });
    }
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void registerStaticUse(StaticUse staticUse) {
    strategy.processStaticUse(this, staticUse);
  }

  void registerStaticUseInternal(StaticUse staticUse) {
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
          universe.closuresWithFreeTypeVariables.add(closure);
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
      addToWorkList(element);
    }
  }

  void registerTypeUse(TypeUse typeUse) {
    strategy.processTypeUse(this, typeUse);
  }

  void registerTypeUseInternal(TypeUse typeUse) {
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
        if (options.enableTypeAssertions) {
          _registerIsCheck(type);
        }
        break;
      case TypeUseKind.TYPE_LITERAL:
        break;
    }
  }

  void _registerIsCheck(DartType type) {
    type = _universe.registerIsCheck(type, resolution);
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

  void registerClosurizedMember(TypedElement element) {
    assert(element.isInstanceMember);
    if (element.computeType(resolution).containsTypeVariables) {
      applyImpact(backend.registerClosureWithFreeTypeVariables(element,
          forResolution: true));
      _universe.closuresWithFreeTypeVariables.add(element);
    }
    applyImpact(backend.registerBoundClosure());
    _universe.closurizedMembers.add(element);
  }

  void forEach(void f(WorkItem work)) {
    do {
      while (queue.isNotEmpty) {
        // TODO(johnniwinther): Find an optimal process order.
        WorkItem work = queue.removeLast();
        if (!isProcessed(work.element)) {
          strategy.processWorkItem(f, work);
          registerProcessedElement(work.element);
        }
      }
      List recents = recentClasses.toList(growable: false);
      recentClasses.clear();
      if (!onQueueEmpty(recents)) recentClasses.addAll(recents);
    } while (queue.isNotEmpty || recentClasses.isNotEmpty);
  }

  void logSummary(log(message)) {
    log('Resolved ${processedElements.length} elements.');
    nativeEnqueuer.logSummary(log);
  }

  String toString() => 'Enqueuer($name)';

  /// All declaration elements that have been processed by the resolver.
  final Set<AstElement> processedElements;

  Iterable<Entity> get processedEntities => processedElements;

  final Queue<ResolutionWorkItem> queue;

  /// Queue of deferred resolution actions to execute when the resolution queue
  /// has been emptied.
  final Queue<_DeferredAction> deferredQueue;

  static const ImpactUseCase IMPACT_USE =
      const ImpactUseCase('ResolutionEnqueuer');

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

  /**
   * Adds [element] to the work list if it has not already been processed.
   *
   * Returns [true] if the element was actually added to the queue.
   */
  bool internalAddToWorkList(Element element) {
    if (element.isMalformed) return false;

    assert(invariant(element, element is AnalyzableElement,
        message: 'Element $element is not analyzable.'));
    if (hasBeenProcessed(element)) return false;
    if (queueIsClosed) {
      throw new SpannableAssertionFailure(
          element, "Resolution work list is closed. Trying to add $element.");
    }

    openWorld.registerUsedElement(element);

    ResolutionWorkItem workItem = resolution.createWorkItem(element);
    queue.add(workItem);

    // Enable isolate support if we start using something from the isolate
    // library, or timers for the async library.  We exclude constant fields,
    // which are ending here because their initializing expression is compiled.
    LibraryElement library = element.library;
    if (!universe.hasIsolateSupport && (!element.isField || !element.isConst)) {
      String uri = library.canonicalUri.toString();
      if (uri == 'dart:isolate') {
        enableIsolateSupport();
      } else if (uri == 'dart:async') {
        if (element.name == '_createTimer' ||
            element.name == '_createPeriodicTimer') {
          // The [:Timer:] class uses the event queue of the isolate
          // library, so we make sure that event queue is generated.
          enableIsolateSupport();
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
    } else if (commonElements.isFunctionApplyMethod(element)) {
      _universe.hasFunctionApplySupport = true;
    }

    return true;
  }

  void registerNoSuchMethod(Element element) {
    backend.registerNoSuchMethod(element);
  }

  void enableIsolateSupport() {
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
    deferredQueue.add(new _DeferredAction(element, action));
  }

  /// [onQueueEmpty] is called whenever the queue is drained. [recentClasses]
  /// contains the set of all classes seen for the first time since
  /// [onQueueEmpty] was called last. A return value of [true] indicates that
  /// the [recentClasses] have been processed and may be cleared. If [false] is
  /// returned, [onQueueEmpty] will be called once the queue is empty again (or
  /// still empty) and [recentClasses] will be a superset of the current value.
  bool onQueueEmpty(Iterable<ClassElement> recentClasses) {
    _emptyDeferredQueue();

    return backend.onQueueEmpty(this, recentClasses);
  }

  void emptyDeferredQueueForTesting() => _emptyDeferredQueue();

  void _emptyDeferredQueue() {
    while (!deferredQueue.isEmpty) {
      _DeferredAction task = deferredQueue.removeFirst();
      reporter.withCurrentElement(task.element, task.action);
    }
  }

  void forgetElement(Element element, Compiler compiler) {
    _universe.forgetElement(element, compiler);
    _processedClasses.remove(element);
    instanceMembersByName[element.name]?.remove(element);
    instanceFunctionsByName[element.name]?.remove(element);
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

  /// Process a class instantiated in live code.
  void processInstantiatedClass(EnqueuerImpl enqueuer, ClassElement cls) {}

  /// Process a static use of and element in live code.
  void processStaticUse(EnqueuerImpl enqueuer, StaticUse staticUse) {}

  /// Process a type use in live code.
  void processTypeUse(EnqueuerImpl enqueuer, TypeUse typeUse) {}

  /// Process a dynamic use for a call site in live code.
  void processDynamicUse(EnqueuerImpl enqueuer, DynamicUse dynamicUse) {}

  /// Check enqueuer consistency after the queue has been closed.
  bool checkEnqueuerConsistency(EnqueuerImpl enqueuer) {
    enqueuer.task.measure(() {
      // Run through the classes and see if we need to enqueue more methods.
      for (ClassElement classElement
          in enqueuer.universe.directlyInstantiatedClasses) {
        for (ClassElement currentClass = classElement;
            currentClass != null;
            currentClass = currentClass.superclass) {
          enqueuer.processInstantiatedClassMembers(currentClass);
        }
      }
    });
    return true;
  }

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
      enqueuer.registerStaticUseInternal(staticUse);
    }
  }
}

/// Strategy used for tree-shaking.
class TreeShakingEnqueuerStrategy extends EnqueuerStrategy {
  const TreeShakingEnqueuerStrategy();

  @override
  void processInstantiatedClass(EnqueuerImpl enqueuer, ClassElement cls) {
    cls.implementation.forEachMember(enqueuer.processInstantiatedClassMember);
  }

  @override
  void processStaticUse(EnqueuerImpl enqueuer, StaticUse staticUse) {
    enqueuer.registerStaticUseInternal(staticUse);
  }

  @override
  void processTypeUse(EnqueuerImpl enqueuer, TypeUse typeUse) {
    enqueuer.registerTypeUseInternal(typeUse);
  }

  @override
  void processDynamicUse(EnqueuerImpl enqueuer, DynamicUse dynamicUse) {
    enqueuer.handleUnseenSelectorInternal(dynamicUse);
  }
}

class EnqueuerImplImpactVisitor implements WorldImpactVisitor {
  final EnqueuerImpl enqueuer;

  EnqueuerImplImpactVisitor(this.enqueuer);

  @override
  void visitDynamicUse(DynamicUse dynamicUse) {
    enqueuer.registerDynamicUse(dynamicUse);
  }

  @override
  void visitStaticUse(StaticUse staticUse) {
    enqueuer.registerStaticUse(staticUse);
  }

  @override
  void visitTypeUse(TypeUse typeUse) {
    enqueuer.registerTypeUse(typeUse);
  }
}

typedef void _DeferredActionFunction();

class _DeferredAction {
  final Element element;
  final _DeferredActionFunction action;

  _DeferredAction(this.element, this.action);
}
