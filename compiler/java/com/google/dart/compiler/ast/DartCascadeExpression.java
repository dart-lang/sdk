// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Instances of the class {@code DartCascadeExpression} represent a sequence of cascaded expressions:
 * expressions that share a common target. There are three kinds of expressions that can be used in
 * a cascade expression: {@link DartArrayAccess}, {@link DartMethodInvocation} and {@link DartPropertyAccess}.
 * 
 * <pre>
 * cascadeExpression ::=
 *     {@link DartExpression conditionalExpression} cascadeSection*
 * 
 * cascadeSection ::=
 *     '..'  (cascadeSelector arguments*) (assignableSelector arguments*)* (assignmentOperator expressionWithoutCascade)?
 * 
 * cascadeSelector ::=
 *     '[ ' expression '] '
 *   | identifier
 * </pre>
 */
public class DartCascadeExpression extends DartExpression {
  /**
   * The target of the cascade sections.
   */
  private DartExpression target;

  /**
   * The cascade sections sharing the common target.
   */
  private NodeList<DartExpression> cascadeSections = new NodeList<DartExpression>(this);

  /**
   * Initialize a newly created cascade expression.
   * 
   * @param target the target of the cascade sections
   * @param cascadeSections the cascade sections sharing the common target
   */
  public DartCascadeExpression(DartExpression target, List<DartExpression> cascadeSections) {
    this.target = becomeParentOf(target);
    this.cascadeSections.addAll(cascadeSections);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitCascadeExpression(this);
  }

  /**
   * Return the cascade sections sharing the common target.
   * 
   * @return the cascade sections sharing the common target
   */
  public NodeList<DartExpression> getCascadeSections() {
    return cascadeSections;
  }

  /**
   * Return the target of the cascade sections.
   * 
   * @return the target of the cascade sections
   */
  public DartExpression getTarget() {
    return target;
  }

  /**
   * Set the target of the cascade sections to the given expression.
   * 
   * @param target the target of the cascade sections
   */
  public void setTarget(DartExpression target) {
    this.target = becomeParentOf(target);
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(target, visitor);
    cascadeSections.accept(visitor);
  }
}
