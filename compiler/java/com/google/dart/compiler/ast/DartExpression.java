// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.type.Type;

/**
 * Abstract base class for Dart expressions.
 */
public abstract class DartExpression extends DartNode {
  Type type;

  public boolean isAssignable() {
    // By default you cannot assign to expressions.
    return false;
  }

  @Override
  public DartExpression getNormalizedNode() {
    return (DartExpression) super.getNormalizedNode();
  }

  @Override
  public void setType(Type type) {
   this.type = type;
  }

  @Override
  public Type getType() {
    return type;
  }
}
