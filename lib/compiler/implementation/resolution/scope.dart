// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

abstract class Scope {
  /**
   * Adds [element] to this scope. This operation is only allowed on mutable
   * scopes such as [MethodScope] and [BlockScope].
   */
  abstract Element add(Element element);

  /**
   * Looks up the [Element] for [name] in this scope.
   */
  abstract Element lookup(SourceString name);

  static Scope buildEnclosingScope(Element element) {
    return element.enclosingElement != null
        ? element.enclosingElement.buildScope() : element.buildScope();
  }
}

abstract class NestedScope extends Scope {
  final Scope parent;

  NestedScope(this.parent);

  Element lookup(SourceString name) {
    Element result = localLookup(name);
    if (result != null) return result;
    return parent.lookup(name);
  }

  abstract Element localLookup(SourceString name);

  static Scope buildEnclosingScope(Element element) {
    return element.enclosingElement != null
        ? element.enclosingElement.buildScope() : element.buildScope();
  }
}

/**
 * [TypeDeclarationScope] defines the outer scope of a type declaration in
 * which the declared type variables and the entities in the enclosing scope are
 * available but where declared and inherited members are not available. This
 * scope is only used for class/interface declarations during resolution of the
 * class hierarchy. In all other cases [ClassScope] is used.
 */
class TypeDeclarationScope extends NestedScope {
  final TypeDeclarationElement element;

  TypeDeclarationScope(parent, this.element)
      : super(parent) {
    assert(parent != null);
  }

  Element add(Element newElement) {
    throw "Cannot add element to TypeDeclarationScope";
  }

  Element lookupTypeVariable(SourceString name) {
    Link<DartType> typeVariableLink = element.typeVariables;
    while (!typeVariableLink.isEmpty()) {
      TypeVariableType typeVariable = typeVariableLink.head;
      if (typeVariable.name == name) {
        return typeVariable.element;
      }
      typeVariableLink = typeVariableLink.tail;
    }
    return null;
  }

  Element localLookup(SourceString name) => lookupTypeVariable(name);

  String toString() =>
      'TypeDeclarationScope($element)';
}

abstract class MutableScope extends NestedScope {
  final Map<SourceString, Element> elements;

  MutableScope(Scope parent)
      : super(parent),
        this.elements = new Map<SourceString, Element>() {
    assert(parent != null);
  }

  Element add(Element newElement) {
    if (elements.containsKey(newElement.name)) {
      return elements[newElement.name];
    }
    elements[newElement.name] = newElement;
    return newElement;
  }

  Element localLookup(SourceString name) => elements[name];
}

class MethodScope extends MutableScope {
  final Element element;

  MethodScope(Scope parent, this.element)
      : super(parent);

  String toString() => 'MethodScope($element${elements.getKeys()})';
}

class BlockScope extends MutableScope {
  BlockScope(Scope parent) : super(parent);

  String toString() => 'BlockScope(${elements.getKeys()})';
}

/**
 * [ClassScope] defines the inner scope of a class/interface declaration in
 * which declared members, declared type variables, entities in the enclosing
 * scope and inherited members are available, in the given order.
 */
class ClassScope extends TypeDeclarationScope {
  ClassElement get element => super.element;

  ClassScope(Scope parentScope, ClassElement element)
      : super(parentScope, element)  {
    assert(parent != null);
  }

  Element localLookup(SourceString name) {
    Element result = element.lookupLocalMember(name);
    if (result != null) return result;
    return super.localLookup(name);
  }

  Element lookup(SourceString name) {
    Element result = localLookup(name);
    if (result != null) return result;
    result = parent.lookup(name);
    if (result != null) return result;
    return element.lookupSuperMember(name);
  }

  Element add(Element newElement) {
    throw "Cannot add an element in a class scope";
  }

  String toString() => 'ClassScope($element)';
}

class LibraryScope implements Scope {
  final LibraryElement library;

  LibraryScope(LibraryElement this.library);

  Element localLookup(SourceString name) => library.find(name);
  Element lookup(SourceString name) => localLookup(name);

  Element add(Element newElement) {
    throw "Cannot add an element to a library scope";
  }

  String toString() => 'LibraryScope($library)';
}
