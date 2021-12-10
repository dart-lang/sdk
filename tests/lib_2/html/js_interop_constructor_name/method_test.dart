// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:html' as html;

import 'package:expect/expect.dart' show Expect;
import 'package:expect/minitest.dart';

import 'util.dart';

main() {
  setUpJS();
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

  test('js-call-static-js-method', () {
    StaticHTMLDivElement e = confuse(makeDiv('hello'));
    expect(e.bar(), equals('hello'));
  });

  test('dom-call-static-js-method', () {
    StaticHTMLDivElement e = confuse(new html.DivElement());
    Expect.type<html.DivElement>(e.cloneNode(false));
  });
}
