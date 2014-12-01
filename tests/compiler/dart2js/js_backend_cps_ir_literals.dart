// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of literals.

library literals_tests;

import 'js_backend_cps_ir_test.dart';

const List<TestEntry> tests = const [
  const TestEntry("""
main() {
  print([]);
  print([1]);
  print([1, 2]);
  print([1, [1, 2]]);
  print({});
  print({1: 2});
  print({[1, 2]: [3, 4]});
}
""",
r"""
function() {
  P.print([]);
  P.print([1]);
  P.print([1, 2]);
  P.print([1, [1, 2]]);
  P.print(P.LinkedHashMap_LinkedHashMap$_empty());
  P.print(P.LinkedHashMap_LinkedHashMap$_literal([1, 2]));
  P.print(P.LinkedHashMap_LinkedHashMap$_literal([[1, 2], [3, 4]]));
  return null;
}"""),
];
