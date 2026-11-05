// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../ir/ir.dart' as ir;
import 'builder.dart';

/// A data segment builder in a module builder.
class DataSegmentBuilder with Builder<ir.DataSegment> {
  final ir.DataSegment dataSegment;
  final BytesBuilder content;

  DataSegmentBuilder(this.dataSegment, [Uint8List? initialContent])
    : content = BytesBuilder() {
    if (initialContent != null && initialContent.isNotEmpty) {
      content.add(initialContent);
    }
  }

  int get index => dataSegment.index;
  ir.Memory? get memory => dataSegment.memory;
  int? get offset => dataSegment.offset;

  bool get isActive => memory != null;
  bool get isPassive => memory == null;

  int get length => content.length;

  /// Append content to the data segment.
  void append(Uint8List data) {
    content.add(data);
    assert(
      isPassive || offset! >= 0 && offset! + content.length <= memory!.minSize,
    );
  }

  @override
  ir.DataSegment forceBuild() {
    dataSegment.content = content.toBytes();
    return dataSegment;
  }
}
