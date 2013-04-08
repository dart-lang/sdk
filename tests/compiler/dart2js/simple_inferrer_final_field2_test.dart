// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a non-used generative constructor does not prevent
// infering types for fields.

import 'package:expect/expect.dart';
import 'compiler_helper.dart';
import 'parser_helper.dart';

const String TEST = """

class A {
  final intField;
  final stringField;
  A() : intField = 42, stringField = 'foo';
  A.bar() : intField = 54, stringField = 42;
}

main() {
  new A();
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
  checkFieldTypeInClass('A', 'stringField', typesInferrer.stringType);
}
