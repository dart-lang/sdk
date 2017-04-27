// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:math' as math;
import 'dart:math' show min;

class C {
  T m<T extends num>(T x, T y) => null;
}

main() {
  takeIII(math.max);
  takeDDD(math.max);
  takeNNN(math.max);
  takeIDN(math.max);
  takeDIN(math.max);
  takeIIN(math.max);
  takeDDN(math.max);
  takeIIO(math.max);
  takeDDO(math.max);

  takeOOI(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/ math.max);
  takeIDI(
      /*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ math.max);
  takeDID(
      /*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ math.max);
  takeOON(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/ math.max);
  takeOOO(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/ math.max);

// Also test SimpleIdentifier
  takeIII(min);
  takeDDD(min);
  takeNNN(min);
  takeIDN(min);
  takeDIN(min);
  takeIIN(min);
  takeDDN(min);
  takeIIO(min);
  takeDDO(min);

  takeOOI(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/ min);
  takeIDI(/*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ min);
  takeDID(/*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ min);
  takeOON(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/ min);
  takeOOO(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/ min);

// Also PropertyAccess
  takeIII(new C().m);
  takeDDD(new C().m);
  takeNNN(new C().m);
  takeIDN(new C().m);
  takeDIN(new C().m);
  takeIIN(new C().m);
  takeDDN(new C().m);
  takeIIO(new C().m);
  takeDDO(new C().m);

// Note: this is a warning because a downcast of a method tear-off could work
// (derived method can be a subtype):
//
//     class D extends C {
//       S m<S extends num>(Object x, Object y);
//     }
//
// That's legal because we're loosening parameter types.
//
// We do issue the inference error though, similar to generic function calls.
  takeOON(/*error:COULD_NOT_INFER,info:DOWN_CAST_COMPOSITE*/ new C().m);
  takeOOO(/*error:COULD_NOT_INFER,info:DOWN_CAST_COMPOSITE*/ new C().m);

// Note: this is a warning because a downcast of a method tear-off could work
// in "normal" Dart, due to bivariance.
//
// We do issue the inference error though, similar to generic function calls.
  takeOOI(/*error:COULD_NOT_INFER,info:DOWN_CAST_COMPOSITE*/ new C().m);

  takeIDI(
      /*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ new C().m);
  takeDID(
      /*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ new C().m);
}

void takeIII(int fn(int a, int b)) {}
void takeDDD(double fn(double a, double b)) {}
void takeIDI(int fn(double a, int b)) {}
void takeDID(double fn(int a, double b)) {}
void takeIDN(num fn(double a, int b)) {}
void takeDIN(num fn(int a, double b)) {}
void takeIIN(num fn(int a, int b)) {}
void takeDDN(num fn(double a, double b)) {}
void takeNNN(num fn(num a, num b)) {}
void takeOON(num fn(Object a, Object b)) {}
void takeOOO(num fn(Object a, Object b)) {}
void takeOOI(int fn(Object a, Object b)) {}
void takeIIO(Object fn(int a, int b)) {}
void takeDDO(Object fn(double a, double b)) {}
