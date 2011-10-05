// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

/**
 * Kinds of types. Use kinds instead of instanceof for maximum flexibility
 * and sharing of similar implementation classes.
 */
public enum TypeKind {
  DYNAMIC,
  FUNCTION,
  FUNCTION_ALIAS,
  INTERFACE,
  NONE,
  VOID,
  VARIABLE;

  public static TypeKind of(Type type) {
    if (type == null) {
      return NONE;
    } else {
      return type.getKind();
    }
  }
}
