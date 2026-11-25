// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:wasm_builder/wasm_builder.dart';

Uint8List serializeModule(Module module) {
  final s = Serializer();
  module.serialize(s);
  return s.data;
}

Module roundtripAndVerifyModule(Module module) {
  final bytes = serializeModule(module);
  final deserialized = Module.deserialize(Deserializer(bytes));
  Expect.listEquals(bytes, serializeModule(deserialized));
  Expect.equals(module.printAsWat(), deserialized.printAsWat());
  return deserialized;
}
