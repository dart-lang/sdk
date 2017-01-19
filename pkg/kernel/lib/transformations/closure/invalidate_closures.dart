// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure.invalidate;

import '../../ast.dart';

class InvalidateClosures extends Transformer {
  FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) {
    invalidate(node.function);
    return node;
  }

  FunctionExpression visitFunctionExpression(FunctionExpression node) {
    invalidate(node.function);
    return node;
  }

  void invalidate(FunctionNode function) {
    var position = function.location;
    function.body = new ExpressionStatement(new Throw(
        new StringLiteral("Calling unconverted closure at $position")))
      ..parent = function;
  }
}
