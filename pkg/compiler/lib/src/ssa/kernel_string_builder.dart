// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import 'builder_kernel.dart';
import 'nodes.dart';

/// Visits and concatenates the expressions in a string concatenation.
class KernelStringBuilder extends ir.Visitor {
  final KernelSsaGraphBuilder builder;

  /// The string value generated so far.
  HInstruction result = null;

  KernelStringBuilder(this.builder);

  @override
  void defaultNode(ir.Node node) {
    failedAt(CURRENT_ELEMENT_SPANNABLE, 'Unexpected node: $node');
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
    if (expression.canBePrimitive(builder.closedWorld)) {
      append(stringify(expression));
      return;
    }

    // TODO(efortuna): If we decide to do inlining before finishing constructing
    // the control flow graph, we'd want to do the optimization of
    // calling toString here if the type is provably a string rather than in the
    // optimization phase (which is where we currently do it).

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
        new HStringConcat(left, right, builder.commonMasks.stringType);
    builder.add(instruction);
    return instruction;
  }

  HInstruction stringify(HInstruction expression) {
    HInstruction instruction =
        new HStringify(expression, builder.commonMasks.stringType)
          ..sourceInformation = expression.sourceInformation;
    builder.add(instruction);
    return instruction;
  }
}
