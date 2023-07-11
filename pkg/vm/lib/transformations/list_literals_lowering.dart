// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

/// VM-specific specialization of list literals.
///
/// Transforms list literals of small length into calls to specialized
/// list constructors.
class ListLiteralsLowering {
  // Number of specialized factories for list literals.
  static const numSpecializedFactories = 8;

  final CoreTypes coreTypes;

  // Default _GrowableList(int length) factory. Used to generate empty list
  // literals.
  final Procedure _defaultFactory;

  // Specialized _GrowableList._literalN(e1, ..., eN) factories.
  final List<Procedure?> _specializedFactories =
      List<Procedure?>.filled(numSpecializedFactories, null);

  ListLiteralsLowering(this.coreTypes)
      : _defaultFactory =
            coreTypes.index.getProcedure('dart:core', '_GrowableList', '');

  Procedure getSpecializedFactory(int length) =>
      (_specializedFactories[length - 1] ??= coreTypes.index
          .getProcedure('dart:core', '_GrowableList', '_literal$length'));

  Expression transformListLiteral(ListLiteral node) {
    if (node.isConst) {
      throw 'Unexpected constant ListLiteral node'
          ' (such nodes should be converted to ConstantExpression): $node';
    }
    final int length = node.expressions.length;
    if (length == 0) {
      return StaticInvocation(_defaultFactory,
          Arguments([IntLiteral(0)], types: [node.typeArgument]))
        ..fileOffset = node.fileOffset;
    } else if (length <= numSpecializedFactories) {
      final factory = getSpecializedFactory(length);
      return StaticInvocation(
          factory, Arguments(node.expressions, types: [node.typeArgument]))
        ..fileOffset = node.fileOffset;
    }
    return node;
  }
}
