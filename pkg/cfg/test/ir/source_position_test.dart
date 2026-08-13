// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/source_position.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:test/test.dart';

void main() {
  test('simple', () {
    final pos = SourcePosition(42);
    expect(SourcePosition(42, inlineContextId: noInlineContext), equals(pos));
    expect(SourcePosition(43), isNot(equals(pos)));
    expect(noPosition, isNot(equals(pos)));
    expect(pos.fileOffset, equals(42));
    expect(pos.inlineContextId, equals(noInlineContext));
  });

  test('noOffset', () {
    final pos = SourcePosition(ast.TreeNode.noOffset);
    expect(
      SourcePosition(ast.TreeNode.noOffset, inlineContextId: noInlineContext),
      equals(pos),
    );
    expect(SourcePosition(0), isNot(equals(pos)));
    expect(noPosition, isNot(equals(pos)));
    expect(pos.fileOffset, equals(ast.TreeNode.noOffset));
  });

  test('inline context', () {
    final ctx1 = InlineContextId(1);
    final ctx2 = InlineContextId(2);

    final pos1 = SourcePosition(42);
    final pos2 = SourcePosition(42, inlineContextId: ctx1);
    final pos3 = SourcePosition(42, inlineContextId: ctx2);

    expect(pos1, isNot(equals(noPosition)));
    expect(pos2, isNot(equals(noPosition)));
    expect(pos3, isNot(equals(noPosition)));

    expect(pos2, isNot(equals(pos1)));
    expect(pos3, isNot(equals(pos1)));
    expect(pos3, isNot(equals(pos2)));

    expect(pos1.fileOffset, equals(42));
    expect(pos2.fileOffset, equals(42));
    expect(pos3.fileOffset, equals(42));

    expect(pos1.inlineContextId, equals(noInlineContext));
    expect(pos2.inlineContextId, equals(ctx1));
    expect(pos3.inlineContextId, equals(ctx2));
  });
}
