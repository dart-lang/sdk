// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.common;

import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.type.DynamicType;
import com.google.dart.compiler.type.Type;

import java.util.Set;

/**
 * Interface for providing information about the types of expressions to backends.
 */
public interface TypeHeuristic {

  public enum FieldKind {
    GETTER, SETTER
  }

  /**
   * Provides the list of all possible types of the given expression. This list may be used for
   * optimization, and must therefore include all possible types of the given expression. If the
   * type is unknown, it must return a list containing a single {@link DynamicType}.
   */
  public abstract Set<Type> getTypesOf(DartExpression expr);

  /**
   * Returns true if types is <'dynamic'> or the set contains more than one type. false otherwise.
   */
  public abstract boolean isDynamic(Set<Type> types);

  /**
   * Returns the set of method implementations for a given expression.
   */
  public abstract Set<MethodElement> getImplementationsOf(DartExpression expr);

  /**
   * Returns the set of field implementations for a given expression.
   */
  public abstract Set<FieldElement> getFieldImplementationsOf(DartExpression expr,
                                                              FieldKind asGetter);

}
