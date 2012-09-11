// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EnqueueTask extends CompilerTask {
  final Enqueuer codegen;
  final Enqueuer resolution;

  String get name => 'Enqueue';

  EnqueueTask(Compiler compiler)
    : codegen = new Enqueuer(compiler,
                             compiler.backend.createItemCompilationContext),
      resolution = new Enqueuer(compiler,
                                compiler.backend.createItemCompilationContext),
      super(compiler) {
    codegen.task = this;
    resolution.task = this;
  }
}

class RecompilationQueue {
  final Function itemCompilationContextCreator;
  final Queue<WorkItem> queue;
  final Set<Element> queueElements;
  int processed = 0;

  RecompilationQueue(ItemCompilationContext itemCompilationContextCreator())
    : this.itemCompilationContextCreator = itemCompilationContextCreator,
      queue = new Queue<WorkItem>(),
      queueElements = new Set<Element>();

  void add(Element element, TreeElements elements) {
    if (queueElements.contains(element)) return;
    queueElements.add(element);
    queue.add(new WorkItem(element, elements, itemCompilationContextCreator()));
  }

  int get length => queue.length;

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
  final Function itemCompilationContextCreator;
  final Map<String, Link<Element>> instanceMembersByName;
  final Set<ClassElement> seenClasses;
  final Universe universe;
  final Queue<WorkItem> queue;
  final Map<Element, TreeElements> resolvedElements;
  final RecompilationQueue recompilationCandidates;

  bool queueIsClosed = false;
  EnqueueTask task;

  Enqueuer(this.compiler,
           ItemCompilationContext itemCompilationContextCreator())
    : this.itemCompilationContextCreator = itemCompilationContextCreator,
      instanceMembersByName = new Map<String, Link<Element>>(),
      seenClasses = new Set<ClassElement>(),
      universe = new Universe(),
      queue = new Queue<WorkItem>(),
      resolvedElements = new Map<Element, TreeElements>(),
      recompilationCandidates =
          new RecompilationQueue(itemCompilationContextCreator);

  bool get isResolutionQueue => compiler.enqueuer.resolution === this;

  TreeElements getCachedElements(Element element) {
    // TODO(ngeoffray): Get rid of this check.
    if (element.enclosingElement.isClosure()) {
      closureMapping.ClosureClassElement cls = element.enclosingElement;
      element = cls.methodElement;
    }
    Element owner = element.getOutermostEnclosingMemberOrTopLevel();
    return compiler.enqueuer.resolution.resolvedElements[owner];
  }

  String lookupCode(Element element) =>
      universe.generatedCode[element].toString();

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
    if (isResolutionQueue) {
      compiler.world.registerUsedElement(element);
    }

    queue.add(new WorkItem(element, elements, itemCompilationContextCreator()));

    // Enable isolate support if we start using something from the
    // isolate library.
    LibraryElement library = element.getLibrary();
    if (!compiler.hasIsolateSupport()
        && library.uri.toString() == 'dart:isolate') {
      compiler.enableIsolateSupport(library);
    }
  }

  void eagerRecompile(Element element) {
    universe.generatedCode.remove(element);
    universe.generatedBailoutCode.remove(element);
    addToWorkList(element);
  }

  void registerRecompilationCandidate(Element element,
                                      [TreeElements elements]) {
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

  void processInstantiatedClassMember(Element member) {
    if (universe.generatedCode.containsKey(member)) return;
    if (resolvedElements[member] !== null) return;
    if (!member.isInstanceMember()) return;
    if (member.isField()) return;

    String memberName = member.name.slowToString();
    Link<Element> members = instanceMembersByName.putIfAbsent(
        memberName, () => const EmptyLink<Element>());
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
    } else if (member.kind === ElementKind.SETTER) {
      if (universe.hasInvokedSetter(member, compiler)) {
        return addToWorkList(member);
      }
    }
  }

  void onRegisterInstantiatedClass(ClassElement cls) {
    task.measure(() {
      // The class must be resolved to compute the set of all
      // supertypes.
      cls.ensureResolved(compiler);

      for (Link<DartType> supertypes = cls.allSupertypesAndSelf;
           !supertypes.isEmpty(); supertypes = supertypes.tail) {
        cls = supertypes.head.element;
        if (seenClasses.contains(cls)) continue;
        seenClasses.add(cls);
        cls.ensureResolved(compiler);
        if (!cls.isInterface()) {
          cls.localMembers.forEach(processInstantiatedClassMember);
        }
        if (isResolutionQueue) {
          compiler.resolver.checkMembers(cls);
        }
       
        if (compiler.enableTypeAssertions) {
          // We need to register is checks and helpers for checking
          // assignments to fields.
          // TODO(ngeoffray): This should really move to the backend. 
          cls.localMembers.forEach((Element member) {
            if (!member.isInstanceMember() && !member.isField()) return;
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
    if (element !== null) addToWorkList(element);
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
    while (!queue.isEmpty()) {
      f(queue.removeLast()); // TODO(kasperl): Why isn't this removeFirst?
    }
  }
}
