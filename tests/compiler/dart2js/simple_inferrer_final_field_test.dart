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
    var typesInferrer = compiler.typesTask.typesInferrer;

    checkFieldTypeInClass(String className, String fieldName, type) {
      var cls = findElement(compiler, className);
      var element = cls.lookupLocalMember(fieldName);
      Expect.equals(type,
          simplify(typesInferrer.getTypeOfElement(element), compiler));
    }

    checkFieldTypeInClass('A', 'intField', compiler.typesTask.uint31Type);
    checkFieldTypeInClass('A', 'giveUpField1',
        findTypeMask(compiler, 'Interceptor', 'nonNullSubclass'));
    checkFieldTypeInClass('A', 'giveUpField2',
        compiler.typesTask.dynamicType.nonNullable());
    checkFieldTypeInClass('A', 'fieldParameter', compiler.typesTask.uint31Type);
  }));
}
