// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeVariable;
import com.google.dart.compiler.type.Types;

/**
 * Representation of a type variable.
 * 
 * <p>
 * For example, in {@code class Foo<T> ... } , {@code T} is a type variable.
 */
class TypeVariableElementImplementation extends AbstractNodeElement implements TypeVariableNodeElement {

  private final EnclosingElement owner;
  private TypeVariable type;
  private Type bound;
  private final DartTypeNode boundNode;

  TypeVariableElementImplementation(String name, Type bound) {
    this(null, name, null);
    this.bound = bound;
  }

  TypeVariableElementImplementation(DartTypeParameter node, String name, EnclosingElement owner) {
    super(node, name);
    this.owner = owner;
    this.boundNode = node != null ? node.getBound() : null;
  }

  @Override
  public TypeVariable getType() {
    return type;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.TYPE_VARIABLE;
  }

  static TypeVariableElementImplementation fromNode(DartTypeParameter node, EnclosingElement owner) {
    TypeVariableElementImplementation element =
        new TypeVariableElementImplementation(node, node.getName().getName(), owner);
    element.setType(Types.typeVariable(element));
    return element;
  }

  @Override
  public TypeVariable getTypeVariable() {
    return getType();
  }

  @Override
  void setType(Type type) {
    this.type = (TypeVariable) type;
  }

  @Override
  public Type getBound() {
    if (boundNode != null) {
      return boundNode.getType();
    }
    // no explicit bound, try to get Object
    if (bound == null) {
      if (owner instanceof ClassElement) {
        Scope libraryScope = ((ClassElement) owner).getLibrary().getScope();
        bound = libraryScope.findElement(null, "Object").getType();
      }
    }
    return bound;
  }

  @Override
  public Element getDeclaringElement() {
    return owner;
  }

  @Override
  public EnclosingElement getEnclosingElement() {
    return owner;
  }
}
