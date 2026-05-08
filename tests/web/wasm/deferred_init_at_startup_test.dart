// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// dart2wasmOptions=--enable-deferred-loading --extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

import '' deferred as D;

import 'package:expect/expect.dart';

void main() async {
  await D.loadLibrary();

  D.write();
  Expect.equals('hello', D.read());
}

void write() => array[0] = 'hello';
String read() => array[0]!;

@pragma("wasm:initialize-at-startup")
final WasmArray<String?> array = WasmArray<String?>(1);
