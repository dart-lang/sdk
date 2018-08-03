// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dynamic_type_helper;

import 'package:expect/expect.dart';

/// Checks that a dynamic type error is thrown when [f] is executed
/// and [expectTypeError] is `true`.
void testDynamicTypeError(bool expectTypeError, f(), [String message]) {
  if (expectTypeError) {
    checkDynamicTypeError(f, message);
  } else {
    checkNoDynamicTypeError(f, message);
  }
}

/// Checks that a dynamic type error is thrown when f is executed.
void checkDynamicTypeError(f(), [String message]) {
  message = message != null ? ': $message' : '';
  try {
    f();
    Expect.fail('Missing type error$message.');
  } on TypeError catch (e) {}
}

/// Checks that no dynamic type error is thrown when [f] is executed.
void checkNoDynamicTypeError(f(), [String message]) {
  message = message != null ? ': $message' : '';
  try {
    f();
  } on TypeError catch (e) {
    Expect.fail('Unexpected type error$message.');
  }
}
