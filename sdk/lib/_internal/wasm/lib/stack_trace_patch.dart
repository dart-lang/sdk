// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@pragma("wasm:import", "dart2wasm.getCurrentStackTrace")
external String _getCurrentStackTrace();

@patch
class StackTrace {
  @patch
  @pragma("wasm:entry-point")
  static StackTrace get current {
    return _StringStackTrace(_getCurrentStackTrace());
  }
}
