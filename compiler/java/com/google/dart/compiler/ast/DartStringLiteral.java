// Copyright (c) 2011, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.collect.ImmutableList;

import java.util.List;

/**
 * Represents a Dart string literal value.
 */
public class DartStringLiteral extends DartLiteral {

  public static DartStringLiteral get(String x) {
    return new DartStringLiteral(x, null);
  }

  public static DartStringLiteral get(String x, List<DartStringLiteral> parts) {
    return new DartStringLiteral(x, parts);
  }

  private final String value;
  private final List<DartStringLiteral> parts;

  private DartStringLiteral(String value, List<DartStringLiteral> parts) {
    this.value = value;
    this.parts = parts;
  }

  public String getValue() {
    return value;
  }

  /**
   * @return the adjacent literals (separated only by whitespace) which consist this
   *         {@link DartStringLiteral}.
   */
  public List<DartStringLiteral> getParts() {
    if (parts == null) {
      return ImmutableList.of(this);
    }
    return parts;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitStringLiteral(this);
  }
}
