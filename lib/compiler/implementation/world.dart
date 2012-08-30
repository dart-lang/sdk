// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class World {
  Compiler compiler;  // Set in populate().
  final Map<ClassElement, Set<ClassElement>> subtypes;

  World() : subtypes = new Map<ClassElement, Set<ClassElement>>();

  void populate(Compiler compiler) {
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

    // Mark the world as populated.
    assert(compiler !== null);
    this.compiler = compiler;
  }

  /**
   * Returns a [MemberSet] that contains the possible targets of the given
   * [selector] on a receiver with the given [type]. This includes all sub
   * types.
   */
  MemberSet _memberSetFor(DartType type, Selector selector) {
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
   * Returns the field in [type] described by the given [selector].
   * If no such field exists, or a subclass overrides the field
   * returns [:null:].
   */
  VariableElement locateSingleField(DartType type, Selector selector) {
    MemberSet memberSet = _memberSetFor(type, selector);
    ClassElement cls = type.element;
    Element result = cls.lookupSelector(selector);
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
