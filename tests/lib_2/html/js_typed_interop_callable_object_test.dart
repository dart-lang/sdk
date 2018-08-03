// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_callable_object_test;

import 'dart:html';

import 'package:expect/expect.dart' show NoInline, AssumeDynamic;
import 'package:js/js.dart';
import 'package:expect/minitest.dart';

// This is a regression test for https://github.com/dart-lang/sdk/issues/25658

@NoInline()
@AssumeDynamic()
confuse(x) => x;

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
  "use strict";

  window.callableObject = function (a, b) { return a + b; };
  window.callableObject.foo = function() { return "bar"; };
  window.callableObject.bar = 42;

""");
}

@JS()
@anonymous
class CallableObject {
  /// If a @JS class implements `call`, the underlying representation must be
  /// a JavaScript callable (i.e. function).
  external num call(num a, num b);
  external int get bar;
  external String foo();
}

@JS()
external CallableObject get callableObject;

main() {
  _injectJs();

  group('callable object', () {
    test('simple', () {
      var obj = callableObject;
      expect(obj(4, 5), equals(9));
      expect(obj.bar, equals(42));
      expect(obj.foo(), equals("bar"));

      expect(callableObject(4, 5), equals(9));
      expect(callableObject.bar, equals(42));
      expect(callableObject.foo(), equals("bar"));
    });

    test('dynamic', () {
      var obj = confuse(callableObject);
      expect(obj(4, 5), equals(9));
      expect(obj.bar, equals(42));
      expect(obj.foo(), equals("bar"));
    });
  });
}
