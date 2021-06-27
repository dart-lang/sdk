// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

//  Regression test for issue 17645.
get never => new DateTime.now().millisecondsSinceEpoch == 0;

class A {
  var foo;
  A(this.foo);
}

var log = [];

test1(a, xs) {
  // Called with a = [null|exact=A]
  log.clear();
  for (var x in xs) {
    if (a != null) {
      log.add('${a.foo}.$x'); // a.foo must not be hoisted
    }
  }
  return '$log';
}

test2(a, xs) {
  // Called with a = [exact=A]
  log.clear();
  for (var x in xs) {
    if (a != null) {
      log.add('${a.foo}.$x'); // a.foo may be hoisted
    }
  }
  return '$log';
}

test3(a, xs) {
  // Called with a = [null|exact=A]
  log.clear();
  for (var x in xs) {
    if (a is A) {
      log.add('${a.foo}.$x'); // a.foo must not be hoisted
    }
  }
  return '$log';
}

test4(a, xs) {
  // Called with a = [exact=A]
  log.clear();
  for (var x in xs) {
    if (a is A) {
      log.add('${a.foo}.$x'); // a.foo may be hoisted
    }
  }
  return '$log';
}

main() {
  var a1 = new A('a1');
  var a2 = new A('a2');

  Expect.equals('[a1.11]', test1(a1, [11]));
  Expect.equals('[]', test1(null, [11]));

  Expect.equals('[a1.22]', test2(a1, [22]));
  Expect.equals('[a2.22]', test2(a2, [22]));

  Expect.equals('[a1.33]', test3(a1, [33]));
  Expect.equals('[]', test3(null, [2]));

  Expect.equals('[a1.44]', test4(a1, [44]));
  Expect.equals('[a2.44]', test4(a2, [44]));
}
