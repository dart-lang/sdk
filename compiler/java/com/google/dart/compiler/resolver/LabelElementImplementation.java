// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartLabel;

class LabelElementImplementation extends AbstractElement implements LabelElement {

  private MethodElement enclosingFunction;

  LabelElementImplementation(DartLabel node, String name, MethodElement enclosingFunction) {
    super(node, name);
    this.enclosingFunction = enclosingFunction;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.LABEL;
  }

  @Override
  public MethodElement getEnclosingFunction() {
    return enclosingFunction;
  }

  @Override
  public void setNode(DartLabel node) {
    super.setNode(node);
  }
}
