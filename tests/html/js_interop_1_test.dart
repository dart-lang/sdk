// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library JsInterop1Test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

injectSource(code) {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHtml = code;
  document.body.append(script);
}

main() {
  useHtmlConfiguration();
  var callback;

  test('js-to-dart-post-message', () {
    var subscription = null;
    var complete = false;
    subscription = window.onMessage.listen(expectAsyncUntil((e) {
      if (e.data == 'hello') {
        subscription.cancel();
        complete = true;
      }
    }, () => complete));
    injectSource("window.postMessage('hello', '*');");
  });
}
