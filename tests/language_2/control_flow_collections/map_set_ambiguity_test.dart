// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test cases where the syntax is ambiguous between maps and sets because of
// spreads inside control flow.
import 'dart:collection';

import 'utils.dart';

void main() {
  testBottomUpInference();
  testTopDownInference();
}

void testBottomUpInference() {
  Map<int, int> map = {};
  Set<int> set = Set();
  dynamic dynMap = map;
  dynamic dynSet = set;
  Iterable<int> iterable = [];
  CustomSet customSet = CustomSet();
  CustomMap customMap = CustomMap();

  // Note: The commented out cases are the error cases. They are shown here for
  // completeness and tested in map_set_ambiguity_error_test.dart.
  expectMapOf<int, int>({if (true) ...map});
  expectSetOf<int>({if (true) ...set});
  // expect___Of<...>({if (true) ...dyn});
  expectSetOf<int>({if (true) ...iterable});
  expectSetOf<int>({if (true) ...customSet});
  expectMapOf<int, String>({if (true) ...customMap});

  expectMapOf<int, int>({if (true) ...map else ...map});
  // expect___Of<...>({if (true) ...map else ...set});
  expectMapOf<dynamic, dynamic>({if (true) ...map else ...dynMap});
  // expect___Of<...>({if (true) ...map else ...iterable});
  // expect___Of<...>({if (true) ...map else ...customSet});
  expectMapOf<int, Object>({if (true) ...map else ...customMap});

  expectSetOf<int>({if (true) ...set else ...set});
  expectSetOf<dynamic>({if (true) ...set else ...dynSet});
  expectSetOf<int>({if (true) ...set else ...iterable});
  expectSetOf<int>({if (true) ...set else ...customSet});
  // expect___Of<...>({if (true) ...set else ...customMap});

  // expect___Of<...>({if (true) ...dyn else ...dyn});
  expectSetOf<dynamic>({if (true) ...dynSet else ...iterable});
  expectSetOf<dynamic>({if (true) ...dynSet else ...customSet});
  expectMapOf<dynamic, dynamic>({if (true) ...dynMap else ...customMap});

  expectSetOf<int>({if (true) ...iterable else ...iterable});
  expectSetOf<int>({if (true) ...iterable else ...customSet});
  // expect___Of<...>({if (true) ...iterable else ...customMap});

  expectSetOf<int>({if (true) ...customSet else ...customSet});
  // expect___Of<...>({if (true) ...customSet else ...customMap});

  expectMapOf<int, String>({if (true) ...customMap else ...customMap});

  // Note: The commented out cases are the error cases. They are shown here for
  // completeness and tested in map_set_ambiguity_error_test.dart.
  expectMapOf<int, int>({for (; false;) ...map});
  expectSetOf<int>({for (; false;) ...set});
  // expect___Of<...>({for (; false;) ...dyn});
  expectSetOf<int>({for (; false;) ...iterable});
  expectSetOf<int>({for (; false;) ...customSet});
  expectMapOf<int, String>({for (; false;) ...customMap});

  expectMapOf<int, int>({for (; false;) ...map, for (; false;) ...map});
  // expect___Of<...>({for (; false;) ...map, for (; false;) ...set});
  expectMapOf<dynamic, dynamic>(
      {for (; false;) ...map, for (; false;) ...dynMap});
  // expect___Of<...>({for (; false;) ...map, for (; false;) ...iterable});
  // expect___Of<...>({for (; false;) ...map, for (; false;) ...customSet});
  expectMapOf<int, Object>(
      {for (; false;) ...map, for (; false;) ...customMap});

  expectSetOf<int>({for (; false;) ...set, for (; false;) ...set});
  expectSetOf<dynamic>({for (; false;) ...set, for (; false;) ...dynSet});
  expectSetOf<int>({for (; false;) ...set, for (; false;) ...iterable});
  expectSetOf<int>({for (; false;) ...set, for (; false;) ...customSet});
  // expect___Of<...>({for (; false;) ...set, for (; false;) ...customMap});

  // expect___Of<...>({for (; false;) ...dyn, for (; false;) ...dyn});
  expectSetOf<dynamic>(
      {for (; false;) ...dynSet, for (; false;) ...iterable});
  expectSetOf<dynamic>(
      {for (; false;) ...dynSet, for (; false;) ...customSet});
  expectMapOf<dynamic, dynamic>(
      {for (; false;) ...dynMap, for (; false;) ...customMap});

  expectSetOf<int>(
      {for (; false;) ...iterable, for (; false;) ...iterable});
  expectSetOf<int>(
      {for (; false;) ...iterable, for (; false;) ...customSet});
  // expect___Of<...>(
  //     {for (; false;) ...iterable, for (; false;) ...customMap});

  expectSetOf<int>(
      {for (; false;) ...customSet, for (; false;) ...customSet});
  // expect___Of<...>(
  //     {for (; false;) ...customSet, for (; false;) ...customMap});

  expectMapOf<int, String>(
      {for (; false;) ...customMap, for (; false;) ...customMap});
}

void testTopDownInference() {
  dynamic untypedMap = <int, int>{};
  dynamic untypedIterable = <int>[];

  Map<int, int> map = {if (true) ...untypedMap};
  Set<int> set = {if (true) ...untypedIterable};
  Iterable<int> iterable = {if (true) ...untypedIterable};

  expectMapOf<int, int>(map);
  expectSetOf<int>(set);
  expectSetOf<int>(iterable);

  map = {for (; false;) ...untypedMap};
  set = {for (; false;) ...untypedIterable};
  iterable = {for (; false;) ...untypedIterable};

  expectMapOf<int, int>(map);
  expectSetOf<int>(set);
  expectSetOf<int>(iterable);
}
