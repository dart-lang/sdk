// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

// `entry-point` needed to make sure the class will be in the class hierarchy
// in programs without records.
@pragma('wasm:entry-point')
abstract class Record {
  _Type get _recordRuntimeType;

  // An instance member needs a call from Dart code to be properly included in
  // the dispatch table. Hence we use an inlined static wrapper as entry point.
  @pragma("wasm:entry-point")
  @pragma("wasm:prefer-inline")
  static _Type _getRecordRuntimeType(Record record) =>
      record._recordRuntimeType;
}
