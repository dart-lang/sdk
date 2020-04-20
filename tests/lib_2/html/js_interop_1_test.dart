// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library JsInterop1Test;

import 'package:async_helper/async_helper.dart';
import 'dart:async';
import 'dart:html';

injectSource(code) {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHtml = code;
  document.body.append(script);
}

main() {
  asyncTest(() async {
    var subscription;
    var completer = Completer<void>();
    subscription = window.onMessage.listen((e) {
      if (!completer.isCompleted && e.data == 'hello') {
        completer.complete();
        subscription.cancel();
      }
    });
    injectSource("window.postMessage('hello', '*');");

    await completer;
  });
}
