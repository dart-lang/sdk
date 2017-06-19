// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a non-used generative constructor does not prevent
// infering types for fields.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'compiler_helper.dart';

const String TEST = """

class A {
  final intField;
  final stringField;
  A() : intField = 42, stringField = 'foo';
  A.bar() : intField = 'bar', stringField = 42;
}

main() {
  new A();
}
""";

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;

        checkFieldTypeInClass(String className, String fieldName, type) {
          dynamic cls = findElement(compiler, className);
          var element = cls.lookupLocalMember(fieldName);
          Expect.isTrue(
              typesInferrer.getTypeOfElement(element).containsOnly(type));
        }

        checkFieldTypeInClass('A', 'intField',
            typesInferrer.closedWorld.commonElements.jsUInt31Class);
        checkFieldTypeInClass('A', 'stringField',
            typesInferrer.closedWorld.commonElements.jsStringClass);
      }));
}
