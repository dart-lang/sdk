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
  });

  group('HTMLDivElement-types-erroneous1', () {
    test('dom-is-js', () {
      var e = confuse(new html.DivElement());
      // TODO(26838): When Issue 26838 is fixed and this test passes, move this
      // test into group `HTMLDivElement-types`.

      // Currently, HTML types are not [JavaScriptObject]s. We could change that
      // by having HTML types extend JavaScriptObject, in which case we would
      // change this expectation.
      expect(e is HTMLDivElement, isFalse);
    });
  });

  group('HTMLDivElement-types-erroneous2', () {
    test('String-is-not-js', () {
      var e = confuse('kombucha');
      // TODO(26838): When Issue 26838 is fixed and this test passes, move this
      // test into group `HTMLDivElement-types`.

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
