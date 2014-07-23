// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

@Native("A")
class A {
}

makeA() native;

void setup() native """
function A() {};
A.prototype.foo = function() { return  42; }
makeA = function() { return new A; }
""";

class B {
  // We need to define a foo method so that Frog sees it. Because it's
  // the only occurence of 'foo', Frog does not bother mangling the
  // call sites. It thinks all calls will either go to this method, or
  // throw a NoSuchMethodError.
  foo() { return 42; }
}

typedContext() {
  var things = [ makeA(), new B() ];
  A a = things[0];
  Expect.throws(() => a.foo(),
                (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo,
                (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo = 4,
                (e) => e is NoSuchMethodError);
}

untypedContext() {
  var things = [ makeA(), new B() ];
  var a = things[0];
  Expect.throws(() => a.foo(),
                (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo,
                (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo = 4,
                (e) => e is NoSuchMethodError);
}

main() {
  setup();
  typedContext();
  untypedContext();
}
