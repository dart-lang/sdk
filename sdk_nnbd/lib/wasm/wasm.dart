// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// {@category VM}
/// {@nodoc}
library dart.wasm;

int callWasm(String name, int arg) {
  return _callWasm(name, arg);
}

external int _callWasm(String name, int arg);
