// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'runtime.dart';
import 'dart:typed_data';
import 'dart:ffi';

class WasmModule {
  Pointer<WasmerModule> _module;

  WasmModule(Uint8List data) {
    _module = WasmRuntime().compile(data);
  }
}
