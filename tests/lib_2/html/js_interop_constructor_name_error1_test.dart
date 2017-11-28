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

  test('dom-is-js', () {
    var e = confuse(new html.DivElement());
    // TODO(26838): When Issue 26838 is fixed and this test passes, move this
    // test into group `HTMLDivElement-types`.

    // Currently, HTML types are not [JavaScriptObject]s. We could change that
    // by having HTML types extend JavaScriptObject, in which case we would
    // change this expectation.
    expect(e is HTMLDivElement, isFalse);
  });
}
