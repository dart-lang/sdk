// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

const String TEST = """

class A {
  final intField;
  final giveUpField1;
  final giveUpField2;
  final fieldParameter;
  A() : intField = 42, giveUpField1 = 'foo', giveUpField2 = 'foo';
  A.bar() : intField = 54, giveUpField1 = 42, giveUpField2 = new A();
  A.foo(this.fieldParameter);
}

main() {
  new A();
  new A.bar();
  new A.foo(42);
}
""";

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var closedWorld = typesInferrer.closedWorld;

        checkFieldTypeInClass(String className, String fieldName, type) {
          dynamic cls = findElement(compiler, className);
          var element = cls.lookupLocalMember(fieldName);
          Expect.equals(type,
              simplify(typesInferrer.getTypeOfMember(element), closedWorld));
        }

        checkFieldTypeInClass(
            'A', 'intField', closedWorld.commonMasks.uint31Type);
        checkFieldTypeInClass(
            'A', 'giveUpField1', closedWorld.commonMasks.interceptorType);
        checkFieldTypeInClass('A', 'giveUpField2',
            closedWorld.commonMasks.dynamicType.nonNullable());
        checkFieldTypeInClass(
            'A', 'fieldParameter', closedWorld.commonMasks.uint31Type);
      }));
}
