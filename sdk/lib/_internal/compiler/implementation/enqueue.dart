// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

typedef ItemCompilationContext ItemCompilationContextCreator();

class EnqueueTask extends CompilerTask {
  final ResolutionEnqueuer resolution;
  final CodegenEnqueuer codegen;

  /// A reverse map from name to *all* elements with that name, not
  /// just instance members of instantiated classes.
  final Map<String, Link<Element>> allElementsByName
      = new Map<String, Link<Element>>();

  void ensureAllElementsByName() {
    if (!allElementsByName.isEmpty) return;

    void addMemberByName(Element element) {
      element = element.declaration;
      String name = element.name;
      ScopeContainerElement container = null;
      if (element.isLibrary) {
        LibraryElement library = element;
        container = library;
        // TODO(ahe): Is this right?  Is this necessary?
        name = library.getLibraryOrScriptName();
      } else if (element.isClass) {
        ClassElement cls = element;
        cls.ensureResolved(compiler);
        container = cls;
        for (var link = cls.computeTypeParameters(compiler);
             !link.isEmpty;
             link = link.tail) {
          addMemberByName(link.head.element);
        }
      }
      allElementsByName[name] = allElementsByName.putIfAbsent(
          name, () => const Link<Element>()).prepend(element);
      if (container != null) {
        container.forEachLocalMember(addMemberByName);
      }
    }

    compiler.libraries.values.forEach(addMemberByName);
  }

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
}

abstract class Enqueuer {
  final String name;
  final Compiler compiler; // TODO(ahe): Remove this dependency.
  final ItemCompilationContextCreator itemCompilationContextCreator;
  final Map<String, Link<Element>> instanceMembersByName
      = new Map<String, Link<Element>>();
  final Map<String, Link<Element>> instanceFunctionsByName
      = new Map<String, Link<Element>>();
  final Set<ClassElement> seenClasses = new Set<ClassElement>();
  final Universe universe = new Universe();

  bool queueIsClosed = false;
  EnqueueTask task;
  native.NativeEnqueuer nativeEnqueuer;  // Set by EnqueueTask

  bool hasEnqueuedEverything = false;
  bool hasEnqueuedReflectiveStaticFields = false;

  Enqueuer(this.name, this.compiler, this.itemCompilationContextCreator);

  Queue<WorkItem> get queue;
  bool get queueIsEmpty => queue.isEmpty;

  /// Returns [:true:] if this enqueuer is the resolution enqueuer.
  bool get isResolutionQueue => false;

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
   */
  void internalAddToWorkList(Element element);

  void registerInstantiatedType(InterfaceType type, Registry registry) {
    task.measure(() {
      ClassElement cls = type.element;
      registry.registerDependency(cls);
      cls.ensureResolved(compiler);
      universe.instantiatedTypes.add(type);
      if (!cls.isAbstract
          // We can't use the closed-world assumption with native abstract
          // classes; a native abstract class may have non-abstract subclasses
          // not declared to the program.  Instances of these classes are
          // indistinguishable from the abstract class.
          || cls.isNative) {
        universe.instantiatedClasses.add(cls);
      }
      onRegisterInstantiatedClass(cls);
    });
  }

  void registerInstantiatedClass(ClassElement cls, Registry registry) {
    cls.ensureResolved(compiler);
    registerInstantiatedType(cls.rawType, registry);
  }

  bool checkNoEnqueuedInvokedInstanceMethods() {
    task.measure(() {
      // Run through the classes and see if we need to compile methods.
      for (ClassElement classElement in universe.instantiatedClasses) {
        for (ClassElement currentClass = classElement;
             currentClass != null;
             currentClass = currentClass.superclass) {
          processInstantiatedClass(currentClass);
        }
      }
    });
    return true;
  }

  void processInstantiatedClass(ClassElement cls) {
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
        if (universe.hasInvokedGetter(member, compiler) ||
            universe.hasInvocation(member, compiler)) {
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
        if (universe.hasInvokedSetter(member, compiler)) {
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
      if (member.name == Compiler.NO_SUCH_METHOD) {
        enableNoSuchMethod(member);
      }
      if (member.name == Compiler.CALL_OPERATOR_NAME &&
          !cls.typeVariables.isEmpty) {
        registerGenericCallMethod(member, compiler.globalDependencies);
      }
      // If there is a property access with the same name as a method we
      // need to emit the method.
      if (universe.hasInvokedGetter(member, compiler)) {
        registerClosurizedMember(member, compiler.globalDependencies);
        addToWorkList(member);
        return;
      }
      // Store the member in [instanceFunctionsByName] to catch
      // getters on the function.
      Link<Element> members = instanceFunctionsByName.putIfAbsent(
          memberName, () => const Link<Element>());
      instanceFunctionsByName[memberName] = members.prepend(member);
      if (universe.hasInvocation(member, compiler)) {
        addToWorkList(member);
        return;
      }
    } else if (member.kind == ElementKind.GETTER) {
      if (universe.hasInvokedGetter(member, compiler)) {
        addToWorkList(member);
        return;
      }
      // We don't know what selectors the returned closure accepts. If
      // the set contains any selector we have to assume that it matches.
      if (universe.hasInvocation(member, compiler)) {
        addToWorkList(member);
        return;
      }
    } else if (member.kind == ElementKind.SETTER) {
      if (universe.hasInvokedSetter(member, compiler)) {
        addToWorkList(member);
        return;
      }
    }

    // The element is not yet used. Add it to the list of instance
    // members to still be processed.
    Link<Element> members = instanceMembersByName.putIfAbsent(
        memberName, () => const Link<Element>());
    instanceMembersByName[memberName] = members.prepend(member);
  }

  void enableNoSuchMethod(Element element) {}
  void enableIsolateSupport() {}

  void onRegisterInstantiatedClass(ClassElement cls) {
    task.measure(() {
      if (seenClasses.contains(cls)) return;
      // The class must be resolved to compute the set of all
      // supertypes.
      cls.ensureResolved(compiler);

      void processClass(ClassElement cls) {
        if (seenClasses.contains(cls)) return;

        seenClasses.add(cls);
        cls.ensureResolved(compiler);
        cls.implementation.forEachMember(processInstantiatedClassMember);
        if (isResolutionQueue) {
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

  void registerNewSelector(Selector selector,
                           Map<String, Set<Selector>> selectorsMap) {
    String name = selector.name;
    Set<Selector> selectors =
        selectorsMap.putIfAbsent(name, () => new Setlet<Selector>());
    if (!selectors.contains(selector)) {
      selectors.add(selector);
      handleUnseenSelector(name, selector);
    }
  }

  void registerInvocation(Selector selector) {
    task.measure(() {
      registerNewSelector(selector, universe.invokedNames);
    });
  }

  void registerInvokedGetter(Selector selector) {
    task.measure(() {
      registerNewSelector(selector, universe.invokedGetters);
    });
  }

  void registerInvokedSetter(Selector selector) {
    task.measure(() {
      registerNewSelector(selector, universe.invokedSetters);
    });
  }

  void pretendElementWasUsed(Element element, Registry registry) {
    if (!compiler.backend.isNeededForReflection(element)) return;
    if (Elements.isUnresolved(element)) {
      // Ignore.
    } else if (element.isSynthesized
               && element.library.isPlatformLibrary) {
      // TODO(ahe): Work-around for http://dartbug.com/11205.
    } else if (element.isConstructor) {
      ClassElement cls = element.declaration.enclosingClass;
      registerInstantiatedType(cls.rawType, registry);
      registerStaticUse(element.declaration);
    } else if (element.isClass) {
      ClassElement cls = element.declaration;
      registerInstantiatedClass(cls, registry);
      // Make sure that even abstract classes are considered instantiated.
      universe.instantiatedClasses.add(cls);
    } else if (element.impliesType) {
      // Don't enqueue typedefs, and type variables.
    } else if (Elements.isStaticOrTopLevel(element)) {
      registerStaticUse(element.declaration);
    } else if (element.isInstanceMember) {
      Selector selector = new Selector.fromElement(element, compiler);
      registerSelectorUse(selector);
      if (element.isField) {
        Selector selector =
            new Selector.setter(element.name, element.library);
        registerInvokedSetter(selector);
      }
    }
  }

  void enqueueEverything() {
    if (hasEnqueuedEverything) return;
    compiler.log('Enqueuing everything');
    task.ensureAllElementsByName();
    for (Link link in task.allElementsByName.values) {
      for (Element element in link) {
        pretendElementWasUsed(element, compiler.mirrorDependencies);
      }
    }
    hasEnqueuedEverything = true;
    hasEnqueuedReflectiveStaticFields = true;
  }

  /// Enqueue the static fields that have been marked as used by reflective
  /// usage through `MirrorsUsed`.
  void enqueueReflectiveStaticFields(Iterable<Element> elements) {
    if (hasEnqueuedReflectiveStaticFields) return;
    hasEnqueuedReflectiveStaticFields = true;
    for (Element element in elements) {
      pretendElementWasUsed(element, compiler.mirrorDependencies);
    }
  }

  processLink(Map<String, Link<Element>> map,
              String memberName,
              bool f(Element e)) {
    Link<Element> members = map[memberName];
    if (members != null) {
      // [f] might add elements to [: map[memberName] :] during the loop below
      // so we create a new list for [: map[memberName] :] and prepend the
      // [remaining] members after the loop.
      map[memberName] = const Link<Element>();
      LinkBuilder<Element> remaining = new LinkBuilder<Element>();
      for (; !members.isEmpty; members = members.tail) {
        if (!f(members.head)) remaining.addLast(members.head);
      }
      map[memberName] = remaining.toLink(map[memberName]);
    }
  }

  processInstanceMembers(String n, bool f(Element e)) {
    processLink(instanceMembersByName, n, f);
  }

  processInstanceFunctions(String n, bool f(Element e)) {
    processLink(instanceFunctionsByName, n, f);
  }

  void handleUnseenSelector(String methodName, Selector selector) {
    processInstanceMembers(methodName, (Element member) {
      if (selector.appliesUnnamed(member, compiler)) {
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
        if (selector.appliesUnnamed(member, compiler)) {
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
    assert(invariant(element, element.isDeclaration));
    addToWorkList(element);
    compiler.backend.registerStaticUse(element, this);
  }

  void registerGetOfStaticFunction(FunctionElement element) {
    registerStaticUse(element);
    compiler.backend.registerGetOfStaticFunction(this);
    universe.staticFunctionsNeedingGetter.add(element);
  }

  void registerDynamicInvocation(Selector selector) {
    assert(selector != null);
    registerInvocation(selector);
  }

  void registerSelectorUse(Selector selector) {
    if (selector.isGetter) {
      registerInvokedGetter(selector);
    } else if (selector.isSetter) {
      registerInvokedSetter(selector);
    } else {
      registerInvocation(selector);
    }
  }

  void registerDynamicGetter(Selector selector) {
    registerInvokedGetter(selector);
  }

  void registerDynamicSetter(Selector selector) {
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

  void registerIsCheck(DartType type, Registry registry) {
    type = universe.registerIsCheck(type, compiler);
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    assert(type.kind != TypeKind.TYPE_VARIABLE ||
           !type.element.enclosingElement.isTypedef);
  }

  /**
   * If a factory constructor is used with type arguments, we lose track
   * which arguments could be used to create instances of classes that use their
   * type variables as expressions, so we have to remember if we saw such a use.
   */
  void registerFactoryWithTypeArguments(Registry registry) {
    universe.usingFactoryWithTypeArguments = true;
  }

  void registerGenericCallMethod(Element element, Registry registry) {
    compiler.backend.registerGenericCallMethod(element, this, registry);
    universe.genericCallMethods.add(element);
  }

  void registerClosurizedMember(Element element, Registry registry) {
    assert(element.isInstanceMember);
    registerIfGeneric(element, registry);
    compiler.backend.registerBoundClosure(this);
    universe.closurizedMembers.add(element);
  }

  void registerIfGeneric(Element element, Registry registry) {
    if (element.computeType(compiler).containsTypeVariables) {
      compiler.backend.registerGenericClosure(element, this, registry);
      universe.genericClosures.add(element);
    }
  }

  void registerClosure(Element element, Registry registry) {
    registerIfGeneric(element, registry);
  }

  void forEach(f(WorkItem work)) {
    do {
      while (!queue.isEmpty) {
        // TODO(johnniwinther): Find an optimal process order.
        f(queue.removeLast());
      }
      onQueueEmpty();
    } while (!queue.isEmpty);
  }

  void onQueueEmpty() {
    compiler.backend.onQueueEmpty(this);
  }

  void logSummary(log(message)) {
    _logSpecificSummary(log);
    nativeEnqueuer.logSummary(log);
  }

  /// Log summary specific to the concrete enqueuer.
  void _logSpecificSummary(log(message));

  String toString() => 'Enqueuer($name)';
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

  /// Returns [:true:] if [element] has actually been used.
  bool isLive(Element element) {
    if (seenClasses.contains(element)) return true;
    if (hasBeenResolved(element)) return true;
    return false;
  }

  void internalAddToWorkList(Element element) {
    assert(invariant(element, element is AnalyzableElement,
        message: 'Element $element is not analyzable.'));
    if (hasBeenResolved(element)) return;
    if (queueIsClosed) {
      throw new SpannableAssertionFailure(element,
          "Resolution work list is closed. Trying to add $element.");
    }

    compiler.world.registerUsedElement(element);

    queue.add(new ResolutionWorkItem(element, itemCompilationContextCreator()));

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
  }

  void enableIsolateSupport() {
    compiler.hasIsolateSupport = true;
    compiler.backend.enableIsolateSupport(this);
  }

  void enableNoSuchMethod(Element element) {
    if (compiler.enabledNoSuchMethod) return;
    if (compiler.backend.isDefaultNoSuchMethodImplementation(element)) return;

    Selector selector = compiler.noSuchMethodSelector;
    compiler.enabledNoSuchMethod = true;
    compiler.backend.enableNoSuchMethod(this);
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

  void onQueueEmpty() {
    emptyDeferredTaskQueue();
    super.onQueueEmpty();
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

  void _logSpecificSummary(log(message)) {
    log('Resolved ${resolvedElements.length} elements.');
  }
}

/// [Enqueuer] which is specific to code generation.
class CodegenEnqueuer extends Enqueuer {
  final Queue<CodegenWorkItem> queue;
  final Map<Element, js.Expression> generatedCode =
      new Map<Element, js.Expression>();

  final Set<Element> newlyEnqueuedElements;

  CodegenEnqueuer(Compiler compiler,
                  ItemCompilationContext itemCompilationContextCreator())
      : queue = new Queue<CodegenWorkItem>(),
        newlyEnqueuedElements = compiler.cacheStrategy.newSet(),
        super('codegen enqueuer', compiler, itemCompilationContextCreator);

  bool isProcessed(Element member) =>
      member.isAbstract || generatedCode.containsKey(member);

  void internalAddToWorkList(Element element) {
    if (compiler.hasIncrementalSupport) {
      newlyEnqueuedElements.add(element);
    }
    // Don't generate code for foreign elements.
    if (element.isForeign(compiler)) return;

    // Codegen inlines field initializers. It only needs to generate
    // code for checked setters.
    if (element.isField && element.isInstanceMember) {
      if (!compiler.enableTypeAssertions
          || element.enclosingElement.isClosure) {
        return;
      }
    }

    if (queueIsClosed) {
      throw new SpannableAssertionFailure(element,
          "Codegen work list is closed. Trying to add $element");
    }
    CodegenWorkItem workItem = new CodegenWorkItem(
        element, itemCompilationContextCreator());
    queue.add(workItem);
  }

  void _logSpecificSummary(log(message)) {
    log('Compiled ${generatedCode.length} methods.');
  }
}
