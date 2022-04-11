// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:isolate';

import 'helpers.dart';

int callbackCount = 0;

void callback(Nonce token) {
  callbackCount++;
  print('$name: Running finalizer: token: $token');
}

final finalizer = Finalizer<Nonce>(callback);

String name;

void main(List<String> arguments, SendPort port) async {
  name = arguments[0];

  final token = Nonce(42);
  makeObjectWithFinalizer(finalizer, token);

  final awaitBeforeShuttingDown = ReceivePort();
  port.send(awaitBeforeShuttingDown.sendPort);
  final message = await awaitBeforeShuttingDown.first;
  print('$name: $message');

  await Future.delayed(Duration(milliseconds: 1));
  print('$name: Awaited to see if there were any callbacks.');

  print('$name: Helper isolate exiting. num callbacks: $callbackCount.');
  port.send(callbackCount);
}
