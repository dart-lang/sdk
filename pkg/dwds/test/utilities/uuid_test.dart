// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/utilities/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('Uuid', () {
    test('v4 generates valid UUIDs', () {
      final uuid = const Uuid();
      final id = uuid.v4();
      expect(id, hasLength(36));
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
            r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('v4 generates unique UUIDs', () {
      final uuid = const Uuid();
      final id1 = uuid.v4();
      final id2 = uuid.v4();
      expect(id1, isNot(equals(id2)));
    });

    test('v4 sets version and variant bits correctly', () {
      final uuid = const Uuid();
      final id = uuid.v4();
      // Version 4
      expect(id[14], equals('4'));
      // Variant 10xx (8, 9, a, b)
      expect(id[19], matches(RegExp(r'[89ab]')));
    });
  });
}
