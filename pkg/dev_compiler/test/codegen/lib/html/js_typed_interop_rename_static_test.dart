// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_rename_static_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS('JSTopLevelField')
external set topLevelFieldOnlySetter(v);

@JS('JSTopLevelField')
external get topLevelFieldOnlyGetter;

@JS()
external get topLevelFieldNoRename;

@JS()
external set topLevelSetterNoRename(v);

@JS()
external topLevelMethod(v);

@JS('topLevelMethod')
external renamedTopLevelMethod(v);

@JS('JSFoo')
class Foo {
  @JS('JSBar')
  external static get bar;

  @JS('JSBar')
  external static set bar(v);

  @JS('JSBar2')
  external static get bar2;

  @JS('JSBaz')
  external static set baz(v);

  @JS('JSMethodAddBar')
  external static addBar(a);
}

main() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
window.JSFoo = {
  'JSBar': 42,
  'JSBar2': 80,
  'JSMethodAddBar': function(a,b) { return a + this.JSBar; }
};
window.JSTopLevelField = 91;
window.topLevelFieldNoRename = 8;
window.topLevelMethod = function(a) { return a * 2; };
""");

  group('rename static', () {
    test('getter', () {
      expect(Foo.bar, equals(42));
      expect(Foo.bar2, equals(80));
      expect(topLevelFieldOnlyGetter, 91);
      expect(topLevelFieldNoRename, 8);
    });

    test('setter', () {
      Foo.baz = 100;
      expect(js_util.getProperty(js_util.getProperty(window, 'JSFoo'), 'JSBaz'),
          equals(100));
      Foo.bar = 30;
      expect(Foo.bar, equals(30));
      expect(js_util.getProperty(js_util.getProperty(window, 'JSFoo'), 'JSBar'),
          equals(30));
      topLevelFieldOnlySetter = 83;
      expect(topLevelFieldOnlyGetter, 83);
      topLevelSetterNoRename = 10;
      expect(js_util.getProperty(window, 'topLevelSetterNoRename'), 10);
    });

    test('method', () {
      Foo.bar = 100;
      expect(Foo.addBar(10), equals(110));
      Foo.bar = 200;
      expect(Foo.addBar(10), equals(210));
      expect(topLevelMethod(10), equals(20));
      expect(renamedTopLevelMethod(10), equals(20));
    });
  });
}
