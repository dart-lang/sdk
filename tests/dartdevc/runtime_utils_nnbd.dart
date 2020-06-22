// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' show gFnType, typeRep;

/// Returns an unwrapped generic function type with a bounded type argument in
/// the form: <T extends [bound]> void -> void.
Object genericFunction(Object bound) =>
    gFnType((T) => [typeRep<void>(), []], (T) => [bound]);

/// Returns an unwrapped generic function type with a bounded type argument in
/// the form: <T extends [bound]> [argumentType] -> T.
Object functionGenericReturn(Object bound, Object argType) => gFnType(
    (T) => [
          T,
          [argType]
        ],
    (T) => [bound]);

/// Returns an unwrapped generic function type with a bounded type argument in
/// the form: <T extends [bound]> T -> [returnType].
Object functionGenericArg(Object bound, Object returnType) => gFnType(
    (T) => [
          returnType,
          [T]
        ],
    (T) => [bound]);
