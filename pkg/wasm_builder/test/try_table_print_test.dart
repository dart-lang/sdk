// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:wasm_builder/wasm_builder.dart';

void main() {
  testNoEffectTryTable();
  testOneOutputTryTable();
  testFunctionTryTable();
}

void testNoEffectTryTable() {
  final moduleBuilder = ModuleBuilder('test', null);
  final tagType = moduleBuilder.types.defineFunction(const [], const []);
  final definedTag = moduleBuilder.tags.define(tagType);
  final importedTag = moduleBuilder.tags.import('env', 'jsTag', tagType);

  final fnType = moduleBuilder.types.defineFunction(const [], const []);
  final fn = moduleBuilder.functions.define(fnType, 'testNoEffect');
  final b = fn.body;

  final catchAllRefLabel = b.block(const [], const [
    RefType.exn(nullable: true),
  ]);
  final catchAllLabel = b.block();
  final catchRefLabel = b.block(const [], const [RefType.exn(nullable: true)]);
  final catchLabel = b.block();

  b.try_table([
    Catch(definedTag, catchLabel),
    CatchRef(importedTag, catchRefLabel),
    CatchAll(catchAllLabel),
    CatchAllRef(catchAllRefLabel),
  ]);
  b.nop();
  b.end(); // end try_table
  b.return_();

  b.end(); // end catchLabel
  b.return_();

  b.end(); // end catchRefLabel
  b.drop();
  b.return_();

  b.end(); // end catchAllLabel
  b.return_();

  b.end(); // end catchAllRefLabel
  b.drop();
  b.end(); // end function
  fn.build();

  final module = moduleBuilder.build();
  final wat = module.printAsWat();

  Expect.isTrue(wat.contains('(tag \$env.jsTag (import "env" "jsTag"))'));
  Expect.isTrue(wat.contains('(tag \$tag0)'));
  Expect.isTrue(
    wat.contains(
      'try_table \$label4 (catch \$tag0 \$label3) (catch_ref \$env.jsTag \$label2) '
      '(catch_all \$label1) (catch_all_ref \$label0)',
    ),
    'Actual WAT:\n$wat',
  );

  // Verify round-trip serialize/deserialize preserves WAT output.
  final serializer = Serializer();
  module.serialize(serializer);
  final deserialized = Module.deserialize(Deserializer(serializer.data));
  Expect.equals(wat, deserialized.printAsWat());
}

void testOneOutputTryTable() {
  final moduleBuilder = ModuleBuilder('test', null);
  final tagType = moduleBuilder.types.defineFunction(const [
    NumType.i32,
  ], const []);
  final tag = moduleBuilder.tags.define(tagType);

  final fnType = moduleBuilder.types.defineFunction(const [], const [
    NumType.i32,
  ]);
  final fn = moduleBuilder.functions.define(fnType, 'testOneOutput');
  final b = fn.body;

  final catchLabel = b.block(const [], const [NumType.i32]);
  b.try_table([Catch(tag, catchLabel)], const [], const [NumType.i32]);
  b.i32_const(42);
  b.end(); // end try_table
  b.end(); // end catchLabel
  b.end(); // end function
  fn.build();

  final module = moduleBuilder.build();
  final wat = module.printAsWat();

  Expect.isTrue(
    wat.contains('try_table \$label1 (result i32) (catch \$tag0 \$label0)'),
    'Actual WAT:\n$wat',
  );

  final serializer = Serializer();
  module.serialize(serializer);
  final deserialized = Module.deserialize(Deserializer(serializer.data));
  Expect.equals(wat, deserialized.printAsWat());
}

void testFunctionTryTable() {
  final moduleBuilder = ModuleBuilder('test', null);
  final tagType = moduleBuilder.types.defineFunction(const [], const []);
  moduleBuilder.tags.define(tagType);

  final fnType = moduleBuilder.types.defineFunction(
    const [NumType.i32],
    const [NumType.i32, NumType.i64],
  );
  final fn = moduleBuilder.functions.define(fnType, 'testFunctionType');
  final b = fn.body;

  final catchLabel = b.block();
  b.local_get(b.locals[0]);
  b.try_table([CatchAll(catchLabel)], const [NumType.i32], const [
    NumType.i32,
    NumType.i64,
  ]);
  b.i64_const(100);
  b.end(); // end try_table
  b.return_();
  b.end(); // end catchLabel
  b.i32_const(0);
  b.i64_const(0);
  b.end(); // end function
  fn.build();

  final module = moduleBuilder.build();
  final wat = module.printAsWat();

  Expect.isTrue(
    wat.contains(
      'try_table \$label1 (param i32) (result i32) (result i64) (catch_all \$label0)',
    ),
    'Actual WAT:\n$wat',
  );

  final serializer = Serializer();
  module.serialize(serializer);
  final deserialized = Module.deserialize(Deserializer(serializer.data));
  Expect.equals(wat, deserialized.printAsWat());
}
