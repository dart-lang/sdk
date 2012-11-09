// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';

const String TEST_ONE = r"""
class A {}
bool foo(bar) {
  var x = new A();
  var y = new A();
  return x === y;
}
""";

main() {
  String generated = compile(TEST_ONE, entry: 'foo');

  // Check that no boolify code is generated.
  RegExp regexp = const RegExp("=== true");
  Iterator matches = regexp.allMatches(generated).iterator();
  Expect.isFalse(matches.hasNext);

  regexp = const RegExp("===");
  matches = regexp.allMatches(generated).iterator();
  Expect.isTrue(matches.hasNext);
  matches.next();
  Expect.isFalse(matches.hasNext);
}
