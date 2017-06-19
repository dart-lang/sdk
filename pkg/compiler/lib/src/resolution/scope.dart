// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.scope;

import '../elements/resolution_types.dart';
import '../elements/elements.dart';

abstract class Scope {
  /**
   * If an [Element] named `element.name` has already been added to this
   * [Scope], return that element and make no changes. If no such element has
   * been added, add the given [element] to this [Scope], and return [element].
   * Note that this operation is only allowed on mutable scopes such as
   * [MethodScope] and [BlockScope].
   */
  Element add(Element element);

  /**
   * Looks up the [Element] for [name] in this scope.
   */
  Element lookup(String name);

  static Scope buildEnclosingScope(Element element) {
    return element.enclosingElement != null
        ? element.enclosingElement.buildScope()
        : element.buildScope();
  }
}

abstract class NestedScope extends Scope {
  final Scope parent;

  NestedScope(this.parent);

  Element lookup(String name) {
    Element result = localLookup(name);
    if (result != null) return result;
    return parent.lookup(name);
  }

  Element localLookup(String name);
}

class VariableDefinitionScope extends NestedScope {
  final String variableName;
  bool variableReferencedInInitializer = false;

  VariableDefinitionScope(Scope parent, this.variableName) : super(parent);

  Element localLookup(String name) {
    if (name == variableName) {
      variableReferencedInInitializer = true;
    }
    return null;
  }

  Element add(Element newElement) {
    throw "Cannot add element to VariableDefinitionScope";
  }
}

/// [TypeVariablesScope] defines the outer scope in a context where some type
/// variables are declared and the entities in the enclosing scope are
/// available, but where locally declared and inherited members are not
/// available.
abstract class TypeVariablesScope extends NestedScope {
  List<ResolutionDartType> get typeVariables;

  TypeVariablesScope(Scope parent) : super(parent) {
    assert(parent != null);
  }

  Element add(Element newElement) {
    throw "Cannot add element to TypeDeclarationScope";
  }

  Element lookupTypeVariable(String name) {
    for (ResolutionTypeVariableType type in typeVariables) {
      if (type.name == name) {
        return type.element;
      }
    }
    return null;
  }

  Element localLookup(String name) => lookupTypeVariable(name);
}

/**
 * [TypeDeclarationScope] defines the outer scope of a type declaration in
 * which the declared type variables and the entities in the enclosing scope are
 * available but where declared and inherited members are not available. This
 * scope is used for class declarations during resolution of the class hierarchy
 * and when resolving typedef signatures. In other cases [ClassScope] is used.
 */
class TypeDeclarationScope extends TypeVariablesScope {
  final GenericElement element;

  @override
  List<ResolutionDartType> get typeVariables => element.typeVariables;

  TypeDeclarationScope(Scope parent, this.element) : super(parent);

  String toString() => 'TypeDeclarationScope($element)';
}

abstract class MutableScope extends NestedScope {
  final Map<String, Element> elements;

  MutableScope(Scope parent)
      : this.elements = new Map<String, Element>(),
        super(parent) {
    assert(parent != null);
  }

  Element add(Element newElement) {
    if (elements.containsKey(newElement.name)) {
      return elements[newElement.name];
    }
    elements[newElement.name] = newElement;
    return newElement;
  }

  Element localLookup(String name) => elements[name];
}

/**
 * [ExtensionScope] enables the creation of an extended version of an
 * existing [NestedScope], received during construction and stored in
 * [extendee]. An [ExtensionScope] will treat an added `element` as conflicting
 * if an element `e` where `e.name == element.name` exists among the elements
 * added to this [ExtensionScope], or among the ones added to [extendee]
 * (according to `extendee.localLookup`). In this sense, it represents the
 * union of the bindings stored locally in [elements] and the bindings in
 * [extendee], not a new scope which is nested inside [extendee].
 *
 * Note that it is required that no bindings are added to [extendee] during the
 * lifetime of this [ExtensionScope]: That would enable duplicates to be
 * introduced into the extended scope consisting of [this] plus [extendee]
 * without detection.
 */
class ExtensionScope extends Scope {
  final NestedScope extendee;
  final Map<String, Element> elements;

  ExtensionScope(this.extendee) : this.elements = new Map<String, Element>() {
    assert(extendee != null);
  }

  Element lookup(String name) {
    Element result = elements[name];
    if (result != null) return result;
    return extendee.lookup(name);
  }

  Element add(Element newElement) {
    if (elements.containsKey(newElement.name)) {
      return elements[newElement.name];
    }
    Element existing = extendee.localLookup(newElement.name);
    if (existing != null) return existing;
    elements[newElement.name] = newElement;
    return newElement;
  }
}

class MethodScope extends MutableScope {
  final Element element;

  MethodScope(Scope parent, this.element) : super(parent);

  String toString() => 'MethodScope($element${elements.keys.toList()})';
}

class BlockScope extends MutableScope {
  BlockScope(Scope parent) : super(parent);

  String toString() => 'BlockScope(${elements.keys.toList()})';
}

/**
 * [ClassScope] defines the inner scope of a class/interface declaration in
 * which declared members, declared type variables, entities in the enclosing
 * scope and inherited members are available, in the given order.
 */
class ClassScope extends TypeDeclarationScope {
  ClassElement get element => super.element;

  ClassScope(Scope parentScope, ClassElement element)
      : super(parentScope, element) {
    assert(parent != null);
  }

  Element localLookup(String name) {
    Element result = element.lookupLocalMember(name);
    if (result != null) return result;
    return super.localLookup(name);
  }

  Element lookup(String name) {
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

  Element localLookup(String name) => library.find(name);
  Element lookup(String name) => localLookup(name);

  Element add(Element newElement) {
    throw "Cannot add an element to a library scope";
  }

  String toString() => 'LibraryScope($library)';
}
