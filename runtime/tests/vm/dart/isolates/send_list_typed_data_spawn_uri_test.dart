// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test ensures that lists of typed data can be sent to an isolate
// spawned via spawnUri.

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:async_helper/async_helper.dart';

void main(List<String> args) async {
  asyncStart();
  if (args.length == 0) {
    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Uint8List>[
      Uint8List.fromList([1])
    ]);
    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Uint8ClampedList>[
      Uint8ClampedList.fromList([1])
    ]);
    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Uint16List>[
      Uint16List.fromList([1])
    ]);
    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Uint32List>[
      Uint32List.fromList([1])
    ]);
    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Uint64List>[
      Uint64List.fromList([1])
    ]);

    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Int8List>[
      Int8List.fromList([1])
    ]);
    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Int16List>[
      Int16List.fromList([1])
    ]);
    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Int32List>[
      Int32List.fromList([1])
    ]);
    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Int64List>[
      Int64List.fromList([1])
    ]);

    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Float32List>[
      Float32List.fromList([1])
    ]);
    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Float64List>[
      Float64List.fromList([1])
    ]);

    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Int32x4List>[
      Int32x4List.fromList([Int32x4(1, 2, 3, 4)])
    ]);
    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Float32x4List>[
      Float32x4List.fromList([Float32x4(1, 2, 3, 4)])
    ]);
    await Isolate.spawnUri(Platform.script, [
      "42"
    ], <Float64x2List>[
      Float64x2List.fromList([Float64x2(1, 2)])
    ]);
  }
  asyncEnd();
}
