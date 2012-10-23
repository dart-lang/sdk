// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class World {
  final Compiler compiler;
  final Map<ClassElement, Set<ClassElement>> subtypes;
  final Set<ClassElement> classesNeedingRti;
  final Map<ClassElement, Set<ClassElement>> rtiDependencies;
  final FunctionSet userDefinedGetters;
  final FunctionSet userDefinedSetters;

  World(Compiler compiler)
      : subtypes = new Map<ClassElement, Set<ClassElement>>(),
        userDefinedGetters = new FunctionSet(compiler),
        userDefinedSetters = new FunctionSet(compiler),
        classesNeedingRti = new Set<ClassElement>(),
        rtiDependencies = new Map<ClassElement, Set<ClassElement>>(),
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
    }

    compiler.resolverWorld.instantiatedClasses.forEach(addSubtypes);

    // Find the classes that need runtime type information. Such
    // classes are:
    // (1) used in a is check with type variables,
    // (2) dependencies of classes in (1),
    // (3) subclasses of (2) and (3).

    void potentiallyAddForRti(ClassElement cls, Function callback) {
      if (cls.typeVariables.isEmpty()) return;
      if (classesNeedingRti.contains(cls)) return;
      classesNeedingRti.add(cls);
      if (callback != null) {
        callback();
      }
      Set<ClassElement> classes = subtypes[cls];
      if (classes == null) return;
      classes.forEach((ClassElement sub) {
        potentiallyAddForRti(sub, callback);
      });
    }

    compiler.resolverWorld.isChecks.forEach((DartType type) {
      if (type is InterfaceType) {
        InterfaceType itf = type;
        if (!itf.arguments.isEmpty()) {
          potentiallyAddForRti(itf.element, null);
        }
      }
    });

    List<ClassElement> worklist =
        new List<ClassElement>.from(classesNeedingRti);
    while (!worklist.isEmpty()) {
      Element e = worklist.removeLast();
      Set<Element> dependencies = rtiDependencies[e];
      if (dependencies == null) continue;
      dependencies.forEach((Element other) {
        potentiallyAddForRti(other, () => worklist.add(other));
      });
    }
  }

  bool needsRti(ClassElement cls) {
    return classesNeedingRti.contains(cls) || compiler.enabledRuntimeType;
  }

  void registerRtiDependency(Element element, Element dependency) {
    // We're not dealing with typedef for now.
    if (!element.isClass() || !dependency.isClass()) return;
    Set<ClassElement> classes =
        rtiDependencies.putIfAbsent(element, () => new Set<ClassElement>());
    classes.add(dependency);
  }

  void recordUserDefinedGetter(Element element) {
    assert(element.isGetter());
    userDefinedGetters.add(element);
  }

  void recordUserDefinedSetter(Element element) {
    assert(element.isSetter());
    userDefinedSetters.add(element);
  }

  bool hasAnyUserDefinedGetter(Selector selector) {
    return userDefinedGetters.hasAnyElementMatchingSelector(selector);
  }

  bool hasAnyUserDefinedSetter(Selector selector) {
    return userDefinedSetters.hasAnyElementMatchingSelector(selector);
  }

  void registerUsedElement(Element element) {
    if (element.isMember()) {
      if (element.isGetter()) {
        // We're collecting user-defined getters to let the codegen know which
        // field accesses might have side effects.
        recordUserDefinedGetter(element);
      } else if (element.isSetter()) {
        recordUserDefinedSetter(element);
      }
    }
  }

  /**
   * Returns a [MemberSet] that contains the possible targets of the given
   * [selector] on a receiver with the given [type]. This includes all sub
   * types.
   */
  MemberSet _memberSetFor(DartType type, Selector selector) {
    assert(compiler != null);
    ClassElement cls = type.element;
    SourceString name = selector.name;
    LibraryElement library = selector.library;
    MemberSet result = new MemberSet(name);
    Element element = cls.implementation.lookupSelector(selector);
    if (element != null) result.add(element);

    bool isPrivate = name.isPrivate();
    Set<ClassElement> subtypesOfCls = subtypes[cls];
    if (subtypesOfCls != null) {
      for (ClassElement sub in subtypesOfCls) {
        // Private members from a different library are not visible.
        if (isPrivate && sub.getLibrary() != library) continue;
        element = sub.implementation.lookupLocalMember(name);
        if (element != null) result.add(element);
      }
    }
    return result;
  }

  /**
   * Returns the field in [type] described by the given [selector].
   * If no such field exists, or a subclass overrides the field
   * returns [:null:].
   */
  VariableElement locateSingleField(DartType type, Selector selector) {
    MemberSet memberSet = _memberSetFor(type, selector);
    ClassElement cls = type.element;
    Element result = cls.implementation.lookupSelector(selector);
    if (result == null) return null;
    if (!result.isField()) return null;

    // Verify that no subclass overrides the field.
    if (memberSet.elements.length != 1) return null;
    assert(memberSet.elements.contains(result));
    return result;
  }

  Set<ClassElement> findNoSuchMethodHolders(DartType type) {
    Set<ClassElement> result = new Set<ClassElement>();
    Selector noSuchMethodSelector = new Selector.noSuchMethod();
    MemberSet memberSet = _memberSetFor(type, noSuchMethodSelector);
    for (Element element in memberSet.elements) {
      ClassElement holder = element.getEnclosingClass();
      if (!identical(holder, compiler.objectClass) &&
          noSuchMethodSelector.applies(element, compiler)) {
        result.add(holder);
      }
    }
    return result;
  }
}

/**
 * A [MemberSet] contains all the possible targets for a selector.
 */
class MemberSet {
  final Set<Element> elements;
  final SourceString name;

  MemberSet(SourceString this.name) : elements = new Set<Element>();

  void add(Element element) {
    elements.add(element);
  }

  bool isEmpty() => elements.isEmpty();
}
