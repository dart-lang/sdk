// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library boolified_operator_test;
import 'compiler_helper.dart';

const String TEST = r"""
foo() {
  var a = foo();
  if (!a) return 1;
  return 2;
}
""";

main() {
  String generated = compile(TEST, entry: 'foo');
  Expect.isTrue(generated.contains('foo() !== true)'));
}
