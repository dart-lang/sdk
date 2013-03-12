// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

class World {
  final Compiler compiler;
  final Map<ClassElement, Set<MixinApplicationElement>> mixinUses;
  final Map<ClassElement, Set<ClassElement>> typesImplementedBySubclasses;
  final Set<ClassElement> classesNeedingRti;
  final Map<ClassElement, Set<ClassElement>> rtiDependencies;
  final FullFunctionSet allFunctions;

  // The set of classes that use one of their type variables as expressions
  // to get the runtime type.
  final Set<ClassElement> classesUsingTypeVariableExpression;

  // We keep track of subtype and subclass relationships in four
  // distinct sets to make class hierarchy analysis faster.
  final Map<ClassElement, Set<ClassElement>> subclasses =
      new Map<ClassElement, Set<ClassElement>>();
  final Map<ClassElement, Set<ClassElement>> superclasses =
      new Map<ClassElement, Set<ClassElement>>();
  final Map<ClassElement, Set<ClassElement>> subtypes =
      new Map<ClassElement, Set<ClassElement>>();
  final Map<ClassElement, Set<ClassElement>> supertypes =
      new Map<ClassElement, Set<ClassElement>>();

  World(Compiler compiler)
      : mixinUses = new Map<ClassElement, Set<MixinApplicationElement>>(),
        typesImplementedBySubclasses =
            new Map<ClassElement, Set<ClassElement>>(),
        classesNeedingRti = new Set<ClassElement>(),
        rtiDependencies = new Map<ClassElement, Set<ClassElement>>(),
        allFunctions = new FullFunctionSet(compiler),
            classesUsingTypeVariableExpression = new Set<ClassElement>(),
        this.compiler = compiler;

  void populate() {
    void addSubtypes(ClassElement cls) {
      if (cls.resolutionState != STATE_DONE) {
        compiler.internalErrorOnElement(
            cls, 'Class "${cls.name.slowToString()}" is not resolved.');
      }

      for (DartType type in cls.allSupertypes) {
        Set<Element> supertypesOfClass =
            supertypes.putIfAbsent(cls, () => new Set<ClassElement>());
        Set<Element> subtypesOfSupertype =
            subtypes.putIfAbsent(type.element, () => new Set<ClassElement>());
        supertypesOfClass.add(type.element);
        subtypesOfSupertype.add(cls);
      }

      // Walk through the superclasses, and record the types
      // implemented by that type on the superclasses.
      DartType type = cls.supertype;
      while (type != null) {
        Set<Element> superclassesOfClass =
            superclasses.putIfAbsent(cls, () => new Set<ClassElement>());
        Set<Element> subclassesOfSuperclass =
            subclasses.putIfAbsent(type.element, () => new Set<ClassElement>());
        superclassesOfClass.add(type.element);
        subclassesOfSuperclass.add(cls);

        Set<Element> typesImplementedBySubclassesOfCls =
            typesImplementedBySubclasses.putIfAbsent(
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

    // Find the classes that need runtime type information. Such
    // classes are:
    // (1) used in a is check with type variables,
    // (2) dependencies of classes in (1),
    // (3) subclasses of (2) and (3).

    void potentiallyAddForRti(ClassElement cls) {
      if (cls.typeVariables.isEmpty) return;
      if (classesNeedingRti.contains(cls)) return;
      classesNeedingRti.add(cls);

      // TODO(ngeoffray): This should use subclasses, not subtypes.
      Set<ClassElement> classes = subtypes[cls];
      if (classes != null) {
        classes.forEach((ClassElement sub) {
          potentiallyAddForRti(sub);
        });
      }

      Set<ClassElement> dependencies = rtiDependencies[cls];
      if (dependencies != null) {
        dependencies.forEach((ClassElement other) {
          potentiallyAddForRti(other);
        });
      }
    }

    Set<ClassElement> classesUsingTypeVariableTests = new Set<ClassElement>();
    compiler.resolverWorld.isChecks.forEach((DartType type) {
      if (type.kind == TypeKind.TYPE_VARIABLE) {
        TypeVariableElement variable = type.element;
        classesUsingTypeVariableTests.add(variable.enclosingElement);
      }
    });
    // Add is-checks that result from classes using type variables in checks.
    compiler.resolverWorld.addImplicitChecks(classesUsingTypeVariableTests);
    // Add the rti dependencies that are implicit in the way the backend
    // generates code: when we create a new [List], we actually create
    // a JSArray in the backend and we need to add type arguments to
    // the calls of the list constructor whenever we determine that
    // JSArray needs type arguments.
    compiler.backend.addBackendRtiDependencies(this);
    // Compute the set of all classes that need runtime type information.
    compiler.resolverWorld.isChecks.forEach((DartType type) {
      if (type.kind == TypeKind.INTERFACE) {
        InterfaceType itf = type;
        if (!itf.isRaw) {
          potentiallyAddForRti(itf.element);
        }
      } else if (type.kind == TypeKind.TYPE_VARIABLE) {
        TypeVariableElement variable = type.element;
        potentiallyAddForRti(variable.enclosingElement);
      }
    });
    // Add the classes that need RTI because they use a type variable as
    // expression.
    classesUsingTypeVariableExpression.forEach(potentiallyAddForRti);
  }

  Iterable<ClassElement> commonSupertypesOf(ClassElement x, ClassElement y) {
    Set<ClassElement> xSet = supertypes[x];
    if (xSet == null) return const <ClassElement>[];
    Set<ClassElement> ySet = supertypes[y];
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
    Set<ClassElement> classes = subclasses[cls];
    return classes != null && !classes.isEmpty;
  }

  bool hasAnySubtype(ClassElement cls) {
    Set<ClassElement> classes = subtypes[cls];
    return classes != null && !classes.isEmpty;
  }

  void registerRtiDependency(Element element, Element dependency) {
    // We're not dealing with typedef for now.
    if (!element.isClass() || !dependency.isClass()) return;
    Set<ClassElement> classes =
        rtiDependencies.putIfAbsent(element, () => new Set<ClassElement>());
    classes.add(dependency);
  }

  void registerClassUsingVariableExpression(ClassElement cls) {
    classesUsingTypeVariableExpression.add(cls);
  }

  bool needsRti(ClassElement cls) {
    return classesNeedingRti.contains(cls) || compiler.enabledRuntimeType;
  }

  bool hasAnyUserDefinedGetter(Selector selector) {
    return allFunctions.filter(selector).any((each) => each.isGetter());
  }

  bool hasAnyUserDefinedSetter(Selector selector) {
     return allFunctions.filter(selector).any((each) => each.isSetter());
  }

  // Returns whether a subclass of [superclass] implements [type].
  bool hasAnySubclassThatImplements(ClassElement superclass, DartType type) {
    Set<ClassElement> subclasses = typesImplementedBySubclasses[superclass];
    if (subclasses == null) return false;
    return subclasses.contains(type.element);
  }

  // Returns whether a subclass of [superclass] mixes in [other].
  bool hasAnySubclassThatMixes(ClassElement superclass, ClassElement other) {
    Set<MixinApplicationElement> uses = mixinUses[other];
    return (uses != null)
        ? uses.any((each) => each.isSubclassOf(superclass))
        : false;
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
    Iterable<Element> targets = allFunctions.filter(selector);
    if (targets.length != 1) return null;
    Element result = targets.first;
    ClassElement enclosing = result.getEnclosingClass();
    // TODO(kasperl): Move this code to the type mask.
    ti.TypeMask mask = selector.mask;
    ClassElement receiverTypeElement = (mask == null)
        ? compiler.objectClass
        : mask.base.element;
    // We only return the found element if it is guaranteed to be
    // implemented on the exact receiver type. It could be found in a
    // subclass or in an inheritance-wise unrelated class in case of
    // subtype selectors.
    return (receiverTypeElement.isSubclassOf(enclosing)) ? result : null;
  }

  Iterable<ClassElement> locateNoSuchMethodHolders(Selector selector) {
    Selector noSuchMethodSelector = new Selector.noSuchMethod();
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
}
