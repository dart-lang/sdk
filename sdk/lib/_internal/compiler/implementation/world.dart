// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

abstract class ClassWorld {
  // TODO(johnniwinther): Refine this into a `BackendClasses` interface.
  Backend get backend;

  // TODO(johnniwinther): Remove the need for this getter.
  @deprecated
  Compiler get compiler;

  /// The [ClassElement] for the [Object] class defined in 'dart:core'.
  ClassElement get objectClass;

  /// The [ClassElement] for the [Function] class defined in 'dart:core'.
  ClassElement get functionClass;

  /// The [ClassElement] for the [bool] class defined in 'dart:core'.
  ClassElement get boolClass;

  /// The [ClassElement] for the [num] class defined in 'dart:core'.
  ClassElement get numClass;

  /// The [ClassElement] for the [int] class defined in 'dart:core'.
  ClassElement get intClass;

  /// The [ClassElement] for the [double] class defined in 'dart:core'.
  ClassElement get doubleClass;

  /// The [ClassElement] for the [String] class defined in 'dart:core'.
  ClassElement get stringClass;

  /// Returns `true` if [cls] is instantiated.
  bool isInstantiated(ClassElement cls);

  /// Returns `true` if the class world is closed.
  bool get isClosed;

  /// Return `true` if [x] is a subclass of [y].
  bool isSubclassOf(ClassElement x, ClassElement y);

  /// Returns `true` if [x] is a subtype of [y], that is, if [x] implements an
  /// instance of [y].
  bool isSubtypeOf(ClassElement x, ClassElement y);

  /// Returns an iterable over the live classes that extend [cls] including
  /// [cls] itself.
  Iterable<ClassElement> subclassesOf(ClassElement cls);

  /// Returns an iterable over the live classes that extend [cls] _not_
  /// including [cls] itself.
  Iterable<ClassElement> strictSubclassesOf(ClassElement cls);

  /// Returns an iterable over the live classes that implement [cls] including
  /// [cls] if it is live.
  Iterable<ClassElement> subtypesOf(ClassElement cls);

  /// Returns an iterable over the live classes that implement [cls] _not_
  /// including [cls] if it is live.
  Iterable<ClassElement> strictSubtypesOf(ClassElement cls);

  /// Returns `true` if any live class extends [cls].
  bool hasAnySubclass(ClassElement cls);

  /// Returns `true` if any live class other than [cls] extends [cls].
  bool hasAnyStrictSubclass(ClassElement cls);

  /// Returns `true` if any live class implements [cls].
  bool hasAnySubtype(ClassElement cls);

  /// Returns `true` if any live class other than [cls] implements [cls].
  bool hasAnyStrictSubtype(ClassElement cls);

  /// Returns `true` if all live classes that implement [cls] extend it.
  bool hasOnlySubclasses(ClassElement cls);

  /// Returns an iterable over the common supertypes of the [classes].
  Iterable<ClassElement> commonSupertypesOf(Iterable<ClassElement> classes);

  /// Returns an iterable over the live mixin applications that mixin [cls].
  Iterable<MixinApplicationElement> mixinUsesOf(ClassElement cls);

  /// Returns `true` if [cls] is mixed into a live class.
  bool isUsedAsMixin(ClassElement cls);

  /// Returns `true` if any live class that mixes in [cls] implements [type].
  bool hasAnySubclassOfMixinUseThatImplements(ClassElement cls,
                                              ClassElement type);

  /// Returns `true` if any live class that mixes in [mixin] is also a subclass
  /// of [superclass].
  bool hasAnySubclassThatMixes(ClassElement superclass, ClassElement mixin);

  /// Returns `true` if any subclass of [superclass] implements [type].
  bool hasAnySubclassThatImplements(ClassElement superclass, ClassElement type);
}

class World implements ClassWorld {
  ClassElement get objectClass => compiler.objectClass;
  ClassElement get functionClass => compiler.functionClass;
  ClassElement get boolClass => compiler.boolClass;
  ClassElement get numClass => compiler.numClass;
  ClassElement get intClass => compiler.intClass;
  ClassElement get doubleClass => compiler.doubleClass;
  ClassElement get stringClass => compiler.stringClass;

  bool checkInvariants(ClassElement cls, {bool mustBeInstantiated: true}) {
    return
      invariant(cls, cls.isDeclaration,
                message: '$cls must be the declaration.') &&
      invariant(cls, cls.isResolved,
                message: '$cls must be resolved.');
    // TODO(johnniwinther): Enable check for instantiation:
    // (!mustBeInstantiated ||
    //   invariant(cls, isInstantiated(cls),
    //             message: '$cls is not instantiated.'));
 }

  /// Returns `true` if [x] is a subtype of [y], that is, if [x] implements an
  /// instance of [y].
  bool isSubtypeOf(ClassElement x, ClassElement y) {
    assert(checkInvariants(x, mustBeInstantiated: true));
    assert(checkInvariants(y));

    if (y == objectClass) return true;
    if (x == objectClass) return false;
    if (x.asInstanceOf(y) != null) return true;
    if (y != functionClass) return false;
    return x.callType != null;
  }

  /// Return `true` if [x] is a (non-strict) subclass of [y].
  bool isSubclassOf(ClassElement x, ClassElement y) {
    assert(checkInvariants(x));
    assert(checkInvariants(y));

    if (y == objectClass) return true;
    if (x == objectClass) return false;
    while (x != null && x.hierarchyDepth >= y.hierarchyDepth) {
      if (x == y) return true;
      x = x.superclass;
    }
    return false;
  }

  /// Returns `true` if [cls] is instantiated.
  bool isInstantiated(ClassElement cls) {
    return compiler.resolverWorld.isInstantiated(cls);
  }

  /// Returns an iterable over the live classes that extend [cls] including
  /// [cls] itself.
  Iterable<ClassElement> subclassesOf(ClassElement cls) {
    Set<ClassElement> subclasses = _subclasses[cls.declaration];
    if (subclasses == null) return const <ClassElement>[];
    assert(invariant(cls, isInstantiated(cls.declaration),
        message: 'Class $cls has not been instantiated.'));
    return subclasses;
  }

  /// Returns an iterable over the live classes that extend [cls] _not_
  /// including [cls] itself.
  Iterable<ClassElement> strictSubclassesOf(ClassElement cls) {
    return subclassesOf(cls).where((c) => c != cls);
  }

  /// Returns an iterable over the live classes that implement [cls] including
  /// [cls] if it is live.
  Iterable<ClassElement> subtypesOf(ClassElement cls) {
    Set<ClassElement> subtypes = _subtypes[cls.declaration];
    return subtypes != null ? subtypes : const <ClassElement>[];
  }

  /// Returns an iterable over the live classes that implement [cls] _not_
  /// including [cls] if it is live.
  Iterable<ClassElement> strictSubtypesOf(ClassElement cls) {
    return subtypesOf(cls).where((c) => c != cls);
  }

  /// Returns `true` if any live class extends [cls].
  bool hasAnySubclass(ClassElement cls) {
    return !subclassesOf(cls).isEmpty;
  }

  /// Returns `true` if any live class other than [cls] extends [cls].
  bool hasAnyStrictSubclass(ClassElement cls) {
    return !strictSubclassesOf(cls).isEmpty;
  }

  /// Returns `true` if any live class implements [cls].
  bool hasAnySubtype(ClassElement cls) {
    return !subtypesOf(cls).isEmpty;
  }

  /// Returns `true` if any live class other than [cls] implements [cls].
  bool hasAnyStrictSubtype(ClassElement cls) {
    return !strictSubtypesOf(cls).isEmpty;
  }

  /// Returns `true` if all live classes that implement [cls] extend it.
  bool hasOnlySubclasses(ClassElement cls) {
    Iterable<ClassElement> subtypes = subtypesOf(cls);
    if (subtypes == null) return true;
    Iterable<ClassElement> subclasses = subclassesOf(cls);
    return subclasses != null && (subclasses.length == subtypes.length);
  }

  /// Returns an iterable over the common supertypes of the [classes].
  Iterable<ClassElement> commonSupertypesOf(Iterable<ClassElement> classes) {
    Iterator<ClassElement> iterator = classes.iterator;
    if (!iterator.moveNext()) return const <ClassElement>[];

    ClassElement cls = iterator.current;
    assert(checkInvariants(cls));
    OrderedTypeSet typeSet = cls.allSupertypesAndSelf;
    if (!iterator.moveNext()) return typeSet.types.map((type) => type.element);

    int depth = typeSet.maxDepth;
    Link<OrderedTypeSet> otherTypeSets = const Link<OrderedTypeSet>();
    do {
      ClassElement otherClass = iterator.current;
      assert(checkInvariants(otherClass));
      OrderedTypeSet otherTypeSet = otherClass.allSupertypesAndSelf;
      otherTypeSets = otherTypeSets.prepend(otherTypeSet);
      if (otherTypeSet.maxDepth < depth) {
        depth = otherTypeSet.maxDepth;
      }
    } while (iterator.moveNext());

    List<ClassElement> commonSupertypes = <ClassElement>[];
    OUTER: for (Link<DartType> link = typeSet[depth];
                link.head.element != objectClass;
                link = link.tail) {
      ClassElement cls = link.head.element;
      for (Link<OrderedTypeSet> link = otherTypeSets;
          !link.isEmpty;
          link = link.tail) {
        if (link.head.asInstanceOf(cls) == null) {
          continue OUTER;
        }
      }
      commonSupertypes.add(cls);
    }
    commonSupertypes.add(objectClass);
    return commonSupertypes;
  }

  /// Returns an iterable over all mixin applications that mixin [cls].
  Iterable<MixinApplicationElement> allMixinUsesOf(ClassElement cls) {
    Iterable<MixinApplicationElement> uses = _mixinUses[cls];
    return uses != null ? uses : const <MixinApplicationElement>[];
  }

  /// Returns an iterable over the live mixin applications that mixin [cls].
  Iterable<MixinApplicationElement> mixinUsesOf(ClassElement cls) {
    assert(isClosed);
    if (_liveMixinUses == null) {
      _liveMixinUses = new Map<ClassElement, List<MixinApplicationElement>>();
      for (ClassElement mixin in _mixinUses.keys) {
        Iterable<MixinApplicationElement> uses =
            _mixinUses[mixin].where(isInstantiated);
        if (uses.isNotEmpty) _liveMixinUses[mixin] = uses.toList();
      }
    }
    Iterable<MixinApplicationElement> uses = _liveMixinUses[cls];
    return uses != null ? uses : const <MixinApplicationElement>[];
  }

  /// Returns `true` if [cls] is mixed into a live class.
  bool isUsedAsMixin(ClassElement cls) {
    return !mixinUsesOf(cls).isEmpty;
  }

  /// Returns `true` if any live class that mixes in [cls] implements [type].
  bool hasAnySubclassOfMixinUseThatImplements(ClassElement cls,
                                              ClassElement type) {
    return mixinUsesOf(cls).any(
        (use) => hasAnySubclassThatImplements(use, type));
  }

  /// Returns `true` if any live class that mixes in [mixin] is also a subclass
  /// of [superclass].
  bool hasAnySubclassThatMixes(ClassElement superclass, ClassElement mixin) {
    return mixinUsesOf(mixin).any((each) => each.isSubclassOf(superclass));
  }

  /// Returns `true` if any subclass of [superclass] implements [type].
  bool hasAnySubclassThatImplements(ClassElement superclass,
                                    ClassElement type) {
    Set<ClassElement> subclasses = typesImplementedBySubclassesOf(superclass);
    if (subclasses == null) return false;
    return subclasses.contains(type);
  }

  final Compiler compiler;
  Backend get backend => compiler.backend;
  final FunctionSet allFunctions;
  final Set<Element> functionsCalledInLoop = new Set<Element>();
  final Map<Element, SideEffects> sideEffects = new Map<Element, SideEffects>();

  final Set<TypedefElement> allTypedefs = new Set<TypedefElement>();

  final Map<ClassElement, List<MixinApplicationElement>> _mixinUses =
      new Map<ClassElement, List<MixinApplicationElement>>();
  Map<ClassElement, List<MixinApplicationElement>> _liveMixinUses;

  final Map<ClassElement, Set<ClassElement>> _typesImplementedBySubclasses =
      new Map<ClassElement, Set<ClassElement>>();

  // We keep track of subtype and subclass relationships in four
  // distinct sets to make class hierarchy analysis faster.
  final Map<ClassElement, Set<ClassElement>> _subclasses =
      new Map<ClassElement, Set<ClassElement>>();
  final Map<ClassElement, Set<ClassElement>> _subtypes =
      new Map<ClassElement, Set<ClassElement>>();

  final Set<Element> sideEffectsFreeElements = new Set<Element>();

  final Set<Element> elementsThatCannotThrow = new Set<Element>();

  final Set<Element> functionsThatMightBePassedToApply =
      new Set<FunctionElement>();

  final Set<Element> alreadyPopulated;

  bool get isClosed => compiler.phase > Compiler.PHASE_RESOLVING;

  // Used by selectors.
  bool isAssertMethod(Element element) {
    return compiler.backend.isAssertMethod(element);
  }

  // Used by selectors.
  bool isForeign(Element element) {
    return element.isForeign(compiler.backend);
  }

  Set<ClassElement> typesImplementedBySubclassesOf(ClassElement cls) {
    return _typesImplementedBySubclasses[cls.declaration];
  }

  World(Compiler compiler)
      : allFunctions = new FunctionSet(compiler),
        this.compiler = compiler,
        alreadyPopulated = compiler.cacheStrategy.newSet();

  void populate() {
    void addSubtypes(ClassElement cls) {
      if (compiler.hasIncrementalSupport && !alreadyPopulated.add(cls)) {
        return;
      }
      assert(cls.isDeclaration);
      if (!cls.isResolved) {
        compiler.internalError(cls, 'Class "${cls.name}" is not resolved.');
      }

      for (DartType type in cls.allSupertypes) {
        Set<Element> subtypesOfSupertype =
            _subtypes.putIfAbsent(type.element, () => new Set<ClassElement>());
        subtypesOfSupertype.add(cls);
      }

      // Walk through the superclasses, and record the types
      // implemented by that type on the superclasses.
      ClassElement superclass = cls.superclass;
      while (superclass != null) {
        Set<Element> subclassesOfSuperclass =
            _subclasses.putIfAbsent(superclass, () => new Set<ClassElement>());
        subclassesOfSuperclass.add(cls);

        Set<Element> typesImplementedBySubclassesOfCls =
            _typesImplementedBySubclasses.putIfAbsent(
                superclass, () => new Set<ClassElement>());
        for (DartType current in cls.allSupertypes) {
          typesImplementedBySubclassesOfCls.add(current.element);
        }
        superclass = superclass.superclass;
      }
    }

    // Use the [:seenClasses:] set to include non-instantiated
    // classes: if the superclass of these classes require RTI, then
    // they also need RTI, so that a constructor passes the type
    // variables to the super constructor.
    compiler.resolverWorld.directlyInstantiatedClasses.forEach(addSubtypes);
  }

  void registerMixinUse(MixinApplicationElement mixinApplication,
                        ClassElement mixin) {
    // TODO(johnniwinther): Add map restricted to live classes.
    // We don't support patch classes as mixin.
    assert(mixin.isDeclaration);
    List<MixinApplicationElement> users =
        _mixinUses.putIfAbsent(mixin, () =>
                               new List<MixinApplicationElement>());
    users.add(mixinApplication);
  }

  bool hasAnyUserDefinedGetter(Selector selector) {
    return allFunctions.filter(selector).any((each) => each.isGetter);
  }

  void registerUsedElement(Element element) {
    if (element.isInstanceMember && !element.isAbstract) {
      allFunctions.add(element);
    }
  }

  VariableElement locateSingleField(Selector selector) {
    Element result = locateSingleElement(selector);
    return (result != null && result.isField) ? result : null;
  }

  Element locateSingleElement(Selector selector) {
    ti.TypeMask mask = selector.mask == null
        ? compiler.typesTask.dynamicType
        : selector.mask;
    return mask.locateSingleElement(selector, compiler);
  }

  void addFunctionCalledInLoop(Element element) {
    functionsCalledInLoop.add(element.declaration);
  }

  bool isCalledInLoop(Element element) {
    return functionsCalledInLoop.contains(element.declaration);
  }

  bool fieldNeverChanges(Element element) {
    if (!element.isField) return false;
    if (element.isNative) {
      // Some native fields are views of data that may be changed by operations.
      // E.g. node.firstChild depends on parentNode.removeBefore(n1, n2).
      // TODO(sra): Refine the effect classification so that native effects are
      // distinct from ordinary Dart effects.
      return false;
    }

    return element.isFinal
        || element.isConst
        || (element.isInstanceMember
            && !compiler.resolverWorld.hasInvokedSetter(element, this));
  }

  SideEffects getSideEffectsOfElement(Element element) {
    // The type inferrer (where the side effects are being computed),
    // does not see generative constructor bodies because they are
    // created by the backend. Also, it does not make any distinction
    // between a constructor and its body for side effects. This
    // implies that currently, the side effects of a constructor body
    // contain the side effects of the initializers.
    assert(!element.isGenerativeConstructorBody);
    assert(!element.isField);
    return sideEffects.putIfAbsent(element.declaration, () {
      return new SideEffects();
    });
  }

  void registerSideEffects(Element element, SideEffects effects) {
    if (sideEffectsFreeElements.contains(element)) return;
    sideEffects[element.declaration] = effects;
  }

  void registerSideEffectsFree(Element element) {
    sideEffects[element.declaration] = new SideEffects.empty();
    sideEffectsFreeElements.add(element);
  }

  SideEffects getSideEffectsOfSelector(Selector selector) {
    // We're not tracking side effects of closures.
    if (selector.isClosureCall) return new SideEffects();
    SideEffects sideEffects = new SideEffects.empty();
    for (Element e in allFunctions.filter(selector)) {
      if (e.isField) {
        if (selector.isGetter) {
          if (!fieldNeverChanges(e)) {
            sideEffects.setDependsOnInstancePropertyStore();
          }
        } else if (selector.isSetter) {
          sideEffects.setChangesInstanceProperty();
        } else {
          assert(selector.isCall);
          sideEffects.setAllSideEffects();
          sideEffects.setDependsOnSomething();
        }
      } else {
        sideEffects.add(getSideEffectsOfElement(e));
      }
    }
    return sideEffects;
  }

  void registerCannotThrow(Element element) {
    elementsThatCannotThrow.add(element);
  }

  bool getCannotThrow(Element element) {
    return elementsThatCannotThrow.contains(element);
  }

  void registerImplicitSuperCall(Registry registry,
                                 FunctionElement superConstructor) {
    registry.registerDependency(superConstructor);
  }

  void registerMightBePassedToApply(Element element) {
    functionsThatMightBePassedToApply.add(element);
  }

  bool getMightBePassedToApply(Element element) {
    // We have to check whether the element we look at was created after
    // type inference ran. This is currently only the case for the call
    // method of function classes that were generated for function
    // expressions. In such a case, we have to look at the original
    // function expressions's element.
    // TODO(herhut): Generate classes for function expressions earlier.
    if (element is closureMapping.SynthesizedCallMethodElementX) {
      return getMightBePassedToApply(element.expression);
    }
    return functionsThatMightBePassedToApply.contains(element);
  }
}
