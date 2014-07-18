// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js where [List.addAll] was not typed
// correctly.

import "package:expect/expect.dart";

import 'dart:collection';
import 'dart:typed_data';

testIntIterable(iterable) {
  Expect.isTrue(iterable is Iterable<int>);
  Expect.isFalse(iterable is Iterable<String>);
}

void testIterable(Iterable<int> iterable, [int depth = 3]) {
  testIntIterable(iterable);
  if (depth > 0) {
    testIterable(iterable, depth - 1);
    testIterable(iterable.where((x) => true), depth - 1);
    testIterable(iterable.skip(1), depth - 1);
    testIterable(iterable.take(1), depth - 1);
    testIterable(iterable.skipWhile((x) => false), depth - 1);
    testIterable(iterable.takeWhile((x) => true), depth - 1);
    testList(iterable.toList(growable: true), depth - 1);
    testList(iterable.toList(growable: false), depth - 1);
    testIterable(iterable.toSet(), depth - 1);
  }
}

void testList(List<int> list, [int depth = 3]) {
  testIterable(list, depth);
  if (depth > 0) {
    testIterable(list.getRange(0, list.length), depth - 1);
    testIterable(list.reversed, depth - 1);
    testMap(list.asMap(), depth - 1);
  }
}

void testMap(Map<int, int> map, [int depth = 3]) {
  Expect.isTrue(map is Map<int,int>);
  Expect.isFalse(map is Map<int,String>);
  Expect.isFalse(map is Map<String,int>);
  if (depth > 0) {
    testIterable(map.keys, depth - 1);
    testIterable(map.values, depth - 1);
  }
}

main() {
  // Empty lists.
  testList(<int>[]);
  testList(new List<int>(0));
  testList(new List<int>());
  testList(const <int>[]);
  testList(new List<int>.generate(0, (x) => x + 1));
  // Singleton lists.
  testList(<int>[1]);
  testList(new List<int>(1)..[0] = 1);
  testList(new List<int>()..add(1));
  testList(const <int>[1]);
  testList(new List<int>.generate(1, (x) => x + 1));

  // Typed lists.
  testList(new Uint8List(1)..[0] = 1);   /// 01: ok
  testList(new Int8List(1)..[0] = 1);    /// 01: continued
  testList(new Uint16List(1)..[0] = 1);  /// 01: continued
  testList(new Int16List(1)..[0] = 1);   /// 01: continued
  testList(new Uint32List(1)..[0] = 1);  /// 01: continued
  testList(new Int32List(1)..[0] = 1);   /// 01: continued
  testList(new Uint64List(1)..[0] = 1);  /// 02: ok
  testList(new Int64List(1)..[0] = 1);   /// 02: continued

  testIterable(new Set<int>()..add(1));
  testIterable(new HashSet<int>()..add(1));
  testIterable(new LinkedHashSet<int>()..add(1));
  testIterable(new SplayTreeSet<int>()..add(1));

  testIterable(new Queue<int>()..add(1));
  testIterable(new DoubleLinkedQueue<int>()..add(1));
  testIterable(new ListQueue<int>()..add(1));

  testMap(new Map<int,int>()..[1] = 1);
  testMap(new HashMap<int,int>()..[1] = 1);
  testMap(new LinkedHashMap<int,int>()..[1] = 1);
  testMap(new SplayTreeMap<int,int>()..[1] = 1);
  testMap(<int,int>{1:1});
  testMap(const <int,int>{1:1});
}
