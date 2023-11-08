// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../serialize/serialize.dart';
import 'ir.dart';

part 'data_segment.dart';

class DataSegments {
  /// Data segments defined in this module.
  final List<DataSegment> defined;

  DataSegments(this.defined);
}
