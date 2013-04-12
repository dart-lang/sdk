// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'compiler_helper.dart';
import 'parser_helper.dart';

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
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  compiler.runCompiler(uri);
  var typesInferrer = compiler.typesTask.typesInferrer;

  checkFieldTypeInClass(String className, String fieldName, type) {
    var cls = findElement(compiler, className);
    var element = cls.lookupLocalMember(buildSourceString(fieldName));
    Expect.equals(type, typesInferrer.typeOf[element]);
  }

  checkFieldTypeInClass('A', 'intField', typesInferrer.intType);
  checkFieldTypeInClass('A', 'giveUpField1',
      findTypeMask(compiler, 'Interceptor', 'nonNullSubclass'));
  checkFieldTypeInClass('A', 'giveUpField2', typesInferrer.dynamicType);
  checkFieldTypeInClass('A', 'fieldParameter', typesInferrer.intType);
}
