// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;

import java.util.List;

/**
 * Common superclass for all invocation expressions. In
 * a Dart program, there are different kinds of invocation:
 * <ul>
 * <li> expression.identifier() is a method invocation, where the
 *      receiver is 'expression' and the method name 'identifier'.
 *      This invocation is represented as a DartMethodInvocation.
 *      Examples: A.foo(), this.foo(), super.foo(), bar().foo().
 * </li>
 *
 * <li> identifier() is an unqualified invocation. After the resolver has
 *      resolved 'identifier', the normalizer will transform the node to
 *      either a DartFunctionObjectInvocation or a DartMethodInvocation.
 *      This invocation is represented as a DartUnqualifiedInvocation.
 *      Examples: foo().
 * </li>
 *
 * <li> expression() is a function object invocation.
 *      This invocation is represented as a DartFunctionObjectInvocation.
 *      Examples: bar()(), (A.bar)(), bar[0](), (bar)().
 * </li>
 * </ul>
 *
 */
public abstract class DartInvocation extends DartExpression implements ElementReference {

  private List<DartExpression> args;
  private Element referencedElement;

  public DartInvocation(List<DartExpression> args) {
    this.args = becomeParentOf(args);
  }

  public DartExpression getTarget() {
    return null;
  }

  public List<DartExpression> getArgs() {
    return args;
  }

  public Element getReferencedElement() {
    return referencedElement;
  }

  public void setReferencedElement(Element referencedElement) {
    this.referencedElement = referencedElement;
  }
}
