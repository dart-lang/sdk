// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_int_literals`

const double okDouble = 7.3; // OK
const double shouldBeInt = 8.0; // LINT
const inferredAsDouble = 8.0; // OK
Object inferredAsDouble2 = 8.0; // OK
dynamic inferredAsDouble3 = 8.0; // OK

class A {
  var w = 7.0e2; // OK
  double x = 7.0e2; // LINT
  double y = 7.1e2; // LINT
  double z = 7.576e2; // OK
  A(this.x);
}

// TODO(danrubel): Report lint in these other situations

//class B extends A {
//  B.one() : super(1.0); // LINT
//  B.two() : super(2.3); // OK
//  B.three() : super(3);
//}
//
//void takesDouble(double value){}
//
//double other() {
//  var inferredAsInt = 3;
//  var inferredAsDouble1 = inferredAsInt + 3.0; // OK
//  var inferredAsDouble2 = inferredAsDouble1 + 3.7; // OK
//  var inferredAsDouble3 = inferredAsDouble2 + 3.0; // LINT
//  takesDouble(3.0); // LINT
//  return inferredAsDouble3;
//}
