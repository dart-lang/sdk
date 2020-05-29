// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library dart2js.constants.values.test;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/helpers/helpers.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/constants/values.dart';
import '../helpers/type_test_helper.dart';

void main() {
  enableDebugMode();

  asyncTest(() async {
    TypeEnvironment env = await TypeEnvironment.create("""
    class C {
      final field1;
      final field2;

      C(this.field1, this.field2);
    }

    main() => new C(null, null);
    """);
    ClassEntity C = env.getClass('C');
    InterfaceType C_raw = env.elementEnvironment.getRawType(C);
    FieldEntity field1 = env.elementEnvironment.lookupClassMember(C, 'field1');
    FieldEntity field2 = env.elementEnvironment.lookupClassMember(C, 'field2');
    ConstructedConstantValue value1 = new ConstructedConstantValue(C_raw, {
      field1: new IntConstantValue(BigInt.zero),
      field2: new IntConstantValue(BigInt.one),
    });
    ConstantValue value2 = new ConstructedConstantValue(C_raw, {
      field2: new IntConstantValue(BigInt.one),
      field1: new IntConstantValue(BigInt.zero),
    });
    Expect.equals(value1.hashCode, value2.hashCode, "Hashcode mismatch.");
    Expect.equals(value1, value2, "Value mismatch.");
  });
}
