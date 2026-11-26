// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:wasm_builder/wasm_builder.dart';

import 'test_utils.dart';

void main() {
  testRefTestCollectsTargetType();
  testActiveExpressionElementSegmentCollectsTypes();
}

void testRefTestCollectsTargetType() {
  final builder = ModuleBuilder('test', null);
  final s = builder.types.defineStruct('S', brand: false);
  final fnType = builder.types.defineFunction(
    const [RefType.any(nullable: true)],
    const [NumType.i32],
  );
  final fn = builder.functions.define(fnType);
  fn.body
    ..local_get(fn.locals[0])
    ..ref_test(RefType.def(s, nullable: false))
    ..end();
  fn.build();

  final module = builder.build();
  Expect.isTrue(module.types.defined.contains(s));
  roundtripAndVerifyModule(module);
}

void testActiveExpressionElementSegmentCollectsTypes() {
  final builder = ModuleBuilder('test', null);
  final s = builder.types.defineStruct('S', brand: false);
  final table = builder.tables.define(const RefType.any(nullable: true), 1);
  final initExpr =
      InstructionsBuilder(builder, const [], const [
          RefType.any(nullable: true),
        ], constantExpression: true)
        ..struct_new_default(s)
        ..end();
  builder.elements
      .activeExpressionSegmentBuilderFor(table)
      .setExpressionAt(0, initExpr);

  final module = builder.build();
  Expect.isTrue(module.types.defined.contains(s));
  roundtripAndVerifyModule(module);
}
