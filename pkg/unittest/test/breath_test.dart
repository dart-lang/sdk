// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:unittest/unittest.dart';

main() {
  // Test the sync test 'breath' feature of unittest.

  group('breath', () {
    var sentinel = 0;
    var start;

    test('initial', () {
      Timer.run(() { sentinel = 1; });
    });

    test('starve', () {
      start = new DateTime.now().millisecondsSinceEpoch;
      var now;
      do {
        expect(sentinel, 0);
        now = new DateTime.now().millisecondsSinceEpoch;
      } while (now - start <= BREATH_INTERVAL);
    });

    test('breathed', () {
      expect(sentinel, 1);
    });
  });
}

