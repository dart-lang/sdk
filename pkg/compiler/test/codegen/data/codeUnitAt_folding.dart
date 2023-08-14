// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('dart2js:never-inline')
/*member: foo1:function() {
  return 72;
}*/
foo1() {
  var a = 'Hello';
  var b = 0;
  return a.codeUnitAt(b);
  // Constant folds to 'return 72;'
}

@pragma('dart2js:never-inline')
/*spec|canary.member: foo2:function() {
  return B.JSString_methods.codeUnitAt$1("Hello", A._asInt("x"));
}*/
/*prod.member: foo2:function() {
  return B.JSString_methods.codeUnitAt$1("Hello", "x");
}*/
foo2() {
  var a = 'Hello';
  dynamic b = 'x';
  return a.codeUnitAt(b);
  // No folding of index type error.
}

@pragma('dart2js:never-inline')
/*member: foo3:function() {
  return A.ioore("Hello", 55);
  return "Hello".charCodeAt(55);
}*/
foo3() {
  var a = 'Hello';
  dynamic b = 55;
  return a.codeUnitAt(b);
  // Index always out of range.
  // The code after the always-fail check is unfortunate.
}

@pragma('dart2js:never-inline')
/*member: foo4:function(i) {
  if (!(i >= 0 && i < 5))
    return A.ioore("Hello", i);
  return "Hello".charCodeAt(i);
}*/
foo4(int i) {
  return 'Hello'.codeUnitAt(i);
  // Normal bounds check.
}

@pragma('dart2js:never-inline')
/*member: foo5:function(i) {
  if (!(i < 5))
    return A.ioore("Hello", i);
  return "Hello".charCodeAt(i);
}*/
foo5(int i) {
  return 'Hello'.codeUnitAt(i);
  // High-only bounds check.
}

@pragma('dart2js:never-inline')
@pragma('dart2js:index-bounds:trust')
/*member: foo6:function(i) {
  return "Hello".charCodeAt(i);
}*/
foo6(int i) {
  return 'Hello'.codeUnitAt(i);
  // No bound check, as requested.
}

@pragma('dart2js:never-inline')
@pragma('dart2js:index-bounds:trust')
/*spec|canary.member: foo7:function(i) {
  return "Hello".charCodeAt(A._asInt(i));
}*/
/*prod.member: foo7:function(i) {
  return B.JSString_methods.codeUnitAt$1("Hello", i);
}*/
foo7(dynamic i) {
  return 'Hello'.codeUnitAt(i);
  // No folding of index type error even when bounds check removed.
}

/*member: main:ignore*/
main() {
  foo1();
  foo2();
  foo3();
  foo4(-9);
  foo4(0);
  foo4(100);
  foo5(0);
  foo5(100);
  foo6(-9);
  foo6(0);
  foo6(100);
  foo7(0);
  foo7('x');
}
