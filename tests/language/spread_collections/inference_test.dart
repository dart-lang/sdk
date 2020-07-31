// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test how spread interacts with inference.
import 'package:expect/expect.dart';

void main() {
  testBottomUpInference();
  testTopDownInference();
}

void testBottomUpInference() {
  // Lists.
  Expect.type<List<dynamic>>([...[]]);
  Expect.type<List<int>>([...<int>[]]);
  Expect.type<List<int>>([...[1]]);
  Expect.type<List<int>>([1, ...[2]]);
  Expect.type<List<num>>([1, ...[0.2]]);
  Expect.type<List<int>>([...[1, 2]]);
  Expect.type<List<num>>([...[1, 0.2]]);
  Expect.type<List<int>>([...[1], ...[2]]);
  Expect.type<List<num>>([...[1], ...[0.2]]);

  // Maps.
  Expect.type<Map<dynamic, dynamic>>({...{}});
  Expect.type<Map<int, int>>({...<int, int>{}});
  Expect.type<Map<int, int>>({...{1: 1}});
  Expect.type<Map<int, int>>({1: 1, ...{2: 2}});
  Expect.type<Map<num, num>>({1: 1, ...{0.2: 0.2}});
  Expect.type<Map<int, int>>({...{1: 1, 2: 2}});
  Expect.type<Map<num, num>>({...{1: 1, 0.2: 0.2}});
  Expect.type<Map<int, int>>({...{1: 1}, ...{2: 2}});
  Expect.type<Map<num, num>>({...{1: 1}, ...{0.2: 0.2}});

  // Sets.
  Expect.type<Set<dynamic>>({...[]});
  Expect.type<Set<int>>({...<int>[]});
  Expect.type<Set<int>>({...[1]});
  Expect.type<Set<int>>({1, ...[2]});
  Expect.type<Set<num>>({1, ...[0.2]});
  Expect.type<Set<int>>({...[1, 2]});
  Expect.type<Set<num>>({...[1, 0.2]});
  Expect.type<Set<int>>({...[1], ...[2]});
  Expect.type<Set<num>>({...[1], ...[0.2]});
  Expect.type<Set<num>>({...{1}, ...[0.2]});
  Expect.type<Set<num>>({...{1}, ...{0.2}});

  // If the iterable's type is dynamic, the element type is inferred as dynamic.
  Expect.type<List<dynamic>>([...([] as dynamic)]);
  Expect.type<Set<dynamic>>({1, ...([] as dynamic)});

  // If the iterable's type is dynamic, the key and value types are inferred as
  // dynamic.
  Expect.type<Map<dynamic, dynamic>>({1: 1, ...({} as dynamic)});
}

void testTopDownInference() {
  // Lists.
  Iterable<T> expectIntIterable<T>() {
    Expect.equals(int, T);
    return [];
  }

  Iterable<T> expectDynamicIterable<T>() {
    Expect.equals(dynamic, T);
    return [];
  }

  // The context element type is pushed into the spread expression if it is
  // Iterable<T>.
  Expect.listEquals(<int>[], <int>[...expectIntIterable()]);

  // Bottom up-inference from elements is not pushed back down into spread.
  Expect.listEquals(<int>[1], [1, ...expectDynamicIterable()]);

  // Maps.
  Map<K, V> expectIntStringMap<K, V>() {
    Expect.equals(int, K);
    Expect.equals(String, V);
    return {};
  }

  Map<K, V> expectDynamicDynamicMap<K, V>() {
    Expect.equals(dynamic, K);
    Expect.equals(dynamic, V);
    return {};
  }

  // The context element type is pushed into the spread expression if it is
  // Map<K, V>.
  Expect.mapEquals(<int, String>{}, <int, String>{...expectIntStringMap()});

  // Bottom up-inference from elements is not pushed back down into spread.
  Expect.mapEquals(<int, String>{1: "s"},
      {1: "s", ...expectDynamicDynamicMap()});

  // Sets.
  Set<T> expectIntSet<T>() {
    Expect.equals(int, T);
    return Set();
  }

  Set<T> expectDynamicSet<T>() {
    Expect.equals(dynamic, T);
    return Set();
  }

  // The context element type is pushed into the spread expression if it is
  // Iterable<T>.
  Expect.setEquals(<int>{}, <int>{...expectIntSet()});

  // Bottom up-inference from elements is not pushed back down into spread.
  Expect.setEquals(<int>{1}, {1, ...expectDynamicSet()});
}
