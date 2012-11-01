// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.NodeElement;

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
public abstract class DartInvocation extends DartExpression {

  private final NodeList<DartExpression> arguments = NodeList.create(this);
  private NodeElement element;

  public DartInvocation(List<DartExpression> arguments) {
    if (arguments != null && !arguments.isEmpty()) {
      this.arguments.addAll(arguments);
    }
  }

  public DartExpression getTarget() {
    return null;
  }

  public List<DartExpression> getArguments() {
    return arguments;
  }

  @Override
  public NodeElement getElement() {
    return element;
  }

  @Override
  public void setElement(Element element) {
    this.element = (NodeElement) element;
  }
}
