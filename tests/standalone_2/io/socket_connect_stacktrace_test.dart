// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests stack trace on socket exceptions.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

import 'dart:io';

Future<void> main() async {
  asyncStart();

  // Test stacktrace when lookup fails
  try {
    await WebSocket.connect('ws://localhost.tld:0/ws');
  } catch (err, stackTrace) {
    Expect.contains('Failed host lookup', err.toString());
    Expect.contains("main ", stackTrace.toString());
  }

  // Test stacktrace when connection fails
  try {
    await WebSocket.connect('ws://localhost:0/ws');
  } catch (err, stackTrace) {
    Expect.contains("main ", stackTrace.toString());
  }
  asyncEnd();
}
