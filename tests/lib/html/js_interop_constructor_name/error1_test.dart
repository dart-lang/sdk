// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsTest;

import 'dart:async';
import 'dart:html' as html;
import 'dart:js';
import 'package:js/js.dart';

import 'package:expect/expect.dart' show NoInline, AssumeDynamic;
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
  test('dom-is-js', () {
    var e = confuse(new html.DivElement());
    // Currently, HTML types are not [JavaScriptObject]s. We could change that
    // by having HTML types extend JavaScriptObject, in which case we would
    // change this expectation.
    expect(e is HTMLDivElement, isFalse);
  });
}
