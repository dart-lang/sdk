// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:html_common';
import 'dart:js' as js;

import 'package:expect/minitest.dart';

/// Test that if we access objects through JS-interop we get the
/// appropriate objects, even if dart:html maps them.
main() {
  test("Access through JS-interop", () {
    var performance = js.context['performance'];
    var entries = performance.callMethod('getEntries', const []);
    entries.forEach((x) {
      expect(x is js.JsObject, isTrue);
    });
  });
}
