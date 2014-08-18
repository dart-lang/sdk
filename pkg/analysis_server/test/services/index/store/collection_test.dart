// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.index.store.collection;

import 'package:analysis_server/src/services/index/store/collection.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(_IntArrayToIntMapTest);
  runReflectiveTests(_IntToIntSetMapTest);
}


@ReflectiveTestCase()
class _IntArrayToIntMapTest {
  IntArrayToIntMap map = new IntArrayToIntMap();

  void test_put_get() {
    map[<int>[1, 2, 3]] = 1;
    map[<int>[2, 3, 4, 5]] = 2;
    expect(map[<int>[0]], isNull);
    expect(map[<int>[1, 2, 3]], 1);
    expect(map[<int>[2, 3, 4, 5]], 2);
  }
}


@ReflectiveTestCase()
class _IntToIntSetMapTest {
  IntToIntSetMap map = new IntToIntSetMap();

  void test_add_duplicate() {
    map.add(1, 0);
    map.add(1, 0);
    List<int> set = map.get(1);
    expect(set, hasLength(1));
  }

  void test_clear() {
    map.add(1, 10);
    map.add(2, 20);
    expect(map.length, 2);
    map.clear();
    expect(map.length, 0);
  }

  void test_get() {
    map.add(1, 10);
    map.add(1, 11);
    map.add(1, 12);
    map.add(2, 20);
    map.add(2, 21);
    expect(map.get(1), unorderedEquals([10, 11, 12]));
    expect(map.get(2), unorderedEquals([20, 21]));
  }

  void test_get_no() {
    expect(map.get(3), []);
  }

  void test_length() {
    expect(map.length, 0);
    map.add(1, 10);
    expect(map.length, 1);
    map.add(1, 11);
    map.add(1, 12);
    expect(map.length, 1);
    map.add(2, 20);
    expect(map.length, 2);
    map.add(2, 21);
    expect(map.length, 2);
  }
}
