// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_extend_class_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS('Date')
class JSDate {
  external get jsField;
  external get jsMethod;
}

@JS('Date.prototype.jsField')
external set datePrototypeJSField(v);

@JS('Date.prototype.jsMethod')
external set datePrototypeJSMethod(v);

// Extending a JS class with a Dart class is only supported by DDC for now.
// We extend the Date class instead of a user defined JS class to avoid the
// hassle of ensuring the JS class exists before we use it.
class DartJsDate extends JSDate {
  get dartField => 100;
  int dartMethod(x) {
    return x * 2;
  }
}

main() {
  // Monkey-patch the JS Date class.
  datePrototypeJSField = 42;
  datePrototypeJSMethod = allowInterop((x) => x * 10);

  group('extend js class', () {
    test('js class members', () {
      var bar = new DartJsDate();
      expect(bar.jsField, equals(42));
      expect(bar.jsMethod(5), equals(50));

      expect(bar.dartField, equals(100));
      expect(bar.dartMethod(4), equals(8));
    });

    test('instance checks and casts', () {
      var bar = new DartJsDate();
      expect(bar is JSDate, isTrue);
      expect(bar as JSDate, equals(bar));
    });

    test('dart subclass members', () {
      var bar = new DartJsDate();
      expect(bar.dartField, equals(100));
      expect(bar.dartMethod(4), equals(8));
    });
  });
}
