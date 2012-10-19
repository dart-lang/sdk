// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

const String TEST = r"""
class A {
  foo({a, b}) {}
}

class B extends A {
}

main() {
  var a = [bar, baz];
  a[0](new A());
  a[1](new A());
}

bar(a) {
  if (a is A) a.foo(a: 42);
}

baz(a) {
  if (a is B) a.foo(a: 42);
}
""";

main() {
  String generated = compileAll(TEST);
  RegExp regexp = new RegExp('foo\\\$1\\\$a: function');
  Iterator<Match> matches = regexp.allMatches(generated).iterator();
  checkNumberOfMatches(matches, 1);
}
