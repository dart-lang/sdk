// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:_js_helper' show Native, Creates, setNativeSubclassDispatchRecord;
import 'dart:_interceptors' show findInterceptorForType;

// Test that subclasses of native classes can be defined by setting the dispatch
// record.

@Native("A")
class A {
  foo(x) =>  '$x,${this.oof()}';
  oof() => 'A';
}

class B extends A {
  oof() => 'B';
}

B makeB1() native;
B makeB2() native;
B makeC() native;

@Creates('=Object')
getBPrototype() native;

@Creates('=Object')
getCPrototype() native;

void setup() native r"""
function A() {}
function B() {}
function C() {}
makeA = function(){return new A;};
makeB1 = function(){return new B;};
makeB2 = function(){return new B;};
makeC = function(){return new C;};

getBPrototype = function(){return B.prototype;};
getCPrototype = function(){return C.prototype;};
""";

main() {
  setup();

  setNativeSubclassDispatchRecord(getBPrototype(), findInterceptorForType(B));
  setNativeSubclassDispatchRecord(getCPrototype(), findInterceptorForType(B));

  B b1 = makeB1();
  Expect.equals('1,B', b1.foo(1));

  B b2 = makeB2();
  Expect.equals('2,B', b2.foo(2));

  B b3 = makeC();
  Expect.equals('3,B', b3.foo(3));
}
