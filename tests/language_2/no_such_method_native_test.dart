// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing that NoSuchMethod is properly called.

import "package:expect/expect.dart";

Invocation invocation;

class C {
  noSuchMethod(Invocation i) {
    invocation = i;
    return 42;
  }
}

expectNSME(Object d) {
  try {
    d.noSuchMethod(invocation);
  } on NoSuchMethodError catch (e) {
    Expect.isTrue(e.toString().contains('foobar'));
  }
}

main() {
  dynamic c = new C() as dynamic;
  Expect.equals(42, c.foobar(123));
  Expect.equals(invocation.memberName, #foobar);
  Expect.listEquals(invocation.positionalArguments, [123]);
  expectNSME(null);
  expectNSME(777);
  expectNSME('hello');
  expectNSME([]);
  expectNSME(<String>['a', 'b', 'c']);
}
