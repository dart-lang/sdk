// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsTest;

import 'dart:async';
import 'dart:html' as html;
import 'dart:js';
import 'package:js/js.dart';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'package:expect/expect.dart' show NoInline, AssumeDynamic;

@JS()
external makeDiv(String text);

@JS()
class HTMLDivElement {
  external String bar();
}

@NoInline()
@AssumeDynamic()
confuse(x) => x;

main() {
  useHtmlIndividualConfiguration();

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
