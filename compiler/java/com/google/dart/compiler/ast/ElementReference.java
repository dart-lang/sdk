// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;

/**
 * An {@link ElementReference} is an AST node that references an element, which is
 * used to calculate its type.
 * For example, a method invocation references the {@link MethodElement} that the call
 * resolves to.
 */
public interface ElementReference {
  public Element getReferencedElement();

  public void setReferencedElement(Element element);
}
