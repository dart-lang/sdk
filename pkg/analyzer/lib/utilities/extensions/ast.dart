// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';

@Deprecated('Use the method defined on `CompilationUnit` instead.')
extension AstNodeExtension on AstNode {
  /// Returns the minimal covering node for the range of characters beginning at
  /// the [offset] with the given [length].
  ///
  /// Returns `null` if the range is outside the range covered by the receiver.
  ///
  /// The minimal covering node is the node, rooted at the receiver, with the
  /// shortest length whose range completely includes the given range.
  @Deprecated('Use the method defined on `CompilationUnit` instead.')
  AstNode? nodeCovering({required int offset, int length = 0}) {
    return (this as CompilationUnit).nodeCovering(
      offset: offset,
      length: length,
    );
  }
}
