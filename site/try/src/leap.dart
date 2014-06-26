// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.main;

import 'dart:html' show
    HttpRequest,
    LinkElement,
    querySelector,
    window;

import 'dart:isolate' show
    Isolate,
    ReceivePort,
    SendPort;

import 'compilation.dart' show
    compilerIsolate,
    compilerPort,
    currentSource;

import 'samples.dart' show
    EXAMPLE_HELLO;

import 'ui.dart' show
    buildUI,
    interaction,
    observer;

import 'user_option.dart' show
    UserOption;

int count = 0;

main() {
  UserOption.storage = window.localStorage;
  if (currentSource == null) {
    currentSource = EXAMPLE_HELLO;
  }

  buildUI();
  ReceivePort port = new ReceivePort();
  Isolate.spawnUri(
      Uri.base.resolve('compiler_isolate.dart.js'),
      const <String>[], port.sendPort).then((Isolate isolate) {
    LinkElement link = querySelector('link[rel="dart-sdk"]');
    String sdk = link.href;
    print('Using Dart SDK: $sdk');
    int messageCount = 0;
    SendPort sendPort;
    port.listen((message) {
      messageCount++;
      switch (messageCount) {
        case 1:
          sendPort = message as SendPort;
          sendPort.send([sdk, port.sendPort]);
          break;
        case 2:
          // Acknowledged Receiving the SDK URI.
          compilerPort = sendPort;
          interaction.onMutation([], observer);
          break;
        default:
          // TODO(ahe): Close [port]?
          print('Unexpected message received: $message');
          break;
      }
    });
  });
}
