// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/src/build/log_injector.dart';


main() {

  useHtmlConfiguration();

  setUp(() => new LogInjector().injectLogs(
      '''[
          {"level": "Info", "message": "foo"},
          {"level": "Warning", "message": "bar"},
          {"level": "Error", "message": "baz"}
      ]'''
  ));

  test('can inject a functioning log widget', () {
    var logsElement = document.querySelector(".build-logs");
    expect(logsElement, isNotNull);

    var menuElements = logsElement.querySelectorAll(".menu > div");
    expect(menuElements.length, 3);
    var contentElements = logsElement.querySelectorAll(".content > div");
    expect(contentElements.length, 3);

    var expectedClasses = ['info', 'warning', 'error'];

    // Check initial setup.
    for (var i = 0; i < menuElements.length; ++i) {
      expect(menuElements[i].classes.contains(expectedClasses[i]), true);
      expect(menuElements[i].classes.contains('active'), false);
      expect(contentElements[i].classes.contains(expectedClasses[i]), true);
      expect(contentElements[i].classes.contains('active'), false);
      expect(contentElements[i].querySelectorAll('.log').length, 1);
    }

    // Test clicking each of the tabs.
    for (var i = 0; i < menuElements.length; ++i) {
      menuElements[i].click();
      for (var j = 0; j < menuElements.length; ++j) {
        expect(menuElements[j].classes.contains('active'), j == i);
        expect(contentElements[j].classes.contains('active'), j == i);
      }
    }

    // Test toggling same tab.
    expect(menuElements[2].classes.contains('active'), true);
    menuElements[2].click();
    expect(menuElements[2].classes.contains('active'), false);
    expect(contentElements[2].classes.contains('active'), false);
  });
}
