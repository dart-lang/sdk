// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

main() {
  var universe = rti.testingCreateUniverse();

  // TODO(sra): Add call: rti.testingAddRules(universe, ???);

  var dynamicRti1 = rti.testingUniverseEval(universe, '@');
  var dynamicRti2 = rti.testingUniverseEval(universe, '@');

  Expect.isTrue(identical(dynamicRti1, dynamicRti2));
  Expect.isFalse(dynamicRti1 is String);
  Expect.equals('dynamic', rti.testingRtiToString(dynamicRti1));
}
