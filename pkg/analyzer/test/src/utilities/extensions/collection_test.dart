// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IterableExtensionTest);
    defineReflectiveTests(IterableMapEntryExtensionTest);
    defineReflectiveTests(ListExtensionTest);
  });
}

@reflectiveTest
class IterableExtensionTest {
  test_whereNotType() {
    expect(<Object>['0', 1, '2'].whereNotType<int>(), ['0', '2']);
  }
}

@reflectiveTest
class IterableMapEntryExtensionTest {
  test_mapFromEntries() {
    final entries = [MapEntry('foo', 0), MapEntry('bar', 1)];
    expect(entries.mapFromEntries, {'foo': 0, 'bar': 1});
  }
}

@reflectiveTest
class ListExtensionTest {
  test_addIfNotNull_notNull() {
    var elements = [0, 1];
    elements.addIfNotNull(2);
    expect(elements, [0, 1, 2]);
  }

  test_addIfNotNull_null() {
    var elements = [0, 1];
    elements.addIfNotNull(null);
    expect(elements, [0, 1]);
  }

  test_elementAtOrNull2() {
    expect([0, 1].elementAtOrNull2(-1), isNull);
    expect([0, 1].elementAtOrNull2(0), 0);
    expect([0, 1].elementAtOrNull2(1), 1);
    expect([0, 1].elementAtOrNull2(2), isNull);
  }

  test_endsWith() {
    expect([0, 1, 2].endsWith([]), isTrue);

    expect([0, 1, 2].endsWith([2]), isTrue);
    expect([0, 1, 2].endsWith([1]), isFalse);
    expect([0, 1, 2].endsWith([0]), isFalse);

    expect([0, 1, 2].endsWith([1, 2]), isTrue);
    expect([0, 1, 2].endsWith([0, 2]), isFalse);

    expect([0, 1, 2].endsWith([0, 1, 2]), isTrue);
    expect([0, 1, 2].endsWith([0, 0, 2]), isFalse);

    expect([0, 1, 2].endsWith([-1, 0, 1, 2]), isFalse);
  }

  test_nextOrNull() {
    var elements = [0, 1, 2];
    expect(elements.nextOrNull(0), 1);
    expect(elements.nextOrNull(1), 2);
    expect(elements.nextOrNull(2), null);
    expect(elements.nextOrNull(3), null);
  }

  test_stablePartition() {
    expect(
      [0, 1, 2, 3, 4, 5].stablePartition((e) => e.isEven),
      [0, 2, 4, 1, 3, 5],
    );
    expect(
      [5, 4, 3, 2, 1, 0].stablePartition((e) => e.isEven),
      [4, 2, 0, 5, 3, 1],
    );
  }

  test_withoutLast() {
    expect([0, 1, 2].withoutLast, [0, 1]);
    expect([0, 1].withoutLast, [0]);
    expect([0].withoutLast, <int>[]);
    expect(<int>[].withoutLast, <int>[]);
  }
}

@reflectiveTest
class SetExtensionTest {
  test_addIfNotNull_notNull() {
    var elements = {0, 1};
    elements.addIfNotNull(2);
    expect(elements, {0, 1, 2});
  }

  test_addIfNotNull_null() {
    var elements = {0, 1};
    elements.addIfNotNull(null);
    expect(elements, {0, 1});
  }
}
