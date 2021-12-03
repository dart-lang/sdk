// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//@dart=2.14

/*member: main:ignore*/
void main() {
  for (var a in [false, true]) {
    sink = cannotRecognize(a ? 10 : C());
    sink = unspecialized(a ? -1 : 1);
    sink = otherPositive2(a);
    sink = shiftBySix(a);
    sink = shiftByMasked(a, 9);
    sink = shiftByMasked(a, -9);
  }

  sink = cannotConstantFold();
  sink = constantFoldPositive();
  sink = constantFoldNegative();
  test6();
}

Object? sink;

@pragma('dart2js:noInline')
/*spec|canary.member: cannotRecognize:function(thing) {
  return A._asInt(J.$shru$n(thing, 1));
}*/
/*prod.member: cannotRecognize:function(thing) {
  return J.$shru$n(thing, 1);
}*/
int cannotRecognize(dynamic thing) {
  return thing >>> 1;
}

@pragma('dart2js:noInline')
/*member: cannotConstantFold:function() {
  return B.JSInt_methods.$shru(1, -1);
}*/
int cannotConstantFold() {
  var a = 1;
  return a >>> -1;
}

@pragma('dart2js:noInline')
/*member: constantFoldPositive:function() {
  return 25;
}*/
int constantFoldPositive() {
  var a = 100;
  return a >>> 2;
}

@pragma('dart2js:noInline')
/*member: constantFoldNegative:function() {
  return 3;
}*/
int constantFoldNegative() {
  var a = -1;
  return a >>> 30;
}

@pragma('dart2js:noInline')
/*member: unspecialized:function(a) {
  return B.JSInt_methods.$shru(1, a);
}*/
int unspecialized(int a) {
  return 1 >>> a;
}

@pragma('dart2js:noInline')
/*member: otherPositive2:function(param) {
  return B.JSInt_methods._shruOtherPositive$1(1, param ? 1 : 2);
}*/
int otherPositive2(bool param) {
  var a = param ? 1 : 2;
  return 1 >>> a;
}

@pragma('dart2js:noInline')
/*member: shiftBySix:function(param) {
  return (param ? 4294967295 : -1) >>> 6;
}*/
int shiftBySix(bool param) {
  var a = param ? 0xFFFFFFFF : -1;
  return a >>> 6;
}

@pragma('dart2js:noInline')
/*member: shiftByMasked:function(param1, shift) {
  var a = param1 ? 4294967295 : 0;
  return a >>> (shift & 31);
}*/
int shiftByMasked(bool param1, int shift) {
  var a = param1 ? 0xFFFFFFFF : 0;
  return a >>> (shift & 31);
}

@pragma('dart2js:noInline')
/*member: otherPositive6:function(a, b) {
  return B.JSInt_methods._shruOtherPositive$1(a, b);
}*/
int otherPositive6(int a, int b) {
  return a >>> b;
}

void test6() {
  sink = otherPositive6(1, 3);
  sink = otherPositive6(0, 4);
  sink = otherPositive6(-1, 2);
}

class C {
  /*member: C.>>>:ignore*/
  C operator >>>(int i) => this;
}
