// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

public interface LabelElement extends Element {
  /**
   * Returns the innermost function where this label is defined.
   */
  public MethodElement getEnclosingFunction();
}
