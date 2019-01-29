// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

abstract class SubtypeTest<T> {
  void isSubtype(String subtypeString, String supertypeString,
      {bool legacyMode: false, String typeParameters}) {
    T subtype = toType(subtypeString);
    T supertype = toType(supertypeString);
    String mode = legacyMode ? " (legacy)" : "";
    Expect.isTrue(isSubtypeImpl(subtype, supertype, legacyMode),
        "$subtype should be a subtype of $supertype$mode.");
  }

  void isNotSubtype(String subtypeString, String supertypeString,
      {bool legacyMode: false, String typeParameters}) {
    T subtype = toType(subtypeString);
    T supertype = toType(supertypeString);
    String mode = legacyMode ? " (legacy)" : "";
    Expect.isFalse(isSubtypeImpl(subtype, supertype, legacyMode),
        "$subtype shouldn't be a subtype of $supertype$mode.");
  }

  T toType(String text);

  bool isSubtypeImpl(T subtype, T supertype, bool legacyMode);

  void run() {
    isSubtype('int', 'num', legacyMode: true);
    isSubtype('int', 'Comparable<num>', legacyMode: true);
    isSubtype('int', 'Comparable<Object>', legacyMode: true);
    isSubtype('int', 'Object', legacyMode: true);
    isSubtype('double', 'num', legacyMode: true);

    isNotSubtype('int', 'double', legacyMode: true);
    isNotSubtype('int', 'Comparable<int>', legacyMode: true);
    isNotSubtype('int', 'Iterable<int>', legacyMode: true);
    isNotSubtype('Comparable<int>', 'Iterable<int>', legacyMode: true);

    isSubtype('List<int>', 'List<int>', legacyMode: true);
    isSubtype('List<int>', 'Iterable<int>', legacyMode: true);
    isSubtype('List<int>', 'List<num>', legacyMode: true);
    isSubtype('List<int>', 'Iterable<num>', legacyMode: true);
    isSubtype('List<int>', 'List<Object>', legacyMode: true);
    isSubtype('List<int>', 'Iterable<Object>', legacyMode: true);
    isSubtype('List<int>', 'Object', legacyMode: true);
    isSubtype('List<int>', 'List<Comparable<Object>>', legacyMode: true);
    isSubtype('List<int>', 'List<Comparable<num>>', legacyMode: true);
    isSubtype('List<int>', 'List<Comparable<Comparable<num>>>',
        legacyMode: true);

    isNotSubtype('List<int>', 'List<double>', legacyMode: true);
    isNotSubtype('List<int>', 'Iterable<double>', legacyMode: true);
    isNotSubtype('List<int>', 'Comparable<int>', legacyMode: true);
    isNotSubtype('List<int>', 'List<Comparable<int>>', legacyMode: true);
    isNotSubtype('List<int>', 'List<Comparable<Comparable<int>>>',
        legacyMode: true);

    isSubtype('(num) -> num', '(int) -> num', legacyMode: true);
    isSubtype('(num) -> int', '(num) -> num', legacyMode: true);
    isSubtype('(num) -> int', '(int) -> num', legacyMode: true);
    isNotSubtype('(int) -> int', '(num) -> num', legacyMode: true);

    isSubtype('(num) -> (num) -> num', '(num) -> (int) -> num',
        legacyMode: true);
    isNotSubtype('(num) -> (int) -> int', '(num) -> (num) -> num',
        legacyMode: true);

    // TODO(ahe): Remove this as the implementation improves.
    return;

    // ignore: dead_code
    isSubtype('(x:num) -> num', '(x:int) -> num',
        legacyMode: true); // named parameters
    isSubtype('(num,x:num) -> num', '(int,x:int) -> num', legacyMode: true);
    isSubtype('(x:num) -> int', '(x:num) -> num', legacyMode: true);
    isNotSubtype('(x:int) -> int', '(x:num) -> num', legacyMode: true);

    isSubtype('<E>(E) -> int', '<E>(E) -> num',
        legacyMode: true); // type parameters
    isSubtype('<E>(num) -> E', '<E>(int) -> E', legacyMode: true);
    isSubtype('<E>(E,num) -> E', '<E>(E,int) -> E', legacyMode: true);
    isNotSubtype('<E>(E,num) -> E', '<E>(E,E) -> E', legacyMode: true);

    isSubtype('<E>(E) -> (E) -> E', '<F>(F) -> (F) -> F', legacyMode: true);
    isSubtype('<E>(E, (int,E) -> E) -> E', '<E>(E, (int,E) -> E) -> E',
        legacyMode: true);
    isSubtype('<E>(E, (int,E) -> E) -> E', '<E>(E, (num,E) -> E) -> E',
        legacyMode: true);
    isNotSubtype('<E,F>(E) -> (F) -> E', '<E>(E) -> <F>(F) -> E',
        legacyMode: true);
    isNotSubtype('<E,F>(E) -> (F) -> E', '<F,E>(E) -> (F) -> E',
        legacyMode: true);

    isNotSubtype('<E>(E,num) -> E', '<E:num>(E,E) -> E', legacyMode: true);
    isNotSubtype('<E:num>(E) -> int', '<E:int>(E) -> int', legacyMode: true);
    isNotSubtype('<E:num>(E) -> E', '<E:int>(E) -> E', legacyMode: true);
    isNotSubtype('<E:num>(int) -> E', '<E:int>(int) -> E', legacyMode: true);
    isSubtype('<E:num>(E) -> E', '<F:num>(F) -> num', legacyMode: true);
    isSubtype('<E:int>(E) -> E', '<F:int>(F) -> num', legacyMode: true);
    isSubtype('<E:int>(E) -> E', '<F:int>(F) -> int', legacyMode: true);
    isNotSubtype('<E>(int) -> int', '(int) -> int', legacyMode: true);
    isNotSubtype('<E,F>(int) -> int', '<E>(int) -> int', legacyMode: true);

    isSubtype('<E:List<E>>(E) -> E', '<F:List<F>>(F) -> F', legacyMode: true);
    isNotSubtype('<E:Iterable<E>>(E) -> E', '<F:List<F>>(F) -> F',
        legacyMode: true);
    isNotSubtype('<E>(E,List<Object>) -> E', '<F:List<F>>(F,F) -> F',
        legacyMode: true);
    isNotSubtype('<E>(E,List<Object>) -> List<E>', '<F:List<F>>(F,F) -> F',
        legacyMode: true);
    isNotSubtype('<E>(E,List<Object>) -> int', '<F:List<F>>(F,F) -> F',
        legacyMode: true);
    isNotSubtype('<E>(E,List<Object>) -> E', '<F:List<F>>(F,F) -> void',
        legacyMode: true);

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

    // T & B <: T & A if B <: A
    isSubtype('T & int', 'T & int', legacyMode: true);
    isSubtype('T & int', 'T & num', legacyMode: true);
    isSubtype('T & num', 'T & num', legacyMode: true);
    isNotSubtype('T & num', 'T & int', legacyMode: true);

    // T & B <: T extends A if B <: A
    // (Trivially satisfied since promoted bounds are always a isSubtype of the
    // original bound)
    isSubtype('T & int', 'T', legacyMode: true, typeParameters: 'T: int');
    isSubtype('T & int', 'T', legacyMode: true, typeParameters: 'T: num');
    isSubtype('T & num', 'T', legacyMode: true, typeParameters: 'T: num');

    // T extends B <: T & A if B <: A
    isSubtype('T', 'T & int', legacyMode: true, typeParameters: 'T: int');
    isSubtype('T', 'T & num', legacyMode: true, typeParameters: 'T: int');
    isSubtype('T', 'T & num', legacyMode: true, typeParameters: 'T: num');
    isNotSubtype('T', 'T & int', legacyMode: true, typeParameters: 'T: num');

    // T extends A <: T extends A
    isSubtype('T', 'T', legacyMode: true, typeParameters: 'T: num');

    // S & B <: A if B <: A, A is not S (or a promotion thereof)
    isSubtype('S & int', 'int', legacyMode: true);
    isSubtype('S & int', 'num', legacyMode: true);
    isSubtype('S & num', 'num', legacyMode: true);
    isNotSubtype('S & num', 'int', legacyMode: true);
    isNotSubtype('S & num', 'T', legacyMode: true);
    isNotSubtype('S & num', 'T & num', legacyMode: true);

    // S extends B <: A if B <: A, A is not S (or a promotion thereof)
    isSubtype('S', 'int', legacyMode: true, typeParameters: 'S: int');
    isSubtype('S', 'num', legacyMode: true, typeParameters: 'S: int');
    isSubtype('S', 'num', legacyMode: true, typeParameters: 'S: num');
    isNotSubtype('S', 'int', legacyMode: true, typeParameters: 'S: num');
    isNotSubtype('S', 'T', legacyMode: true, typeParameters: 'S: num');
    isNotSubtype('S', 'T & num', legacyMode: true, typeParameters: 'S: num');
  }
}
