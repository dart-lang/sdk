// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' as html;

import 'package:expect/minitest.dart';

import 'util.dart';

main() {
  setUpJS();
  test('dom-is-js', () {
    var e = confuse(new html.DivElement());
    // Currently, HTML types are not `LegacyJavaScriptObject`s, so therefore
    // they cannot be used with the usual `package:js` types.
    expect(e is HTMLDivElement, isFalse);
  });
  test('dom-is-static-js', () {
    var e = confuse(new html.DivElement());
    // However, HTML types are `JavaScriptObject`s, so they can be used with
    // static `package:js` types, using `@staticInterop`.
    expect(e is StaticHTMLDivElement, isTrue);
  });
}
