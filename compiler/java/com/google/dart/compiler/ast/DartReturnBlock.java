// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.ast;

import com.google.common.collect.Lists;

/**
 * Represents a Dart block containing a single return statement.
 */
public class DartReturnBlock extends DartBlock {
  private final DartExpression value;

  public DartReturnBlock(DartExpression value) {
    super(Lists.<DartStatement> newArrayList(new DartReturnStatement(value)));
    this.value = value;
    // Set the source information for the synthesized node.
    getStatements().get(0).setSourceInfo(value.getSourceInfo());
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitReturnBlock(this);
  }

  public DartExpression getValue() {
    return value;
  }
}
