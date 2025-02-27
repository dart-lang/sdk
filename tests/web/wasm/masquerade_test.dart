// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'dart:js_interop';

import 'package:expect/expect.dart';

const bool isJsCompatibility =
    bool.fromEnvironment('dart.wasm.js_compatibility');

void main() {
  final uint8List = Uint8List(10);
  final uint8ListView = uint8List.buffer.asUint8List(1, 2);
  final uint16ListView = uint8List.buffer.asUint16List(2, 4);

  Expect.equals('Uint8List', uint8List.runtimeType.toString());
  Expect.equals('Uint8List', uint8ListView.runtimeType.toString());
  Expect.equals('Uint16List', uint16ListView.runtimeType.toString());

  final jsString = eval('"foobar"').dartify();
  final jsTypedData = eval('new Uint8Array(10)').dartify();

  Expect.equals('String', jsString.runtimeType.toString());

  if (isJsCompatibility) {
    Expect.equals('Uint8List', jsTypedData.runtimeType.toString());
  } else {
    Expect.equals('JSUint8ArrayImpl', jsTypedData.runtimeType.toString());
  }
}

@JS()
external JSObject eval(String code);
