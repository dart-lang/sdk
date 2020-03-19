// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsTest;

import 'dart:async';
import 'dart:html' as html;
import 'dart:js';
import 'package:js/js.dart';

import 'package:expect/expect.dart' show NoInline, AssumeDynamic, Expect;
import 'package:expect/minitest.dart';

@JS()
external makeDiv(String text);

@JS()
class HTMLDivElement {
  external String bar();
}

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

main() {
  test('js-call-js-method', () {
    var e = confuse(makeDiv('hello'));
    expect(e.bar(), equals('hello'));
  });

  test('dom-call-js-method', () {
    var e = confuse(new html.DivElement());
    expect(() => e.bar(), throws);
  });

  test('js-call-dom-method', () {
    var e = confuse(makeDiv('hello'));
    expect(() => e.clone(false), throws);
  });

  test('dom-call-dom-method', () {
    var e = confuse(new html.DivElement());
    Expect.type<html.DivElement>(e.clone(false));
  });
}
