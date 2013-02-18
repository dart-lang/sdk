// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

class World {
  final Compiler compiler;
  final Map<ClassElement, Set<ClassElement>> subtypes;
  final Map<ClassElement, Set<MixinApplicationElement>> mixinUses;
  final Map<ClassElement, Set<ClassElement>> typesImplementedBySubclasses;
  final Set<ClassElement> classesNeedingRti;
  final Map<ClassElement, Set<ClassElement>> rtiDependencies;
  final FullFunctionSet allFunctions;

  World(Compiler compiler)
      : subtypes = new Map<ClassElement, Set<ClassElement>>(),
        mixinUses = new Map<ClassElement, Set<MixinApplicationElement>>(),
        typesImplementedBySubclasses =
            new Map<ClassElement, Set<ClassElement>>(),
        classesNeedingRti = new Set<ClassElement>(),
        rtiDependencies = new Map<ClassElement, Set<ClassElement>>(),
        allFunctions = new FullFunctionSet(compiler),
        this.compiler = compiler;

  void populate() {
    void addSubtypes(ClassElement cls) {
      if (cls.resolutionState != STATE_DONE) {
        compiler.internalErrorOnElement(
            cls, 'Class "${cls.name.slowToString()}" is not resolved.');
      }

      for (DartType type in cls.allSupertypes) {
        Set<Element> subtypesOfCls =
          subtypes.putIfAbsent(type.element, () => new Set<ClassElement>());
        subtypesOfCls.add(cls);
      }

      // Walk through the superclasses, and record the types
      // implemented by that type on the superclasses.
      DartType type = cls.supertype;
      while (type != null) {
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

    compiler.resolverWorld.instantiatedClasses.forEach(addSubtypes);

    // Find the classes that need runtime type information. Such
    // classes are:
    // (1) used in a is check with type variables,
    // (2) dependencies of classes in (1),
    // (3) subclasses of (2) and (3).

    void potentiallyAddForRti(ClassElement cls) {
      if (cls.typeVariables.isEmpty) return;
      if (classesNeedingRti.contains(cls)) return;
      classesNeedingRti.add(cls);

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

    compiler.resolverWorld.isChecks.forEach((DartType type) {
      if (type is InterfaceType) {
        InterfaceType itf = type;
        if (!itf.isRaw) {
          potentiallyAddForRti(itf.element);
        }
      }
    });
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


  void registerRtiDependency(Element element, Element dependency) {
    // We're not dealing with typedef for now.
    if (!element.isClass() || !dependency.isClass()) return;
    Set<ClassElement> classes =
        rtiDependencies.putIfAbsent(element, () => new Set<ClassElement>());
    classes.add(dependency);
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
    DartType receiverType = selector.receiverType;
    ClassElement receiverTypeElement = (receiverType == null)
        ? compiler.objectClass
        : receiverType.element;
    // We only return the found element if it is guaranteed to be
    // implemented on the exact receiver type. It could be found in a
    // subclass or in an inheritance-wise unrelated class in case of
    // subtype selectors.
    return (receiverTypeElement.isSubclassOf(enclosing)) ? result : null;
  }

  Iterable<ClassElement> locateNoSuchMethodHolders(Selector selector) {
    Selector noSuchMethodSelector = new Selector.noSuchMethod();
    DartType receiverType = selector.receiverType;
    if (receiverType != null) {
      noSuchMethodSelector = new TypedSelector(
          receiverType, selector.typeKind, noSuchMethodSelector);
    }
    ClassElement objectClass = compiler.objectClass;
    return allFunctions
        .filter(noSuchMethodSelector)
        .map((Element member) => member.getEnclosingClass())
        .where((ClassElement holder) => !identical(holder, objectClass));
  }
}
