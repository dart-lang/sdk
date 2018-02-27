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
dynamic confuse(dynamic x) => x;

main() {
  useHtmlIndividualConfiguration();

  group('HTMLDivElement-types', () {
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
    test('dom-is-js', () {
      var e = confuse(new html.DivElement());
      // Currently, HTML types are not [JavaScriptObject]s. We could change that
      // by having HTML types extend JavaScriptObject, in which case we would
      // change this expectation.
      expect(e is HTMLDivElement, isFalse);
    });
    test('String-is-not-js', () {
      var e = confuse('kombucha');
      // A String should not be a JS interop type. The type test flags are added
      // to Interceptor, but should be added to the class that implements all
      // the JS-interop methods.
      expect(e is HTMLDivElement, isFalse);
    });
  });

  group('HTMLDivElement-methods', () {
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
  });
}
