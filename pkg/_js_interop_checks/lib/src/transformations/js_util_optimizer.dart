// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';

/// Replaces js_util methods with inline calls to foreign_helper JS which
/// emits the code as a JavaScript code fragment.
class JsUtilOptimizer extends Transformer {
  final Procedure _jsTarget;
  final Procedure _getPropertyTarget;

  JsUtilOptimizer(CoreTypes coreTypes)
      : _jsTarget =
            coreTypes.index.getTopLevelMember('dart:_foreign_helper', 'JS'),
        _getPropertyTarget =
            coreTypes.index.getTopLevelMember('dart:js_util', 'getProperty') {}

  /// Replaces js_util method calls with lowering straight to JS fragment call.
  ///
  /// Lowers the following types of js_util calls:
  ///  - `getProperty` for any argument types
  @override
  visitStaticInvocation(StaticInvocation node) {
    if (node.target == _getPropertyTarget) {
      node = _lowerGetProperty(node);
    }
    node.transformChildren(this);
    return node;
  }

  /// Lowers the given js_util `getProperty` call to the foreign_helper JS call
  /// for any argument type. Lowers `getProperty(o, name)` to
  /// `JS('Object|Null', '#.#', o, name)`.
  StaticInvocation _lowerGetProperty(StaticInvocation node) {
    Arguments args = node.arguments;
    assert(args.positional.length == 2);
    return StaticInvocation(
        _jsTarget,
        Arguments(
          [
            StringLiteral("Object|Null"),
            StringLiteral("#.#"),
            args.positional.first,
            args.positional.last
          ],
          // TODO(rileyporter): Copy type from getProperty when it's generic.
          types: [DynamicType()],
        ))
      ..fileOffset = node.fileOffset;
  }
}
