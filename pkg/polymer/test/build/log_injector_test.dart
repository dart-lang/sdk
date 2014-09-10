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
      '''{
        "polymer#0":[{
            "level":"Info",
            "message":{"id":"polymer#0","snippet":"foo"}}
        ],
        "polymer#1":[{
            "level":"Info",
            "message":{"id":"polymer#1","snippet":"foo"},
            "span":{
              "start":{
                "url":"web/test.html",
                "offset":22,
                "line":1,
                "column":0
              },
              "end":{
                "url":"web/test.html",
                "offset":50,
                "line":1,
                "column":28
              },
              "text":"<polymer-element name=\\"x-a\\">"
            }
          }],
        "polymer#2":[
            {"level":"Warning","message":{"id":"polymer#2","snippet":"bar"}},
            {"level":"Warning","message":{"id":"polymer#2",
             "snippet":"bar again"}},
            {"level":"Error","message":{"id":"polymer#2","snippet":"baz1"}}
        ],
        "foo#44":[{"level":"Error","message":{"id":"foo#44","snippet":"baz2"}}]
      }'''
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
      expect(contentElements[i].querySelectorAll('.log').length, 2);
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
