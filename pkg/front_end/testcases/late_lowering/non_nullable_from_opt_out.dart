// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.8

import 'non_nullable_from_opt_out_lib.dart';

main() {
  topLevelField = null;
  finalTopLevelField = null;

  var c = new Class<int>();
  c.instanceField = null;
  c.finalInstanceField = null;
  c.instanceTypeVariable = null;
  c.finalInstanceTypeVariable = null;

  Class.staticField = null;
  Class.staticFinalField = null;

  expect(null, topLevelField);
  expect(null, finalTopLevelField);
  expect(null, c.instanceField);
  expect(null, c.finalInstanceField);
  expect(null, c.instanceTypeVariable);
  expect(null, c.finalInstanceTypeVariable);
  expect(null, Class.staticField);
  expect(null, Class.staticFinalField);

  throws(() => finalTopLevelField = null);
  throws(() => c.finalInstanceField = null);
  throws(() => c.finalInstanceTypeVariable = null);
  throws(() => Class.staticFinalField = null);

  method(true, null, null);
}
