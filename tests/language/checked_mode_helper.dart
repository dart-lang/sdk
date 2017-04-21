// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library checked_mode_helper;

import 'package:expect/expect.dart';

/// Returns `true` if the program is running in checked mode.
bool inCheckedMode() {
  try {
    var i = 42;
    String s = i;
  } on TypeError catch (e) {
    return true;
  }
  return false;
}

/// Checks that a dynamic type error is thrown if and only if [f] is executed in
/// checked mode and [expectTypeError] is `true`.
void testDynamicTypeError(bool expectTypeError, f(), [String message]) {
  if (expectTypeError) {
    checkDynamicTypeError(f, message);
  } else {
    checkNoDynamicTypeError(f, message);
  }
}

/// Checks that a dynamic type error is thrown if and only if [f] is executed in
/// checked mode.
void checkDynamicTypeError(f(), [String message]) {
  message = message != null ? ': $message' : '';
  try {
    f();
    Expect.isFalse(
        inCheckedMode(), 'Missing type error in checked mode$message.');
  } on TypeError catch (e) {
    Expect.isTrue(inCheckedMode(), 'Unexpected type error in production mode.');
  }
}

/// Checks that no dynamic type error is thrown when [f] is executed regardless
/// of execution mode.
void checkNoDynamicTypeError(f(), [String message]) {
  message = message != null ? ': $message' : '';
  try {
    f();
  } on TypeError catch (e) {
    String mode = inCheckedMode() ? 'checked mode' : 'production mode';
    Expect.fail('Unexpected type error in $mode$message.');
  }
}
