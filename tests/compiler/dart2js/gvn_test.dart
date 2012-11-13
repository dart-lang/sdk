// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';

const String TEST_ONE = r"""
void foo(bar) {
  for (int i = 0; i < 1; i++) {
    print(1 + bar);
    print(1 + bar);
  }
}
""";

main() {
  String generated = compile(TEST_ONE, entry: 'foo');
  RegExp regexp = new RegExp(r"1 \+ [a-z]+");
  Iterator matches = regexp.allMatches(generated).iterator();
  Expect.isTrue(matches.hasNext);
  matches.next();
  Expect.isFalse(matches.hasNext);
}
