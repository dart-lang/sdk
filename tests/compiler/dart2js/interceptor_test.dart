// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_ONE = r"""
  foo(a) {
    var myVariableName = a.toString();
    print(myVariableName);
    print(myVariableName);
  }
""";

const String TEST_TWO = r"""
  class A {
    var length;
  }
  foo(a) {
    print([]); // Make sure the array class is instantiated.
    return new A().length + a.length;
  }
""";

main() {
  asyncTest(() => Future.wait([
    // Check that one-shot interceptors preserve variable names, see
    // https://code.google.com/p/dart/issues/detail?id=8106.
    compile(TEST_ONE, entry: 'foo', check: (String generated) {
      Expect.isTrue(
          generated.contains(new RegExp(r'[$A-Z]+\.toString\$0\(a\)')));
      Expect.isTrue(generated.contains('myVariableName'));
    }),
    // Check that an intercepted getter that does not need to be
    // intercepted, is turned into a regular getter call or field
    // access.
    compile(TEST_TWO, entry: 'foo', check: (String generated) {
      Expect.isFalse(generated.contains(r'a.get$length()'));
      Expect.isTrue(
          generated.contains(new RegExp(r'[$A-Z]+\.A\$\(\)\.length')));
      Expect.isTrue(
          generated.contains(new RegExp(r'[$A-Z]+\.get\$length\$as\(a\)')));
    }),
  ]));
}
