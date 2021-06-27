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
    // Currently, HTML types are not [JavaScriptObject]s. We could change that
    // by having HTML types extend JavaScriptObject, in which case we would
    // change this expectation.
    expect(e is HTMLDivElement, isFalse);
  });
}
