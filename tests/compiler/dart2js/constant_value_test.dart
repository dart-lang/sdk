// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.values.test;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/helpers/helpers.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/constants/values.dart';
import 'type_test_helper.dart';

void main() {
  enableDebugMode();

  asyncTest(() async {
    TypeEnvironment env = await TypeEnvironment.create('''
    class C {
      final field1;
      final field2;

      C(this.field1, this.field2);
    }
    ''');
    ClassElement C = env.getElement('C');
    FieldElement field1 = C.lookupLocalMember('field1');
    FieldElement field2 = C.lookupLocalMember('field2');
    ConstantValue value1 = new ConstructedConstantValue(C.rawType, {
      field1: new IntConstantValue(0),
      field2: new IntConstantValue(1),
    });
    ConstantValue value2 = new ConstructedConstantValue(C.rawType, {
      field2: new IntConstantValue(1),
      field1: new IntConstantValue(0),
    });
    Expect.equals(value1.hashCode, value2.hashCode, "Hashcode mismatch.");
    Expect.equals(value1, value2, "Value mismatch.");
  });
}
