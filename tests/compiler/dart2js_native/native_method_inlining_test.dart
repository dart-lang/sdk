// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that native methods with unnamed optional arguments are called with the
// number of arguments in the call site AND the call site is inlined.

class A native "*A" {
  int foo([x, y, z]) native;
}

class B {
  static var g;
  work(a) {
    g = 'Sandwich';  // Tag to identify compiled JavaScript method.
    A x = makeA();
    // Call sites that are searched for in compiled JavaScript.
    x.foo();
    x.foo(1);
    x.foo(2, 10);
    return x.foo(3, 10, 30);
  }
}

A makeA() native;

String findMethodTextContaining(instance, string) native;

void setup() native r"""
function A() {}
A.prototype.foo = function () { return arguments.length; };

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
      "$pattern1 or $pattern2");
}

test() {
  var a = makeA();

  Expect.equals(0, a.foo());
  Expect.equals(1, a.foo(10));
  Expect.equals(2, a.foo(10, 20));
  Expect.equals(3, a.foo(10, 20, 30));

  var b = new B();
  var r = b.work(a);
  Expect.equals(3, r);

  String text = findMethodTextContaining(b, 'Sandwich');
  Expect.isNotNull(text, 'No method found containing "Sandwich"');

  if (isCheckedMode) {
    // TODO: inlining in checked mode.
    //  t1.foo$3(x, 3, 10, 30)  or  y.EL(z,3,10,30)
    match(text, r', 3, 10, 30)');
  } else {
    // Direct (inlined) calls don't have $3 or minified names.
    match(text, r'.foo()');
    match(text, r'.foo(1)');
    match(text, r'.foo(2, 10)');
    match(text, r'.foo(3, 10, 30)');
  }
}

main() {
  setup();
  test();
}
