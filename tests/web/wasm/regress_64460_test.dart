// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  final bytes = utf8.encode('[12]');
  final decoder = utf8.decoder.fuse(json.decoder);
  late final Object? decoded;
  final sink = decoder.startChunkedConversion(
    ChunkedConversionSink<Object?>.withCallback(
      (values) => decoded = values.single,
    ),
  );

  sink.add(Uint8List.sublistView(bytes, 0, 2)); // [1
  sink.add(Uint8List.sublistView(bytes, 2)); // 2]
  sink.close();

  Expect.listEquals([12], decoded as List);
}
