// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library null_test;

import 'dart:js';
import 'package:expect/expect.dart';

main() {
  context.callMethod('eval', ['isNull = function (x) { return x === null; }']);
  context.callMethod(
      'eval', ['isUndefined = function (x) { return x === void 0; }']);
  Expect.isTrue(context['isNull'].apply([null]));
  Expect.isFalse(context['isUndefined'].apply([null]));
}
