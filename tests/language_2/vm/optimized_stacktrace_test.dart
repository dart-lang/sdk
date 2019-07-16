// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--stacktrace-every=3 --optimization-counter-threshold=10 --enable-inlining-annotations --no-background-compilation

// Test generating stacktraces with inlining and deferred code.
// Regression test for issue dartbug.com/22331

class A {
  final N;
  final inc;
  var next;
  A(this.N, this.inc) {
    next = this;
  }
}

foo(o, value) {
  for (var i = 0; i < o.N; i += o.inc) {
    if (value < i) {
      throw "";
    }
    o = o.next;
  }
  return value;
}

const NeverInline = 'NeverInline';

@NeverInline
baz(x, y, z) => z;

bar(o) {
  var value = 0x100000000 + o.inc;
  baz(0, 0, foo(o, value));
}

main() {
  var o = new A(10, 1);
  for (var i = 0; i < 100; i++) bar(o);
  bar(new A(100000, 1));
}
