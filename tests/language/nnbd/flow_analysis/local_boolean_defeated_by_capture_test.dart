// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks various scenarios in which the use of a local variable for
// type promotion is defeated by write capture of either the local variable
// itself or the variable that would be promoted.

capture_conditionVar_prior_to_assignment(int? x) {
  bool b;
  (bool b2) => b = b2;
  b = x != null;
  if (b) x.expectStaticType<Exactly<int?>>();
}

capture_conditionVar_prior_to_assignment_from_other_condition(int? x) {
  bool b1 = x != null;
  bool b3;
  (bool b2) => b3 = b2;
  b3 = b1;
  if (b3) x.expectStaticType<Exactly<int?>>();
}

capture_promotedVar_prior_to_assignment(int? x) {
  int? y;
  (int? z) => y = z;
  y = x;
  bool b = y != null;
  if (b) y.expectStaticType<Exactly<int?>>();
}

capture_conditionVar_after_assignment(int? x) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  (bool b2) => b = b2;
  if (b) x.expectStaticType<Exactly<int?>>();
}

capture_conditionVar_after_assignment_from_other_condition(int? x) {
  bool b1 = x != null;
  bool b3 = b1;
  if (b3) x.expectStaticType<Exactly<int>>();
  (bool b2) => b3 = b2;
  if (b3) x.expectStaticType<Exactly<int?>>();
}

capture_conditionVar_after_assignment_then_copy_to_other_condition(int? x) {
  bool b1 = x != null;
  bool b3;
  (bool b2) => b1 = b2;
  b3 = b1;
  if (b3) x.expectStaticType<Exactly<int?>>();
}

capture_promotedVar_after_assignment(int? x) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  (int? y) => x = y;
  if (b) x.expectStaticType<Exactly<int?>>();
}

main() {
  capture_conditionVar_prior_to_assignment(null);
  capture_conditionVar_prior_to_assignment(0);
  capture_conditionVar_prior_to_assignment_from_other_condition(null);
  capture_conditionVar_prior_to_assignment_from_other_condition(0);
  capture_promotedVar_prior_to_assignment(null);
  capture_promotedVar_prior_to_assignment(0);
  capture_conditionVar_after_assignment(null);
  capture_conditionVar_after_assignment(0);
  capture_conditionVar_after_assignment_from_other_condition(null);
  capture_conditionVar_after_assignment_from_other_condition(0);
  capture_conditionVar_after_assignment_then_copy_to_other_condition(null);
  capture_conditionVar_after_assignment_then_copy_to_other_condition(0);
  capture_promotedVar_after_assignment(null);
  capture_promotedVar_after_assignment(0);
}
