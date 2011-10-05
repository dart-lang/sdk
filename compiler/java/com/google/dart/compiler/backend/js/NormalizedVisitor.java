// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.dart.compiler.ast.DartContext;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartVisitable;
import com.google.dart.compiler.ast.DartVisitor;

/**
 * A visitor that always visits the normalized node.
 */
class NormalizedVisitor extends DartVisitor {
  @Override
  protected void doTraverse(DartVisitable visitable, DartContext ctx) {
    DartNode node = (DartNode) visitable;
    super.doTraverse(node.getNormalizedNode(), ctx);
  }
}