// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library element_animate_test;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_minitest.dart';

main() {
  test('timing dict', () {
    if (Animation.supported) {
      var body = document.body!;
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
    }
  });
}
