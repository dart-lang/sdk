// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:telemetry/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('ThrottlingBucket', () {
    test('can send', () {
      ThrottlingBucket bucket = new ThrottlingBucket(10, Duration(minutes: 1));
      expect(bucket.removeDrop(), true);
    });

    test("doesn't send too many", () {
      ThrottlingBucket bucket = new ThrottlingBucket(10, Duration(minutes: 1));
      for (int i = 0; i < 10; i++) {
        expect(bucket.removeDrop(), true);
      }
      expect(bucket.removeDrop(), false);
    });
  });
}
