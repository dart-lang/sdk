// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import "package:expect/expect.dart";

void main() {
  test();
}

void test() {
  checkSet<T>(Object o, List elements) {
    Expect.type<Set<T>>(o);
    Set<T> set = o;
    Expect.listEquals(elements, set.toList());
    Expect.throws<Error>(set.clear);
  }

  // Various context types for literals.
  Object setContext<T>(Set<T> object) => object;
  Object iterableContext<T>(Iterable<T> object) => object;
  Object foSetContext<T>(FutureOr<Set<T>> object) => object;
  Object foIterableContext<T>(FutureOr<Set<T>> object) => object;

  // Empty literal, no type arguments.
  // No context.
  Expect.type<Map<dynamic, dynamic>>(const {});
  // Set context with no inferred type argument.
  checkSet<dynamic>(setContext(const {}), []);
  checkSet<dynamic>(iterableContext(const {}), []);
  checkSet<dynamic>(foSetContext(const {}), []);
  checkSet<dynamic>(foIterableContext(const {}), []);
  // Specific set context.
  checkSet<int>(setContext<int>(const {}), []);
  checkSet<int>(iterableContext<int>(const {}), []);
  checkSet<int>(foSetContext<int>(const {}), []);
  checkSet<int>(foIterableContext<int>(const {}), []);

  // Non-empty set literal, no type argument.
  // No context.
  checkSet<int>(const {1}, [1]);
  checkSet<int>(const {3, 1, 2, 4}, [3, 1, 2, 4]);
  // Set context with no inferred type argument.
  checkSet<int>(setContext(const {1}), [1]);
  checkSet<int>(iterableContext(const {1}), [1]);
  checkSet<int>(foSetContext(const {1}), [1]);
  checkSet<int>(foIterableContext(const {1}), [1]);
  checkSet<int>(setContext(const {3, 1, 2, 4}), [3, 1, 2, 4]);
  checkSet<int>(iterableContext(const {3, 1, 2, 4}), [3, 1, 2, 4]);
  checkSet<int>(foSetContext(const {1}), [1]);
  checkSet<int>(foIterableContext(const {1}), [1]);
  // Specific set context.
  checkSet<num>(setContext<num>(const {1}), [1]);
  checkSet<num>(iterableContext<num>(const {1}), [1]);
  checkSet<num>(foSetContext<num>(const {1}), [1]);
  checkSet<num>(foIterableContext<num>(const {1}), [1]);
  checkSet<num>(setContext<num>(const {3, 1, 2, 4}), [3, 1, 2, 4]);
  checkSet<num>(iterableContext<num>(const {3, 1, 2, 4}), [3, 1, 2, 4]);
  checkSet<num>(foSetContext<num>(const {3, 1, 2, 4}), [3, 1, 2, 4]);
  checkSet<num>(foIterableContext<num>(const {3, 1, 2, 4}), [3, 1, 2, 4]);

  // Non-empty set literal with type argument.
  checkSet<num>(const <num>{1}, [1]);
  checkSet<num>(const <num>{3, 1, 2, 4}, [3, 1, 2, 4]);

  // Integers, String and symbols work, even if they override ==.
  checkSet<String>(const {"foo", "bar"}, ["foo", "bar"]);
  checkSet<Symbol>(const {#foo, #bar}, [#foo, #bar]);
  checkSet<Symbol>(const {#_foo, #_bar}, [#_foo, #_bar]);
  const object = Object();
  checkSet<Object>(const {#foo, 1, "string", object, true},
      [#foo, 1, "string", object, true]);

  // Nested constant literals.
  const Object o = {{2}};
  Expect.type<Set<Set<int>>>(o);
  Set<Set<int>> set = o;
  Expect.equals(1, set.length);
  Expect.equals(1, set.first.length);
  Expect.equals(2, set.first.first);

  const Object o2 = {{2}, <int>{}};
  Expect.type<Set<Set<int>>>(o);
  set = o2;
  Expect.equals(2, set.length);
  Expect.equals(1, set.first.length);
  Expect.equals(2, set.first.first);

  const Set<Set<int>> o3 = {{}};
  Expect.equals(1, o3.length);
  Expect.equals(0, o3.first.length);

  const o4 = {{}};
  Expect.type<Set<Map<dynamic, dynamic>>>(o4);
  Expect.equals(1, o4.length);
  Expect.equals(0, o4.first.length);

  const o5 = {{1}, {}};  // Set<Object>
  Expect.type<Set<Object>>(o5);
  Expect.notType<Set<Set<Object>>>(o5);

  // User defined constant class.
  const o6 = {
    Something(1, "a"),
    Something(2, "a"),
    Something(1, "b"),
    Something(2, "b"),
  };
  Expect.equals("1:a,2:a,1:b,2:b", o6.toList().join(","));

  // Canonicalization of constant sets takes ordering into account,
  // that is, o7 and o8 cannot be the same object.
  const o7 = {1, 2, 3};
  const o8 = {3, 2, 1};
  Expect.notIdentical(o7, o8);
  // But o7 and o9 must be identical.
  const o9 = {1, 2, 3};
  Expect.identical(o7, o9);
}

class Something {
  final int id;
  final String name;
  const Something(this.id, this.name);
  String toString() => "$id:$name";
}
