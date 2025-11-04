// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Context when there are no inlined functions.
const InlineContextId noInlineContext = InlineContextId._(0);

/// Idenifies a call stack of inlined functions along with
/// source positions of each inlined call site.
extension type const InlineContextId._(int index) {
  static const int maxIndex = 0x7fffffff;

  factory InlineContextId(int index) {
    if (index <= 0 || index > maxIndex) {
      throw ArgumentError('Inline context id $index is out of range');
    }
    return InlineContextId._(index);
  }
}

/// Invalid source position.
const SourcePosition noPosition = SourcePosition._(-1);

/// Position in the source file.
extension type const SourcePosition._(int _raw) {
  static const int fileOffsetMask = 0xffffffff;
  static const int inlineContextShift = 32;

  factory SourcePosition(
    int fileOffset, {
    InlineContextId inlineContextId = noInlineContext,
  }) {
    final int fileOffsetPlus1 = fileOffset + 1;
    if ((fileOffsetPlus1 & fileOffsetMask) != fileOffsetPlus1) {
      throw ArgumentError('File offset $fileOffset is out of range');
    }
    return SourcePosition._(
      (inlineContextId.index << inlineContextShift) | fileOffsetPlus1,
    );
  }

  /// Offset in the source file of enclosing function.
  ///
  /// Same as `TreeNode.fileOffset`.
  int get fileOffset => (_raw & fileOffsetMask) - 1;

  /// Identifier of the inline context.
  InlineContextId get inlineContextId =>
      InlineContextId._(_raw >> inlineContextShift);
}
