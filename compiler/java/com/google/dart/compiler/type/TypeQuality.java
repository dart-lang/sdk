// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.resolver.Element;

/**
 * Quality of the {@link Type}.
 */
public enum TypeQuality {
  /**
   * {@link Element} was declared with this {@link Type}.
   */
  EXACT,
  /**
   * {@link Element} was not declared with this {@link Type}, but we can prove that we can treat it
   * as if it was declared with this {@link Type}.
   */
  INFERRED_EXACT,
  /**
   * {@link Element} was not declared this {@link Type}, but we have some reasons to think that it
   * has such {@link Type}, or one of its subtypes.
   */
  INFERRED;

  public static TypeQuality of(Type type) {
    return type.getQuality();
  }

  public static boolean isInferred(Type type) {
    return type.getQuality() != EXACT;
  }

}
