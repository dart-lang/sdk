// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_bind_this_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

// This is a regression test for https://github.com/dart-lang/sdk/issues/25658

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
  "use strict";

  function JsTest() {
  }

  JsTest.returnThis = function(name, value) {
    return this;
  };
""");
}

@JS('JsTest.returnThis')
external returnThis([name, value]);

@JS('JsTest')
external get jsTestObject;

@JS('window')
external get jsWindow;

main() {
  _injectJs();

  group('bind this', () {
    test('simple', () {
      expect(identical(returnThis(), jsWindow), isFalse);
      expect(identical(returnThis(), null), isFalse);
      expect(identical(returnThis(), jsTestObject), isTrue);
    });
  });
}
