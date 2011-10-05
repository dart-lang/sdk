// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * The context in which a DartNode visitation occurs. This represents the set of
 * possible operations a DartVisitor subclass can perform on the currently
 * visited node.
 */
public interface DartContext {

  boolean canInsert();

  boolean canRemove();

  void insertAfter(DartVisitable node);

  void insertBefore(DartVisitable node);

  boolean isLvalue();

  void removeMe();

  void replaceMe(DartVisitable node);
}
