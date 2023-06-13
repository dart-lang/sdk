// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListExtensionTest);
  });
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
