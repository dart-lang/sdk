// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

@Native("A")
class A {}

A makeA() native;

void setup() native """
function A() {};
A.prototype.foo = function() { return  99; }
makeA = function() { return new A; }
self.nativeConstructor(A);
""";

class B {
  // We need to define a foo method so that dart2js sees it. Because the
  // only occurences of 'foo' is on B, a Dart class, no interceptor is used.  It
  // thinks all calls will either go to this method, or throw a
  // NoSuchMethodError. It is possible that the native class will shadow a
  // method, but it will not shadow 'foo' because the name is either 'mangled'
  // with the arity, or minified.
  foo() {
    return 42;
  }
}

typedContext() {
  confuse(new B()).foo();
  A a = makeA();
  Expect.throws(() => a.foo(), (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo, (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo = 4, (e) => e is NoSuchMethodError);
}

untypedContext() {
  confuse(new B()).foo();
  var a = confuse(makeA());
  Expect.throws(() => a.foo(), (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo, (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo = 4, (e) => e is NoSuchMethodError);
}

main() {
  nativeTesting();
  setup();
  typedContext();
  untypedContext();
}
