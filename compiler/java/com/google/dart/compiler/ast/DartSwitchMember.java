// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart 'switch' member ('case' or 'default').
 */
public abstract class DartSwitchMember extends DartNode {

  private final NodeList<DartStatement> statements = NodeList.create(this);
  private final NodeList<DartLabel> labels = NodeList.create(this);

  public DartSwitchMember(List<DartLabel> labels, List<DartStatement> statements) {
    this.labels.addAll(labels);
    this.statements.addAll(statements);
  }

  public List<DartStatement> getStatements() {
    return statements;
  }

  public List<DartLabel> getLabels() {
    return labels;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    labels.accept(visitor);
    statements.accept(visitor);
  }
}
