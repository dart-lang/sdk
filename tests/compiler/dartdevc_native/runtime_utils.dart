// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_runtime' show gFnType, typeRep, isSubtypeOf;

import 'package:expect/expect.dart';

/// Returns an unwrapped generic function type with a bounded type argument in
/// the form: <T extends [bound]> void -> void.
///
// TODO(nshahan): The generic function type is created as a legacy type.
genericFunction(bound) => gFnType((T) => [typeRep<void>(), []], (T) => [bound]);

/// Returns an unwrapped generic function type with a bounded type argument in
/// the form: <T extends [bound]> [argumentType] -> T.
///
// TODO(nshahan): The generic function type is created as a legacy type.
functionGenericReturn(bound, argumentType) => gFnType(
    (T) => [
          T,
          [argumentType]
        ],
    (T) => [bound]);

/// Returns an unwrapped generic function type with a bounded type argument in
/// the form: <T extends [bound]> T -> [returnType].
///
// TODO(nshahan): The generic function type is created as a legacy type.
functionGenericArg(bound, returnType) => gFnType(
    (T) => [
          returnType,
          [T]
        ],
    (T) => [bound]);

void checkSubtype(s, t) =>
    Expect.isTrue(isSubtypeOf(s, t), '$s should be subtype of $t.');

void checkProperSubtype(s, t) {
  Expect.isTrue(isSubtypeOf(s, t), '$s should be subtype of $t.');
  checkSubtypeFailure(t, s);
}

void checkMutualSubtype(Object s, Object t) {
  Expect.isTrue(isSubtypeOf(s, t), '$s should be subtype of $t.');
  Expect.isTrue(isSubtypeOf(t, s), '$t should be subtype of $s.');
}

void checkSubtypeFailure(s, t) =>
    Expect.isFalse(isSubtypeOf(s, t), '$s should not be subtype of $t.');
