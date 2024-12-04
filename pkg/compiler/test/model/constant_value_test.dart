// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.values.test;

import 'package:compiler/src/elements/names.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/diagnostics/invariant.dart' show DEBUG_MODE;
import '../helpers/type_test_helper.dart';

void main() {
  DEBUG_MODE = true;

  asyncTest(() async {
    TypeEnvironment env = await TypeEnvironment.create("""
    class C {
      final field1;
      final field2;

      C(this.field1, this.field2);
    }

    main() => C(null, null);
    """);
    ClassEntity C = env.getClass('C');
    InterfaceType C_raw = env.elementEnvironment.getRawType(C);
    final field1 = env.elementEnvironment
        .lookupClassMember(C, PublicName('field1')) as FieldEntity;
    final field2 = env.elementEnvironment
        .lookupClassMember(C, PublicName('field2')) as FieldEntity;
    ConstructedConstantValue value1 = ConstructedConstantValue(C_raw, {
      field1: IntConstantValue(BigInt.zero),
      field2: IntConstantValue(BigInt.one),
    });
    ConstantValue value2 = ConstructedConstantValue(C_raw, {
      field2: IntConstantValue(BigInt.one),
      field1: IntConstantValue(BigInt.zero),
    });
    Expect.equals(value1.hashCode, value2.hashCode, "Hashcode mismatch.");
    Expect.equals(value1, value2, "Value mismatch.");
  });
}
