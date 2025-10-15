// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:wasm_builder/wasm_builder.dart';

void main(List<String> args) {
  final input = args[0];
  final wasmBytes = File(input).readAsBytesSync();

  final deserializer = Deserializer(wasmBytes);
  final module = Module.deserialize(deserializer);
  print(module.printAsWat());
}
