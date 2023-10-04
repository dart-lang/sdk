// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

//ignore_for_file: unused_local_variable
void main() {
  var mapToLint = new Map(); // LINT
  var LinkedHashMapToLint = new LinkedHashMap(); // LINT

  var m1 = Map.unmodifiable({}); //OK
  var m2 = Map.fromIterable([]); //OK
  var m3 = Map.fromIterables([], []); //OK

  var literalListInsideLiteralList = [[], []]; // OK

  var namedConstructorList = new List.filled(5, true); // OK
  var namedConstructorMap = new Map.identity(); // OK
  var namedConstructorLinkedHashMap = new LinkedHashMap.identity(); // OK

  var literalList = []; // OK
  var literalMap = {}; // OK

  Set s = new Set(); // LINT
  var s1 = new Set<int>(); // LINT
  Set<int> s2 = new Set(); // LINT
  var s3 = new Set.from(['foo', 'bar', 'baz']); // LINT
  var s4 = new Set.of(['foo', 'bar', 'baz']); // LINT

  var s5 = ['foo', 'bar', 'baz'].toSet(); // LINT

  var s6 = new LinkedHashSet.from(['foo', 'bar', 'baz']); // LINT
  var s7 = new LinkedHashSet.of(['foo', 'bar', 'baz']); // LINT
  var s8 = new LinkedHashSet.from(<int>[]); // LINT
  var s9 = new Set<int>.from([]); // LINT

  var is1 = new Set.identity(); // OK
  var is2 = new LinkedHashSet.identity(); // OK

  var ss1 = new Set(); // LINT
  var ss2 = new LinkedHashSet(); // LINT
  var ss3 = LinkedHashSet.from([]); // LINT
  var ss4 = LinkedHashSet.of([]); // LINT

  Set<int> ss5 = LinkedHashSet<int>(); // LINT
  LinkedHashSet<int> ss6 = LinkedHashSet<int>(); // OK
  Object ss7 = LinkedHashSet<int>(); // LINT

  printObject(Set()); // LINT
  printSet(Set()); // LINT
  printObject(LinkedHashSet()); // LINT
  printSet(LinkedHashSet<int>()); // LINT
  printIndentedSet(0, LinkedHashSet<int>()); // LINT
  printHashSet(LinkedHashSet<int>()); // OK
  printIndentedHashSet(0, LinkedHashSet<int>()); // OK

  Set<int> ss8 = LinkedHashSet.from([1, 2, 3]); // LINT
  LinkedHashSet<int> ss9 = LinkedHashSet.from([1, 2, 3]); // OK

  Iterable iter = Iterable.empty(); // OK
  var sss = Set.from(iter); // OK

  LinkedHashSet<String> sss1 = <int, LinkedHashSet<String>>{}
      .putIfAbsent(3, () => LinkedHashSet<String>()); // OK

  var lhs = LinkedHashSet(equals: (a, b) => false, hashCode: (o) => 13)
    ..addAll({}); // OK

  LinkedHashMap hashMap = LinkedHashMap(); // OK
  Object hashMap2 = LinkedHashMap(); // LINT

  printObject(Map()); // LINT
  printMap(Map()); // LINT
  printObject(LinkedHashMap()); // LINT
  printMap(LinkedHashMap<int, int>()); // LINT
  printHashMap(LinkedHashMap<int, int>()); // OK

  LinkedHashMap<String, String> lhm = <int, LinkedHashMap<String, String>>{}
      .putIfAbsent(3, () => LinkedHashMap<String, String>()); // OK
}

void printObject(Object o) => print('$o');
void printSet(Set<int> ids) => print('$ids!');
void printIndentedSet(int indent, Set<int> ids) => print('$ids!');
void printHashSet(LinkedHashSet<int> ids) => printSet(ids);
void printIndentedHashSet(int indent, LinkedHashSet<int> ids) => printSet(ids);
void printMap(Map map) => print('$map!');
void printHashMap(LinkedHashMap map) => printMap(map);
