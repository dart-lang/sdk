// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.resolver.TypeVariableElement;

/**
 * Represents a type variable, that is the type parameters of a class
 * or interface type. For example, in {@code class Array<E> { ... }},
 * E is a type variable.
 *
 * <p>Each class/interface should have its own unique type variables,
 * one for each type parameter. A class/interface with type parameters
 * is said to be parameterized or generic.
 *
 * <p>Non-static members, constructors, and factories of generic
 * class/interface can refer to type variables of the current class
 * (not of supertypes).
 *
 * <p>When using a generic type, also known as an application or
 * instantiation of the type, the actual type arguments should be
 * substituted for the type variables in the class declaration.
 *
 * <p>For example, given a box, {@code class Box<T> { T value; }}, the
 * type of the expression {@code new Box<String>().value} is
 * {@code String} because we must substitute {@code String} for the
 * the type variable {@code T}.
 */
public interface TypeVariable extends Type {
  // Work around JDK 6 bug. Should @Override getElement().
  TypeVariableElement getTypeVariableElement();
}
