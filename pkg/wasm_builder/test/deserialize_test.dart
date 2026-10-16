// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:wasm_builder/wasm_builder.dart';

void main() {
  testSimdInstructionDeserialize();
  testBrOnCastRoundTrip();
}

void testSimdInstructionDeserialize() {
  final builder = ModuleBuilder('test', null, allowRelaxedSimd: true);
  final fnType = builder.types.defineFunction(
    const [NumType.v128, NumType.v128],
    const [NumType.v128],
  );
  final fn = builder.functions.define(fnType);
  fn.body
    ..local_get(fn.locals[0])
    ..local_get(fn.locals[1])
    ..i32x4_add()
    ..local_get(fn.locals[0])
    ..f32x4_relaxed_min()
    ..end();
  fn.build();

  roundtripSerializeAndCompare(builder.build());
}

void testBrOnCastRoundTrip() {
  final builder = ModuleBuilder('test', null);
  final structType = builder.types.defineStruct('S', brand: false);
  for (final inputNullable in [false, true]) {
    for (final targetNullable in [false, true]) {
      if (!inputNullable && targetNullable) continue;
      final inputRef = RefType.any(nullable: inputNullable);
      final targetRef = RefType.def(structType, nullable: targetNullable);
      final fnType = builder.types.defineFunction([inputRef], const []);
      final fn = builder.functions.define(fnType);
      final b = fn.body;

      final castBlock = b.block(const [], [targetRef]);
      b.local_get(fn.locals[0]);
      b.br_on_cast(castBlock, inputRef, targetRef);
      b.drop();
      b.unreachable();
      b.end();
      b.drop();

      final failResult = RefType.any(
        nullable: inputNullable && !targetNullable,
      );
      final failBlock = b.block(const [], [failResult]);
      b.local_get(fn.locals[0]);
      b.br_on_cast_fail(failBlock, inputRef, targetRef);
      b.drop();
      b.unreachable();
      b.end();
      b.drop();

      b.end();
      fn.build();
    }
  }

  roundtripSerializeAndCompare(builder.build());
}

void roundtripSerializeAndCompare(Module module) {
  final bytes = _serializeModule(module);
  final deserialized = Module.deserialize(Deserializer(bytes));
  Expect.listEquals(bytes, _serializeModule(deserialized));
  Expect.equals(module.printAsWat(), deserialized.printAsWat());
}

Uint8List _serializeModule(Module module) {
  final s = Serializer();
  module.serialize(s);
  return s.data;
}
