// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:ignore*/
void main() {
  for (var a in [false, true]) {
    sink = foo1(a);
    sink = foo2(a);
    sink = foo3(a);
    sink = foo4(a, 2);
    sink = foo4(a, 10);

    for (var b in [false, true]) {
      sink = foo5(a, b);
      sink = foo_regress_37502(a, b);
    }
  }
}

Object sink;

@pragma('dart2js:noInline')
/*spec.member: foo1:function(param) {
  return (H.boolConversionCheck(param) ? 4294967295 : 1) / 2 | 0;
}*/
/*prod.member: foo1:function(param) {
  return (param ? 4294967295 : 1) / 2 | 0;
}*/
int foo1(bool param) {
  var a = param ? 0xFFFFFFFF : 1;
  return a ~/ 2;
  // Above can be compiled to division followed by truncate.
  // present: ' / 2 | 0'
}

@pragma('dart2js:noInline')
/*spec.member: foo2:function(param) {
  return (H.boolConversionCheck(param) ? 4294967295 : 1) / 3 | 0;
}*/
/*prod.member: foo2:function(param) {
  return (param ? 4294967295 : 1) / 3 | 0;
}*/
int foo2(bool param) {
  var a = param ? 0xFFFFFFFF : 1;
  return a ~/ 3;
  // Above can be compiled to division followed by truncate.
  // present: ' / 3 | 0'
}

@pragma('dart2js:noInline')
/*spec.member: foo3:function(param) {
  return C.JSInt_methods._tdivFast$1(H.boolConversionCheck(param) ? 4294967295 : -1, 2);
}*/
/*prod.member: foo3:function(param) {
  return C.JSInt_methods._tdivFast$1(param ? 4294967295 : -1, 2);
}*/
int foo3(bool param) {
  var a = param ? 0xFFFFFFFF : -1;
  return a ~/ 2;
  // Potentially negative inputs go via '_tdivFast' fast helper.
  // present: '_tdivFast'
}

@pragma('dart2js:noInline')
/*spec.member: foo4:function(param1, param2) {
  return C.JSInt_methods.$tdiv(H.boolConversionCheck(param1) ? 4294967295 : 0, param2);
}*/
/*prod.member: foo4:function(param1, param2) {
  return C.JSInt_methods.$tdiv(param1 ? 4294967295 : 0, param2);
}*/
int foo4(bool param1, int param2) {
  var a = param1 ? 0xFFFFFFFF : 0;
  return a ~/ param2;
  // Unknown divisor goes via full implementation.
  // present: '$tdiv'
  // absent: '/'
}

@pragma('dart2js:noInline')
/*spec.member: foo5:function(param1, param2) {
  var a = H.boolConversionCheck(param1) ? 4294967295 : 0;
  return C.JSInt_methods.$tdiv(a, H.boolConversionCheck(param2) ? 3 : 4);
}*/
/*prod.member: foo5:function(param1, param2) {
  var a = param1 ? 4294967295 : 0;
  return C.JSInt_methods.$tdiv(a, param2 ? 3 : 4);
}*/
int foo5(bool param1, bool param2) {
  var a = param1 ? 0xFFFFFFFF : 0;
  var b = param2 ? 3 : 4;
  return a ~/ b;
  // We could optimize this with range analysis, but type inference summarizes
  // '3 or 4' to uint31, which is not >= 2.
  // present: '$tdiv'
  // absent: '/'
}

@pragma('dart2js:noInline')
/*spec.member: foo_regress_37502:function(param1, param2) {
  var a = H.boolConversionCheck(param1) ? 1.2 : 12.3;
  return C.JSInt_methods.gcd$1(C.JSDouble_methods.$tdiv(a, H.boolConversionCheck(param2) ? 3.14 : 2.81), 2);
}*/
/*prod.member: foo_regress_37502:function(param1, param2) {
  var a = param1 ? 1.2 : 12.3;
  return C.JSInt_methods.gcd$1(C.JSDouble_methods.$tdiv(a, param2 ? 3.14 : 2.81), 2);
}*/
foo_regress_37502(param1, param2) {
  var a = param1 ? 1.2 : 12.3;
  var b = param2 ? 3.14 : 2.81;
  return (a ~/ b).gcd(2);
  // The result of ~/ is int; gcd is defined only on int and is too complex
  // to be inlined.
  //
  // present: 'JSInt_methods.gcd'
}
