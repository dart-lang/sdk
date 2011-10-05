// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Interface to be implemented by a class that can be visited by {@link DartVisitor}.
 */
public interface DartVisitable {

  /**
   * Causes this object to have the visitor visit itself and its children.
   *
   * @param visitor the visitor that should traverse this node
   * @param ctx the context of an existing traversal
   */
  void traverse(DartVisitor v, DartContext ctx);
}
