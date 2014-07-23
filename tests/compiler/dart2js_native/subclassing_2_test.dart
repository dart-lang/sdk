// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:_js_helper' show Native, Creates, setNativeSubclassDispatchRecord;
import 'dart:_interceptors' show findInterceptorForType;

// Test calling convention of methods introduced on subclasses of native
// classes.

doFoo(r, x) => '$x,${r.oof()}';

@Native("A")
class A {
  foo(x) => (doFoo)(this, x);
}

class B extends A {
  // [oof] is introduced only on this subclass of a native class.  It should
  // have interceptor calling convention.
  oof() => 'B';
}

B makeB() native;

@Creates('=Object')
getBPrototype() native;

void setup() native r"""
function A() {}
function B() {}
makeA = function(){return new A;};
makeB = function(){return new B;};

getBPrototype = function(){return B.prototype;};
""";

main() {
  setup();

  setNativeSubclassDispatchRecord(getBPrototype(), findInterceptorForType(B));

  B b = makeB();
  Expect.equals('1,B', b.foo(1));
}
