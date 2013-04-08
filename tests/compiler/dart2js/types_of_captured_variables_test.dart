// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'compiler_helper.dart';

const String TEST1 = r"""
main() {
  var a = 52;
  var f = () => a + 3;
  f();
}
""";

const String TEST2 = r"""
main() {
  var a = 52;
  var g = () { a = 48; };
  var f = () => a + 3;
  f();
  g();
}
""";

const String TEST3 = r"""
main() {
  var a = 52;
  var g = () { a = 'foo'; };
  var f = () => a + 3;
  f();
  g();
}
""";

main() {
  // Test that we know the type of captured, non-mutated variables.
  String generated = compileAll(TEST1);
  Expect.isTrue(generated.contains('+ 3'));

  // Test that we know the type of captured, mutated variables.
  generated = compileAll(TEST2);
  Expect.isTrue(generated.contains('+ 3'));

  // Test that we know when types of a captured, mutated variable
  // conflict.
  generated = compileAll(TEST3);
  Expect.isFalse(generated.contains('+ 3'));
}
