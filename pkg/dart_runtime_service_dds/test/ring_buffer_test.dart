// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service_dds/src/ring_buffer.dart';
import 'package:test/test.dart';

void main() {
  group('RingBuffer', () {
    test('adds elements and iterates in order', () {
      final buffer = RingBuffer<int>(3);
      expect(buffer.bufferSize, 3);
      expect(buffer.isTruncated, isFalse);
      expect(buffer().toList(), isEmpty);

      buffer.add(1);
      buffer.add(2);
      expect(buffer().toList(), equals(<int>[1, 2]));
      expect(buffer.isTruncated, isFalse);

      buffer.add(3);
      expect(buffer().toList(), equals(<int>[1, 2, 3]));
      expect(buffer.isTruncated, isFalse);

      // Eviction happens when exceeding buffer size.
      final evicted = buffer.add(4);
      expect(evicted, equals(1));
      expect(buffer().toList(), equals(<int>[2, 3, 4]));
      expect(buffer.isTruncated, isTrue);
    });

    test('resizes buffer correctly', () {
      final buffer = RingBuffer<int>(3);
      buffer.add(1);
      buffer.add(2);
      buffer.add(3);
      buffer.add(4);
      expect(buffer().toList(), equals(<int>[2, 3, 4]));

      // Grow buffer size.
      buffer.resize(5);
      expect(buffer.bufferSize, 5);
      expect(buffer().toList(), equals(<int>[2, 3, 4]));
      buffer.add(5);
      buffer.add(6);
      expect(buffer().toList(), equals(<int>[2, 3, 4, 5, 6]));

      // Shrink buffer size.
      buffer.resize(2);
      expect(buffer.bufferSize, 2);
      expect(buffer().toList(), equals(<int>[5, 6]));
    });
  });
}
