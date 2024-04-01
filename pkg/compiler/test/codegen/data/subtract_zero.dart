// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generally, we can replace `a - b` with `a` when `a` is a number and `b` is
// zero.
//
// The exception is when both operands are negative zero: `(-0.0) - (-0.0)`
// results in a non-negative zero.
//
// With web numbers, the value `-0.0` is recognized as an integer so can occur
// as a constant right operand, usually by constant-folding.

/*member: main:ignore*/
void main() {
  for (final a in [
    C(),
    0,
    -0.0,
    1,
    -1,
    1.1,
    -1.1,
    double.nan,
    double.infinity,
    double.negativeInfinity,
  ]) {
    sink.add(whenDynamic(a));

    if (a is int) {
      sink.add(whenInt1(a));
      sink.add(whenInt2(a));
    }
    if (a is double) {
      sink.add(whenDouble1(a));
      sink.add(whenDouble2(a));
    }
    if (a is num) {
      sink.add(whenNum1(a));
      sink.add(whenNum2(a));
      sink.add(whenNum3(a));
    }
  }
}

final List<Object?> sink = [];

@pragma('dart2js:never-inline')
/*member: whenDynamic:function(thing) {
  return J.$sub$n(thing, 0);
}*/
whenDynamic(dynamic thing) {
  return thing - 0;
}

@pragma('dart2js:never-inline')
/*member: whenInt1:function(a) {
  return a;
}*/
int whenInt1(int a) {
  return a - 0;
}

@pragma('dart2js:never-inline')
/*member: whenInt2:function(a) {
  return a - -0.0;
}*/
int whenInt2(int a) {
  return a - (-0);
}

@pragma('dart2js:never-inline')
/*member: whenDouble1:function(a) {
  return a;
}*/
double whenDouble1(double a) {
  return a - 0;
}

@pragma('dart2js:never-inline')
/*member: whenDouble2:function(a) {
  return a - -0.0;
}*/
double whenDouble2(double a) {
  return a - (-0.0);
}

@pragma('dart2js:never-inline')
/*member: whenNum1:function(a) {
  return a;
}*/
num whenNum1(num a) {
  return a - 0;
}

@pragma('dart2js:never-inline')
/*member: whenNum2:function(a) {
  return a - -0.0;
}*/
num whenNum2(num a) {
  return a - (-0);
}

@pragma('dart2js:never-inline')
/*member: whenNum3:function(a) {
  return a - -0.0;
}*/
num whenNum3(num a) {
  return a - (-0.0);
}

class C {
  /*member: C.-:ignore*/
  C operator -(int i) => this;
}
