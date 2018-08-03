// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_dart_to_string_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""

  function jsToStringViaCoercion(a) {
    return a + '';
  };
""");
}

@JS()
external String jsToStringViaCoercion(obj);

class ExampleClassWithCustomToString {
  var x;
  ExampleClassWithCustomToString(this.x);
  String toString() => "#$x#";
}

main() {
  _injectJs();

  useHtmlConfiguration();

  group('toString', () {
    test('custom dart', () {
      var x = new ExampleClassWithCustomToString("fooBar");
      expect(jsToStringViaCoercion(x), equals("#fooBar#"));
      expect(jsToStringViaCoercion({'a': 1, 'b': 2}), equals("{a: 1, b: 2}"));
    });
  });
}
