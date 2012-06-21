// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

final String TEST_ONE = @"""
foo(int param0, int param1, bool param2) {
  for (int i = 0; i < 1; i++) {
    var x = param0 + 5;  // '+' is now GVNed.
    if (param2) {
      print(param0 + param1);
    } else {
      print(param0 + param1);
    }
  }
}
""";

main() {
  String generated = compile(TEST_ONE, 'foo');
  RegExp regexp = const RegExp('param0 \\+ param1');
  Iterator matches = regexp.allMatches(generated).iterator();
  Expect.isTrue(matches.hasNext());
  matches.next();
  Expect.isFalse(matches.hasNext());
}
