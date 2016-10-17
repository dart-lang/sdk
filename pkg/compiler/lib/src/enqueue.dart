// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.enqueue;

import 'dart:collection' show Queue;

import 'common/names.dart' show Identifiers;
import 'common/resolution.dart' show Resolution;
import 'common/resolution.dart' show ResolutionWorkItem;
import 'common/tasks.dart' show CompilerTask;
import 'common/work.dart' show WorkItem;
import 'common.dart';
import 'compiler.dart' show Compiler;
import 'dart_types.dart' show DartType, InterfaceType;
import 'elements/elements.dart'
    show
        AnalyzableElement,
        AstElement,
        ClassElement,
        ConstructorElement,
        Element,
        Elements,
        Entity,
        FunctionElement,
        LibraryElement,
        Member,
        Name,
        TypedElement,
        TypedefElement;
import 'native/native.dart' as native;
import 'types/types.dart' show TypeMaskStrategy;
import 'universe/selector.dart' show Selector;
import 'universe/world_builder.dart';
import 'universe/use.dart'
    show DynamicUse, StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import 'universe/world_impact.dart'
    show ImpactUseCase, WorldImpact, WorldImpactVisitor;
import 'util/util.dart' show Setlet;

class EnqueueTask extends CompilerTask {
  final ResolutionEnqueuer resolution;
  final Enqueuer codegen;
  final Compiler compiler;

  String get name => 'Enqueue';

  EnqueueTask(Compiler compiler)
      : compiler = compiler,
        resolution = new ResolutionEnqueuer(
            compiler,
            compiler.options.analyzeOnly && compiler.options.analyzeMain
                ? const EnqueuerStrategy()
                : const TreeShakingEnqueuerStrategy()),
        codegen = compiler.backend.createCodegenEnqueuer(compiler),
        super(compiler.measurer) {
    codegen.task = this;
    resolution.task = this;

    codegen.nativeEnqueuer = compiler.backend.nativeCodegenEnqueuer(codegen);
    resolution.nativeEnqueuer =
        compiler.backend.nativeResolutionEnqueuer(resolution);
  }

  void forgetElement(Element element) {
    resolution.forgetElement(element);
    codegen.forgetElement(element);
  }
}

abstract class Enqueuer {
  EnqueueTask task;
  WorldBuilder get universe;
  native.NativeEnqueuer nativeEnqueuer; // Set by EnqueueTask
  void forgetElement(Element element);
  void processInstantiatedClassMembers(ClassElement cls);
  void processInstantiatedClassMember(ClassElement cls, Element member);
  void handleUnseenSelectorInternal(DynamicUse dynamicUse);
  void registerStaticUse(StaticUse staticUse);
  void registerStaticUseInternal(StaticUse staticUse);
  void registerDynamicUse(DynamicUse dynamicUse);
  void registerTypeUse(TypeUse typeUse);

  /// Returns [:true:] if this enqueuer is the resolution enqueuer.
  bool get isResolutionQueue;

  bool queueIsClosed;

  bool get queueIsEmpty;

  ImpactUseCase get impactUse;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void addToWorkList(Element element);

  void enableIsolateSupport();

  /// Enqueue the static fields that have been marked as used by reflective
  /// usage through `MirrorsUsed`.
  void enqueueReflectiveStaticFields(Iterable<Element> elements);

  /// Enqueue all elements that are matched by the mirrors used
  /// annotation or, in lack thereof, all elements.
  void enqueueReflectiveElements(Iterable<ClassElement> recents);

  void registerInstantiatedType(InterfaceType type, {bool mirrorUsage: false});
  void forEach(void f(WorkItem work));

  /// Apply the [worldImpact] to this enqueuer. If the [impactSource] is provided
  /// the impact strategy will remove it from the element impact cache, if it is
  /// no longer needed.
  void applyImpact(WorldImpact worldImpact, {Element impactSource});
  bool checkNoEnqueuedInvokedInstanceMethods();
  void logSummary(log(message));

  /// Returns [:true:] if [member] has been processed by this enqueuer.
  bool isProcessed(Element member);

  Iterable<Entity> get processedEntities;
}

/// [Enqueuer] which is specific to resolution.
class ResolutionEnqueuer extends Enqueuer {
  final String name;
  final Compiler compiler; // TODO(ahe): Remove this dependency.
  final EnqueuerStrategy strategy;
  final Map<String, Set<Element>> instanceMembersByName =
      new Map<String, Set<Element>>();
  final Map<String, Set<Element>> instanceFunctionsByName =
      new Map<String, Set<Element>>();
  final Set<ClassElement> _processedClasses = new Set<ClassElement>();
  Set<ClassElement> recentClasses = new Setlet<ClassElement>();
  final ResolutionWorldBuilderImpl _universe =
      new ResolutionWorldBuilderImpl(const TypeMaskStrategy());

  static final TRACE_MIRROR_ENQUEUING =
      const bool.fromEnvironment("TRACE_MIRROR_ENQUEUING");

  bool queueIsClosed = false;

  bool hasEnqueuedReflectiveElements = false;
  bool hasEnqueuedReflectiveStaticFields = false;

  WorldImpactVisitor impactVisitor;

  ResolutionEnqueuer(Compiler compiler, this.strategy)
      : this.name = 'resolution enqueuer',
        this.compiler = compiler,
        processedElements = new Set<AstElement>(),
        queue = new Queue<ResolutionWorkItem>(),
        deferredQueue = new Queue<_DeferredAction>() {
    impactVisitor = new _EnqueuerImpactVisitor(this);
  }

  // TODO(johnniwinther): Move this to [ResolutionEnqueuer].
  Resolution get resolution => compiler.resolution;

  ResolutionWorldBuilder get universe => _universe;

  bool get queueIsEmpty => queue.isEmpty;

  QueueFilter get filter => compiler.enqueuerFilter;

  DiagnosticReporter get reporter => compiler.reporter;

  bool isClassProcessed(ClassElement cls) => _processedClasses.contains(cls);

  Iterable<ClassElement> get processedClasses => _processedClasses;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void addToWorkList(Element element) {
    assert(invariant(element, element.isDeclaration));
    if (internalAddToWorkList(element) && compiler.options.dumpInfo) {
      // TODO(sigmund): add other missing dependencies (internals, selectors
      // enqueued after allocations), also enable only for the codegen enqueuer.
      compiler.dumpInfoTask
          .registerDependency(compiler.currentElement, element);
    }
  }

  void applyImpact(WorldImpact worldImpact, {Element impactSource}) {
    compiler.impactStrategy
        .visitImpact(impactSource, worldImpact, impactVisitor, impactUse);
  }

  void registerInstantiatedType(InterfaceType type, {bool mirrorUsage: false}) {
    task.measure(() {
      ClassElement cls = type.element;
      cls.ensureResolved(resolution);
      bool isNative = compiler.backend.isNative(cls);
      _universe.registerTypeInstantiation(type,
          isNative: isNative,
          byMirrors: mirrorUsage, onImplemented: (ClassElement cls) {
        compiler.backend
            .registerImplementedClass(cls, this, compiler.globalDependencies);
      });
      // TODO(johnniwinther): Share this reasoning with [Universe].
      if (!cls.isAbstract || isNative || mirrorUsage) {
        processInstantiatedClass(cls);
      }
    });
  }

  bool checkNoEnqueuedInvokedInstanceMethods() {
    return filter.checkNoEnqueuedInvokedInstanceMethods(this);
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
      if (compiler.backend.isNative(cls)) {
        compiler.openWorld.registerUsedElement(member);
        if (_universe.hasInvokedGetter(member, compiler.openWorld) ||
            _universe.hasInvocation(member, compiler.openWorld)) {
          addToWorkList(member);
          return;
        }
        if (_universe.hasInvokedSetter(member, compiler.openWorld)) {
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
        registerCallMethodWithFreeTypeVariables(function);
      }
      // If there is a property access with the same name as a method we
      // need to emit the method.
      if (_universe.hasInvokedGetter(function, compiler.openWorld)) {
        registerClosurizedMember(function);
        addToWorkList(function);
        return;
      }
      // Store the member in [instanceFunctionsByName] to catch
      // getters on the function.
      instanceFunctionsByName
          .putIfAbsent(memberName, () => new Set<Element>())
          .add(member);
      if (_universe.hasInvocation(function, compiler.openWorld)) {
        addToWorkList(function);
        return;
      }
    } else if (member.isGetter) {
      FunctionElement getter = member;
      getter.computeType(resolution);
      if (_universe.hasInvokedGetter(getter, compiler.openWorld)) {
        addToWorkList(getter);
        return;
      }
      // We don't know what selectors the returned closure accepts. If
      // the set contains any selector we have to assume that it matches.
      if (_universe.hasInvocation(getter, compiler.openWorld)) {
        addToWorkList(getter);
        return;
      }
    } else if (member.isSetter) {
      FunctionElement setter = member;
      setter.computeType(resolution);
      if (_universe.hasInvokedSetter(setter, compiler.openWorld)) {
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
        if (!compiler.serialization.isDeserialized(superclass)) {
          compiler.resolver.checkClass(superclass);
        }
        // We only tell the backend once that [superclass] was instantiated, so
        // any additional dependencies must be treated as global
        // dependencies.
        compiler.backend.registerInstantiatedClass(
            superclass, this, compiler.globalDependencies);
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

  void logEnqueueReflectiveAction(action, [msg = ""]) {
    if (TRACE_MIRROR_ENQUEUING) {
      print("MIRROR_ENQUEUE (R): $action $msg");
    }
  }

  /// Enqeue the constructor [ctor] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void enqueueReflectiveConstructor(
      ConstructorElement ctor, bool enclosingWasIncluded) {
    if (shouldIncludeElementDueToMirrors(ctor,
        includedEnclosing: enclosingWasIncluded)) {
      logEnqueueReflectiveAction(ctor);
      ClassElement cls = ctor.declaration.enclosingClass;
      compiler.backend.registerInstantiatedType(
          cls.rawType, this, compiler.mirrorDependencies,
          mirrorUsage: true);
      registerStaticUse(new StaticUse.foreignUse(ctor.declaration));
    }
  }

  /// Enqeue the member [element] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void enqueueReflectiveMember(Element element, bool enclosingWasIncluded) {
    if (shouldIncludeElementDueToMirrors(element,
        includedEnclosing: enclosingWasIncluded)) {
      logEnqueueReflectiveAction(element);
      if (element.isTypedef) {
        TypedefElement typedef = element;
        typedef.ensureResolved(resolution);
      } else if (Elements.isStaticOrTopLevel(element)) {
        registerStaticUse(new StaticUse.foreignUse(element.declaration));
      } else if (element.isInstanceMember) {
        // We need to enqueue all members matching this one in subclasses, as
        // well.
        // TODO(herhut): Use TypedSelector.subtype for enqueueing
        DynamicUse dynamicUse =
            new DynamicUse(new Selector.fromElement(element), null);
        registerDynamicUse(dynamicUse);
        if (element.isField) {
          DynamicUse dynamicUse = new DynamicUse(
              new Selector.setter(
                  new Name(element.name, element.library, isSetter: true)),
              null);
          registerDynamicUse(dynamicUse);
        }
      }
    }
  }

  /// Enqeue the member [element] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void enqueueReflectiveElementsInClass(ClassElement cls,
      Iterable<ClassElement> recents, bool enclosingWasIncluded) {
    if (cls.library.isInternalLibrary || cls.isInjected) return;
    bool includeClass = shouldIncludeElementDueToMirrors(cls,
        includedEnclosing: enclosingWasIncluded);
    if (includeClass) {
      logEnqueueReflectiveAction(cls, "register");
      ClassElement decl = cls.declaration;
      decl.ensureResolved(resolution);
      compiler.backend.registerInstantiatedType(
          decl.rawType, this, compiler.mirrorDependencies,
          mirrorUsage: true);
    }
    // If the class is never instantiated, we know nothing of it can possibly
    // be reflected upon.
    // TODO(herhut): Add a warning if a mirrors annotation cannot hit.
    if (recents.contains(cls.declaration)) {
      logEnqueueReflectiveAction(cls, "members");
      cls.constructors.forEach((Element element) {
        enqueueReflectiveConstructor(element, includeClass);
      });
      cls.forEachClassMember((Member member) {
        enqueueReflectiveMember(member.element, includeClass);
      });
    }
  }

  /// Enqeue special classes that might not be visible by normal means or that
  /// would not normally be enqueued:
  ///
  /// [Closure] is treated specially as it is the superclass of all closures.
  /// Although it is in an internal library, we mark it as reflectable. Note
  /// that none of its methods are reflectable, unless reflectable by
  /// inheritance.
  void enqueueReflectiveSpecialClasses() {
    Iterable<ClassElement> classes =
        compiler.backend.classesRequiredForReflection;
    for (ClassElement cls in classes) {
      if (compiler.backend.referencedFromMirrorSystem(cls)) {
        logEnqueueReflectiveAction(cls);
        cls.ensureResolved(resolution);
        compiler.backend.registerInstantiatedType(
            cls.rawType, this, compiler.mirrorDependencies,
            mirrorUsage: true);
      }
    }
  }

  /// Enqeue all local members of the library [lib] if they are required for
  /// reflection.
  void enqueueReflectiveElementsInLibrary(
      LibraryElement lib, Iterable<ClassElement> recents) {
    bool includeLibrary =
        shouldIncludeElementDueToMirrors(lib, includedEnclosing: false);
    lib.forEachLocalMember((Element member) {
      if (member.isInjected) return;
      if (member.isClass) {
        enqueueReflectiveElementsInClass(member, recents, includeLibrary);
      } else {
        enqueueReflectiveMember(member, includeLibrary);
      }
    });
  }

  /// Enqueue all elements that are matched by the mirrors used
  /// annotation or, in lack thereof, all elements.
  void enqueueReflectiveElements(Iterable<ClassElement> recents) {
    if (!hasEnqueuedReflectiveElements) {
      logEnqueueReflectiveAction("!START enqueueAll");
      // First round of enqueuing, visit everything that is visible to
      // also pick up static top levels, etc.
      // Also, during the first round, consider all classes that have been seen
      // as recently seen, as we do not know how many rounds of resolution might
      // have run before tree shaking is disabled and thus everything is
      // enqueued.
      recents = _processedClasses.toSet();
      reporter.log('Enqueuing everything');
      for (LibraryElement lib in compiler.libraryLoader.libraries) {
        enqueueReflectiveElementsInLibrary(lib, recents);
      }
      enqueueReflectiveSpecialClasses();
      hasEnqueuedReflectiveElements = true;
      hasEnqueuedReflectiveStaticFields = true;
      logEnqueueReflectiveAction("!DONE enqueueAll");
    } else if (recents.isNotEmpty) {
      // Keep looking at new classes until fixpoint is reached.
      logEnqueueReflectiveAction("!START enqueueRecents");
      recents.forEach((ClassElement cls) {
        enqueueReflectiveElementsInClass(
            cls,
            recents,
            shouldIncludeElementDueToMirrors(cls.library,
                includedEnclosing: false));
      });
      logEnqueueReflectiveAction("!DONE enqueueRecents");
    }
  }

  /// Enqueue the static fields that have been marked as used by reflective
  /// usage through `MirrorsUsed`.
  void enqueueReflectiveStaticFields(Iterable<Element> elements) {
    if (hasEnqueuedReflectiveStaticFields) return;
    hasEnqueuedReflectiveStaticFields = true;
    for (Element element in elements) {
      enqueueReflectiveMember(element, true);
    }
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
      if (dynamicUse.appliesUnnamed(member, compiler.openWorld)) {
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
        if (dynamicUse.appliesUnnamed(member, compiler.openWorld)) {
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
    compiler.backend.registerStaticUse(element, forResolution: true);
    bool addElement = true;
    switch (staticUse.kind) {
      case StaticUseKind.STATIC_TEAR_OFF:
        compiler.backend.registerGetOfStaticFunction(this);
        break;
      case StaticUseKind.FIELD_GET:
      case StaticUseKind.FIELD_SET:
      case StaticUseKind.CLOSURE:
        // TODO(johnniwinther): Avoid this. Currently [FIELD_GET] and
        // [FIELD_SET] contains [BoxFieldElement]s which we cannot enqueue.
        // Also [CLOSURE] contains [LocalFunctionElement] which we cannot
        // enqueue.
        addElement = false;
        break;
      case StaticUseKind.SUPER_FIELD_SET:
      case StaticUseKind.SUPER_TEAR_OFF:
      case StaticUseKind.GENERAL:
        break;
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        registerTypeUse(new TypeUse.instantiation(staticUse.type));
        break;
    }
    if (addElement) {
      addToWorkList(element);
    }
  }

  void registerTypeUse(TypeUse typeUse) {
    DartType type = typeUse.type;
    switch (typeUse.kind) {
      case TypeUseKind.INSTANTIATION:
        registerInstantiatedType(type);
        break;
      case TypeUseKind.IS_CHECK:
      case TypeUseKind.AS_CAST:
      case TypeUseKind.CATCH_TYPE:
        _registerIsCheck(type);
        break;
      case TypeUseKind.CHECKED_MODE_CHECK:
        if (compiler.options.enableTypeAssertions) {
          _registerIsCheck(type);
        }
        break;
      case TypeUseKind.TYPE_LITERAL:
        break;
    }
  }

  void _registerIsCheck(DartType type) {
    type = _universe.registerIsCheck(type, compiler);
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    assert(!type.isTypeVariable || !type.element.enclosingElement.isTypedef);
  }

  void registerCallMethodWithFreeTypeVariables(Element element) {
    compiler.backend.registerCallMethodWithFreeTypeVariables(
        element, this, compiler.globalDependencies);
    _universe.callMethodsWithFreeTypeVariables.add(element);
  }

  void registerClosurizedMember(TypedElement element) {
    assert(element.isInstanceMember);
    if (element.computeType(resolution).containsTypeVariables) {
      compiler.backend.registerClosureWithFreeTypeVariables(
          element, this, compiler.globalDependencies);
      _universe.closuresWithFreeTypeVariables.add(element);
    }
    compiler.backend.registerBoundClosure(this);
    _universe.closurizedMembers.add(element);
  }

  void forEach(void f(WorkItem work)) {
    do {
      while (queue.isNotEmpty) {
        // TODO(johnniwinther): Find an optimal process order.
        filter.processWorkItem(f, queue.removeLast());
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
    compiler.backend.onElementResolved(element);
  }

  /**
   * Decides whether an element should be included to satisfy requirements
   * of the mirror system.
   *
   * During resolution, we have to resort to matching elements against the
   * [MirrorsUsed] pattern, as we do not have a complete picture of the world,
   * yet.
   */
  bool shouldIncludeElementDueToMirrors(Element element,
      {bool includedEnclosing}) {
    return includedEnclosing ||
        compiler.backend.requiredByMirrorSystem(element);
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

    compiler.openWorld.registerUsedElement(element);

    ResolutionWorkItem workItem = compiler.resolution.createWorkItem(element);
    queue.add(workItem);

    // Enable isolate support if we start using something from the isolate
    // library, or timers for the async library.  We exclude constant fields,
    // which are ending here because their initializing expression is compiled.
    LibraryElement library = element.library;
    if (!compiler.hasIsolateSupport && (!element.isField || !element.isConst)) {
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
      compiler.enabledRuntimeType = true;
      // TODO(ahe): Record precise dependency here.
      compiler.backend.registerRuntimeType(this, compiler.globalDependencies);
    } else if (compiler.commonElements.isFunctionApplyMethod(element)) {
      compiler.enabledFunctionApply = true;
    }

    return true;
  }

  void registerNoSuchMethod(Element element) {
    compiler.backend.registerNoSuchMethod(element);
  }

  void enableIsolateSupport() {
    compiler.hasIsolateSupport = true;
    compiler.backend.enableIsolateSupport(this);
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

    return compiler.backend.onQueueEmpty(this, recentClasses);
  }

  void emptyDeferredQueueForTesting() => _emptyDeferredQueue();

  void _emptyDeferredQueue() {
    while (!deferredQueue.isEmpty) {
      _DeferredAction task = deferredQueue.removeFirst();
      reporter.withCurrentElement(task.element, task.action);
    }
  }

  void forgetElement(Element element) {
    _universe.forgetElement(element, compiler);
    _processedClasses.remove(element);
    instanceMembersByName[element.name]?.remove(element);
    instanceFunctionsByName[element.name]?.remove(element);
    processedElements.remove(element);
  }
}

/// Parameterizes filtering of which work items are enqueued.
class QueueFilter {
  bool checkNoEnqueuedInvokedInstanceMethods(Enqueuer enqueuer) {
    enqueuer.task.measure(() {
      // Run through the classes and see if we need to compile methods.
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

  void processWorkItem(void f(WorkItem work), WorkItem work) {
    f(work);
  }
}

void removeFromSet(Map<String, Set<Element>> map, Element element) {
  Set<Element> set = map[element.name];
  if (set == null) return;
  set.remove(element);
}

/// Strategy used by the enqueuer to populate the world.
// TODO(johnniwinther): Merge this interface with [QueueFilter].
class EnqueuerStrategy {
  const EnqueuerStrategy();

  /// Process a class instantiated in live code.
  void processInstantiatedClass(Enqueuer enqueuer, ClassElement cls) {}

  /// Process a static use of and element in live code.
  void processStaticUse(Enqueuer enqueuer, StaticUse staticUse) {}

  /// Process a dynamic use for a call site in live code.
  void processDynamicUse(Enqueuer enqueuer, DynamicUse dynamicUse) {}
}

class TreeShakingEnqueuerStrategy implements EnqueuerStrategy {
  const TreeShakingEnqueuerStrategy();

  @override
  void processInstantiatedClass(Enqueuer enqueuer, ClassElement cls) {
    cls.implementation.forEachMember(enqueuer.processInstantiatedClassMember);
  }

  @override
  void processStaticUse(Enqueuer enqueuer, StaticUse staticUse) {
    enqueuer.registerStaticUseInternal(staticUse);
  }

  @override
  void processDynamicUse(Enqueuer enqueuer, DynamicUse dynamicUse) {
    enqueuer.handleUnseenSelectorInternal(dynamicUse);
  }
}

class _EnqueuerImpactVisitor implements WorldImpactVisitor {
  final Enqueuer enqueuer;

  _EnqueuerImpactVisitor(this.enqueuer);

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
