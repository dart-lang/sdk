// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS_EMBEDDED_GLOBAL;
import 'dart:_js_shared_embedded_names' show RTI_UNIVERSE;
import 'dart:_rti' show isSubtype;

import 'package:expect/expect.dart';

bool isSubtypeOf(s, t) => isSubtype(JS_EMBEDDED_GLOBAL('', RTI_UNIVERSE), s, t);

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
