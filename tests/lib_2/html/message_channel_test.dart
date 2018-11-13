// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:expect/minitest.dart';

main() async {
  var gotOnMessage = false;
  var gotEventListener = false;

  Completer completer = new Completer();

  var channel = new MessageChannel();
  channel.port1.postMessage("Tickle me.");

  channel.port2.onMessage.listen((MessageEvent e) {
    expect(e.data, "Tickle me.");
    gotOnMessage = true;
  });

  channel.port2.addEventListener("message", (message) {
    var msg = message as MessageEvent;
    expect(msg.data, "Tickle me.");
    gotEventListener = true;
    completer.complete();
  });

  // Wait for the event listener.
  await completer.future;

  // Make sure both fired.
  expect(gotOnMessage, true);
  expect(gotEventListener, true);
}
