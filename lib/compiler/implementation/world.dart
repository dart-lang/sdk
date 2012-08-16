// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class World {
  Compiler compiler;  // Set in populate().
  final Map<ClassElement, Set<ClassElement>> subtypes;

  World() : subtypes = new Map<ClassElement, Set<ClassElement>>();

  void populate(Compiler compiler) {
    void addSubtypes(ClassElement cls) {
      if (cls.resolutionState != ClassElement.STATE_DONE) {
        compiler.internalErrorOnElement(
            cls, 'Class "${cls.name.slowToString()}" is not resolved.');
      }
      for (Type type in cls.allSupertypes) {
        Set<Element> subtypesOfCls =
          subtypes.putIfAbsent(type.element, () => new Set<ClassElement>());
        subtypesOfCls.add(cls);
      }
    }

    compiler.resolverWorld.instantiatedClasses.forEach(addSubtypes);

    // Mark the world as populated.
    assert(compiler !== null);
    this.compiler = compiler;
  }

  /**
   * Returns a [MemberSet] that contains the possible targets of the given
   * [selector] on a receiver with the given [type].
   */
  MemberSet _memberSetFor(Type type, Selector selector) {
    assert(compiler !== null);
    ClassElement cls = type.element;
    SourceString name = selector.name;
    LibraryElement library = selector.library;
    MemberSet result = new MemberSet(name);
    Element element = cls.lookupSelector(selector);
    if (element !== null) result.add(element);

    bool isPrivate = name.isPrivate();
    Set<ClassElement> subtypesOfCls = subtypes[cls];
    if (subtypesOfCls !== null) {
      for (ClassElement sub in subtypesOfCls) {
        // Private members from a different library are not visible.
        if (isPrivate && sub.getLibrary() != library) continue;
        element = sub.lookupLocalMember(name);
        if (element !== null) result.add(element);
      }
    }
    return result;
  }

  /**
   * Returns the single field with the given [selector]. If there is no such
   * field, or there are multiple possible fields returns [:null:].
   */
  VariableElement locateSingleField(Type type, Selector selector) {
    MemberSet memberSet = _memberSetFor(type, selector);
    int fieldCount = 0;
    int nonFieldCount = 0;
    VariableElement field;
    memberSet.elements.forEach((Element element) {
      if (element.isField()) {
        field = element;
        fieldCount++;
      } else {
        nonFieldCount++;
      }
    });
    return (fieldCount == 1 && nonFieldCount == 0) ? field : null;
  }

  Set<ClassElement> findNoSuchMethodHolders(Type type) {
    Set<ClassElement> result = new Set<ClassElement>();
    Selector noSuchMethodSelector = new Selector.noSuchMethod();
    MemberSet memberSet = _memberSetFor(type, noSuchMethodSelector);
    for (Element element in memberSet.elements) {
      ClassElement holder = element.getEnclosingClass();
      if (holder !== compiler.objectClass &&
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
