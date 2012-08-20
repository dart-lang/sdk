// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;


/**
 * Instances of the class {@code DartAnnotation} represent metadata that can be associated with an
 * AST node.
 * 
 * <pre>
 * metadata ::=
 *     annotation*
 * 
 * annotation ::=
 *     '@' qualified (‘.’ identifier)? arguments?
 * </pre>
 */
public class DartAnnotation extends DartNode {
  private DartExpression name;

  private NodeList<DartExpression> arguments = NodeList.create(this);

  public DartAnnotation(DartExpression name, List<DartExpression> arguments) {
    this.name = becomeParentOf(name);
    if (arguments != null) {
      this.arguments.addAll(arguments);
    }
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitAnnotation(this);
  }

  public DartExpression getName() {
    return name;
  }

  public NodeList<DartExpression> getArguments() {
    return arguments;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(name, visitor);
    arguments.accept(visitor);
  }
}
