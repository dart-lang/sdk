// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EnqueueTask extends CompilerTask {
  final Map<String, Link<Element>> instanceMembersByName;
  final Set<ClassElement> seenClasses;

  String get name() => 'Enqueue';

  EnqueueTask(Compiler compiler)
    : instanceMembersByName = new Map<String, Link<Element>>(),
      seenClasses = new Set<ClassElement>(),
      super(compiler);

  bool checkNoEnqueuedInvokedInstanceMethods() {
    measure(() {
      // Run through the classes and see if we need to compile methods.
      for (ClassElement classElement in compiler.universe.instantiatedClasses) {
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
    cls.members.forEach(processInstantiatedClassMember);
  }

  void registerFieldClosureInvocations() {
    measure(() {
      // Make sure that the closure understands a call with the given
      // selector. For a method-invocation of the form o.foo(a: 499), we
      // need to make sure that closures can handle the optional argument if
      // there exists a field or getter 'foo'.
      var names = compiler.universe.instantiatedClassInstanceFields;
      // TODO(ahe): Might be enough to use invokedGetters.
      for (SourceString name in names) {
        Set<Selector> invokedSelectors = compiler.universe.invokedNames[name];
        if (invokedSelectors != null) {
          for (Selector selector in invokedSelectors) {
            compiler.registerDynamicInvocation(Namer.CLOSURE_INVOCATION_NAME,
                                               selector);
          }
        }
      }
    });
  }

  void processInstantiatedClassMember(Element member) {
    if (compiler.universe.generatedCode.containsKey(member)) return;

    if (!member.isInstanceMember()) return;

    String memberName = member.name.slowToString();
    Link<Element> members = instanceMembersByName.putIfAbsent(
        memberName, () => const EmptyLink<Element>());
    instanceMembersByName[memberName] = members.prepend(member);

    if (member.kind === ElementKind.GETTER ||
        member.kind === ElementKind.FIELD) {
      compiler.universe.instantiatedClassInstanceFields.add(member.name);
    }

    if (member.kind == ElementKind.FUNCTION) {
      if (member.name == Compiler.NO_SUCH_METHOD) {
        compiler.enableNoSuchMethod(member);
      }
      Set<Selector> selectors = compiler.universe.invokedNames[member.name];
      if (selectors != null) {
        FunctionElement functionMember = member;
        FunctionParameters parameters =
            functionMember.computeParameters(compiler);
        for (Selector selector in selectors) {
          if (selector.applies(parameters)) {
            return compiler.addToWorkList(member);
          }
        }
      }
      // If there is a property access with the same name as a method we
      // need to emit the method.
      if (compiler.universe.invokedGetters.contains(member.name)) {
        // We will emit a closure, so make sure the closure class is
        // generated.
        compiler.closureClass.ensureResolved(compiler);
        compiler.registerInstantiatedClass(compiler.closureClass);
        return compiler.addToWorkList(member);
      }
    } else if (member.kind == ElementKind.GETTER) {
      if (compiler.universe.invokedGetters.contains(member.name)) {
        return compiler.addToWorkList(member);
      }
      // A method invocation like in o.foo(x, y) might actually be an
      // invocation of the getter foo followed by an invocation of the
      // returned closure.
      Set<Selector> invokedSelectors =
        compiler.universe.invokedNames[member.name];
      // We don't know what selectors the returned closure accepts. If
      // the set contains any selector we have to assume that it matches.
      if (invokedSelectors !== null && !invokedSelectors.isEmpty()) {
        return compiler.addToWorkList(member);
      }
    } else if (member.kind === ElementKind.SETTER) {
      if (compiler.universe.invokedSetters.contains(member.name)) {
        return compiler.addToWorkList(member);
      }
    }
  }

  void onRegisterInstantiatedClass(ClassElement cls) {
    measure(() {
      while (cls !== null) {
        if (seenClasses.contains(cls)) return;
        seenClasses.add(cls);
        // TODO(ahe): Don't call resolveType, instead, call this method
        // when resolveType is called.
        compiler.resolveType(cls);
        cls.members.forEach(processInstantiatedClassMember);
        cls = cls.superclass;
      }
    });
  }

  void registerInvocation(SourceString methodName, Selector selector) {
    measure(() {
      Map<SourceString, Set<Selector>> invokedNames =
        compiler.universe.invokedNames;
      Set<Selector> selectors =
        invokedNames.putIfAbsent(methodName, () => new Set<Selector>());
      if (!selectors.contains(selector)) {
        selectors.add(selector);
        handleUnseenInvocation(methodName, selector);
      }
    });
  }

  void registerGetter(SourceString methodName) {
    measure(() {
      if (!compiler.universe.invokedGetters.contains(methodName)) {
        compiler.universe.invokedGetters.add(methodName);
        handleUnseenGetter(methodName);
      }
    });
  }

  void registerSetter(SourceString methodName) {
    measure(() {
      if (!compiler.universe.invokedSetters.contains(methodName)) {
        compiler.universe.invokedSetters.add(methodName);
        handleUnseenSetter(methodName);
      }
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

  void handleUnseenInvocation(SourceString methodName, Selector selector) {
    processInstanceMembers(methodName, (Element member) {
      if (member.isGetter()) {
        compiler.addToWorkList(member);
        return true;
      } else if (member.isFunction()) {
        FunctionElement functionMember = member;
        FunctionParameters parameters =
          functionMember.computeParameters(compiler);
        if (selector.applies(parameters)) {
          compiler.addToWorkList(member);
          return true;
        }
      }
      return false;
    });
  }

  void handleUnseenGetter(SourceString methodName) {
    processInstanceMembers(methodName, (Element member) {
      if (member.isGetter() || member.isFunction()) {
        compiler.addToWorkList(member);
        return true;
      } else {
        return false;
      }
    });
  }

  void handleUnseenSetter(SourceString methodName) {
    processInstanceMembers(methodName, (Element member) {
      if (member.isSetter()) {
        compiler.addToWorkList(member);
        return true;
      } else {
        return false;
      }
    });
  }
}
