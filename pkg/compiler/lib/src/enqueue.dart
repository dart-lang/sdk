// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

typedef ItemCompilationContext ItemCompilationContextCreator();

class EnqueueTask extends CompilerTask {
  final ResolutionEnqueuer resolution;
  final CodegenEnqueuer codegen;

  String get name => 'Enqueue';

  EnqueueTask(Compiler compiler)
    : resolution = new ResolutionEnqueuer(
          compiler, compiler.backend.createItemCompilationContext),
      codegen = new CodegenEnqueuer(
          compiler, compiler.backend.createItemCompilationContext),
      super(compiler) {
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

class WorldImpact {
  const WorldImpact();

  Iterable<UniverseSelector> get dynamicInvocations =>
      const <UniverseSelector>[];
  Iterable<UniverseSelector> get dynamicGetters => const <UniverseSelector>[];
  Iterable<UniverseSelector> get dynamicSetters => const <UniverseSelector>[];

  // TODO(johnniwinther): Split this into more precise subsets.
  Iterable<Element> get staticUses => const <Element>[];

  // TODO(johnniwinther): Replace this by called constructors with type
  // arguments.
  Iterable<InterfaceType> get instantiatedTypes => const <InterfaceType>[];

  // TODO(johnniwinther): Collect checked types for checked mode separately to
  // support serialization.
  Iterable<DartType> get checkedTypes => const <DartType>[];

  Iterable<MethodElement> get closurizedFunctions => const <MethodElement>[];
}

abstract class Enqueuer {
  final String name;
  final Compiler compiler; // TODO(ahe): Remove this dependency.
  final ItemCompilationContextCreator itemCompilationContextCreator;
  final Map<String, Set<Element>> instanceMembersByName
      = new Map<String, Set<Element>>();
  final Map<String, Set<Element>> instanceFunctionsByName
      = new Map<String, Set<Element>>();
  final Set<ClassElement> _processedClasses = new Set<ClassElement>();
  Set<ClassElement> recentClasses = new Setlet<ClassElement>();
  final Universe universe = new Universe();

  static final TRACE_MIRROR_ENQUEUING =
      const bool.fromEnvironment("TRACE_MIRROR_ENQUEUING");

  bool queueIsClosed = false;
  EnqueueTask task;
  native.NativeEnqueuer nativeEnqueuer;  // Set by EnqueueTask

  bool hasEnqueuedReflectiveElements = false;
  bool hasEnqueuedReflectiveStaticFields = false;

  Enqueuer(this.name, this.compiler, this.itemCompilationContextCreator);

  Queue<WorkItem> get queue;
  bool get queueIsEmpty => queue.isEmpty;

  /// Returns [:true:] if this enqueuer is the resolution enqueuer.
  bool get isResolutionQueue => false;

  QueueFilter get filter => compiler.enqueuerFilter;

  /// Returns [:true:] if [member] has been processed by this enqueuer.
  bool isProcessed(Element member);

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void addToWorkList(Element element) {
    assert(invariant(element, element.isDeclaration));
    internalAddToWorkList(element);
  }

  /**
   * Adds [element] to the work list if it has not already been processed.
   *
   * Returns [true] if the element was actually added to the queue.
   */
  bool internalAddToWorkList(Element element);

  /// Apply the [worldImpact] of processing [element] to this enqueuer.
  void applyImpact(Element element, WorldImpact worldImpact) {
    // TODO(johnniwinther): Optimize the application of the world impact.
    worldImpact.dynamicInvocations.forEach(registerDynamicInvocation);
    worldImpact.dynamicGetters.forEach(registerDynamicGetter);
    worldImpact.dynamicSetters.forEach(registerDynamicSetter);
    worldImpact.staticUses.forEach(registerStaticUse);
    // TODO(johnniwinther): Register [worldImpact.instantiatedTypes] when it
    // doesn't require a [Registry].
    worldImpact.checkedTypes.forEach(registerIsCheck);
    worldImpact.closurizedFunctions.forEach(registerGetOfStaticFunction);
  }

  // TODO(johnniwinther): Remove the need for passing the [registry].
  void registerInstantiatedType(InterfaceType type, Registry registry,
                                {bool mirrorUsage: false}) {
    task.measure(() {
      ClassElement cls = type.element;
      registry.registerDependency(cls);
      cls.ensureResolved(compiler);
      universe.registerTypeInstantiation(type, byMirrors: mirrorUsage);
      processInstantiatedClass(cls);
      compiler.backend.registerInstantiatedType(type, registry);
    });
  }

  bool checkNoEnqueuedInvokedInstanceMethods() {
    return filter.checkNoEnqueuedInvokedInstanceMethods(this);
  }

  void processInstantiatedClassMembers(ClassElement cls) {
    cls.implementation.forEachMember(processInstantiatedClassMember);
  }

  void processInstantiatedClassMember(ClassElement cls, Element member) {
    assert(invariant(member, member.isDeclaration));
    if (isProcessed(member)) return;
    if (!member.isInstanceMember) return;
    String memberName = member.name;

    if (member.kind == ElementKind.FIELD) {
      // The obvious thing to test here would be "member.isNative",
      // however, that only works after metadata has been parsed/analyzed,
      // and that may not have happened yet.
      // So instead we use the enclosing class, which we know have had
      // its metadata parsed and analyzed.
      // Note: this assumes that there are no non-native fields on native
      // classes, which may not be the case when a native class is subclassed.
      if (cls.isNative) {
        compiler.world.registerUsedElement(member);
        nativeEnqueuer.handleFieldAnnotations(member);
        if (universe.hasInvokedGetter(member, compiler.world) ||
            universe.hasInvocation(member, compiler.world)) {
          nativeEnqueuer.registerFieldLoad(member);
          // In handleUnseenSelector we can't tell if the field is loaded or
          // stored.  We need the basic algorithm to be Church-Rosser, since the
          // resolution 'reduction' order is different to the codegen order. So
          // register that the field is also stored.  In other words: if we
          // don't register the store here during resolution, the store could be
          // registered during codegen on the handleUnseenSelector path, and
          // cause the set of codegen elements to include unresolved elements.
          nativeEnqueuer.registerFieldStore(member);
          addToWorkList(member);
          return;
        }
        if (universe.hasInvokedSetter(member, compiler.world)) {
          nativeEnqueuer.registerFieldStore(member);
          // See comment after registerFieldLoad above.
          nativeEnqueuer.registerFieldLoad(member);
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
    } else if (member.kind == ElementKind.FUNCTION) {
      FunctionElement function = member;
      function.computeType(compiler);
      if (function.name == Compiler.NO_SUCH_METHOD) {
        registerNoSuchMethod(function);
      }
      if (function.name == Compiler.CALL_OPERATOR_NAME &&
          !cls.typeVariables.isEmpty) {
        registerCallMethodWithFreeTypeVariables(
            function, compiler.globalDependencies);
      }
      // If there is a property access with the same name as a method we
      // need to emit the method.
      if (universe.hasInvokedGetter(function, compiler.world)) {
        registerClosurizedMember(function, compiler.globalDependencies);
        addToWorkList(function);
        return;
      }
      // Store the member in [instanceFunctionsByName] to catch
      // getters on the function.
      instanceFunctionsByName.putIfAbsent(memberName, () => new Set<Element>())
          .add(member);
      if (universe.hasInvocation(function, compiler.world)) {
        addToWorkList(function);
        return;
      }
    } else if (member.kind == ElementKind.GETTER) {
      FunctionElement getter = member;
      getter.computeType(compiler);
      if (universe.hasInvokedGetter(getter, compiler.world)) {
        addToWorkList(getter);
        return;
      }
      // We don't know what selectors the returned closure accepts. If
      // the set contains any selector we have to assume that it matches.
      if (universe.hasInvocation(getter, compiler.world)) {
        addToWorkList(getter);
        return;
      }
    } else if (member.kind == ElementKind.SETTER) {
      FunctionElement setter = member;
      setter.computeType(compiler);
      if (universe.hasInvokedSetter(setter, compiler.world)) {
        addToWorkList(setter);
        return;
      }
    }

    // The element is not yet used. Add it to the list of instance
    // members to still be processed.
    instanceMembersByName.putIfAbsent(memberName, () => new Set<Element>())
        .add(member);
  }

  void registerNoSuchMethod(Element noSuchMethod);

  void enableIsolateSupport() {}

  void processInstantiatedClass(ClassElement cls) {
    task.measure(() {
      if (_processedClasses.contains(cls)) return;
      // The class must be resolved to compute the set of all
      // supertypes.
      cls.ensureResolved(compiler);

      void processClass(ClassElement cls) {
        if (_processedClasses.contains(cls)) return;

        _processedClasses.add(cls);
        recentClasses.add(cls);
        cls.ensureResolved(compiler);
        cls.implementation.forEachMember(processInstantiatedClassMember);
        if (isResolutionQueue && !cls.isSynthesized) {
          compiler.resolver.checkClass(cls);
        }
        // We only tell the backend once that [cls] was instantiated, so
        // any additional dependencies must be treated as global
        // dependencies.
        compiler.backend.registerInstantiatedClass(
            cls, this, compiler.globalDependencies);
      }
      processClass(cls);
      for (Link<DartType> supertypes = cls.allSupertypes;
           !supertypes.isEmpty; supertypes = supertypes.tail) {
        processClass(supertypes.head.element);
      }
    });
  }

  void registerInvocation(UniverseSelector selector) {
    task.measure(() {
      if (universe.registerInvocation(selector)) {
        handleUnseenSelector(selector);
      }
    });
  }

  void registerInvokedGetter(UniverseSelector selector) {
    task.measure(() {
      if (universe.registerInvokedGetter(selector)) {
        handleUnseenSelector(selector);
      }
    });
  }

  void registerInvokedSetter(UniverseSelector selector) {
    task.measure(() {
      if (universe.registerInvokedSetter(selector)) {
        handleUnseenSelector(selector);
      }
    });
  }

  /**
   * Decides whether an element should be included to satisfy requirements
   * of the mirror system. [includedEnclosing] provides a hint whether the
   * enclosing element was included.
   *
   * The actual implementation depends on the current compiler phase.
   */
  bool shouldIncludeElementDueToMirrors(Element element,
                                        {bool includedEnclosing});

  void logEnqueueReflectiveAction(action, [msg = ""]) {
    if (TRACE_MIRROR_ENQUEUING) {
      print("MIRROR_ENQUEUE (${isResolutionQueue ? "R" : "C"}): $action $msg");
    }
  }

  /// Enqeue the constructor [ctor] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void enqueueReflectiveConstructor(ConstructorElement ctor,
                                    bool enclosingWasIncluded) {
    if (shouldIncludeElementDueToMirrors(ctor,
        includedEnclosing: enclosingWasIncluded)) {
      logEnqueueReflectiveAction(ctor);
      ClassElement cls = ctor.declaration.enclosingClass;
      registerInstantiatedType(cls.rawType, compiler.mirrorDependencies,
          mirrorUsage: true);
      registerStaticUse(ctor.declaration);
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
        typedef.ensureResolved(compiler);
        compiler.world.allTypedefs.add(element);
      } else if (Elements.isStaticOrTopLevel(element)) {
        registerStaticUse(element.declaration);
      } else if (element.isInstanceMember) {
        // We need to enqueue all members matching this one in subclasses, as
        // well.
        // TODO(herhut): Use TypedSelector.subtype for enqueueing
        UniverseSelector selector = new UniverseSelector(
            new Selector.fromElement(element), null);
        registerSelectorUse(selector);
        if (element.isField) {
          UniverseSelector selector = new UniverseSelector(
              new Selector.setter(element.name, element.library), null);
          registerInvokedSetter(selector);
        }
      }
    }
  }

  /// Enqeue the member [element] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void enqueueReflectiveElementsInClass(ClassElement cls,
                                        Iterable<ClassElement> recents,
                                        bool enclosingWasIncluded) {
    if (cls.library.isInternalLibrary || cls.isInjected) return;
    bool includeClass = shouldIncludeElementDueToMirrors(cls,
        includedEnclosing: enclosingWasIncluded);
    if (includeClass) {
      logEnqueueReflectiveAction(cls, "register");
      ClassElement decl = cls.declaration;
      decl.ensureResolved(compiler);
      registerInstantiatedType(decl.rawType, compiler.mirrorDependencies,
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
        cls.ensureResolved(compiler);
        registerInstantiatedType(cls.rawType, compiler.mirrorDependencies,
            mirrorUsage: true);
      }
    }
  }

  /// Enqeue all local members of the library [lib] if they are required for
  /// reflection.
  void enqueueReflectiveElementsInLibrary(LibraryElement lib,
                                          Iterable<ClassElement> recents) {
    bool includeLibrary = shouldIncludeElementDueToMirrors(lib,
        includedEnclosing: false);
    lib.forEachLocalMember((Element member) {
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
      compiler.log('Enqueuing everything');
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
        enqueueReflectiveElementsInClass(cls, recents,
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
      Map<String, Set<Element>> map,
      String memberName,
      bool f(Element e)) {
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

  void handleUnseenSelector(UniverseSelector universeSelector) {
    Selector selector = universeSelector.selector;
    String methodName = selector.name;
    processInstanceMembers(methodName, (Element member) {
      if (universeSelector.appliesUnnamed(member, compiler.world)) {
        if (member.isFunction && selector.isGetter) {
          registerClosurizedMember(member, compiler.globalDependencies);
        }
        if (member.isField && member.enclosingClass.isNative) {
          if (selector.isGetter || selector.isCall) {
            nativeEnqueuer.registerFieldLoad(member);
            // We have to also handle storing to the field because we only get
            // one look at each member and there might be a store we have not
            // seen yet.
            // TODO(sra): Process fields for storing separately.
            nativeEnqueuer.registerFieldStore(member);
          } else {
            assert(selector.isSetter);
            nativeEnqueuer.registerFieldStore(member);
            // We have to also handle loading from the field because we only get
            // one look at each member and there might be a load we have not
            // seen yet.
            // TODO(sra): Process fields for storing separately.
            nativeEnqueuer.registerFieldLoad(member);
          }
        }
        addToWorkList(member);
        return true;
      }
      return false;
    });
    if (selector.isGetter) {
      processInstanceFunctions(methodName, (Element member) {
        if (universeSelector.appliesUnnamed(member, compiler.world)) {
          registerClosurizedMember(member, compiler.globalDependencies);
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
  void registerStaticUse(Element element) {
    if (element == null) return;
    assert(invariant(element, element.isDeclaration,
        message: "Element ${element} is not the declaration."));
    if (Elements.isStaticOrTopLevel(element) && element.isField) {
      universe.registerStaticFieldUse(element);
    }
    addToWorkList(element);
    compiler.backend.registerStaticUse(element, this);
  }

  void registerGetOfStaticFunction(FunctionElement element) {
    registerStaticUse(element);
    compiler.backend.registerGetOfStaticFunction(this);
    universe.staticFunctionsNeedingGetter.add(element);
  }

  void registerDynamicInvocation(UniverseSelector selector) {
    assert(selector != null);
    registerInvocation(selector);
  }

  void registerSelectorUse(UniverseSelector universeSelector) {
    if (universeSelector.selector.isGetter) {
      registerInvokedGetter(universeSelector);
    } else if (universeSelector.selector.isSetter) {
      registerInvokedSetter(universeSelector);
    } else {
      registerInvocation(universeSelector);
    }
  }

  void registerDynamicGetter(UniverseSelector selector) {
    registerInvokedGetter(selector);
  }

  void registerDynamicSetter(UniverseSelector selector) {
    registerInvokedSetter(selector);
  }

  void registerGetterForSuperMethod(Element element) {
    universe.methodsNeedingSuperGetter.add(element);
  }

  void registerFieldGetter(Element element) {
    universe.fieldGetters.add(element);
  }

  void registerFieldSetter(Element element) {
    universe.fieldSetters.add(element);
  }

  void registerIsCheck(DartType type) {
    type = universe.registerIsCheck(type, compiler);
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    assert(type.kind != TypeKind.TYPE_VARIABLE ||
           !type.element.enclosingElement.isTypedef);
  }

  void registerCallMethodWithFreeTypeVariables(
      Element element,
      Registry registry) {
    compiler.backend.registerCallMethodWithFreeTypeVariables(
        element, this, registry);
    universe.callMethodsWithFreeTypeVariables.add(element);
  }

  void registerClosurizedMember(TypedElement element, Registry registry) {
    assert(element.isInstanceMember);
    registerClosureIfFreeTypeVariables(element, registry);
    compiler.backend.registerBoundClosure(this);
    universe.closurizedMembers.add(element);
  }

  void registerClosureIfFreeTypeVariables(TypedElement element,
                                          Registry registry) {
    if (element.computeType(compiler).containsTypeVariables) {
      compiler.backend.registerClosureWithFreeTypeVariables(
          element, this, registry);
      universe.closuresWithFreeTypeVariables.add(element);
    }
  }

  void registerClosure(LocalFunctionElement element, Registry registry) {
    universe.allClosures.add(element);
    registerClosureIfFreeTypeVariables(element, registry);
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

  /// [onQueueEmpty] is called whenever the queue is drained. [recentClasses]
  /// contains the set of all classes seen for the first time since
  /// [onQueueEmpty] was called last. A return value of [true] indicates that
  /// the [recentClasses] have been processed and may be cleared. If [false] is
  /// returned, [onQueueEmpty] will be called once the queue is empty again (or
  /// still empty) and [recentClasses] will be a superset of the current value.
  bool onQueueEmpty(Iterable<ClassElement> recentClasses) {
    return compiler.backend.onQueueEmpty(this, recentClasses);
  }

  void logSummary(log(message)) {
    _logSpecificSummary(log);
    nativeEnqueuer.logSummary(log);
  }

  /// Log summary specific to the concrete enqueuer.
  void _logSpecificSummary(log(message));

  String toString() => 'Enqueuer($name)';

  void forgetElement(Element element) {
    universe.forgetElement(element, compiler);
    _processedClasses.remove(element);
  }
}

/// [Enqueuer] which is specific to resolution.
class ResolutionEnqueuer extends Enqueuer {
  /**
   * Map from declaration elements to the [TreeElements] object holding the
   * resolution mapping for the element implementation.
   *
   * Invariant: Key elements are declaration elements.
   */
  final Set<AstElement> resolvedElements;

  final Queue<ResolutionWorkItem> queue;

  /**
   * A deferred task queue for the resolution phase which is processed
   * when the resolution queue has been emptied.
   */
  final Queue<DeferredTask> deferredTaskQueue;

  ResolutionEnqueuer(Compiler compiler,
                     ItemCompilationContext itemCompilationContextCreator())
      : super('resolution enqueuer', compiler, itemCompilationContextCreator),
        resolvedElements = new Set<AstElement>(),
        queue = new Queue<ResolutionWorkItem>(),
        deferredTaskQueue = new Queue<DeferredTask>();

  bool get isResolutionQueue => true;

  bool isProcessed(Element member) => resolvedElements.contains(member);

  /// Returns `true` if [element] has been processed by the resolution enqueuer.
  bool hasBeenResolved(Element element) {
    return resolvedElements.contains(element.analyzableElement.declaration);
  }

  /// Registers [element] as resolved for the resolution enqueuer.
  void registerResolvedElement(AstElement element) {
    resolvedElements.add(element);
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
    return includedEnclosing || compiler.backend.requiredByMirrorSystem(element);
  }

  bool internalAddToWorkList(Element element) {
    if (element.isErroneous) return false;

    assert(invariant(element, element is AnalyzableElement,
        message: 'Element $element is not analyzable.'));
    if (hasBeenResolved(element)) return false;
    if (queueIsClosed) {
      throw new SpannableAssertionFailure(element,
          "Resolution work list is closed. Trying to add $element.");
    }

    compiler.world.registerUsedElement(element);

    ResolutionWorkItem workItem;
    if (compiler.serialization.isDeserialized(element)) {
      workItem = compiler.serialization.createResolutionWorkItem(
          element, itemCompilationContextCreator());
    } else {
      workItem = new ResolutionWorkItem(
          element, itemCompilationContextCreator());
    }
    queue.add(workItem);

    // Enable isolate support if we start using something from the isolate
    // library, or timers for the async library.  We exclude constant fields,
    // which are ending here because their initializing expression is compiled.
    LibraryElement library = element.library;
    if (!compiler.hasIsolateSupport &&
        (!element.isField || !element.isConst)) {
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

    if (element.isGetter && element.name == Compiler.RUNTIME_TYPE) {
      // Enable runtime type support if we discover a getter called runtimeType.
      // We have to enable runtime type before hitting the codegen, so
      // that constructors know whether they need to generate code for
      // runtime type.
      compiler.enabledRuntimeType = true;
      // TODO(ahe): Record precise dependency here.
      compiler.backend.registerRuntimeType(this, compiler.globalDependencies);
    } else if (element == compiler.functionApplyMethod) {
      compiler.enabledFunctionApply = true;
    }

    nativeEnqueuer.registerElement(element);
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
  void addDeferredAction(Element element, DeferredAction action) {
    if (queueIsClosed) {
      throw new SpannableAssertionFailure(element,
          "Resolution work list is closed. "
          "Trying to add deferred action for $element");
    }
    deferredTaskQueue.add(new DeferredTask(element, action));
  }

  bool onQueueEmpty(Iterable<ClassElement> recentClasses) {
    emptyDeferredTaskQueue();
    return super.onQueueEmpty(recentClasses);
  }

  void emptyDeferredTaskQueue() {
    while (!deferredTaskQueue.isEmpty) {
      DeferredTask task = deferredTaskQueue.removeFirst();
      compiler.withCurrentElement(task.element, task.action);
    }
  }

  void registerJsCall(Send node, ResolverVisitor resolver) {
    nativeEnqueuer.registerJsCall(node, resolver);
  }

  void registerJsEmbeddedGlobalCall(Send node, ResolverVisitor resolver) {
    nativeEnqueuer.registerJsEmbeddedGlobalCall(node, resolver);
  }

  void registerJsBuiltinCall(Send node, ResolverVisitor resolver) {
    nativeEnqueuer.registerJsBuiltinCall(node, resolver);
  }

  void _logSpecificSummary(log(message)) {
    log('Resolved ${resolvedElements.length} elements.');
  }

  void forgetElement(Element element) {
    super.forgetElement(element);
    resolvedElements.remove(element);
  }
}

/// [Enqueuer] which is specific to code generation.
class CodegenEnqueuer extends Enqueuer {
  final Queue<CodegenWorkItem> queue;
  final Map<Element, js.Expression> generatedCode =
      new Map<Element, js.Expression>();

  final Set<Element> newlyEnqueuedElements;

  final Set<UniverseSelector> newlySeenSelectors;

  bool enabledNoSuchMethod = false;

  CodegenEnqueuer(Compiler compiler,
                  ItemCompilationContext itemCompilationContextCreator())
      : queue = new Queue<CodegenWorkItem>(),
        newlyEnqueuedElements = compiler.cacheStrategy.newSet(),
        newlySeenSelectors = compiler.cacheStrategy.newSet(),
        super('codegen enqueuer', compiler, itemCompilationContextCreator);

  bool isProcessed(Element member) =>
      member.isAbstract || generatedCode.containsKey(member);

  /**
   * Decides whether an element should be included to satisfy requirements
   * of the mirror system.
   *
   * For code generation, we rely on the precomputed set of elements that takes
   * subtyping constraints into account.
   */
  bool shouldIncludeElementDueToMirrors(Element element,
                                        {bool includedEnclosing}) {
    return compiler.backend.isAccessibleByReflection(element);
  }

  bool internalAddToWorkList(Element element) {
    // Don't generate code for foreign elements.
    if (compiler.backend.isForeign(element)) return false;

    // Codegen inlines field initializers. It only needs to generate
    // code for checked setters.
    if (element.isField && element.isInstanceMember) {
      if (!compiler.enableTypeAssertions
          || element.enclosingElement.isClosure) {
        return false;
      }
    }

    if (compiler.hasIncrementalSupport && !isProcessed(element)) {
      newlyEnqueuedElements.add(element);
    }

    if (queueIsClosed) {
      throw new SpannableAssertionFailure(element,
          "Codegen work list is closed. Trying to add $element");
    }
    CodegenWorkItem workItem = new CodegenWorkItem(
        compiler, element, itemCompilationContextCreator());
    queue.add(workItem);
    return true;
  }

  void registerNoSuchMethod(Element element) {
    if (!enabledNoSuchMethod && compiler.backend.enabledNoSuchMethod) {
      compiler.backend.enableNoSuchMethod(this);
      enabledNoSuchMethod = true;
    }
  }

  void _logSpecificSummary(log(message)) {
    log('Compiled ${generatedCode.length} methods.');
  }

  void forgetElement(Element element) {
    super.forgetElement(element);
    generatedCode.remove(element);
    if (element is MemberElement) {
      for (Element closure in element.nestedClosures) {
        generatedCode.remove(closure);
        removeFromSet(instanceMembersByName, closure);
        removeFromSet(instanceFunctionsByName, closure);
      }
    }
  }

  void handleUnseenSelector(UniverseSelector selector) {
    if (compiler.hasIncrementalSupport) {
      newlySeenSelectors.add(selector);
    }
    super.handleUnseenSelector(selector);
  }
}

/// Parameterizes filtering of which work items are enqueued.
class QueueFilter {
  bool checkNoEnqueuedInvokedInstanceMethods(Enqueuer enqueuer) {
    enqueuer.task.measure(() {
      // Run through the classes and see if we need to compile methods.
      for (ClassElement classElement in
               enqueuer.universe.directlyInstantiatedClasses) {
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
