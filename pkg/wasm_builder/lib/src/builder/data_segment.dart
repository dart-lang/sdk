// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'data_segments.dart';

/// A data segment builder in a module builder.
class DataSegmentBuilder extends ir.BaseDataSegment
    with Builder<ir.DataSegment> {
  final BytesBuilder content;

  DataSegmentBuilder(
      super.index, Uint8List initialContent, super.memory, super.offset)
      : content = BytesBuilder()..add(initialContent);

  bool get isActive => memory != null;
  bool get isPassive => memory == null;

  int get length => content.length;

  /// Append content to the data segment.
  void append(Uint8List data) {
    content.add(data);
    assert(isPassive ||
        offset! >= 0 && offset! + content.length <= memory!.minSize);
  }

  @override
  ir.DataSegment forceBuild() =>
      ir.DataSegment(index, content.toBytes(), memory, offset);
}
