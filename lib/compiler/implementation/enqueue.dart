// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EnqueueTask extends CompilerTask {
  final Enqueuer codegen;
  final Enqueuer resolution;

  String get name() => 'Enqueue';

  EnqueueTask(Compiler compiler)
    : codegen = new Enqueuer(compiler),
      resolution = new Enqueuer(compiler),
      super(compiler) {
    codegen.task = this;
    resolution.task = this;
  }
}

class RecompilationQueue {
  final Queue<WorkItem> queue;
  final Set<Element> queueElements;
  int processed = 0;

  RecompilationQueue()
    : queue = new Queue<WorkItem>(),
      queueElements = new Set<Element>();

  void add(Element element, TreeElements elements) {
    if (queueElements.contains(element)) return;
    queueElements.add(element);
    queue.add(new WorkItem(element, elements));
  }

  int get length() => queue.length;

  bool isEmpty() => queue.isEmpty();

  WorkItem next() {
    WorkItem item = queue.removeLast();
    queueElements.remove(item.element);
    processed++;
    return item;
  }
}

class Enqueuer {
  final Compiler compiler; // TODO(ahe): Remove this dependency.
  final Map<String, Link<Element>> instanceMembersByName;
  final Set<ClassElement> seenClasses;
  final Universe universe;
  final Queue<WorkItem> queue;
  final Map<Element, TreeElements> resolvedElements;
  final RecompilationQueue recompilationCandidates;

  bool queueIsClosed = false;
  EnqueueTask task;

  Enqueuer(this.compiler)
    : instanceMembersByName = new Map<String, Link<Element>>(),
      seenClasses = new Set<ClassElement>(),
      universe = new Universe(),
      queue = new Queue<WorkItem>(),
      resolvedElements = new Map<Element, TreeElements>(),
      recompilationCandidates = new RecompilationQueue();

  bool get isResolutionQueue() => compiler.enqueuer.resolution === this;

  TreeElements getCachedElements(Element element) {
    Element owner = element.getOutermostEnclosingMemberOrTopLevel();
    return compiler.enqueuer.resolution.resolvedElements[owner];
  }

  void addToWorkList(Element element, [TreeElements elements]) {
    if (element.isForeign()) return;
    if (compiler.phase == Compiler.PHASE_RECOMPILING) return;
    if (queueIsClosed) {
      if (isResolutionQueue && getCachedElements(element) !== null) return;
      compiler.internalErrorOnElement(element, "Work list is closed.");
    }
    if (!isResolutionQueue &&
        element.kind === ElementKind.GENERATIVE_CONSTRUCTOR) {
      registerInstantiatedClass(element.getEnclosingClass());
    }
    if (elements === null) {
      elements = getCachedElements(element);
    }
    queue.add(new WorkItem(element, elements));
  }

  void eagerRecompile(Element element) {
    universe.generatedCode.remove(element);
    universe.generatedBailoutCode.remove(element);
    addToWorkList(element);
  }

  bool canBeRecompiled(Element element) {
    // Only member functions can be recompiled. An exception to this is members
    // of closures. They are processed as part of the enclosing function and not
    // present as a separate element (the call to the closure will be a member
    // function).
    return element.isMember() && !element.getEnclosingClass().isClosure();
  }

  void registerRecompilationCandidate(Element element,
                                      [TreeElements elements]) {
    if (!canBeRecompiled(element)) return;
    if (queueIsClosed) {
      compiler.internalErrorOnElement(element, "Work list is closed.");
    }
    recompilationCandidates.add(element, elements);
  }

  void registerInstantiatedClass(ClassElement cls) {
    if (cls.isInterface()) {
      compiler.internalErrorOnElement(
          // Use the current element, as this is where cls is referenced from.
          compiler.currentElement,
          'Expected a class, but $cls is an interface.');
    }
    universe.instantiatedClasses.add(cls);
    onRegisterInstantiatedClass(cls);
  }

  bool checkNoEnqueuedInvokedInstanceMethods() {
    task.measure(() {
      // Run through the classes and see if we need to compile methods.
      for (ClassElement classElement in universe.instantiatedClasses) {
        for (ClassElement currentClass = classElement;
             currentClass !== null;
             currentClass = currentClass.superclass) {
          processInstantiatedClass(currentClass);
        }
      }
    });
    return true;
  }

  void processInstantiatedClass(ClassElement cls) {
    cls.localMembers.forEach(processInstantiatedClassMember);
  }

  void registerFieldClosureInvocations() {
    task.measure(() {
      // Make sure that the closure understands a call with the given
      // selector. For a method-invocation of the form o.foo(a: 499), we
      // need to make sure that closures can handle the optional argument if
      // there exists a field or getter 'foo'.
      var names = universe.instantiatedClassInstanceFields;
      // TODO(ahe): Might be enough to use invokedGetters.
      for (SourceString name in names) {
        Set<Selector> invokedSelectors = universe.invokedNames[name];
        if (invokedSelectors != null) {
          for (Selector selector in invokedSelectors) {
            registerDynamicInvocation(compiler.namer.CLOSURE_INVOCATION_NAME,
                                      selector);
          }
        }
      }
    });
  }

  void processInstantiatedClassMember(Element member) {
    if (universe.generatedCode.containsKey(member)) return;
    if (resolvedElements[member] !== null) return;

    if (!member.isInstanceMember()) return;
    if (member.isField()) return;

    String memberName = member.name.slowToString();
    Link<Element> members = instanceMembersByName.putIfAbsent(
        memberName, () => const EmptyLink<Element>());
    instanceMembersByName[memberName] = members.prepend(member);

    if (member.kind === ElementKind.GETTER ||
        member.kind === ElementKind.FIELD) {
      universe.instantiatedClassInstanceFields.add(member.name);
    }

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
    } else if (member.kind === ElementKind.SETTER) {
      if (universe.hasInvokedSetter(member, compiler)) {
        return addToWorkList(member);
      }
    }
  }

  void onRegisterInstantiatedClass(ClassElement cls) {
    task.measure(() {
      while (cls !== null) {
        if (seenClasses.contains(cls)) return;
        seenClasses.add(cls);
        // TODO(ahe): Don't call resolveType, instead, call this method
        // when resolveType is called.
        compiler.resolveClass(cls);
        cls.localMembers.forEach(processInstantiatedClassMember);
        cls = cls.superclass;
      }
    });
  }

  void registerNewSelector(SourceString name,
                           Selector selector,
                           Map<SourceString, Set<Selector>> selectorsMap) {
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
    if (members !== null) {
      LinkBuilder<Element> remaining = new LinkBuilder<Element>();
      for (; !members.isEmpty(); members = members.tail) {
        if (!f(members.head)) remaining.addLast(members.head);
      }
      instanceMembersByName[memberName] = remaining.toLink();
    }
  }

  void handleUnseenSelector(SourceString methodName, Selector selector) {
    processInstanceMembers(methodName, (Element member) {
      if (selector.applies(member, compiler)) {
        addToWorkList(member);
        return true;
      }
      return false;
    });
  }

  void registerStaticUse(Element element) {
    addToWorkList(element);
  }

  void registerGetOfStaticFunction(FunctionElement element) {
    registerStaticUse(element);
    universe.staticFunctionsNeedingGetter.add(element);
  }

  void registerDynamicInvocation(SourceString methodName, Selector selector) {
    assert(selector !== null);
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

  void registerFieldGetter(SourceString getterName, Type type) {
    task.measure(() {
      registerNewSelector(getterName,
                          new TypedSelector(type, Selector.GETTER),
                          universe.fieldGetters);
    });
  }

  void registerFieldSetter(SourceString setterName, Type type) {
    task.measure(() {
      registerNewSelector(setterName,
                          new TypedSelector(type, Selector.SETTER),
                          universe.fieldSetters);
    });
  }

  // TODO(ngeoffray): This should get a type.
  void registerIsCheck(Element element) {
    universe.isChecks.add(element);
  }

  void forEach(f(WorkItem work)) {
    while (!queue.isEmpty()) {
      do {
        f(queue.removeLast());
      } while (!queue.isEmpty());
      // TODO(ahe): we shouldn't register the field closure invocations here.
      registerFieldClosureInvocations();
    }
  }
}
