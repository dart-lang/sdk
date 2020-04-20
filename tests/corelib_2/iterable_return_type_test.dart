// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js where [List.addAll] was not typed
// correctly.

import 'iterable_return_type_helper.dart';

import 'dart:collection';
import 'dart:typed_data';

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
  testList(new Uint8List(1)..[0] = 1);
  testList(new Int8List(1)..[0] = 1);
  testList(new Uint16List(1)..[0] = 1);
  testList(new Int16List(1)..[0] = 1);
  testList(new Uint32List(1)..[0] = 1);
  testList(new Int32List(1)..[0] = 1);

  testIterable(new Set<int>()..add(1));
  testIterable(new HashSet<int>()..add(1));
  testIterable(new LinkedHashSet<int>()..add(1));
  testIterable(new SplayTreeSet<int>()..add(1));

  testIterable(new Queue<int>()..add(1));
  testIterable(new DoubleLinkedQueue<int>()..add(1));
  testIterable(new ListQueue<int>()..add(1));

  testMap(new Map<int, int>()..[1] = 1);
  testMap(new HashMap<int, int>()..[1] = 1);
  testMap(new LinkedHashMap<int, int>()..[1] = 1);
  testMap(new SplayTreeMap<int, int>()..[1] = 1);
  testMap(<int, int>{1: 1});
  testMap(const <int, int>{1: 1});
}
