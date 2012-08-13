// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;


/**
 * Abstract base class for Dart expressions.
 */
public abstract class DartExpression extends DartNode {
  
  private Object invocationParameterId;

  public boolean isAssignable() {
    // By default you cannot assign to expressions.
    return false;
  }

  /**
   * @return the ID of parameter, {@link Integer} index of positional, {@link String} name if named.
   */
  public Object getInvocationParameterId() {
    return invocationParameterId;
  }

  /**
   * @see #getInvocationParameterId()
   */
  public void setInvocationParameterId(Object parameterId) {
    this.invocationParameterId = parameterId;
  }
}
