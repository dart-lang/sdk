// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when `inference-update-3` is disabled, and an assignment is made
// to a local variable (or parameter), the unpromoted type of the variable is
// used as the context for the RHS of the assignment.

// @dart=3.3

import 'package:expect/expect.dart';

import '../static_type_helper.dart';

void testNonDemotingAssignmentOfParameter(num? x, num? y) {
  if (x != null) {
    x = contextType(1)..expectStaticType<Exactly<num>>();
  }
  if (y is int) {
    y = contextType(1)..expectStaticType<Exactly<int>>();
  }
}

void testNonDemotingAssignmentOfExplicitlyTypedLocal(num? x) {
  num? y = x;
  if (y != null) {
    y = contextType(1)..expectStaticType<Exactly<num>>();
  }
  y = x;
  if (y is int) {
    y = contextType(1)..expectStaticType<Exactly<int>>();
  }
}

void testNonDemotingAssignmentOfImplicitlyTypedLocal(num? x) {
  var y = x;
  if (y != null) {
    y = contextType(1)..expectStaticType<Exactly<num>>();
  }
  y = x;
  if (y is int) {
    y = contextType(1)..expectStaticType<Exactly<int>>();
  }
}

void testDemotingAssignmentOfParameter(num? x, num? y) {
  if (x != null) {
    // A type error is expected at runtime, because type inference will fill in
    // a type of `num` for the type argument of `contextType`, and `contextType`
    // tries to cast its input to its type argument.
    //
    // We can't use `Expect.throwsTypeError` to check for this, because then the
    // assignment would be happening inside a function expression, blocking type
    // promotion.
    bool errorOccurred = false;
    try {
      x = contextType(null)..expectStaticType<Exactly<num>>();
    } on TypeError {
      errorOccurred = true;
    }
    Expect.equals(hasSoundNullSafety, errorOccurred);
  }
  if (y is int) {
    // A type error is expected at runtime, because type inference will fill in
    // a type of `int` for the type argument of `contextType`, and `contextType`
    // tries to cast its input to its type argument.
    //
    // We can't use `Expect.throwsTypeError` to check for this, because then the
    // assignment would be happening inside a function expression, blocking type
    // promotion.
    bool errorOccurred = false;
    try {
      y = contextType(1.5)..expectStaticType<Exactly<int>>();
    } on TypeError {
      errorOccurred = true;
    }
    Expect.isTrue(errorOccurred);
  }
}

void testDemotingAssignmentOfExplicitlyTypedLocal(num? x) {
  num? y = x;
  if (y != null) {
    // A type error is expected at runtime, because type inference will fill in
    // a type of `num` for the type argument of `contextType`, and `contextType`
    // tries to cast its input to its type argument.
    //
    // We can't use `Expect.throwsTypeError` to check for this, because then the
    // assignment would be happening inside a function expression, blocking type
    // promotion.
    bool errorOccurred = false;
    try {
      y = contextType(null)..expectStaticType<Exactly<num>>();
    } on TypeError {
      errorOccurred = true;
    }
    Expect.equals(hasSoundNullSafety, errorOccurred);
  }
  y = x;
  if (y is int) {
    // A type error is expected at runtime, because type inference will fill in
    // a type of `int` for the type argument of `contextType`, and `contextType`
    // tries to cast its input to its type argument.
    //
    // We can't use `Expect.throwsTypeError` to check for this, because then the
    // assignment would be happening inside a function expression, blocking type
    // promotion.
    bool errorOccurred = false;
    try {
      y = contextType(1.5)..expectStaticType<Exactly<int>>();
    } on TypeError {
      errorOccurred = true;
    }
    Expect.isTrue(errorOccurred);
  }
}

void testDemotingAssignmentOfImplicitlyTypedLocal(num? x) {
  var y = x;
  if (y != null) {
    // A type error is expected at runtime, because type inference will fill in
    // a type of `num` for the type argument of `contextType`, and `contextType`
    // tries to cast its input to its type argument.
    //
    // We can't use `Expect.throwsTypeError` to check for this, because then the
    // assignment would be happening inside a function expression, blocking type
    // promotion.
    bool errorOccurred = false;
    try {
      y = contextType(null)..expectStaticType<Exactly<num>>();
    } on TypeError {
      errorOccurred = true;
    }
    Expect.equals(hasSoundNullSafety, errorOccurred);
  }
  y = x;
  if (y is int) {
    // A type error is expected at runtime, because type inference will fill in
    // a type of `int` for the type argument of `contextType`, and `contextType`
    // tries to cast its input to its type argument.
    //
    // We can't use `Expect.throwsTypeError` to check for this, because then the
    // assignment would be happening inside a function expression, blocking type
    // promotion.
    bool errorOccurred = false;
    try {
      y = contextType(1.5)..expectStaticType<Exactly<int>>();
    } on TypeError {
      errorOccurred = true;
    }
    Expect.isTrue(errorOccurred);
  }
}

main() {
  for (var x in [null, 0, 0.5]) {
    testNonDemotingAssignmentOfParameter(x, x);
    testNonDemotingAssignmentOfExplicitlyTypedLocal(x);
    testNonDemotingAssignmentOfImplicitlyTypedLocal(x);
    testDemotingAssignmentOfParameter(x, x);
    testDemotingAssignmentOfExplicitlyTypedLocal(x);
    testDemotingAssignmentOfImplicitlyTypedLocal(x);
  }
}
