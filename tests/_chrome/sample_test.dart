// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sample_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:_chrome' as _chrome;

main() {
  useHtmlConfiguration();
  test('access', () {
    var window = _chrome.app.window;
    expect(window is _chrome.WindowModule, true);
  });

  test('fails from browser', () {
    // APIs should not work in standard browser apps.
    expect(() {
      _chrome.app.window.create('IntentionallyMissingFile.html');
    }, throws);
  });
}
