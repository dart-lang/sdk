// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of interceptors.

library supercall_test;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [
  const TestEntry("""
class Base {
  m(x) {
    print(x+1);
  }
}
class Sub extends Base {
  m(x) => super.m(x+10);
}
main() {
  new Sub().m(100);
}""",
r"""
function() {
  var v0;
  V.Sub$();
  v0 = H.S(100 + 10 + 1);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),

  // Reenable when we support compiling functions that
  // need interceptor calling convention.
// const TestEntry.forMethod('function(Sub#+)', """
// class Base {
//   m(x) {
//     print(x+1000);
//   }
//   operator+(x) => m(x+10);
// }
// class Sub extends Base {
//   m(x) => super.m(x+100);
//   operator+(x) => super + (x+1);
// }
// main() {
//   new Sub() + 10000;
// }""",
// r"""
// function(x) {
//   var v0, v1, v2;
//   v0 = 1;
//   v1 = J.getInterceptor$ns(x).$add(x, v0);
//   v2 = this;
//   return V.Base.prototype.$add.call(null, v2, v1);
// }"""),

const TestEntry("""
class Base {
  var field = 123;
}
class Sub extends Base {
  m(x) => x + super.field;
}
main() {
  print(new Sub().m(10));
}""",
r"""
function() {
  var v0 = H.S(10 + V.Sub$().field);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),


];

void main() {
  runTests(tests);
}
