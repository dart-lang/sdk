// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we are analyzing field parameters correctly.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import 'parser_helper.dart';
import 'type_mask_test_helper.dart';

const String TEST = """

class A {
  final dynamicField;
  A() : dynamicField = 42;
  A.bar(this.dynamicField);
}

main() {
  new A();
  new A.bar('foo');
}
""";

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.runCompiler(uri).then((_) {
    var typesInferrer = compiler.typesTask.typesInferrer;

    checkFieldTypeInClass(String className, String fieldName, type) {
      var cls = findElement(compiler, className);
      var element = cls.lookupLocalMember(fieldName);
      Expect.equals(type,
          simplify(typesInferrer.getTypeOfElement(element), compiler));
    }

    checkFieldTypeInClass('A', 'dynamicField',
        findTypeMask(compiler, 'Interceptor', 'nonNullSubclass'));
  }));
}
