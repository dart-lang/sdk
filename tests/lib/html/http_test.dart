// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

bool testSwitch(int currentValue) {
  switch (currentValue) {
    case HttpStatus.continue_:
      return true;
    case HttpStatus.ok:
      return true;
    case HttpStatus.NETWORK_CONNECT_TIMEOUT_ERROR:
      return true;
  }

  return false;
}

main() {
  expect(testSwitch(HttpStatus.continue_), isTrue);
  expect(testSwitch(HttpStatus.CONTINUE), isTrue);

  expect(testSwitch(HttpStatus.ok), isTrue);
  expect(testSwitch(HttpStatus.OK), isTrue);

  expect(testSwitch(HttpStatus.networkConnectTimeoutError), isTrue);
  expect(testSwitch(HttpStatus.NETWORK_CONNECT_TIMEOUT_ERROR), isTrue);

  expect(testSwitch(-20100), isFalse);
}
