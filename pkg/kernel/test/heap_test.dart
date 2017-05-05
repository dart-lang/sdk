// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/src/heap.dart';
import 'package:test/test.dart';

main() {
  check_sort(Iterable<int> initialOrder) {
    var values = initialOrder.toList();
    var heap = new _intHeap();
    values.forEach(heap.add);
    values.sort();
    var result = <int>[];
    while (heap.isNotEmpty) {
      expect(heap.isEmpty, isFalse);
      result.add(heap.remove());
    }
    expect(heap.isEmpty, isTrue);
    expect(result, values);
  }

  test('sort', () {
    check_sort(<int>[3, 1, 4, 1, 5, 9, 2, 6]);
  });

  test('sort_already_sorted', () {
    check_sort(<int>[1, 1, 2, 3, 4, 5, 6, 9]);
  });

  test('sort_reverse_sorted', () {
    check_sort(<int>[9, 6, 5, 4, 3, 2, 1, 1]);
  });
}

class _intHeap extends Heap<int> {
  bool sortsBefore(int a, int b) => a < b;
}
