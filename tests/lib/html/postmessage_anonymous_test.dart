// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library postmessage_anonymous_test;

import 'dart:async';
import 'dart:html';
import 'package:expect/expect.dart';
import 'package:js/js.dart';

const String JS_CODE = """
window.addEventListener('message', handler);
function handler(e) {
  var data = e.data;
  if (typeof data == 'string') return;
  if (data.recipient != 'JS') return;
  var response = {recipient: 'DART', msg: data.msg};
  window.removeEventListener('message', handler);
  window.postMessage(response, '*');
}
""";

const String TEST_MSG = "hello world";

@JS()
@anonymous
class Message {
  external String get recipient;
  external String get msg;
  external factory Message({required String recipient, required String msg});
}

main() {
  var subscription;
  subscription = window.onMessage.listen((e) {
    var data = e.data;
    if (data is String) return;
    if (data['recipient'] != 'DART') return;
    subscription.cancel();
    Expect.equals(TEST_MSG, data['msg']);
  });
  injectSource(JS_CODE);
  window.postMessage(Message(recipient: 'JS', msg: TEST_MSG), '*');
}

void injectSource(String code) {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHtml = code;
  document.body!.append(script);
}
