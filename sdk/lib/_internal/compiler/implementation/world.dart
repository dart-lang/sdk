// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

class World {
  final Compiler compiler;
  final FunctionSet allFunctions;
  final Set<Element> functionsCalledInLoop = new Set<Element>();
  final Map<Element, SideEffects> sideEffects = new Map<Element, SideEffects>();

  final Map<ClassElement, Set<MixinApplicationElement>> mixinUses =
      new Map<ClassElement, Set<MixinApplicationElement>>();

  final Map<ClassElement, Set<ClassElement>> _typesImplementedBySubclasses =
      new Map<ClassElement, Set<ClassElement>>();

  // We keep track of subtype and subclass relationships in four
  // distinct sets to make class hierarchy analysis faster.
  final Map<ClassElement, Set<ClassElement>> _subclasses =
      new Map<ClassElement, Set<ClassElement>>();
  final Map<ClassElement, Set<ClassElement>> _superclasses =
      new Map<ClassElement, Set<ClassElement>>();
  final Map<ClassElement, Set<ClassElement>> _subtypes =
      new Map<ClassElement, Set<ClassElement>>();
  final Map<ClassElement, Set<ClassElement>> _supertypes =
      new Map<ClassElement, Set<ClassElement>>();

  Set<ClassElement> subclassesOf(ClassElement cls) {
    return _subclasses[cls.declaration];
  }

  Set<ClassElement> subtypesOf(ClassElement cls) {
    return _subtypes[cls.declaration];
  }

  Set<ClassElement> superclassesOf(ClassElement cls) {
    return _superclasses[cls.declaration];
  }

  Set<ClassElement> supertypesOf(ClassElement cls) {
    return _supertypes[cls.declaration];
  }

  Set<ClassElement> typesImplementedBySubclassesOf(ClassElement cls) {
    return _typesImplementedBySubclasses[cls.declaration];
  }

  bool hasSubclasses(ClassElement cls) {
    Set<ClassElement> subclasses = compiler.world.subclassesOf(cls);
    return subclasses != null && !subclasses.isEmpty;
  }

  World(Compiler compiler)
      : allFunctions = new FunctionSet(compiler),
        this.compiler = compiler;

  void populate() {
    void addSubtypes(ClassElement cls) {
      assert(cls.isDeclaration);
      if (cls.resolutionState != STATE_DONE) {
        compiler.internalErrorOnElement(
            cls, 'Class "${cls.name}" is not resolved.');
      }

      for (DartType type in cls.allSupertypes) {
        Set<Element> supertypesOfClass =
            _supertypes.putIfAbsent(cls, () => new Set<ClassElement>());
        Set<Element> subtypesOfSupertype =
            _subtypes.putIfAbsent(type.element, () => new Set<ClassElement>());
        supertypesOfClass.add(type.element);
        subtypesOfSupertype.add(cls);
      }

      // Walk through the superclasses, and record the types
      // implemented by that type on the superclasses.
      DartType type = cls.supertype;
      while (type != null) {
        Set<Element> superclassesOfClass =
            _superclasses.putIfAbsent(cls, () => new Set<ClassElement>());
        Set<Element> subclassesOfSuperclass =
            _subclasses.putIfAbsent(type.element, () => new Set<ClassElement>());
        superclassesOfClass.add(type.element);
        subclassesOfSuperclass.add(cls);

        Set<Element> typesImplementedBySubclassesOfCls =
            _typesImplementedBySubclasses.putIfAbsent(
                type.element, () => new Set<ClassElement>());
        for (DartType current in cls.allSupertypes) {
          typesImplementedBySubclassesOfCls.add(current.element);
        }
        ClassElement classElement = type.element;
        type = classElement.supertype;
      }
    }

    // Use the [:seenClasses:] set to include non-instantiated
    // classes: if the superclass of these classes require RTI, then
    // they also need RTI, so that a constructor passes the type
    // variables to the super constructor.
    compiler.enqueuer.resolution.seenClasses.forEach(addSubtypes);
  }

  Iterable<ClassElement> commonSupertypesOf(ClassElement x, ClassElement y) {
    Set<ClassElement> xSet = supertypesOf(x);
    if (xSet == null) return const <ClassElement>[];
    Set<ClassElement> ySet = supertypesOf(y);
    if (ySet == null) return const <ClassElement>[];
    Set<ClassElement> smallSet, largeSet;
    if (xSet.length <= ySet.length) {
      smallSet = xSet;
      largeSet = ySet;
    } else {
      smallSet = ySet;
      largeSet = xSet;
    }
    return smallSet.where((ClassElement each) => largeSet.contains(each));
  }

  void registerMixinUse(MixinApplicationElement mixinApplication,
                        ClassElement mixin) {
    // We don't support patch classes as mixin.
    assert(mixin.isDeclaration);
    Set<MixinApplicationElement> users =
        mixinUses.putIfAbsent(mixin, () =>
                              new Set<MixinApplicationElement>());
    users.add(mixinApplication);
  }

  bool isUsedAsMixin(ClassElement cls) {
    Set<MixinApplicationElement> uses = mixinUses[cls];
    return uses != null && !uses.isEmpty;
  }

  bool hasAnySubclass(ClassElement cls) {
    Set<ClassElement> classes = subclassesOf(cls);
    return classes != null && !classes.isEmpty;
  }

  bool hasAnySubtype(ClassElement cls) {
    Set<ClassElement> classes = subtypesOf(cls);
    return classes != null && !classes.isEmpty;
  }

  bool hasAnyUserDefinedGetter(Selector selector) {
    return allFunctions.filter(selector).any((each) => each.isGetter());
  }

  bool hasAnyUserDefinedSetter(Selector selector) {
     return allFunctions.filter(selector).any((each) => each.isSetter());
  }

  // Returns whether a subclass of [superclass] implements [type].
  bool hasAnySubclassThatImplements(ClassElement superclass,
                                    ClassElement type) {
    Set<ClassElement> subclasses = typesImplementedBySubclassesOf(superclass);
    if (subclasses == null) return false;
    return subclasses.contains(type);
  }

  // Returns whether a subclass of any mixin application of [cls] implements
  // [type].
  bool hasAnySubclassOfMixinUseThatImplements(ClassElement cls,
                                              ClassElement type) {
    Set<MixinApplicationElement> uses = mixinUses[cls];
    if (uses == null || uses.isEmpty) return false;
    return uses.any((use) => hasAnySubclassThatImplements(use, type));
  }

  // Returns whether a subclass of [superclass] mixes in [other].
  bool hasAnySubclassThatMixes(ClassElement superclass, ClassElement other) {
    Set<MixinApplicationElement> uses = mixinUses[other];
    return (uses != null)
        ? uses.any((each) => each.isSubclassOf(superclass))
        : false;
  }

  bool isSubtype(ClassElement supertype, ClassElement test) {
    Set<ClassElement> subtypes = subtypesOf(supertype);
    return subtypes != null && subtypes.contains(test.declaration);
  }

  bool isSubclass(ClassElement superclass, ClassElement test) {
    Set<ClassElement> subclasses = subclassesOf(superclass);
    return subclasses != null && subclasses.contains(test.declaration);
  }

  void registerUsedElement(Element element) {
    if (element.isInstanceMember() && !element.isAbstract(compiler)) {
      allFunctions.add(element);
    }
  }

  VariableElement locateSingleField(Selector selector) {
    Element result = locateSingleElement(selector);
    return (result != null && result.isField()) ? result : null;
  }

  Element locateSingleElement(Selector selector) {
    ti.TypeMask mask = selector.mask == null
        ? new ti.TypeMask.subclass(compiler.objectClass)
        : selector.mask;
    return mask.locateSingleElement(selector, compiler);
  }

  bool hasSingleMatch(Selector selector) {
    Iterable<Element> targets = allFunctions.filter(selector);
    return targets.length == 1;
  }

  Iterable<ClassElement> locateNoSuchMethodHolders(Selector selector) {
    Selector noSuchMethodSelector = compiler.noSuchMethodSelector;
    ti.TypeMask mask = selector.mask;
    if (mask != null) {
      noSuchMethodSelector = new TypedSelector(mask, noSuchMethodSelector);
    }
    ClassElement objectClass = compiler.objectClass;
    return allFunctions
        .filter(noSuchMethodSelector)
        .map((Element member) => member.getEnclosingClass())
        .where((ClassElement holder) => !identical(holder, objectClass));
  }

  void addFunctionCalledInLoop(Element element) {
    functionsCalledInLoop.add(element.declaration);
  }

  bool isCalledInLoop(Element element) {
    return functionsCalledInLoop.contains(element.declaration);
  }

  SideEffects getSideEffectsOfElement(Element element) {
    // The type inferrer (where the side effects are being computed),
    // does not see generative constructor bodies because they are
    // created by the backend. Also, it does not make any distinction
    // between a constructor and its body for side effects. This
    // implies that currently, the side effects of a constructor body
    // contain the side effects of the initializers.
    assert(!element.isGenerativeConstructorBody());
    return sideEffects.putIfAbsent(element.declaration, () {
      return new SideEffects();
    });
  }

  void registerSideEffects(Element element, SideEffects effects) {
    sideEffects[element.declaration] = effects;
  }

  SideEffects getSideEffectsOfSelector(Selector selector) {
    // We're not tracking side effects of closures.
    if (selector.isClosureCall()) {
      return new SideEffects();
    }
    SideEffects sideEffects = new SideEffects.empty();
    for (Element e in allFunctions.filter(selector)) {
      if (e.isField()) {
        if (selector.isGetter()) {
          sideEffects.setDependsOnInstancePropertyStore();
        } else if (selector.isSetter()) {
          sideEffects.setChangesInstanceProperty();
        }
      }
      sideEffects.add(getSideEffectsOfElement(e));
    }
    return sideEffects;
  }
}
