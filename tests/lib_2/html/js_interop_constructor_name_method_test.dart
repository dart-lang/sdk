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
    expect(e.clone(false), new isInstanceOf<html.DivElement>());
  });
}
