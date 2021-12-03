// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Verify that socket connection gracefully closes if cancelled.

import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';

void main() async {
  final task = await Socket.startConnect('google.com', 80);
  task.cancel();
  try {
    await task.socket;
  } catch (e) {
    Expect.isTrue(e is SocketException);
    final socketException = e as SocketException;
    Expect.isTrue(
        socketException.message.startsWith('Connection attempt cancelled'));
  }
}
