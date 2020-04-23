// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for default constructors.

import "package:expect/expect.dart";

String message;

foo() {
  message += 'foo';
  return 1;
}

bar() {
  message += 'bar';
  return 2;
}

class X {
  var i;
  var j;
  X({a: 'defa', b: 'defb'})
      : this.i = a,
        this.j = b;
  X.foo() : this(b: 1, a: 2);
  X.bar()
      : this(
                     1, // //# 01: compile-time error, runtime error
            a: 2);
  X.baz() : this(a: 1, b: 2);
  X.qux() : this(b: 2);
  X.hest() : this();
  X.fisk() : this(b: bar(), a: foo());
  X.naebdyr() : this(a: foo(), b: bar());
}

test(x, a, b) {
  Expect.equals(x.i, a);
  Expect.equals(x.j, b);
}

main() {
  test(new X.foo(), 2, 1);
  test(new X.bar(), 2, 'defb');
  test(new X.baz(), 1, 2);
  test(new X.qux(), 'defa', 2);
  test(new X.hest(), 'defa', 'defb');

  message = '';
  new X.fisk();
  Expect.equals('barfoo', message);

  message = '';
  new X.naebdyr();
  Expect.equals('foobar', message);
}
