// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:js_ast/js_ast.dart';

class _DeferredStatement extends DeferredStatement {
  final Statement statement;

  _DeferredStatement(this.statement);
}

main() {
  // Defering a statement should not change how it prints.
  var undeferredStatement = js.statement('var x = 3');
  var deferredStatement = _DeferredStatement(undeferredStatement);
  Expect.equals(DebugPrint(undeferredStatement), DebugPrint(deferredStatement));

  // Printing a non-finalized DeferredStatement throws.
  Expect.throws(() => DebugPrint(_DeferredStatement(null)));

  // DeferredStatement with empty Block puts braces.
  Expect.equals(DebugPrint(_DeferredStatement(Block.empty())), '{\n}\n');

  // DeferredStatement in block with nested block gets elided.
  Expect.equals(
      DebugPrint(Block([_DeferredStatement(Block.empty())])), '{\n}\n');
  Expect.equals(
      DebugPrint(Block([
        _DeferredStatement(
            _DeferredStatement(_DeferredStatement(Block.empty())))
      ])),
      '{\n}\n');

  // Nested Blocks in DeferredStatements are elided.
  Expect.equals(
      DebugPrint(Block([
        _DeferredStatement(Block([
          _DeferredStatement(Block.empty()),
          Block.empty(),
          Block([_DeferredStatement(Block.empty()), Block.empty()]),
          _DeferredStatement(_DeferredStatement(Block.empty()))
        ]))
      ])),
      '{\n}\n');

  // DeferredStatement with empty Statement prints semicolon and a newline.
  Expect.equals(DebugPrint(_DeferredStatement(EmptyStatement())), ';\n');
}
