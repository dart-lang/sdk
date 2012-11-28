// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

class EnqueueTask extends CompilerTask {
  final Enqueuer codegen;
  final Enqueuer resolution;

  String get name => 'Enqueue';

  EnqueueTask(Compiler compiler)
    : codegen = new Enqueuer('codegen enqueuer', compiler,
                             compiler.backend.createItemCompilationContext),
      resolution = new Enqueuer('resolution enqueuer', compiler,
                                compiler.backend.createItemCompilationContext),
      super(compiler) {
    codegen.task = this;
    resolution.task = this;

    codegen.nativeEnqueuer = compiler.backend.nativeCodegenEnqueuer(codegen);
    resolution.nativeEnqueuer =
        compiler.backend.nativeResolutionEnqueuer(resolution);
  }
}

class Enqueuer {
  final String name;
  final Compiler compiler; // TODO(ahe): Remove this dependency.
  final Function itemCompilationContextCreator;
  final Map<String, Link<Element>> instanceMembersByName;
  final Set<ClassElement> seenClasses;
  final Universe universe;
  final Queue<WorkItem> queue;

  /**
   * Map from declaration elements to the [TreeElements] object holding the
   * resolution mapping for the element implementation.
   *
   * Invariant: Key elements are declaration elements.
   */
  final Map<Element, TreeElements> resolvedElements;

  bool queueIsClosed = false;
  EnqueueTask task;
  native.NativeEnqueuer nativeEnqueuer;  // Set by EnqueueTask

  Enqueuer(this.name, this.compiler,
           ItemCompilationContext itemCompilationContextCreator())
    : this.itemCompilationContextCreator = itemCompilationContextCreator,
      instanceMembersByName = new Map<String, Link<Element>>(),
      seenClasses = new Set<ClassElement>(),
      universe = new Universe(),
      queue = new Queue<WorkItem>(),
      resolvedElements = new Map<Element, TreeElements>();

  bool get isResolutionQueue => identical(compiler.enqueuer.resolution, this);

  TreeElements getCachedElements(Element element) {
    // TODO(ngeoffray): Get rid of this check.
    if (element.enclosingElement.isClosure()) {
      closureMapping.ClosureClassElement cls = element.enclosingElement;
      element = cls.methodElement;
    }
    Element owner = element.getOutermostEnclosingMemberOrTopLevel();
    return compiler.enqueuer.resolution.resolvedElements[owner.declaration];
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  String lookupCode(Element element) {
    assert(invariant(element, element.isDeclaration));
    return universe.generatedCode[element].toString();
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void addToWorkList(Element element, [TreeElements elements]) {
    assert(invariant(element, element.isDeclaration));
    if (element.isForeign()) return;
    if (queueIsClosed) {
      if (isResolutionQueue && getCachedElements(element) != null) return;
      compiler.internalErrorOnElement(element, "Work list is closed.");
    }
    if (elements == null) {
      elements = getCachedElements(element);
    }
    if (isResolutionQueue) {
      compiler.world.registerUsedElement(element);
    }

    queue.add(new WorkItem(element, elements, itemCompilationContextCreator()));

    // Enable runtime type support if we discover a getter called runtimeType.
    // We have to enable runtime type before hitting the codegen, so
    // that constructors know whether they need to generate code for
    // runtime type.
    if (element.isGetter() && element.name == Compiler.RUNTIME_TYPE) {
      compiler.enabledRuntimeType = true;
    } else if (element == compiler.functionApplyMethod) {
      compiler.enabledFunctionApply = true;
    } else if (element == compiler.invokeOnMethod) {
      compiler.enabledInvokeOn = true;
    }

    // Enable isolate support if we start using something from the
    // isolate library.
    LibraryElement library = element.getLibrary();
    if (!compiler.hasIsolateSupport()
        && library.uri.toString() == 'dart:isolate') {
      compiler.enableIsolateSupport(library);
    }

    nativeEnqueuer.registerElement(element);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void eagerRecompile(Element element) {
    assert(invariant(element, element.isDeclaration));
    universe.generatedCode.remove(element);
    universe.generatedBailoutCode.remove(element);
    addToWorkList(element);
  }

  void registerInstantiatedClass(ClassElement cls) {
    if (universe.instantiatedClasses.contains(cls)) return;
    if (!cls.isAbstract(compiler)) {
      universe.instantiatedClasses.add(cls);
      onRegisterInstantiatedClass(cls);
    }
    compiler.backend.registerInstantiatedClass(cls, this);
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
    if (universe.generatedCode.containsKey(member)) return;
    if (resolvedElements[member] != null) return;
    if (!member.isInstanceMember()) return;
    if (member.isField()) {
      // Native fields need to go into instanceMembersByName as they are virtual
      // instantiation points and escape points.
      if (!member.enclosingElement.isNative()) return;
    }

    String memberName = member.name.slowToString();
    Link<Element> members = instanceMembersByName.putIfAbsent(
        memberName, () => const Link<Element>());
    instanceMembersByName[memberName] = members.prepend(member);

    if (member.kind == ElementKind.FUNCTION) {
      if (member.name == Compiler.NO_SUCH_METHOD) {
        compiler.enableNoSuchMethod(member);
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
        registerInstantiatedClass(compiler.closureClass);
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
      if (universe.hasInvokedGetter(member, compiler) ||
          universe.hasInvocation(member, compiler)) {
        nativeEnqueuer.registerFieldLoad(member);
      }
      if (universe.hasInvokedSetter(member, compiler)) {
        nativeEnqueuer.registerFieldStore(member);
      }
    }
  }

  void onRegisterInstantiatedClass(ClassElement cls) {
    task.measure(() {
      // The class must be resolved to compute the set of all
      // supertypes.
      cls.ensureResolved(compiler);

      for (Link<DartType> supertypes = cls.allSupertypesAndSelf;
           !supertypes.isEmpty; supertypes = supertypes.tail) {
        cls = supertypes.head.element;
        if (seenClasses.contains(cls)) continue;
        seenClasses.add(cls);
        cls.ensureResolved(compiler);
        cls.implementation.forEachMember(processInstantiatedClassMember);
        if (isResolutionQueue) {
          compiler.resolver.checkMembers(cls);
        }

        if (compiler.enableTypeAssertions) {
          // We need to register is checks and helpers for checking
          // assignments to fields.
          // TODO(ngeoffray): This should really move to the backend.
          cls.localMembers.forEach((Element member) {
            if (!member.isInstanceMember() || !member.isField()) return;
            DartType type = member.computeType(compiler);
            registerIsCheck(type);
            SourceString helper = compiler.backend.getCheckedModeHelper(type);
            if (helper != null) {
              Element helperElement = compiler.findHelper(helper);
              registerStaticUse(helperElement);
            }
          });
        }
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
      if (selector.applies(member, compiler)) {
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

  void registerDynamicInvocationOf(Element element) {
    addToWorkList(element);
  }

  void registerDynamicGetter(SourceString methodName, Selector selector) {
    registerInvokedGetter(methodName, selector);
  }

  void registerDynamicSetter(SourceString methodName, Selector selector) {
    registerInvokedSetter(methodName, selector);
  }

  void registerFieldGetter(SourceString getterName,
                           LibraryElement library,
                           DartType type) {
    task.measure(() {
      Selector getter = new Selector.getter(getterName, library);
      registerNewSelector(getterName,
                          new TypedSelector(type, getter),
                          universe.fieldGetters);
    });
  }

  void registerFieldSetter(SourceString setterName,
                           LibraryElement library,
                           DartType type) {
    task.measure(() {
      Selector setter = new Selector.setter(setterName, library);
      registerNewSelector(setterName,
                          new TypedSelector(type, setter),
                          universe.fieldSetters);
    });
  }

  void registerIsCheck(DartType type) {
    universe.isChecks.add(type);
  }

  void forEach(f(WorkItem work)) {
    while (!queue.isEmpty) {
      f(queue.removeLast()); // TODO(kasperl): Why isn't this removeFirst?
    }
  }

  String toString() => 'Enqueuer($name)';

  void logSummary(log(message)) {
    log(isResolutionQueue
        ? 'Resolved ${resolvedElements.length} elements.'
        : 'Compiled ${universe.generatedCode.length} methods.');
    nativeEnqueuer.logSummary(log);
  }
}
