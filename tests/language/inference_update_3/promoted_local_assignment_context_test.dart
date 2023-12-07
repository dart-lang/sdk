// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when `inference-update-3` is enabled, and an assignment is made to
// a local variable (or parameter), the unpromoted type of the variable is used
// as the context for the RHS of the assignment.

// SharedOptions=--enable-experiment=inference-update-3

import '../static_type_helper.dart';

void testNonDemotingAssignmentOfParameter(num? x, num? y) {
  if (x != null) {
    x = contextType(1)..expectStaticType<Exactly<num?>>();
  }
  if (y is int) {
    y = contextType(1)..expectStaticType<Exactly<num?>>();
  }
}

void testNonDemotingAssignmentOfExplicitlyTypedLocal(num? x) {
  num? y = x;
  if (y != null) {
    y = contextType(1)..expectStaticType<Exactly<num?>>();
  }
  y = x;
  if (y is int) {
    y = contextType(1)..expectStaticType<Exactly<num?>>();
  }
}

void testNonDemotingAssignmentOfImplicitlyTypedLocal(num? x) {
  var y = x;
  if (y != null) {
    y = contextType(1)..expectStaticType<Exactly<num?>>();
  }
  y = x;
  if (y is int) {
    y = contextType(1)..expectStaticType<Exactly<num?>>();
  }
}

void testDemotingAssignmentOfParameter(num? x, num? y) {
  if (x != null) {
    x = contextType(null)..expectStaticType<Exactly<num?>>();
  }
  if (y is int) {
    y = contextType(null)..expectStaticType<Exactly<num?>>();
  }
}

void testDemotingAssignmentOfExplicitlyTypedLocal(num? x) {
  num? y = x;
  if (y != null) {
    y = contextType(null)..expectStaticType<Exactly<num?>>();
  }
  y = x;
  if (y is int) {
    y = contextType(null)..expectStaticType<Exactly<num?>>();
  }
}

void testDemotingAssignmentOfImplicitlyTypedLocal(num? x) {
  var y = x;
  if (y != null) {
    y = contextType(null)..expectStaticType<Exactly<num?>>();
  }
  y = x;
  if (y is int) {
    y = contextType(null)..expectStaticType<Exactly<num?>>();
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
