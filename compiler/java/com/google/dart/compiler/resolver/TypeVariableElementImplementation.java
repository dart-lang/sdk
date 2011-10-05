// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeVariable;
import com.google.dart.compiler.type.Types;

/**
 * Represention of a type variable.
 *
 * <p>For example, in {@code class Foo<T> { ... }}, {@code T} is a
 * type variable.
 */
class TypeVariableElementImplementation extends AbstractElement implements TypeVariableElement {

  private final Element owner;
  private TypeVariable type;
  private Type bound;

  TypeVariableElementImplementation(DartNode node, String name, Element owner) {
    super(node, name);
    this.owner = owner;
  }

  @Override
  public TypeVariable getType() {
    return type;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.TYPE_VARIABLE;
  }

  static TypeVariableElementImplementation fromNode(DartTypeParameter node, Element owner) {
    TypeVariableElementImplementation element =
      new TypeVariableElementImplementation(node, node.getName().getTargetName(), owner);
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
  public void setBound(Type bound) {
    this.bound = bound;
  }

  @Override
  public Type getBound() {
    return bound;
  }

  @Override
  public Element getDeclaringElement() {
    return owner;
  }
}
