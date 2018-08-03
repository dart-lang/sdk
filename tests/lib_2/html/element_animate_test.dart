// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library element_animate_test;

import 'dart:async';
import 'dart:html';
import 'package:unittest/html_individual_config.dart';
import 'package:unittest/unittest.dart';

main() {
  useHtmlIndividualConfiguration();

  group('animate_supported', () {
    test('supported', () {
      expect(Animation.supported, isTrue);
    });
  });

  group('simple_timing', () {
    test('simple timing', () {
      var body = document.body;
      var opacity = num.parse(body.getComputedStyle().opacity);
      body.animate([
        {"opacity": 100},
        {"opacity": 0}
      ], 100);
      var newOpacity = num.parse(body.getComputedStyle().opacity);
      expect(newOpacity == opacity, isTrue);
    });
  });

  group('timing_dict', () {
    test('timing dict', () {
      var body = document.body;
      // Animate different characteristics so the tests can run concurrently.
      var fontSize = body.getComputedStyle().fontSize;
      var player = body.animate([
        {"font-size": "500px"},
        {"font-size": fontSize}
      ], {
        "duration": 100
      });
      var newFontSize = body.getComputedStyle().fontSize;
      // Don't bother to parse to numbers, as long as it's changed that
      // indicates something is happening.
      expect(newFontSize == fontSize, isFalse);
      player.on['finish'].listen(expectAsync((_) => 'done'));
    });
  });

  group('omit_timing', () {
    test('omit timing', () {
      var body = document.body;
      var player = body.animate([
        {"transform": "translate(100px, -100%)"},
        {"transform": "translate(400px, 500px)"}
      ]);
      player.on['finish'].listen(expectAsync((_) => 'done'));
    });
  });
}
