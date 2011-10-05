// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.Modifiers;

class ConstructorElementImplementation extends MethodElementImplementation
    implements ConstructorElement {
  private final ClassElement constructorType;

  private ConstructorElementImplementation(DartMethodDefinition node,
                             String name,
                             ClassElement declaringClass,
                             ClassElement constructorType) {
    super(node, name, declaringClass);
    this.constructorType = constructorType;
  }

  private ConstructorElementImplementation(String name,
                             ClassElement declaringClass,
                             ClassElement constructorType) {
    super(name, declaringClass, Modifiers.NONE.makeFactory());
    this.constructorType = constructorType;
  }

  public ClassElement getConstructorType() {
    return constructorType;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.CONSTRUCTOR;
  }

  @Override
  public boolean isConstructor() {
    return true;
  }

  public static ConstructorElementImplementation fromMethodNode(DartMethodDefinition node,
                                                  String name,
                                                  ClassElement declaringClass,
                                                  ClassElement constructorType) {
    return new ConstructorElementImplementation(node, name, declaringClass, constructorType);
  }

  public static ConstructorElementImplementation named(String name,
                                         ClassElement declaringClass,
                                         ClassElement constructorType) {
    return new ConstructorElementImplementation(name, declaringClass, constructorType);
  }
}
