// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

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
}

abstract class Enqueuer {
  final String name;
  final Compiler compiler; // TODO(ahe): Remove this dependency.
  final Function itemCompilationContextCreator;
  final Map<String, Link<Element>> instanceMembersByName;
  final Set<ClassElement> seenClasses;
  final Universe universe;

  bool queueIsClosed = false;
  EnqueueTask task;
  native.NativeEnqueuer nativeEnqueuer;  // Set by EnqueueTask

  Enqueuer(this.name, this.compiler,
           ItemCompilationContext itemCompilationContextCreator())
    : this.itemCompilationContextCreator = itemCompilationContextCreator,
      instanceMembersByName = new Map<String, Link<Element>>(),
      universe = new Universe(),
      seenClasses = new Set<ClassElement>();

  /// Returns [:true:] if this enqueuer is the resolution enqueuer.
  bool get isResolutionQueue => false;

  /// Returns [:true:] if [member] has been processed by this enqueuer.
  bool isProcessed(Element member);

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void addToWorkList(Element element, [TreeElements elements]) {
    assert(invariant(element, element.isDeclaration));
    if (element.isForeign(compiler)) return;

    if (!addElementToWorkList(element, elements)) return;

    // Enable runtime type support if we discover a getter called runtimeType.
    // We have to enable runtime type before hitting the codegen, so
    // that constructors know whether they need to generate code for
    // runtime type.
    if (element.isGetter() && element.name == Compiler.RUNTIME_TYPE) {
      compiler.enabledRuntimeType = true;
      // TODO(ahe): Record precise dependency here.
      compiler.backend.registerRuntimeType(compiler.globalDependencies);
    } else if (element == compiler.functionApplyMethod) {
      compiler.enabledFunctionApply = true;
    } else if (element == compiler.invokeOnMethod) {
      compiler.enabledInvokeOn = true;
    }

    nativeEnqueuer.registerElement(element);
  }

  /**
   * Adds [element] to the work list if it has not already been processed.
   *
   * Returns [:true:] if the [element] should be processed.
   */
  // TODO(johnniwinther): Change to 'Returns true if the element was added to
  // the work list'?
  bool addElementToWorkList(Element element, [TreeElements elements]);

  void registerInstantiatedType(InterfaceType type, TreeElements elements) {
    ClassElement cls = type.element;
    elements.registerDependency(cls);
    cls.ensureResolved(compiler);
    universe.instantiatedTypes.add(type);
    if (universe.instantiatedClasses.contains(cls)) return;
    if (!cls.isAbstract(compiler)) {
      universe.instantiatedClasses.add(cls);
    }
    onRegisterInstantiatedClass(cls);
    // We only tell the backend once that [cls] was instantiated, so
    // any additional dependencies must be treated as global
    // dependencies.
    compiler.backend.registerInstantiatedClass(
        cls, this, compiler.globalDependencies);
  }

  void registerInstantiatedClass(ClassElement cls, TreeElements elements) {
    cls.ensureResolved(compiler);
    registerInstantiatedType(cls.rawType, elements);
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

  /**
   * Documentation wanted -- johnniwinther
   */
  void processInstantiatedClassMember(ClassElement cls, Element member) {
    assert(invariant(member, member.isDeclaration));
    if (isProcessed(member)) return;
    if (!member.isInstanceMember()) return;
    if (member.isField()) {
      // Fields are implicitly used by the constructor of the
      // instantiated class they are part of.
      compiler.world.registerUsedElement(member);
      // Native fields need to go into instanceMembersByName as they
      // are virtual instantiation points and escape points. Test the
      // enclosing class, since the metadata has not been parsed yet.
      if (!member.enclosingElement.isNative()) return;
    }

    String memberName = member.name.slowToString();

    if (member.kind == ElementKind.FUNCTION) {
      if (member.name == Compiler.NO_SUCH_METHOD) {
        enableNoSuchMethod(member);
      }
      if (universe.hasInvocation(member, compiler)) {
        return addToWorkList(member);
      }
      // If there is a property access with the same name as a method we
      // need to emit the method.
      if (universe.hasInvokedGetter(member, compiler)) {
        // We will emit a closure, so make sure the closure class is
        // generated.
        compiler.closureClass.ensureResolved(compiler);
        registerInstantiatedClass(compiler.closureClass,
                                  // Precise dependency is not important here.
                                  compiler.globalDependencies);
        return addToWorkList(member);
      }
    } else if (member.kind == ElementKind.GETTER) {
      if (universe.hasInvokedGetter(member, compiler)) {
        return addToWorkList(member);
      }
      // We don't know what selectors the returned closure accepts. If
      // the set contains any selector we have to assume that it matches.
      if (universe.hasInvocation(member, compiler)) {
        return addToWorkList(member);
      }
    } else if (member.kind == ElementKind.SETTER) {
      if (universe.hasInvokedSetter(member, compiler)) {
        return addToWorkList(member);
      }
    } else if (member.kind == ElementKind.FIELD &&
               member.enclosingElement.isNative()) {
      nativeEnqueuer.handleFieldAnnotations(member);
      if (universe.hasInvokedGetter(member, compiler) ||
          universe.hasInvocation(member, compiler)) {
        nativeEnqueuer.registerFieldLoad(member);
        // In handleUnseenSelector we can't tell if the field is loaded or
        // stored.  We need the basic algorithm to be Church-Rosser, since the
        // resolution 'reduction' order is different to the codegen order. So
        // register that the field is also stored.  In other words: if we don't
        // register the store here during resolution, the store could be
        // registered during codegen on the handleUnseenSelector path, and cause
        // the set of codegen elements to include unresolved elements.
        nativeEnqueuer.registerFieldStore(member);
        return;
      }
      if (universe.hasInvokedSetter(member, compiler)) {
        nativeEnqueuer.registerFieldStore(member);
        // See comment after registerFieldLoad above.
        nativeEnqueuer.registerFieldLoad(member);
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

  void onRegisterInstantiatedClass(ClassElement cls) {
    task.measure(() {
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
      }
      processClass(cls);
      for (Link<DartType> supertypes = cls.allSupertypes;
           !supertypes.isEmpty; supertypes = supertypes.tail) {
        processClass(supertypes.head.element);
      }
    });
  }

  void registerNewSelector(SourceString name,
                           Selector selector,
                           Map<SourceString, Set<Selector>> selectorsMap) {
    if (name != selector.name) {
      String message = "$name != ${selector.name} (${selector.kind})";
      compiler.internalError("Wrong selector name: $message.");
    }
    Set<Selector> selectors =
        selectorsMap.putIfAbsent(name, () => new Set<Selector>());
    if (!selectors.contains(selector)) {
      selectors.add(selector);
      handleUnseenSelector(name, selector);
    }
  }

  void registerInvocation(SourceString methodName, Selector selector) {
    task.measure(() {
      registerNewSelector(methodName, selector, universe.invokedNames);
    });
  }

  void registerInvokedGetter(SourceString getterName, Selector selector) {
    task.measure(() {
      registerNewSelector(getterName, selector, universe.invokedGetters);
    });
  }

  void registerInvokedSetter(SourceString setterName, Selector selector) {
    task.measure(() {
      registerNewSelector(setterName, selector, universe.invokedSetters);
    });
  }

  processInstanceMembers(SourceString n, bool f(Element e)) {
    String memberName = n.slowToString();
    Link<Element> members = instanceMembersByName[memberName];
    if (members != null) {
      LinkBuilder<Element> remaining = new LinkBuilder<Element>();
      for (; !members.isEmpty; members = members.tail) {
        if (!f(members.head)) remaining.addLast(members.head);
      }
      instanceMembersByName[memberName] = remaining.toLink();
    }
  }

  void handleUnseenSelector(SourceString methodName, Selector selector) {
    processInstanceMembers(methodName, (Element member) {
      if (selector.appliesUnnamed(member, compiler)) {
        if (member.isField() && member.enclosingElement.isNative()) {
          if (selector.isGetter() || selector.isCall()) {
            nativeEnqueuer.registerFieldLoad(member);
            // We have to also handle storing to the field because we only get
            // one look at each member and there might be a store we have not
            // seen yet.
            // TODO(sra): Process fields for storing separately.
            nativeEnqueuer.registerFieldStore(member);
          } else {
            nativeEnqueuer.registerFieldStore(member);
            // We have to also handle loading from the field because we only get
            // one look at each member and there might be a load we have not
            // seen yet.
            // TODO(sra): Process fields for storing separately.
            nativeEnqueuer.registerFieldLoad(member);
          }
        } else {
          addToWorkList(member);
        }
        return true;
      }
      return false;
    });
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
  }

  void registerGetOfStaticFunction(FunctionElement element) {
    registerStaticUse(element);
    universe.staticFunctionsNeedingGetter.add(element);
  }

  void registerDynamicInvocation(SourceString methodName, Selector selector) {
    assert(selector != null);
    registerInvocation(methodName, selector);
  }

  void registerDynamicInvocationOf(Element element, Selector selector) {
    assert(selector.isCall()
           || selector.isOperator()
           || selector.isIndex()
           || selector.isIndexSet());
    if (element.isFunction() || element.isGetter()) {
      addToWorkList(element);
    } else if (element.isAbstractField()) {
      AbstractFieldElement field = element;
      // Since the invocation is a dynamic call on a getter, we only
      // need to schedule the getter on the work list.
      addToWorkList(field.getter);
    } else {
      assert(element.isField());
    }
    // We also need to add the selector to the invoked names map,
    // because the emitter uses that map to generate parameter stubs.
    Set<Selector> selectors = universe.invokedNames.putIfAbsent(
        element.name, () => new Set<Selector>());
    selectors.add(selector);
  }

  void registerSelectorUse(Selector selector) {
    if (selector.isGetter()) {
      registerInvokedGetter(selector.name, selector);
    } else if (selector.isSetter()) {
      registerInvokedSetter(selector.name, selector);
    } else {
      registerInvocation(selector.name, selector);
    }
  }

  void registerDynamicGetter(SourceString methodName, Selector selector) {
    registerInvokedGetter(methodName, selector);
  }

  void registerDynamicSetter(SourceString methodName, Selector selector) {
    registerInvokedSetter(methodName, selector);
  }

  void registerFieldGetter(Element element) {
    universe.fieldGetters.add(element);
  }

  void registerFieldSetter(Element element) {
    universe.fieldSetters.add(element);
  }

  void registerIsCheck(DartType type, TreeElements elements) {
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    assert(type.kind != TypeKind.TYPE_VARIABLE ||
           !type.element.enclosingElement.isTypedef());
    universe.isChecks.add(type);
    compiler.backend.registerIsCheck(type, this, elements);
  }

  /**
   * If a factory constructor is used with type arguments, we lose track
   * which arguments could be used to create instances of classes that use their
   * type variables as expressions, so we have to remember if we saw such a use.
   */
  void registerFactoryWithTypeArguments(TreeElements elements) {
    universe.usingFactoryWithTypeArguments = true;
  }

  void registerAsCheck(DartType type, TreeElements elements) {
    registerIsCheck(type, elements);
    compiler.backend.registerAsCheck(type, elements);
  }

  void forEach(f(WorkItem work));

  void forEachPostProcessTask(f(PostProcessTask work)) {}

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
  final Map<Element, TreeElements> resolvedElements;

  final Queue<ResolutionWorkItem> queue;

  /**
   * A post-processing queue for the resolution phase which is processed
   * immediately after the resolution queue has been closed.
   */
  final Queue<PostProcessTask> postQueue;

  ResolutionEnqueuer(Compiler compiler,
                     ItemCompilationContext itemCompilationContextCreator())
      : super('resolution enqueuer', compiler, itemCompilationContextCreator),
        resolvedElements = new Map<Element, TreeElements>(),
        queue = new Queue<ResolutionWorkItem>(),
        postQueue = new Queue<PostProcessTask>();

  bool get isResolutionQueue => true;

  bool isProcessed(Element member) => resolvedElements.containsKey(member);

  TreeElements getCachedElements(Element element) {
    // TODO(ngeoffray): Get rid of this check.
    if (element.enclosingElement.isClosure()) {
      closureMapping.ClosureClassElement cls = element.enclosingElement;
      element = cls.methodElement;
    }
    Element owner = element.getOutermostEnclosingMemberOrTopLevel();
    if (owner == null) {
      owner = element;
    }
    return resolvedElements[owner.declaration];
  }

  /**
   * Sets the resolved elements of [element] to [elements], or if [elements] is
   * [:null:], to the elements found through [getCachedElements].
   *
   * Returns the resolved elements.
   */
  TreeElements ensureCachedElements(Element element, TreeElements elements) {
    if (elements == null) {
      elements = getCachedElements(element);
    }
    resolvedElements[element] = elements;
    return elements;
  }

  bool addElementToWorkList(Element element, [TreeElements elements]) {
    if (queueIsClosed) {
      if (getCachedElements(element) != null) return false;
      throw new SpannableAssertionFailure(element,
                                          "Resolution work list is closed.");
    }
    if (elements == null) {
      elements = getCachedElements(element);
    }
    compiler.world.registerUsedElement(element);

    if (elements == null) {
      queue.add(
          new ResolutionWorkItem(element, itemCompilationContextCreator()));
    }

    // Enable isolate support if we start using something from the
    // isolate library, or timers for the async library.
    LibraryElement library = element.getLibrary();
    if (!compiler.hasIsolateSupport()) {
      String uri = library.canonicalUri.toString();
      if (uri == 'dart:isolate') {
        enableIsolateSupport(library);
      } else if (uri == 'dart:async') {
        ClassElement cls = element.getEnclosingClass();
        if (cls != null && cls.name == const SourceString('Timer')) {
          // The [:Timer:] class uses the event queue of the isolate
          // library, so we make sure that event queue is generated.
          enableIsolateSupport(library);
        }
      }
    }

    return true;
  }

  void enableIsolateSupport(LibraryElement element) {
    compiler.isolateLibrary = element.patch;
    var startRootIsolate =
        compiler.isolateHelperLibrary.find(Compiler.START_ROOT_ISOLATE);
    addToWorkList(startRootIsolate);
    compiler.globalDependencies.registerDependency(startRootIsolate);
    addToWorkList(compiler.isolateHelperLibrary.find(
        const SourceString('_currentIsolate')));
    addToWorkList(compiler.isolateHelperLibrary.find(
        const SourceString('_callInIsolate')));
  }

  void enableNoSuchMethod(Element element) {
    if (compiler.enabledNoSuchMethod) return;
    if (compiler.backend.isDefaultNoSuchMethodImplementation(element)) return;

    Selector selector = new Selector.noSuchMethod();
    compiler.enabledNoSuchMethod = true;
    registerInvocation(Compiler.NO_SUCH_METHOD, selector);

    compiler.createInvocationMirrorElement =
        compiler.findHelper(Compiler.CREATE_INVOCATION_MIRROR);
    addToWorkList(compiler.createInvocationMirrorElement);
  }

  void forEach(f(WorkItem work)) {
    while (!queue.isEmpty) {
      // TODO(johnniwinther): Find an optimal process order for resolution.
      f(queue.removeLast());
    }
  }

  /**
   * Adds an action to the post-processing queue.
   *
   * The action is performed as part of the post-processing immediately after
   * the resolution queue has been closed. As a consequence, [action] must not
   * add elements to the resolution queue.
   */
  void addPostProcessAction(Element element, PostProcessAction action) {
    if (queueIsClosed) {
      throw new SpannableAssertionFailure(element,
                                          "Resolution work list is closed.");
    }
    postQueue.add(new PostProcessTask(element, action));
  }

  void forEachPostProcessTask(f(PostProcessTask work)) {
    while (!postQueue.isEmpty) {
      f(postQueue.removeFirst());
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

  CodegenEnqueuer(Compiler compiler,
                  ItemCompilationContext itemCompilationContextCreator())
      : super('codegen enqueuer', compiler, itemCompilationContextCreator),
        queue = new Queue<CodegenWorkItem>();

  bool isProcessed(Element member) =>
      member.isAbstract(compiler) || generatedCode.containsKey(member);

  bool addElementToWorkList(Element element, [TreeElements elements]) {
    if (queueIsClosed) {
      throw new SpannableAssertionFailure(element,
                                          "Codegen work list is closed.");
    }
    elements =
        compiler.enqueuer.resolution.ensureCachedElements(element, elements);

    CodegenWorkItem workItem = new CodegenWorkItem(
        element, elements, itemCompilationContextCreator());
    queue.add(workItem);

    return true;
  }

  void forEach(f(WorkItem work)) {
    while(!queue.isEmpty) {
      // TODO(johnniwinther): Find an optimal process order for codegen.
      f(queue.removeLast());
    }
  }

  void _logSpecificSummary(log(message)) {
    log('Compiled ${generatedCode.length} methods.');
  }
}
