// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  static late int sf1;
  static late final int sf2;
  static late final int sf3 = recursiveInitSf3();

  static bool doRecursiveInitSf3 = true;
  static int recursiveInitSf3() {
    if (doRecursiveInitSf3) {
      doRecursiveInitSf3 = false;
      return sf3; // Trigger initialization recursively.
    }
    return 3;
  }

  late int f1;
  late final int f2;
  late final int f3 = recursiveInitF3();

  bool doRecursiveInitF3 = true;
  int recursiveInitF3() {
    if (doRecursiveInitF3) {
      doRecursiveInitF3 = false;
      return f3; // Trigger initialization recursively.
    }
    return 3;
  }
}

bool isValidError(error, String message) {
  if (error is LateInitializationError) {
    Expect.equals('LateInitializationError: $message', error.toString());
    return true;
  }
  return false;
}

main() {
  // Static fields.

  Expect.throws(() => A.sf1,
      (e) => isValidError(e, "Field 'sf1' has not been initialized."));
  Expect.throws(() => A.sf2,
      (e) => isValidError(e, "Field 'sf2' has not been initialized."));
  A.sf2 = 42;
  Expect.throws(() {
    A.sf2 = 2;
  }, (e) => isValidError(e, "Field 'sf2' has already been initialized."));
  Expect.throws(
      () => A.sf3,
      (e) => isValidError(
          e, "Field 'sf3' has been assigned during initialization."));

  // Instance fields.

  A obj = A();
  Expect.throws(() => obj.f1,
      (e) => isValidError(e, "Field 'f1' has not been initialized."));
  Expect.throws(() => obj.f2,
      (e) => isValidError(e, "Field 'f2' has not been initialized."));
  obj.f2 = 42;
  Expect.throws(() {
    obj.f2 = 2;
  }, (e) => isValidError(e, "Field 'f2' has already been initialized."));
  Expect.throws(
      () => obj.f3,
      (e) => isValidError(
          e, "Field 'f3' has been assigned during initialization."));

  // Local variables.
  late int local1;
  late final int local2;

  late int Function() recursiveInitLocal3;
  late final int local3 = recursiveInitLocal3();

  bool doRecursiveInitLocal3 = true;
  recursiveInitLocal3 = () {
    if (doRecursiveInitLocal3) {
      doRecursiveInitLocal3 = false;
      return local3; // Trigger initialization recursively.
    }
    return 3;
  };

  // Avoid compile-time error "Late variable 'local1' without initializer is
  // definitely unassigned."
  if (int.parse('1') == 2) {
    local1 = -1;
  }

  Expect.throws(() => local1,
      (e) => isValidError(e, "Local 'local1' has not been initialized."));
  Expect.throws(() => local2,
      (e) => isValidError(e, "Local 'local2' has not been initialized."));
  // Assignment is conditional to avoid compile-time error "Late final variable
  // 'local2' definitely assigned."
  if (int.parse('1') == 1) {
    local2 = 42;
  }
  Expect.throws(() {
    local2 = 2;
  }, (e) => isValidError(e, "Local 'local2' has already been initialized."));
  Expect.throws(
      () => local3,
      (e) => isValidError(
          e, "Local 'local3' has been assigned during initialization."));
}
