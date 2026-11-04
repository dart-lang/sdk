// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:wasm_builder/wasm_builder.dart';

void main() {
  testNameMapsAreSorted();
}

/// Name maps must be in increasing index order, otherwise engines (e.g.
/// Firefox 159+) discard the whole name section.
void testNameMapsAreSorted() {
  final builder = ModuleBuilder('test', null);
  final structType = builder.types.defineStruct(
    'S',
    fields: [
      FieldType(NumType.i32),
      FieldType(NumType.i32),
      FieldType(NumType.i32),
    ],
    brand: false,
  );
  structType.fieldNames[2] = 'c';
  structType.fieldNames[0] = 'a';
  structType.fieldNames[1] = 'b';

  final fnType = builder.types.defineFunction([
    RefType.def(structType, nullable: true),
    NumType.i32,
  ], const []);
  final fn = builder.functions.define(fnType, 'f');
  final b = fn.body;
  b.localNames[0] = 'this';
  // Name a non-parameter local before the second parameter.
  b.addLocal(NumType.i32, name: 'local');
  b.localNames[1] = 'param';
  b.end();
  fn.build();

  final deserialized = _roundtrip(builder.build());
  final deserializedFn = deserialized.functions.defined.single;
  Expect.listEquals([0, 1, 2], deserializedFn.localNames.keys.toList());
  Expect.listEquals([
    'this',
    'param',
    'local',
  ], deserializedFn.localNames.values.toList());

  final deserializedStruct = deserialized.types.recursionGroups
      .expand((group) => group)
      .whereType<StructType>()
      .single;
  Expect.listEquals([0, 1, 2], deserializedStruct.fieldNames.keys.toList());
  Expect.listEquals([
    'a',
    'b',
    'c',
  ], deserializedStruct.fieldNames.values.toList());
}

Module _roundtrip(Module module) =>
    Module.deserialize(Deserializer(_serializeModule(module)));

Uint8List _serializeModule(Module module) {
  final s = Serializer();
  module.serialize(s);
  return s.data;
}
