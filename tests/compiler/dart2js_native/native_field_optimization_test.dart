// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

// Test that compiler is cautious with optimizations on native fields.  The
// motivation is that DOM properties are getters and setters with arbitrary
// effects.  Setting CSSStyleDeclaration.borderLeft can canonicalize the value
// and changes the value of CSSStyleDeclaration.border.

@Native("Foo")
class Foo {
  var a;
  var b;
  var ab;
}

Foo makeFoo() native;

void setup() {
  JS('', r"""
(function(){
  function Foo() { this.i = 0; }

  Object.defineProperty(Foo.prototype, 'a', {
    get: function () { return (this._a || '') + ++this.i; },
    set: function (v) { this._a = v.toLowerCase(); }
  });

  Object.defineProperty(Foo.prototype, 'b', {
    get: function () { return this._b || ''; },
    set: function (v) { this._b = v.toLowerCase(); }
  });

  Object.defineProperty(Foo.prototype, 'ab', {
    get: function () { return this.a + ' ' + this.b; },
    set: function (v) {
      var s = v.split(' ');
      this.a = s[0];
      this.b = s[1];
    }
  });

  makeFoo = function() { return new Foo() };

  self.nativeConstructor(Foo);
})()""");
}

test1() {
  var f = makeFoo();
  f.a = 'Hi';
  f.b = 'There';
  Expect.equals('hi1 there', f.ab);
}

test2() {
  // Test for CSE. dart2js currently does CSE loads. Is this the right choice?
  var f = makeFoo();
  var a1 = f.a;
  var b1 = f.b;
  var a2 = f.a;
  Expect.equals('1', a1);
  if (a2 == a1) {
    // We did CSE.
  } else {
    Expect.equals('2', a2);
  }
}

test3() {
  // Must not CSE over a native field store.
  var f = makeFoo();
  var a1 = f.a;
  f.ab = 'X Y';
  var a2 = f.a;
  Expect.equals('1', a1);
  Expect.equals('x2', a2);
}

test4() {
  // Must not store-forward.
  var f = makeFoo();
  f.a = 'A';
  var a2 = f.a;
  Expect.equals('a1', a2);
}

main() {
  nativeTesting();
  setup();
  (test1)();
  (test2)();
  (test3)();
  (test4)();
}
