// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'exhaustiveness_lib.dart';

main() {
  expect(true, boolSwitchStatement(true));
  expect(false, boolSwitchStatement(false));
  throws(() => boolSwitchStatement(null));

  expect(true, boolSwitchExpression(true));
  expect(false, boolSwitchExpression(false));
  throws(() => boolSwitchExpression(null));

  expect(0, sealedSwitchStatement(A1()));
  expect(1, sealedSwitchStatement(A2()));
  throws(() => sealedSwitchStatement(null));

  expect(0, sealedSwitchExpression(A1()));
  expect(1, sealedSwitchExpression(A2()));
  throws(() => sealedSwitchExpression(null));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Missing throws';
}
