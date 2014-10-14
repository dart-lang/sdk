// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library validator.utils;

import 'package:scheduled_test/scheduled_test.dart';

import '../test_pub.dart';

void expectNoValidationError(ValidatorCreator fn) {
  expect(schedulePackageValidation(fn), completion(pairOf(isEmpty, isEmpty)));
}

void expectValidationError(ValidatorCreator fn) {
  expect(
      schedulePackageValidation(fn),
      completion(pairOf(isNot(isEmpty), anything)));
}

void expectValidationWarning(ValidatorCreator fn) {
  expect(
      schedulePackageValidation(fn),
      completion(pairOf(isEmpty, isNot(isEmpty))));
}
