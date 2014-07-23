// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that native methods with unnamed optional arguments are called with the
// number of arguments in the call site AND the call site is inlined.

import "package:expect/expect.dart";
import 'dart:_js_helper' show Native, NoInline;

typedef int Int2Int(int x);

@Native("A")
class A {
  int foo([x, y, z]) native;

  // Calls can be inlined provided they don't pass an argument.
  int callFun([Int2Int fn]) native;
}

class B {
  static var g;
  @NoInline()
  method1(a) {
    g = '(Method1Tag)';  // Tag to identify compiled JavaScript method.
    A x = makeA();
    // Call sites that are searched for in compiled JavaScript.
    x.foo();
    x.foo(1);
    x.foo(2, 10);
    return x.foo(3, 10, 30);
  }
  @NoInline()
  method2() {
    g = '(Method2Tag)';
    A x = makeA();
    var r1 = x.callFun();  // Can be inlined.
    var r2 = x.callFun();
    return r1 + r2;
  }
  @NoInline()
  method3() {
    g = '(Method3Tag)';
    A x = makeA();
    var r1 = x.callFun((x) => x * 2);   // Can't be inlined due to conversion.
    var r2 = x.callFun((x) => x * 0);
    return r1 + r2;
  }
}

A makeA() native;

String findMethodTextContaining(instance, string) native;

void setup() native r"""
function A() {}
A.prototype.foo = function () { return arguments.length; };
A.prototype.callFun = function (fn) { return fn ? fn(123) : 1; };

makeA = function(){return new A;};

findMethodTextContaining = function (instance, string) {
  var proto = Object.getPrototypeOf(instance);
  var keys = Object.keys(proto);
  for (var i = 0; i < keys.length; i++) {
    var name = keys[i];
    var member = proto[name];
    var s = String(member);
    if (s.indexOf(string)>0) return s;
  }
};
""";


bool get isCheckedMode {
  int i = 0;
  try {
    i = 'a';
  } catch (e) {
    return true;
  }
  return false;
}

void match(String s, String pattern1) {
  var pattern2 = pattern1.replaceAll(' ', '');
  Expect.isTrue(s.contains(pattern1) || s.contains(pattern2),
      "expected $pattern1 or $pattern2");
}

void nomatch(String s, String pattern1) {
  var pattern2 = pattern1.replaceAll(' ', '');
  Expect.isFalse(s.contains(pattern1) || s.contains(pattern2),
      "should not have $pattern1 or $pattern2");
}

test1() {
  String method1 = findMethodTextContaining(new B(), '(Method1Tag)');
  Expect.isNotNull(method1, 'No method found containing "(Method1Tag)"');

  if (isCheckedMode) {
    match(method1, r'foo()');
    // TODO: inlining in checked mode.
    nomatch(method1, r'foo(1)');
    //  t1.foo$3(x, 3, 10, 30)  or  y.EL(z,3,10,30)
    match(method1, r', 3, 10, 30)');
  } else {
    // Direct (inlined) calls don't have $3 or minified names.
    match(method1, r'.foo()');
    match(method1, r'.foo(1)');
    match(method1, r'.foo(2, 10)');
    match(method1, r'.foo(3, 10, 30)');
  }

  // Ensure the methods are compiled by calling them.
  var a = makeA();

  Expect.equals(0, a.foo());
  Expect.equals(1, a.foo(10));
  Expect.equals(2, a.foo(10, 20));
  Expect.equals(3, a.foo(10, 20, 30));

  var b = new B();
  var r = b.method1(a);
  Expect.equals(3, r);
}

test2() {
  String method2 = findMethodTextContaining(new B(), '(Method2Tag)');
  Expect.isNotNull(method2, 'No method found containing "(Method2Tag)"');
  // Can always inline the zero-arg call.
  match(method2, r'.callFun()');

  String method3 = findMethodTextContaining(new B(), '(Method3Tag)');
  Expect.isNotNull(method3, 'No method found containing "(Method3Tag)"');
  // Don't inline native method with a function argument - should call a stub
  // containing the conversion.
  nomatch(method3, r'.callFun(');

  // Ensure the methods are compiled by calling them.
  var a = makeA();
  Expect.equals(369, a.callFun((i) => 3 * i));

  var b = new B();
  Expect.equals(2, b.method2());
  Expect.equals(246, b.method3());
}

main() {
  setup();
  test1();
  test2();
}
