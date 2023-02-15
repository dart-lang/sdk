// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test verifies that concurrent requests to start service server still
// result only in one server being brought up.

import 'dart:async';
import 'dart:developer';

main() async {
  for (int i = 0; i < 32; i++) {
    Service.controlWebServer(enable: true, silenceOutput: true);
  }
  // Give some time for control messages to arrive to vmservice isolate.
  await Future.delayed(Duration(seconds: 2));
  // If the program doesn't hang on shutdown, the test passes.
  // Program hanging means that more than one http server was launched,
  // but only one gets closed.
}
