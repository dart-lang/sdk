// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

Never doThrow() {
  throw 'TheException'; // Line 13.
}

String doCaught() {
  try {
    doThrow();
  } catch (e) {
    return 'end of doCaught';
  }
}

String doUncaught() {
  doThrow();
  // ignore: dead_code
  return 'end of doUncaught';
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest();
}
