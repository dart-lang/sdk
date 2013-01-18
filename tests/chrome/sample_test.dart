// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sample_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:chrome' as chrome;

main() {
  useHtmlConfiguration();
  test('access', () {
    var window = chrome.app.window;
    expect(window is chrome.WindowModule, true);
  });

  test('fails from browser', () {
    // APIs should not work in standard browser apps.
    expect(() {
      chrome.app.window.create('foo.html');
    }, throws);
  });
}
