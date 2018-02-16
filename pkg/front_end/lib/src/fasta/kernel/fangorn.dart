// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.fangorn;

import 'kernel_shadow_ast.dart';

import 'forest.dart' show Forest;

/// A shadow tree factory.
class Fangorn extends Forest<ShadowExpression, ShadowStatement> {
  @override
  ShadowExpression literalInt(int value, int offset) {
    return new ShadowIntLiteral(value)..fileOffset = offset;
  }
}
