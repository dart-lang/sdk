// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that we get rid of duplicate type guards on a field when that
// field is being gvn'ed.

import 'compiler_helper.dart';

const String TEST = r"""
class A {
  var field = 52;
  foo() {
    var a = this.field;
    while (a + 42 == 42);
    // This field get should be GVN'ed
    a = this.field;
    while (a + 87 == 87);
    field = 'bar';
  }
}

main() {
  while (true) new A().foo();
}
""";

main() {
  String generated = compileAll(TEST);
  RegExp regexp = const RegExp('foo\\\$0\\\$bailout');
  Iterator matches = regexp.allMatches(generated).iterator();

  // We check that there is only one call to the bailout method.
  // One match for the call, one for the definition.
  checkNumberOfMatches(matches, 2);
}
