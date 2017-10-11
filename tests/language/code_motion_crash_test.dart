// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to crash during the
// [SsaCodeMotion] phase on this code.

class A {
  final finalField;
  var field = 2;
  foo() {
    new A().field = 42;
  }

  A._() : finalField = 42;
  A() : finalField = [new A._(), new B(), new Object()][1];
}

class B {
  foo() {}
  bar() {}
}

main() {
  var a = new A();
  // Create a new block for SsaCodeMotion: the phase will want to move
  // field access on [a] to this block.
  if (true) {
    var b = a.finalField;
    var d = a.field;
    b.bar();

    // [c] gets GVN'ed with [b]. As a consequence, the type propagator
    // that runs after GVN sees that [c] can only be a [B] because of
    // the call to [bar].
    var c = a.finalField;
    c.foo();

    // [e] does not get GVN'ed because the GVN phase sees [c.foo()] as
    // having side effects.
    var e = a.field;
    if (d + e != 4) throw 'Test failed';
  }
}
