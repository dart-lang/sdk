// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../ir/ir.dart' as ir;
import 'builder.dart';

/// The interface for building data segments in a module.
class DataSegmentsBuilder with Builder<ir.DataSegments> {
  final _dataSegmentBuilders = <DataSegmentBuilder>[];
  final _definedDataSegments = <ir.DataSegment>[];

  static const int memoryBlockSize = 0x10000;

  List<ir.DataSegment> get defined => _definedDataSegments;

  /// Defines a new data segment in this module.
  ///
  /// Either [memory] and [offset] must be both specified or both omitted. If
  /// they are specified, the segment becomes an *active* segment, otherwise it
  /// becomes a *passive* segment.
  ///
  /// If [initialContent] is specified, it defines the initial content of the
  /// segment. The content can be extended later.
  DataSegmentBuilder define([
    Uint8List? initialContent,
    ir.Memory? memory,
    int? offset,
  ]) {
    initialContent ??= Uint8List(0);
    assert((memory != null) == (offset != null));
    assert(
      memory == null ||
          offset! >= 0 &&
              offset + initialContent.length <=
                  memory.minSize * memoryBlockSize,
    );
    final dataSegment = ir.DataSegment.withoutContent(
      _definedDataSegments.length,
      memory,
      offset,
    );
    _definedDataSegments.add(dataSegment);
    final builder = DataSegmentBuilder(dataSegment, initialContent);
    _dataSegmentBuilders.add(builder);
    return builder;
  }

  @override
  ir.DataSegments forceBuild() {
    for (final b in _dataSegmentBuilders) {
      b.build();
    }
    return ir.DataSegments(_definedDataSegments);
  }
}
