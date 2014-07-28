// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that exception unwrapping handle cases like ({foo:null}).foo().

import "dart:_js_helper";

import "package:expect/expect.dart";

typedef void MyFunctionType();

@Native("A")
class A {
  setClosure(MyFunctionType f) native;
  check(MyFunctionType f) native;
  invoke() native;
}

makeA() native;

void setup() native """
function A() {}
A.prototype.setClosure = function(f) { this.f = f; };
A.prototype.check = function(f) { return this.f === f; };
A.prototype.invoke = function() { return this.f(); };
makeA = function(){return new A;};
""";

main() {
  setup();
  A a = makeA();
  a.setClosure(null);
  Expect.isTrue(a.check(null));
  bool caughtException = false;
  try {
    a.invoke();
  } on JsNoSuchMethodError catch (e) {
    print(e);
    caughtException = true;
  }
  Expect.isTrue(caughtException);
}
