// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart 'switch' member ('case' or 'default').
 */
public abstract class DartSwitchMember extends DartNode {

  private final NodeList<DartStatement> statements = NodeList.create(this);
  private final DartLabel label;

  public DartSwitchMember(DartLabel label, List<DartStatement> statements) {
    this.label = becomeParentOf(label);
    this.statements.addAll(statements);
  }

  public List<DartStatement> getStatements() {
    return statements;
  }

  public DartLabel getLabel() {
    return label;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    if (label != null) {
      label.accept(visitor);
    }
    statements.accept(visitor);
  }
}
