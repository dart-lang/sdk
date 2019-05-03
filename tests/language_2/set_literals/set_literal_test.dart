// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "dart:collection" show LinkedHashSet;

import "package:expect/expect.dart";

void main() {
  test();
}

void test() {
  checkSet<T>(Object o, List elements) {
    Expect.type<LinkedHashSet<T>>(o);
    Set<T> set = o;
    Expect.listEquals(elements, set.toList());
  }

  Object setContext<T>(Set<T> object) => object;
  Object iterableContext<T>(Iterable<T> object) => object;
  Object foSetContext<T>(FutureOr<Set<T>> object) => object;
  Object foIterableContext<T>(FutureOr<Iterable<T>> object) => object;

  // Empty literal, no type arguments.
  // No context.
  Expect.type<Map<dynamic, dynamic>>({});
  // Set context with no inferred type argument.
  checkSet<dynamic>(setContext({}), []);
  checkSet<dynamic>(iterableContext({}), []);
  checkSet<dynamic>(foSetContext({}), []);
  checkSet<dynamic>(foIterableContext({}), []);
  // Specific set context.
  checkSet<int>(setContext<int>({}), []);
  checkSet<int>(iterableContext<int>({}), []);
  checkSet<int>(foSetContext<int>({}), []);
  checkSet<int>(foIterableContext<int>({}), []);

  // Non-empty set literal, no type argument.
  // No context.
  checkSet<int>({1}, [1]);
  checkSet<int>({3, 1, 2, 4, 1, 4}, [3, 1, 2, 4]);
  // Set context with no inferred type argument.
  checkSet<int>(setContext({1}), [1]);
  checkSet<int>(iterableContext({1}), [1]);
  checkSet<int>(foSetContext({1}), [1]);
  checkSet<int>(foIterableContext({1}), [1]);
  checkSet<int>(setContext({3, 1, 2, 4, 1, 4}), [3, 1, 2, 4]);
  checkSet<int>(iterableContext({3, 1, 2, 4, 1, 4}), [3, 1, 2, 4]);
  checkSet<int>(foSetContext({3, 1, 2, 4, 1, 4}), [3, 1, 2, 4]);
  checkSet<int>(foIterableContext({3, 1, 2, 4, 1, 4}), [3, 1, 2, 4]);
  // Specific set context.
  checkSet<num>(setContext<num>({1}), [1]);
  checkSet<num>(iterableContext<num>({1}), [1]);
  checkSet<num>(foSetContext<num>({1}), [1]);
  checkSet<num>(foIterableContext<num>({1}), [1]);
  checkSet<num>(setContext<num>({3, 1, 2, 4, 1, 4}), [3, 1, 2, 4]);
  checkSet<num>(iterableContext<num>({3, 1, 2, 4, 1, 4}), [3, 1, 2, 4]);
  checkSet<num>(foSetContext<num>({3, 1, 2, 4, 1, 4}), [3, 1, 2, 4]);
  checkSet<num>(foIterableContext<num>({3, 1, 2, 4, 1, 4}), [3, 1, 2, 4]);

  // Non-empty set literal with type argument.
  checkSet<num>(<num>{1}, [1]);
  checkSet<num>(<num>{3, 1, 2, 4, 1, 4}, [3, 1, 2, 4]);

  // Iteration order. Values are evaluated in first-added order.
  var e1a = Equality(1, "a");
  var e1b = Equality(1, "b");
  var e2a = Equality(2, "a");
  var e2b = Equality(2, "b");
  var es = {e1a, e2b, e1b, e2a};
  checkSet<Equality>(es, [e1a, e2b]);
  Expect.equals("1:a,2:b", es.join(","));

  // Evaluation order. All elements are evaluated, left to right.
  var entries = <int>[];
  T log<T>(T value, int entry) {
    entries.add(entry);
    return value;
  }
  checkSet<Equality>(
      {log(e1a, 1), log(e2b, 2), log(e1b, 3), log(e2a, 4)}, [e1a, e2b]);
  Expect.listEquals([1, 2, 3, 4], entries);

  // Nested literals.
  Object o = {{2}};
  Expect.type<LinkedHashSet<Set<int>>>(o);
  Expect.type<LinkedHashSet<int>>((o as Set).first);
  Set<Set<int>> set = o;
  Expect.equals(1, set.length);
  Expect.equals(1, set.first.length);
  Expect.equals(2, set.first.first);

  o = {{2}, <int>{}};
  Expect.type<LinkedHashSet<Set<int>>>(o);
  Expect.type<LinkedHashSet<int>>((o as Set).first);
  set = o;
  Expect.equals(2, set.length);
  Expect.equals(1, set.first.length);
  Expect.equals(2, set.first.first);

  var set2 = {{}};
  Expect.type<Set<Map<dynamic, dynamic>>>(set2);
  Expect.equals(1, set2.length);
  Expect.equals(0, set2.first.length);

  var set3 = {{1}, {}};  // Set<Object>
  Expect.type<Set<Object>>(set3);
  Expect.notType<Set<Set<Object>>>(set3);

  // Trailing comma.
  Iterable<Object> i;
  i = {1,};
  Expect.type<Set<Object>>(i);
  Expect.equals(1, i.length);

  o = {1, 2, 3,};
  Expect.type<Set<int>>(o);
  Set<Object> set4 = o;
  Expect.equals(3, set4.length);
}

class Equality {
  final int id;
  final String name;
  const Equality(this.id, this.name);
  int get hashCode => id;
  bool operator==(Object other) => other is Equality && id == other.id;
  String toString() => "$id:$name";
}
