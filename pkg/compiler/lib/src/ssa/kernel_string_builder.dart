// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../compiler.dart';

import 'builder_kernel.dart';
import 'kernel_ast_adapter.dart';
import 'nodes.dart';

/// Visits and concatenates the expressions in a string concatenation.
class KernelStringBuilder extends ir.Visitor {
  final KernelSsaBuilder builder;
  Compiler get compiler => builder.compiler;
  KernelAstAdapter get astAdapter => builder.astAdapter;

  /// The string value generated so far.
  HInstruction result = null;

  KernelStringBuilder(this.builder);

  @override
  void defaultNode(ir.Node node) {
    compiler.reporter
        .internalError(astAdapter.getNode(node), 'Unexpected node.');
  }

  @override
  void defaultExpression(ir.Expression node) {
    node.accept(builder);
    HInstruction expression = builder.pop();

    // We want to use HStringify when:
    //   1. The value is known to be a primitive type, because it might get
    //      constant-folded and codegen has some tricks with JavaScript
    //      conversions.
    //   2. The value can be primitive, because the library stringifier has
    //      fast-path code for most primitives.
    if (expression.canBePrimitive(compiler)) {
      append(stringify(expression));
      return;
    }

    // TODO(het): If toString method is guaranteed to return a string, then call
    // it directly instead of stringify. Or, better yet, do this later in the
    // optimization phase.

    append(stringify(expression));
  }

  @override
  void visitStringConcatenation(ir.StringConcatenation node) {
    node.visitChildren(this);
  }

  void append(HInstruction expression) {
    result = (result == null) ? expression : concat(result, expression);
  }

  HInstruction concat(HInstruction left, HInstruction right) {
    HInstruction instruction =
        new HStringConcat(left, right, builder.backend.stringType);
    builder.add(instruction);
    return instruction;
  }

  HInstruction stringify(HInstruction expression) {
    HInstruction instruction =
        new HStringify(expression, builder.backend.stringType);
    builder.add(instruction);
    return instruction;
  }
}
