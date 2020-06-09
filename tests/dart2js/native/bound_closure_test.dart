// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

// Test calling convention of property extraction closures.

class AA {
  bar(a, [b = 'A']) => 'AA.bar($a, $b)'; // bar is plain dart convention.
  foo(a, [b = 'A']) => 'AA.foo($a, $b)'; // foo has interceptor convention.
}

@Native("BB")
class BB {
  foo(a, [b = 'B']) native;
}

@Native("CC")
class CC extends BB {
  foo(a, [b = 'C']) native;

  get superfoo => super.foo;
}

makeBB() native;
makeCC() native;
inscrutable(a) native;

void setup() {
  JS('', r"""
(function(){
  function BB() {}
  BB.prototype.foo = function(u, v) {
    return 'BB.foo(' + u + ', ' + v + ')';
  };

  function CC() {}
  CC.prototype.foo = function(u, v) {
    return 'CC.foo(' + u + ', ' + v + ')';
  };

  makeBB = function(){return new BB()};
  makeCC = function(){return new CC()};
  inscrutable = function(a){return a;};

  self.nativeConstructor(BB);
  self.nativeConstructor(CC);
})()""");
}

main() {
  nativeTesting();
  setup();
  var a = inscrutable(new AA());
  var b = inscrutable(makeBB());
  var c = inscrutable(makeCC)();

  Expect.equals('AA.bar(1, A)', inscrutable(a).bar(1));
  Expect.equals('AA.bar(2, 3)', inscrutable(a).bar(2, 3));

  Expect.equals('AA.foo(1, A)', inscrutable(a).foo(1));
  Expect.equals('AA.foo(2, 3)', inscrutable(a).foo(2, 3));

  Expect.equals('BB.foo(1, B)', inscrutable(b).foo(1));
  Expect.equals('BB.foo(2, 3)', inscrutable(b).foo(2, 3));

  Expect.equals('CC.foo(1, C)', inscrutable(c).foo(1));
  Expect.equals('CC.foo(2, 3)', inscrutable(c).foo(2, 3));

  var abar = inscrutable(a).bar;
  var afoo = inscrutable(a).foo;
  var bfoo = inscrutable(b).foo;
  var cfoo = inscrutable(c).foo;

  Expect.equals('AA.bar(1, A)', abar(1));
  Expect.equals('AA.bar(2, 3)', abar(2, 3));

  Expect.equals('AA.foo(1, A)', afoo(1));
  Expect.equals('AA.foo(2, 3)', afoo(2, 3));

  Expect.equals('BB.foo(1, B)', bfoo(1));
  Expect.equals('BB.foo(2, 3)', bfoo(2, 3));

  Expect.equals('CC.foo(1, C)', cfoo(1));
  Expect.equals('CC.foo(2, 3)', cfoo(2, 3));
}
