// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;


/**
 * Abstract base class for Dart expressions.
 */
public abstract class DartExpression extends DartNode {

  public boolean isAssignable() {
    // By default you cannot assign to expressions.
    return false;
  }

  @Override
  public DartExpression getNormalizedNode() {
    return (DartExpression) super.getNormalizedNode();
  }
}
