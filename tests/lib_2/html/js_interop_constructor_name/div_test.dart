// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:html' as html;

import 'package:expect/minitest.dart';

import 'util.dart';

main() {
  setUpJS();
  test('dom-is-dom', () {
    var e = confuse(new html.DivElement());
    expect(e is html.DivElement, isTrue);
  });

  test('js-is-dom', () {
    var e = confuse(makeDiv('hello'));
    expect(e is html.DivElement, isFalse);
  });

  test('js-is-js', () {
    var e = confuse(makeDiv('hello'));
    expect(e is HTMLDivElement, isTrue);
  });
}
