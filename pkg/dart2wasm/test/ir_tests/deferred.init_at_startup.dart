// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// functionFilter=write|read|#init
// tableFilter=cross-module-funcs
// globalFilter=array
// typeFilter=NoMatch
// compilerOption=--enable-deferred-loading
// compilerOption=--no-minify

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
