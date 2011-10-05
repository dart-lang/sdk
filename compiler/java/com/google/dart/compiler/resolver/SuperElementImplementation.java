// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartSuperExpression;

/**
 * Resolved element for a Dart 'super' expression.
 */
public class SuperElementImplementation extends AbstractElement implements SuperElement {

  public ClassElement classElement;

  public SuperElementImplementation(DartSuperExpression node, ClassElement cls) {
    super(node, "");
    this.classElement = cls;
  }

  public ClassElement getClassElement() {
    return classElement;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.SUPER;
  }
}
