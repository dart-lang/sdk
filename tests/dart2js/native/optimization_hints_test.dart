// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS;

import 'package:expect/expect.dart';

var x;

foo(c) {
  x = "in foo function";
  c.c_field = x;
}

@pragma('dart2js:noSideEffects')
@pragma('dart2js:noInline')
bar(d) {
  x = "in bar function";
  d.d_field = x;
}

class C {
  var c_field;
  m() => c_field;
}

class D {
  var d_field;
  m() => d_field;
}

@pragma('dart2js:noSideEffects')
@pragma('dart2js:noInline')
@pragma('dart2js:noThrows')
baz() {
  throw 'in baz function';
}

@pragma('dart2js:noInline')
geeNoInline() {
  // Use `gee` several times, so `gee` isn't used only once (and thus inlinable
  // independently of its size).
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
  gee();
}

@pragma('dart2js:tryInline')
// Big function that would normally not be inlinable.
gee([c]) {
  if (c != null) {
    x = "in gee function";
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
    geeNoInline();
  }
}

main() {
  JS('', 'String("in main function")');
  var c;
  if (new DateTime.now().millisecondsSinceEpoch != 42) {
    c = new C();
    print(c.m());
    foo(c);
    print(c.m());
  } else {
    var d = new D();
    print(d.m());
    bar(d);
    print(d.m());
  }
  print(c.m());
  simple();
  noinline();
  baz(); // This call should be eliminated by the optimizer.
  gee(new C());
  print(x);
  check(JS('', 'arguments.callee'));
}

@pragma('dart2js:noInline')
check(func) {
  JS('', 'String("in check function")');
  var source = JS('String', 'String(#)', func);
  print(source);
  Expect.isTrue(source.contains('"in main function"'), "should contain 'main'");
  Expect.isTrue(
      source.contains('"in simple function"'), "should inline 'simple'");
  Expect.isTrue(source.contains('"in foo function"'), "should inline 'foo'");
  Expect.isFalse(
      source.contains('"in bar function"'), "should not inline 'bar'");
  Expect.isFalse(
      source.contains('"in check function"'), "should not inline 'check'");
  Expect.isFalse(source.contains('"in noinline function"'),
      "should not inline 'noinline'");
  Expect.equals(2, new RegExp(r'\.c_field').allMatches(source).length,
      "should contain r'\.c_field' exactly twice");
  Expect.isFalse(
      source.contains('.d_field'), "should not contain r'\.d_field'");
  Expect.isTrue(source.contains('"in gee function"'), "must inline 'gee'");
}

simple() {
  JS('', 'String("in simple function")');
}

@pragma('dart2js:noInline')
noinline() {
  JS('', 'String("in noinline function")');
}
