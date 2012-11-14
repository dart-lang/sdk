// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_metadata.dart';

typedef void MyFunctionType();

@Native("*A")
class A {
  @native setClosure(MyFunctionType f);
  @native check(MyFunctionType f);
  @native invoke();
}

@native makeA() { return new A(); }

@Native("""
function A() {}
A.prototype.setClosure = function(f) { this.f = f; };
A.prototype.check = function(f) { return this.f === f; };
A.prototype.invoke = function() { return this.f(); };
makeA = function(){return new A;};
""")
void setup();


main() {
  setup();
  A a = makeA();
  a.setClosure(null);
  Expect.isTrue(a.check(null));
  bool caughtException = false;
  try {
    a.invoke();
  } on Exception catch (e) {
    caughtException = true;
  }
  Expect.isTrue(caughtException);
}
