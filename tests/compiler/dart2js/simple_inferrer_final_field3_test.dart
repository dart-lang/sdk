// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we are analyzing field parameters correctly.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
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
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var closedWorld = typesInferrer.closedWorld;

        checkFieldTypeInClass(String className, String fieldName, type) {
          dynamic cls = findElement(compiler, className);
          var element = cls.lookupLocalMember(fieldName);
          Expect.equals(type,
              simplify(typesInferrer.getTypeOfElement(element), closedWorld));
        }

        checkFieldTypeInClass(
            'A', 'dynamicField', closedWorld.commonMasks.interceptorType);
      }));
}
