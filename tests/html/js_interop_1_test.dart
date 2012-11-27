// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library JsInterop1Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:json';

injectSource(code) {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHtml = code;
  document.body.nodes.add(script);
}

main() {
  useHtmlConfiguration();
  var callback;

  test('js-to-dart-post-message', () {
    var onSuccess = expectAsync1((e) {
      window.on.message.remove(callback);
    });
    callback = (e) {
      if (e.data == 'hello') {
        onSuccess(e);
      }
    };
    window.on.message.add(callback);
    injectSource("window.postMessage('hello', '*');");
  });
}
