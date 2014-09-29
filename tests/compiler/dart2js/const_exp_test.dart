// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'type_test_helper.dart';

test(String constantInitializer, [String expectedOutput]) {
  if (expectedOutput == null) {
    expectedOutput = constantInitializer;
  }
  return () => TypeEnvironment.create("""
    class Class<T, S> {
      final a;
      final b;
      final c;
      const Class(this.a, {this.b, this.c: true});
      const Class.named([this.a, this.b = 0, this.c = 2]);

      static const staticConstant = 0;
      static staticFunction() {}
    }
    const t = true;
    const f = false;
    const toplevelConstant = 0;
    toplevelFunction() {}
    const constant = $constantInitializer;
""", expectNoWarningsOrErrors: true).then((env) {
     var element = env.getElement('constant');
     Expect.isNotNull(element, "Element 'constant' not found.");
     var constant = env.compiler.constants.getConstantForVariable(element);
     Expect.isNotNull(constant,
                      "No constant computed for '$element'.");
     Expect.equals(expectedOutput, constant.getText(),
         "Unexpected to string '${constant.getText()}' for constant "
         "'$constantInitializer' of value "
         "${constant.value.toStructuredString()}");
   });
}

void main() {
  asyncTest(() => Future.forEach([
    test('null'),
    test('0'),
    test('1.5'),
    test('true'),
    test('false'),
    test('"f"'),
    test('"a" "b"', '"ab"'),
    test('const []'),
    test('const <int>[0, 1]'),
    test('const <dynamic>[0, 1]', 'const [0, 1]'),
    test('const {}'),
    test('const {0: 1, 2: 3}'),
    test('const <String, int>{"0": 1, "2": 3}'),
    test('const <String, dynamic>{"0": 1, "2": 3}'),
    test('const <dynamic, dynamic>{"0": 1, "2": 3}', 'const {"0": 1, "2": 3}'),
    test('const Class(0)'),
    test('const Class(0, b: 1)'),
    test('const Class(0, c: 2)'),
    test('const Class(0, b: 3, c: 4)'),
    test('const Class.named()'),
    test('const Class.named(0)'),
    test('const Class.named(0, 1)'),
    test('const Class.named(0, 1, 2)'),
    test('const Class<String, int>(0)'),
    test('const Class<String, dynamic>(0)'),
    test('const Class<dynamic, String>(0)'),
    test('const Class<dynamic, dynamic>(0)', 'const Class(0)'),
    test('toplevelConstant'),
    test('toplevelFunction'),
    test('Class.staticConstant'),
    test('Class.staticFunction'),
    test('#a'),
    test('1 + 2'),
    test('1 + 2 + 3'),
    test('1 + -2'),
    test('-1 + 2'),
    test('(1 + 2) + 3', '1 + 2 + 3'),
    test('1 + (2 + 3)', '1 + 2 + 3'),
    test('1 * 2'),
    test('1 * 2 + 3'),
    test('1 * (2 + 3)'),
    test('1 + 2 * 3'),
    test('(1 + 2) * 3'),
    test('false || identical(0, 1)'),
    test('!identical(0, 1)'),
    test('!identical(0, 1) || false'),
    test('!(identical(0, 1) || false)'),
    test('identical(0, 1) ? 3 * 4 + 5 : 6 + 7 * 8'),
    test('t ? f ? 0 : 1 : 2'),
    test('(t ? t : f) ? f ? 0 : 1 : 2'),
    test('t ? t : f ? f ? 0 : 1 : 2'),
    test('t ? t ? t : t : t ? t : t'),
    test('t ? (t ? t : t) : (t ? t : t)',
         't ? t ? t : t : t ? t : t'),
    test('const [const <dynamic, dynamic>{0: true, "1": "c" "d"}, '
         'const Class(const Class<dynamic, dynamic>(toplevelConstant))]',
         'const [const {0: true, "1": "cd"}, '
         'const Class(const Class(toplevelConstant))]'),
  ], (f) => f()));
}