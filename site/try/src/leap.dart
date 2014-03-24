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
    ReceivePort,
    SendPort;

import 'compilation.dart' show
    compilerIsolate,
    compilerPort;

import 'isolate_legacy.dart' show
    spawnDomFunction,
    spawnFunction;

import 'samples.dart' show
    EXAMPLE_HELLO;

import 'ui.dart' show
    buildUI,
    interaction,
    observer;

import 'user_option.dart' show
    UserOption;

int count = 0;

const String HAS_NON_DOM_HTTP_REQUEST = 'spawnFunction supports HttpRequest';
const String NO_NON_DOM_HTTP_REQUEST =
    'spawnFunction does not support HttpRequest';

checkHttpRequest(SendPort replyTo) {
  try {
    new HttpRequest();
    replyTo.send(HAS_NON_DOM_HTTP_REQUEST);
  } catch (e, trace) {
    replyTo.send(NO_NON_DOM_HTTP_REQUEST);
  }
}

main() {
  UserOption.storage = window.localStorage;
  if (window.localStorage['currentSource'] == null) {
    window.localStorage['currentSource'] = EXAMPLE_HELLO;
  }

  buildUI();
  spawnFunction(checkHttpRequest).first.then((reply) {
    ReceivePort port;
    if (reply == HAS_NON_DOM_HTTP_REQUEST) {
      port = spawnFunction(compilerIsolate);
    } else {
      port = spawnDomFunction(compilerIsolate);
    }
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
