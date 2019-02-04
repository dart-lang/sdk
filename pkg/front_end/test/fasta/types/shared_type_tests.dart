// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

abstract class SubtypeTest<T, E> {
  void isSubtype(String subtypeString, String supertypeString,
      {String typeParameters}) {
    E environment = extend(typeParameters);
    T subtype = toType(subtypeString, environment);
    T supertype = toType(supertypeString, environment);
    Expect.isTrue(isSubtypeImpl(subtype, supertype),
        "$subtypeString should be a subtype of $supertypeString.");
  }

  void isNotSubtype(String subtypeString, String supertypeString,
      {String typeParameters}) {
    E environment = extend(typeParameters);
    T subtype = toType(subtypeString, environment);
    T supertype = toType(supertypeString, environment);
    Expect.isFalse(isSubtypeImpl(subtype, supertype),
        "$subtypeString shouldn't be a subtype of $supertypeString.");
  }

  T toType(String text, E environment);

  bool isSubtypeImpl(T subtype, T supertype);

  E extend(String typeParameters);

  void run() {
    isSubtype('int', 'num');
    isSubtype('int', 'Comparable<num>');
    isSubtype('int', 'Comparable<Object>');
    isSubtype('int', 'Object');
    isSubtype('double', 'num');

    isNotSubtype('int', 'double');
    isNotSubtype('int', 'Comparable<int>');
    isNotSubtype('int', 'Iterable<int>');
    isNotSubtype('Comparable<int>', 'Iterable<int>');

    isSubtype('List<int>', 'List<int>');
    isSubtype('List<int>', 'Iterable<int>');
    isSubtype('List<int>', 'List<num>');
    isSubtype('List<int>', 'Iterable<num>');
    isSubtype('List<int>', 'List<Object>');
    isSubtype('List<int>', 'Iterable<Object>');
    isSubtype('List<int>', 'Object');
    isSubtype('List<int>', 'List<Comparable<Object>>');
    isSubtype('List<int>', 'List<Comparable<num>>');
    isSubtype('List<int>', 'List<Comparable<Comparable<num>>>');

    isNotSubtype('List<int>', 'List<double>');
    isNotSubtype('List<int>', 'Iterable<double>');
    isNotSubtype('List<int>', 'Comparable<int>');
    isNotSubtype('List<int>', 'List<Comparable<int>>');
    isNotSubtype('List<int>', 'List<Comparable<Comparable<int>>>');

    isSubtype('(num) -> num', '(int) -> num');
    isSubtype('(num) -> int', '(num) -> num');
    isSubtype('(num) -> int', '(int) -> num');
    isNotSubtype('(int) -> int', '(num) -> num');
    isSubtype('Null', '(int) -> num');

    isSubtype('(num) -> (num) -> num', '(num) -> (int) -> num');
    isNotSubtype('(num) -> (int) -> int', '(num) -> (num) -> num');

    isSubtype('({num x}) -> num', '({int x}) -> num'); // named parameters
    isSubtype('(num, {num x}) -> num', '(int, {int x}) -> num');
    isSubtype('({num x}) -> int', '({num x}) -> num');
    isNotSubtype('({int x}) -> int', '({num x}) -> num');

    isSubtype('<E>(E) -> int', '<E>(E) -> num'); // type parameters
    isSubtype('<E>(num) -> E', '<E>(int) -> E');
    isSubtype('<E>(E,num) -> E', '<E>(E,int) -> E');
    isNotSubtype('<E>(E,num) -> E', '<E>(E,E) -> E');

    isSubtype('<E>(E) -> (E) -> E', '<F>(F) -> (F) -> F');
    isSubtype('<E>(E, (int,E) -> E) -> E', '<E>(E, (int,E) -> E) -> E');
    isSubtype('<E>(E, (int,E) -> E) -> E', '<E>(E, (num,E) -> E) -> E');
    isNotSubtype('<E,F>(E) -> (F) -> E', '<E>(E) -> <F>(F) -> E');
    isNotSubtype('<E,F>(E) -> (F) -> E', '<F,E>(E) -> (F) -> E');

    isNotSubtype('<E>(E,num) -> E', '<E extends num>(E,E) -> E');
    isNotSubtype('<E extends num>(E) -> int', '<E extends int>(E) -> int');
    isNotSubtype('<E extends num>(E) -> E', '<E extends int>(E) -> E');
    isNotSubtype('<E extends num>(int) -> E', '<E extends int>(int) -> E');
    isSubtype('<E extends num>(E) -> E', '<F extends num>(F) -> num');
    isSubtype('<E extends int>(E) -> E', '<F extends int>(F) -> num');
    isSubtype('<E extends int>(E) -> E', '<F extends int>(F) -> int');
    isNotSubtype('<E>(int) -> int', '(int) -> int');
    isNotSubtype('<E,F>(int) -> int', '<E>(int) -> int');

    isSubtype('<E extends List<E>>(E) -> E', '<F extends List<F>>(F) -> F');
    isNotSubtype(
        '<E extends Iterable<E>>(E) -> E', '<F extends List<F>>(F) -> F');
    isNotSubtype('<E>(E,List<Object>) -> E', '<F extends List<F>>(F,F) -> F');
    isNotSubtype(
        '<E>(E,List<Object>) -> List<E>', '<F extends List<F>>(F,F) -> F');
    isNotSubtype('<E>(E,List<Object>) -> int', '<F extends List<F>>(F,F) -> F');
    isNotSubtype(
        '<E>(E,List<Object>) -> E', '<F extends List<F>>(F,F) -> void');

    isSubtype('int', 'FutureOr<int>');
    isSubtype('int', 'FutureOr<num>');
    isSubtype('Future<int>', 'FutureOr<int>');
    isSubtype('Future<int>', 'FutureOr<num>');
    isSubtype('Future<int>', 'FutureOr<Object>');
    isSubtype('FutureOr<int>', 'FutureOr<int>');
    isSubtype('FutureOr<int>', 'FutureOr<num>');
    isSubtype('FutureOr<int>', 'Object');
    isNotSubtype('int', 'FutureOr<double>');
    isNotSubtype('FutureOr<double>', 'int');
    isNotSubtype('FutureOr<int>', 'Future<num>');
    isNotSubtype('FutureOr<int>', 'num');
    isSubtype('Null', 'FutureOr<int>');
    isSubtype('Null', 'Future<int>');

    // T & B <: T & A if B <: A
    isSubtype('T & int', 'T & int', typeParameters: 'T');
    isSubtype('T & int', 'T & num', typeParameters: 'T');
    isSubtype('T & num', 'T & num', typeParameters: 'T');
    isNotSubtype('T & num', 'T & int', typeParameters: 'T');
    isSubtype('Null', 'T & num', typeParameters: 'T');

    // T & B <: T extends A if B <: A
    // (Trivially satisfied since promoted bounds are always a isSubtype of the
    // original bound)
    isSubtype('T & int', 'T', typeParameters: 'T extends int');
    isSubtype('T & int', 'T', typeParameters: 'T extends num');
    isSubtype('T & num', 'T', typeParameters: 'T extends num');

    // T extends B <: T & A if B <: A
    isSubtype('T', 'T & int', typeParameters: 'T extends int');
    isSubtype('T', 'T & num', typeParameters: 'T extends int');
    isSubtype('T', 'T & num', typeParameters: 'T extends num');
    isNotSubtype('T', 'T & int', typeParameters: 'T extends num');

    // T extends A <: T extends A
    isSubtype('T', 'T', typeParameters: 'T extends num');

    // S & B <: A if B <: A, A is not S (or a promotion thereof)
    isSubtype('S & int', 'int', typeParameters: 'S');
    isSubtype('S & int', 'num', typeParameters: 'S');
    isSubtype('S & num', 'num', typeParameters: 'S');
    isNotSubtype('S & num', 'int', typeParameters: 'S');
    isNotSubtype('S & num', 'T', typeParameters: 'S, T');
    isNotSubtype('S & num', 'T & num', typeParameters: 'S, T');

    // S extends B <: A if B <: A, A is not S (or a promotion thereof)
    isSubtype('S', 'int', typeParameters: 'S extends int');
    isSubtype('S', 'num', typeParameters: 'S extends int');
    isSubtype('S', 'num', typeParameters: 'S extends num');
    isNotSubtype('S', 'int', typeParameters: 'S extends num');
    isNotSubtype('S', 'T', typeParameters: 'S extends num, T');
    isNotSubtype('S', 'T & num', typeParameters: 'S extends num, T');

    isNotSubtype('dynamic', 'int');
    isNotSubtype('void', 'int');
    isNotSubtype('() -> int', 'int');
    isNotSubtype('Typedef<Object>', 'int');
    isSubtype('() -> int', 'Function');
    isSubtype('() -> int', 'Object');

    isNotSubtype('Null', 'bottom');
    isSubtype('Null', 'Object');
    isSubtype('Null', 'void');
    isSubtype('Null', 'dynamic');
    isSubtype('Null', 'double');
    isSubtype('Null', 'Comparable<Object>');
    isSubtype('Null', 'Typedef<Object>');
    isSubtype('Null', 'T', typeParameters: 'T');

    isSubtype('Null', 'Null');
    isSubtype('bottom', 'bottom');
    isSubtype('Object', 'Object');
    isSubtype('dynamic', 'dynamic');
    isSubtype('void', 'void');

    // Check that the top types are equivalent.
    isSubtype('<S extends Object, T extends void>(S, T) -> void',
        '<U extends dynamic, V extends Object>(U, V) -> void');

    {
      String f = '<T extends dynamic>() -> T';
      String g = '<T extends Object>() -> T';
      isSubtype(f, g);
      isSubtype(g, f);
    }

    {
      String h = '<T extends List<dynamic>>() -> T';
      String i = '<T extends List<Object>>() -> T';
      String j = '<T extends List<void>>() -> T';
      isSubtype(h, i);
      isSubtype(h, j);
      isSubtype(i, h);
      isSubtype(i, j);
      isSubtype(j, h);
      isSubtype(j, i);
    }

    isNotSubtype('dynamic', '() -> dynamic');
    isNotSubtype('FutureOr<() -> void>', '() -> void');
    isSubtype('T & () -> void', '() -> void', typeParameters: 'T');
    isSubtype('T & () -> void', '() -> dynamic', typeParameters: 'T');
    isSubtype('T & () -> void', '() -> Object', typeParameters: 'T');

    isSubtype('T & (void) -> void', '(void) -> void', typeParameters: 'T');
    isSubtype('T & (void) -> void', '(dynamic) -> dynamic',
        typeParameters: 'T');
    isSubtype('T & (void) -> void', '(Object) -> Object', typeParameters: 'T');

    isSubtype('T & (void) -> void', '(void) -> void', typeParameters: 'T');
    isSubtype('T & (void) -> void', '(Iterable<int>) -> dynamic',
        typeParameters: 'T');
    isSubtype('T & (void) -> void', '(int) -> Object', typeParameters: 'T');

    isNotSubtype('T & (void) -> void', '(int) -> int', typeParameters: 'T');

    isSubtype('T', '() -> void', typeParameters: 'T extends () -> void');
    isNotSubtype('T', '() -> void', typeParameters: 'T');
    isNotSubtype('Typedef<void>', '() -> void');
    isSubtype('VoidFunction', '() -> void');
    isNotSubtype(
        'DefaultTypes<void, void, List<void>, List<void>, int, (int) -> void, () -> int>',
        '() -> void');
    isNotSubtype('void', '() -> void');
  }
}
