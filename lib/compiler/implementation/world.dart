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
   * Returns a [MemberSet] that contains the possible targets of a
   * selector named [member] on a receiver whose type is [type].
   */
  MemberSet _memberSetFor(Type type, SourceString member) {
    assert(compiler !== null);
    ClassElement cls = type.element;
    MemberSet result = new MemberSet(member);
    Element element = cls.lookupMember(member);
    if (element !== null) result.add(element);

    Set<ClassElement> subtypesOfCls = subtypes[cls];
    if (subtypesOfCls !== null) {
      for (ClassElement sub in subtypesOfCls) {
        element = sub.lookupLocalMember(member);
        if (element !== null) result.add(element);
      }
    }
    return result;
  }

  /**
   * Returns the single field with the given name, if such a field
   * exists. If there are multple fields, or none, return null.
   */
  VariableElement locateSingleField(Type type, SourceString member) {
    MemberSet memberSet = _memberSetFor(type, member);
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
    MemberSet memberSet = _memberSetFor(type, Compiler.NO_SUCH_METHOD);
    for (Element element in memberSet.elements) {
      ClassElement holder = element.getEnclosingClass();
      if (holder !== compiler.objectClass &&
          Selector.INVOCATION_2.applies(element, compiler)) {
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
