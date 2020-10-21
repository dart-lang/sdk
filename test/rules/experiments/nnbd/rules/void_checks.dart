// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N void_checks`

import 'dart:async';

void emptyFunctionExpressionReturningFutureOrVoid(FutureOr<void> Function() f) {
  f = () {}; // OK
}
