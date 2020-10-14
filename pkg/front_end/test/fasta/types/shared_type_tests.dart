// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import "package:kernel/type_environment.dart";

abstract class SubtypeTest<T, E> {
  void isSubtype(String subtypeString, String supertypeString,
      {String typeParameters}) {
    E environment = extend(typeParameters);
    T subtype = toType(subtypeString, environment);
    T supertype = toType(supertypeString, environment);
    Expect.isTrue(
        isSubtypeImpl(subtype, supertype).isSubtypeWhenUsingNullabilities(),
        "$subtypeString should be a subtype of ${supertypeString}, "
        "regardless of whether the nullability modifiers are ignored or not.");
  }

  void isNotSubtype(String subtypeString, String supertypeString,
      {String typeParameters}) {
    E environment = extend(typeParameters);
    T subtype = toType(subtypeString, environment);
    T supertype = toType(supertypeString, environment);
    Expect.isFalse(
        isSubtypeImpl(subtype, supertype).isSubtypeWhenIgnoringNullabilities(),
        "$subtypeString shouldn't be a subtype of $supertypeString, "
        "regardless of whether the nullability modifiers are ignored or not.");
  }

  /// Checks if a type is a subtype of the other ignoring nullability modifiers.
  void isObliviousSubtype(String subtypeString, String supertypeString,
      {String typeParameters}) {
    E environment = extend(typeParameters);
    T subtype = toType(subtypeString, environment);
    T supertype = toType(supertypeString, environment);
    IsSubtypeOf result = isSubtypeImpl(subtype, supertype);
    Expect.isFalse(
        result.isSubtypeWhenUsingNullabilities(),
        "$subtypeString should be a subtype of $supertypeString "
        "only if the nullability modifiers are ignored.");
    Expect.isFalse(
        !result.isSubtypeWhenIgnoringNullabilities(),
        "$subtypeString should be a subtype of $supertypeString "
        "if the nullability modifiers are ignored.");
  }

  bool get skipFutureOrPromotion => false;

  T toType(String text, E environment);

  IsSubtypeOf isSubtypeImpl(T subtype, T supertype);

  E extend(String typeParameters);

  void run() {
    // Tests for subtypes and supertypes of num.
    isSubtype('int*', 'num*');
    isSubtype('int*', 'Comparable<num*>*');
    isSubtype('int*', 'Comparable<Object*>*');
    isSubtype('int*', 'Object*');
    isSubtype('double*', 'num*');
    isSubtype('num', 'Object');
    isSubtype('num*', 'Object');
    isSubtype('Null', 'num*');
    isSubtype('Null', 'num?');
    isSubtype('Never', 'num');
    isSubtype('Never', 'num*');
    isSubtype('Never', 'num?');
    isSubtype('bottom', 'num');
    isSubtype('bottom', 'num*');
    isSubtype('bottom', 'num?');

    isNotSubtype('int*', 'double*');
    isNotSubtype('int*', 'Comparable<int*>*');
    isNotSubtype('int*', 'Iterable<int*>*');
    isNotSubtype('Comparable<int*>*', 'Iterable<int*>*');
    isObliviousSubtype('num?', 'Object');
    isObliviousSubtype('Null', 'num');
    isNotSubtype('num', 'Never');

    // Tests for subtypes and supertypes of List.
    isSubtype('List<int*>*', 'List<int*>*');
    isSubtype('List<int*>*', 'Iterable<int*>*');
    isSubtype('List<int*>*', 'List<num*>*');
    isSubtype('List<int*>*', 'Iterable<num*>*');
    isSubtype('List<int*>*', 'List<Object*>*');
    isSubtype('List<int*>*', 'Iterable<Object*>*');
    isSubtype('List<int*>*', 'Object*');
    isSubtype('List<int*>*', 'List<Comparable<Object*>*>*');
    isSubtype('List<int*>*', 'List<Comparable<num*>*>*');
    isSubtype('List<int*>*', 'List<Comparable<Comparable<num*>*>*>*');
    isSubtype('List<int*>', 'Object');
    isSubtype('List<int*>*', 'Object');
    isSubtype('Null', 'List<int*>*');
    isSubtype('Null', 'List<int*>?');
    isSubtype('Never', 'List<int*>');
    isSubtype('Never', 'List<int*>*');
    isSubtype('Never', 'List<int*>?');

    isSubtype('List<int>', 'List<int>');
    isSubtype('List<int>', 'List<int>*');
    isSubtype('List<int>', 'List<int>?');
    isSubtype('List<int>*', 'List<int>');
    isSubtype('List<int>*', 'List<int>*');
    isSubtype('List<int>*', 'List<int>?');
    isObliviousSubtype('List<int>?', 'List<int>');
    isSubtype('List<int>?', 'List<int>*');
    isSubtype('List<int>?', 'List<int>?');

    isSubtype('List<int>', 'List<int*>');
    isSubtype('List<int>', 'List<int?>');
    // TODO(dmitryas):  Uncomment the following when type arguments are allowed
    // to be intersection types.
//    isSubtype('List<X & int>', 'List<X>',
//    typeParameters: 'X extends Object?');
    isSubtype('List<int*>', 'List<int>');
    isSubtype('List<int*>', 'List<int*>');
    isSubtype('List<int*>', 'List<int?>');
    isObliviousSubtype('List<int?>', 'List<int>');
    isSubtype('List<int?>', 'List<int*>');
    isSubtype('List<int?>', 'List<int?>');
    // TODO(dmitryas):  Uncomment the following when type arguments are allowed
    // to be intersection types.
//    isSubtype('List<X & int?>', 'List<X>',
//    typeParameters: 'X extends Object?');

    isNotSubtype('List<int*>*', 'List<double*>*');
    isNotSubtype('List<int*>*', 'Iterable<double*>*');
    isNotSubtype('List<int*>*', 'Comparable<int*>*');
    isNotSubtype('List<int*>*', 'List<Comparable<int*>*>*');
    isNotSubtype('List<int*>*', 'List<Comparable<Comparable<int*>*>*>*');
    isObliviousSubtype('List<int*>?', 'Object');
    isObliviousSubtype('Null', 'List<int*>');
    isNotSubtype('List<int*>', 'Never');

    isObliviousSubtype('T?', 'List<int>',
        typeParameters: 'T extends List<int>');

    // Tests for non-generic one-argument function types.
    isSubtype('(num*) ->* num*', '(int*) ->* num*');
    isSubtype('(num*) ->* int*', '(num*) ->* num*');
    isSubtype('(num*) ->* int*', '(int*) ->* num*');
    isNotSubtype('(int*) ->* int*', '(num*) ->* num*');
    isSubtype('Null', '(int*) ->* num*');
    isSubtype('Null', '(int*) ->? num*');
    isSubtype('Never', '(int*) -> num*');
    isSubtype('Never', '(int*) ->* num*');
    isSubtype('Never', '(int*) ->? num*');
    isSubtype('bottom', '(int) -> num');
    isSubtype('bottom', '(int) ->* num');
    isSubtype('bottom', '(int) ->? num');
    isSubtype('(num*) ->* num*', 'Object');
    isSubtype('(num*) -> num*', 'Object');
    isObliviousSubtype('(num*) ->? num*', 'Object');
    isObliviousSubtype('Null', '(int*) -> num*');
    isNotSubtype('(int*) -> num*', 'Never');
    isNotSubtype('num', '(num) -> num');
    isNotSubtype('Object', '(num) -> num');
    isNotSubtype('Object*', '(num) -> num');
    isNotSubtype('Object?', '(num) -> num');
    isNotSubtype('dynamic', '(num) -> num');

    isSubtype('(num) -> num', '(num) ->* num');
    isSubtype('(num) ->* num', '(num) -> num');
    isSubtype('(num) ->? num', '(num) ->* num');
    isSubtype('(num) ->* num', '(num) ->? num');
    isSubtype('(num) -> num', '(num) ->? num');
    isObliviousSubtype('(num) ->? num', '(num) -> num');

    isSubtype('(num) -> num', '(num) -> num?');
    isSubtype('(num?) -> num', '(num) -> num');
    isSubtype('(num?) -> num', '(num) -> num?');
    isObliviousSubtype('(num) -> num', '(num?) -> num?');

    // Tests for non-generic two-argument curried function types.
    isSubtype('(num*) ->* (num*) ->* num*', '(num*) ->* (int*) ->* num*');
    isNotSubtype('(num*) ->* (int*) ->* int*', '(num*) ->* (num*) ->* num*');

    // Tests for non-generic one-argument function types with named parameters.
    isSubtype('({num* x}) ->* num*', '({int* x}) ->* num*');
    isSubtype('(num*, {num* x}) ->* num*', '(int*, {int* x}) ->* num*');
    isSubtype('({num* x}) ->* int*', '({num* x}) ->* num*');
    isNotSubtype('({int* x}) ->* int*', '({num* x}) ->* num*');

    isSubtype('({num x}) -> num', '({num x}) -> num?');
    isSubtype('({num? x}) -> num', '({num x}) -> num');
    isSubtype('({num? x}) -> num', '({num x}) -> num?');
    isObliviousSubtype('({num x}) -> num', '({num? x}) -> num?');

    // Tests for non-generic one-argument function types with optional
    // positional parameters.
    isSubtype('([num]) -> num', '([num]) -> num?');
    isSubtype('([num?]) -> num', '([num]) -> num');
    isSubtype('([num?]) -> num', '([num]) -> num?');
    isObliviousSubtype('([num]) -> num', '([num?]) -> num?');

    // Tests for function types with type parameters.
    isSubtype('<E>(E) ->* int*', '<E>(E) ->* num*');
    isSubtype('<E>(num*) ->* E', '<E>(int*) ->* E');
    isSubtype('<E>(E,num*) ->* E', '<E>(E,int*) ->* E');
    isNotSubtype('<E>(E,num*) ->* E', '<E>(E,E) ->* E');

    // Tests for curried function types with type parameters.
    isSubtype('<E>(E) ->* (E) ->* E', '<F>(F) ->* (F) ->* F');
    isSubtype('<E>(E, (int*,E) ->* E) ->* E', '<E>(E, (int*,E) ->* E) ->* E');
    isSubtype('<E>(E, (int*,E) ->* E) ->* E', '<E>(E, (num*,E) ->* E) ->* E');
    isNotSubtype('<E,F>(E) ->* (F) ->* E', '<E>(E) ->* <F>(F) ->* E');
    isNotSubtype('<E,F>(E) ->* (F) ->* E', '<F,E>(E) ->* (F) ->* E');

    isNotSubtype('<E>(E,num*) ->* E', '<E extends num*>(E*,E*) ->* E*');
    isNotSubtype(
        '<E extends num*>(E*) ->* int*', '<E extends int*>(E*) ->* int*');
    isNotSubtype('<E extends num*>(E*) ->* E*', '<E extends int*>(E*) ->* E*');
    isNotSubtype(
        '<E extends num*>(int*) ->* E*', '<E extends int*>(int*) ->* E*');
    isSubtype('<E extends num*>(E*) ->* E*', '<F extends num*>(F*) ->* num*');
    isSubtype('<E extends int*>(E*) ->* E*', '<F extends int*>(F*) ->* num*');
    isSubtype('<E extends int*>(E*) ->* E*', '<F extends int*>(F*) ->* int*');
    isNotSubtype('<E>(int*) ->* int*', '(int*) ->* int*');
    isNotSubtype('<E,F>(int*) ->* int*', '<E>(int*) ->* int*');

    // Tests for generic function types with bounded type parameters.
    isSubtype(
        '<E extends List<E*>*>(E*) ->* E*', '<F extends List<F*>*>(F*) ->* F*');
    isNotSubtype('<E extends Iterable<E*>*>(E*) ->* E*',
        '<F extends List<F*>*>(F*) ->* F*');
    isNotSubtype(
        '<E>(E,List<Object*>*) ->* E*', '<F extends List<F*>*>(F*,F*) ->* F*');
    isNotSubtype('<E>(E,List<Object*>*) ->* List<E>*',
        '<F extends List<F*>*>(F*,F*) ->* F*');
    isNotSubtype('<E>(E,List<Object*>*) ->* int*',
        '<F extends List<F*>*>(F*,F*) ->* F*');
    isNotSubtype(
        '<E>(E,List<Object*>*) ->* E', '<F extends List<F*>*>(F*,F*) ->* void');

    isSubtype('<E extends num>(E) -> E', '<F extends num*>(F*) -> F*');
    isSubtype('<E extends num*>(E*) -> E*', '<F extends num>(F) -> F');
    isSubtype('<E extends num?>(E) -> E', '<F extends num*>(F*) -> F*');
    isSubtype('<E extends num*>(E*) -> E*', '<F extends num?>(F) -> F');
    isObliviousSubtype('<E extends num>(E) -> E', '<F extends num?>(F) -> F');

    // Tests for FutureOr.
    isSubtype('int*', 'FutureOr<int*>*');
    isSubtype('int*', 'FutureOr<num*>*');
    isSubtype('Future<int*>*', 'FutureOr<int*>*');
    isSubtype('Future<int*>*', 'FutureOr<num*>*');
    isSubtype('Future<int*>*', 'FutureOr<Object*>*');
    isSubtype('FutureOr<int*>*', 'FutureOr<int*>*');
    isSubtype('FutureOr<int*>*', 'Object*');
    isSubtype('Null', 'FutureOr<num?>');
    isSubtype('Null', 'FutureOr<num>?');
    isSubtype('num?', 'FutureOr<num?>');
    isSubtype('num?', 'FutureOr<num>?');
    isSubtype('Future<num>', 'FutureOr<num?>');
    isSubtype('Future<num>', 'FutureOr<num>?');
    isSubtype('Future<num>', 'FutureOr<num?>?');
    isSubtype('Future<num?>', 'FutureOr<num?>');
    isObliviousSubtype('Future<num?>', 'FutureOr<num>?');
    isObliviousSubtype('FutureOr<int>?', 'FutureOr<int>');
    isObliviousSubtype('Future<int>?', 'FutureOr<int>');
    isSubtype('Future<num?>', 'FutureOr<num?>?');
    isSubtype('FutureOr<X>', 'FutureOr<Future<X>>',
        typeParameters: 'X extends Future<Future<X>>');

    isSubtype('FutureOr<int*>*', 'FutureOr<num*>*');
    isSubtype('FutureOr<A>', 'FutureOr<B>', typeParameters: 'B,A extends B');

    isSubtype('X', 'FutureOr<int>',
        typeParameters: 'X extends FutureOr<int*>*');
    isSubtype('X*', 'FutureOr<int>',
        typeParameters: 'X extends FutureOr<int*>*');

    isSubtype('num?', 'FutureOr<FutureOr<FutureOr<num>>?>');
    isSubtype('Future<num>?', 'FutureOr<FutureOr<FutureOr<num>>?>');
    isSubtype('Future<Future<num>>?', 'FutureOr<FutureOr<FutureOr<num>>?>');
    isSubtype(
        'Future<Future<Future<num>>>?', 'FutureOr<FutureOr<FutureOr<num>>?>');
    isSubtype('Future<num>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype('Future<Future<num>>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype(
        'Future<Future<Future<num>>>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype('Future<num?>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype('Future<Future<num?>?>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype('Future<Future<Future<num?>?>?>?',
        'FutureOr<FutureOr<FutureOr<num?>>>');

    isSubtype('FutureOr<num>?', 'FutureOr<num?>');
    isObliviousSubtype('FutureOr<num?>', 'FutureOr<num>?');

    isSubtype('List<FutureOr<List<dynamic>>>',
        'List<FutureOr<List<FutureOr<dynamic>>>>');
    isSubtype('List<FutureOr<List<FutureOr<dynamic>>>>',
        'List<FutureOr<List<dynamic>>>');

    isSubtype('X', 'FutureOr<List<X>>',
        typeParameters: 'X extends FutureOr<List<X>>');
    isNotSubtype('X', 'FutureOr<List<X>>',
        typeParameters: 'X extends List<FutureOr<X>>');

    isSubtype('dynamic', 'FutureOr<Object?>');
    isSubtype('dynamic', 'FutureOr<Object>?');
    isSubtype('void', 'FutureOr<Object?>');
    isSubtype('void', 'FutureOr<Object>?');
    isSubtype('Object*', 'FutureOr<Object?>');
    isSubtype('Object*', 'FutureOr<Object>?');
    isSubtype('Object?', 'FutureOr<Object?>');
    isSubtype('Object?', 'FutureOr<Object>?');
    isSubtype('Object', 'FutureOr<Object?>');
    isSubtype('Object', 'FutureOr<Object>?');
    isObliviousSubtype('dynamic', 'FutureOr<Object>');
    isObliviousSubtype('void', 'FutureOr<Object>');
    isObliviousSubtype('Object?', 'FutureOr<Object>');
    isSubtype('Object', 'FutureOr<Object>');

    isSubtype('FutureOr<int>', 'Object');
    isSubtype('FutureOr<int>', 'Object*');
    isSubtype('FutureOr<int>', 'Object?');
    isSubtype('FutureOr<int>*', 'Object');
    isSubtype('FutureOr<int>*', 'Object*');
    isSubtype('FutureOr<int>*', 'Object?');
    isObliviousSubtype('FutureOr<int>?', 'Object');
    isSubtype('FutureOr<int>?', 'Object*');
    isSubtype('FutureOr<int>?', 'Object?');

    isSubtype('FutureOr<int*>', 'Object');
    isSubtype('FutureOr<int*>', 'Object*');
    isSubtype('FutureOr<int*>', 'Object?');
    isObliviousSubtype('FutureOr<int?>', 'Object');
    isSubtype('FutureOr<int?>', 'Object*');
    isSubtype('FutureOr<int?>', 'Object?');

    isSubtype('FutureOr<Future<Object>>', 'Future<Object>');
    isObliviousSubtype('FutureOr<Future<Object>>?', 'Future<Object>');
    isObliviousSubtype('FutureOr<Future<Object>?>', 'Future<Object>');
    isObliviousSubtype('FutureOr<Future<Object>?>?', 'Future<Object>');

    isNotSubtype('int*', 'FutureOr<double*>*');
    isNotSubtype('FutureOr<double*>*', 'int*');
    isNotSubtype('FutureOr<int*>*', 'Future<num*>*');
    isNotSubtype('FutureOr<int*>*', 'num*');
    isSubtype('Null', 'FutureOr<int*>*');
    isSubtype('Null', 'Future<int*>*');
    isSubtype('dynamic', 'FutureOr<dynamic>*');
    isNotSubtype('dynamic', 'FutureOr<String*>*');
    isSubtype('void', 'FutureOr<void>*');
    isNotSubtype('void', 'FutureOr<String*>*');

    isSubtype('E*', 'FutureOr<E*>*', typeParameters: 'E extends Object*');
    isSubtype('E?', 'FutureOr<E>?', typeParameters: 'E extends Object');
    isSubtype('E?', 'FutureOr<E?>', typeParameters: 'E extends Object');
    isSubtype('E', 'FutureOr<E>?', typeParameters: 'E extends Object?');
    isSubtype('E', 'FutureOr<E?>', typeParameters: 'E extends Object?');
    isObliviousSubtype('E?', 'FutureOr<E>', typeParameters: 'E extends Object');
    isSubtype('E', 'FutureOr<E>', typeParameters: 'E extends Object?');
    isNotSubtype('E*', 'FutureOr<String*>*',
        typeParameters: 'E extends Object*');
    isSubtype('E?', 'FutureOr<String>?', typeParameters: 'E extends String');
    isSubtype('E?', 'FutureOr<String?>', typeParameters: 'E extends String');
    isSubtype('E', 'FutureOr<String>?', typeParameters: 'E extends String?');
    isSubtype('E', 'FutureOr<String?>', typeParameters: 'E extends String?');
    isObliviousSubtype('E?', 'FutureOr<String>',
        typeParameters: 'E extends String');
    isObliviousSubtype('E', 'FutureOr<String>',
        typeParameters: 'E extends String?');
    isSubtype('X', 'X', typeParameters: 'X extends num?');
    isSubtype('FutureOr<X>', 'FutureOr<X>', typeParameters: 'X extends num?');
    isSubtype('FutureOr<FutureOr<X>>', 'FutureOr<FutureOr<X>>',
        typeParameters: 'X extends num?');
    isSubtype('FutureOr<X>', 'FutureOr<FutureOr<X>>',
        typeParameters: 'X extends num?');

    isSubtype('() ->* String*', 'FutureOr<() ->* void>*');
    isSubtype('() -> String', 'FutureOr<() -> void>');
    isSubtype('() -> String', 'FutureOr<() ->? void>');
    isSubtype('() -> String', 'FutureOr<() -> void>?');
    isSubtype('() ->? String', 'FutureOr<() ->? void>');
    isSubtype('() ->? String', 'FutureOr<() -> void>?');
    isObliviousSubtype('() ->? String', 'FutureOr<() -> void>');
    isObliviousSubtype('() ->? String', 'FutureOr<() -> void>');
    isNotSubtype('() ->* void', 'FutureOr<() ->* String>*');
    isSubtype('FutureOr<int*>*', 'FutureOr<num*>*');
    isNotSubtype('FutureOr<num*>*', 'FutureOr<int*>*');

    isSubtype('T* & int*', 'FutureOr<num*>*',
        typeParameters: 'T extends Object*');
    isSubtype('T & int', 'FutureOr<num>', typeParameters: 'T extends Object');
    isSubtype('T & int', 'FutureOr<num?>', typeParameters: 'T extends Object');
    isSubtype('T & int', 'FutureOr<num>?', typeParameters: 'T extends Object');
    isSubtype('T & int', 'FutureOr<num>', typeParameters: 'T extends Object?');
    isSubtype('T & int', 'FutureOr<num?>', typeParameters: 'T extends Object?');
    isSubtype('T & int', 'FutureOr<num>?', typeParameters: 'T extends Object?');
    isObliviousSubtype('T & int?', 'FutureOr<num>',
        typeParameters: 'T extends Object?');
    isSubtype('T & int?', 'FutureOr<num?>',
        typeParameters: 'T extends Object?');
    isSubtype('T & int?', 'FutureOr<num>?',
        typeParameters: 'T extends Object?');
    isObliviousSubtype('T & S', 'FutureOr<Object>',
        typeParameters: 'T extends Object?, S extends T');
    isSubtype('T & S', 'FutureOr<Object?>',
        typeParameters: 'T extends Object?, S extends T');
    isSubtype('T & S', 'FutureOr<Object>?',
        typeParameters: 'T extends Object?, S extends T');

    isSubtype('T* & Future<num*>*', 'FutureOr<num*>*',
        typeParameters: 'T extends Object*');
    isSubtype('T* & Future<int*>*', 'FutureOr<num*>*',
        typeParameters: 'T extends Object*');
    isSubtype('T & Future<int>', 'FutureOr<num>',
        typeParameters: 'T extends Object');
    isSubtype('T & Future<int>', 'FutureOr<num?>',
        typeParameters: 'T extends Object');
    isSubtype('T & Future<int>', 'FutureOr<num>?',
        typeParameters: 'T extends Object');
    isSubtype('T & Future<int>', 'FutureOr<num>',
        typeParameters: 'T extends Object?');
    isSubtype('T & Future<int>', 'FutureOr<num?>',
        typeParameters: 'T extends Object?');
    isSubtype('T & Future<int>', 'FutureOr<num>?',
        typeParameters: 'T extends Object?');
    isObliviousSubtype('T & Future<int>?', 'FutureOr<num>',
        typeParameters: 'T extends Object?');
    isSubtype('T & Future<int>?', 'FutureOr<num?>',
        typeParameters: 'T extends Object?');
    isSubtype('T & Future<int>?', 'FutureOr<num>?',
        typeParameters: 'T extends Object?');
    isObliviousSubtype('T & Future<int?>', 'FutureOr<num>',
        typeParameters: 'T extends Object');
    isSubtype('T & Future<int?>', 'FutureOr<num?>',
        typeParameters: 'T extends Object');
    isObliviousSubtype('T & Future<int?>', 'FutureOr<num>?',
        typeParameters: 'T extends Object');

    if (!skipFutureOrPromotion) {
      isSubtype('T & FutureOr<int*>*', 'FutureOr<num*>*', typeParameters: 'T');
      isSubtype('T & FutureOr<num*>*', 'FutureOr<num*>*', typeParameters: 'T');
      isSubtype('T* & String*', 'FutureOr<num*>*',
          typeParameters: 'T extends int*');
      isSubtype('T* & Future<String*>*', 'FutureOr<num*>*',
          typeParameters: 'T extends Future<num*>*');
      isSubtype('T* & FutureOr<String*>*', 'FutureOr<num*>*',
          typeParameters: 'T extends FutureOr<int*>*');
      isSubtype('T* & FutureOr<String*>*', 'FutureOr<num*>*',
          typeParameters: 'T extends FutureOr<num*>*');
      isNotSubtype('FutureOr<num>', 'T & FutureOr<num>',
          typeParameters: 'T extends FutureOr<num>');
    }
    isNotSubtype('T & num*', 'FutureOr<int*>*', typeParameters: 'T');
    isNotSubtype('T & Future<num*>*', 'FutureOr<int*>*', typeParameters: 'T');
    isNotSubtype('T & FutureOr<num*>*', 'FutureOr<int*>*', typeParameters: 'T');
    isNotSubtype('T* & String*', 'FutureOr<int*>*',
        typeParameters: 'T extends num*');
    isNotSubtype('T* & Future<String*>*', 'FutureOr<int*>*',
        typeParameters: 'T extends Future<num*>*');
    isNotSubtype('T* & FutureOr<String*>*', 'FutureOr<int*>*',
        typeParameters: 'T extends FutureOr<num*>*');

    isSubtype('Id<int*>*', 'FutureOr<num*>*');
    isSubtype('Id<int>', 'FutureOr<num>');
    isObliviousSubtype('Id<int?>', 'FutureOr<num>');
    isSubtype('Id<int?>', 'FutureOr<num?>');
    isSubtype('Id<int?>', 'FutureOr<num>?');
    isObliviousSubtype('Id<int>?', 'FutureOr<num>');
    isSubtype('Id<int>?', 'FutureOr<num?>');
    isSubtype('Id<int>?', 'FutureOr<num>?');
    isNotSubtype('Id<num*>*', 'FutureOr<int*>*');

    isSubtype('FutureOr<Object*>*', 'FutureOr<FutureOr<Object*>*>*');
    isSubtype('FutureOr<num>*', 'Object');
    isSubtype('FutureOr<num>', 'Object');
    isObliviousSubtype('FutureOr<num>?', 'Object');
    isSubtype('Never', 'FutureOr<num>');
    isSubtype('Never', 'FutureOr<num*>');
    isSubtype('Never', 'FutureOr<num>*');
    isSubtype('Never', 'FutureOr<num?>');
    isSubtype('Never', 'FutureOr<num>?');
    isNotSubtype('FutureOr<num>', 'Never');

    // Testing bottom types against an intersection type.
    isSubtype('Null', 'T* & num*', typeParameters: 'T extends Object*');
    isSubtype('Never', 'T* & num*', typeParameters: 'T extends Object*');
    isObliviousSubtype('Null', 'T & num', typeParameters: 'T extends Object?');
    isObliviousSubtype('Null', 'T & num?', typeParameters: 'T extends Object?');
    isObliviousSubtype('Null', 'T & num', typeParameters: 'T extends Object');
    isObliviousSubtype('Null', 'T & S',
        typeParameters: 'T extends Object?, S extends T');
    isNotSubtype('T* & num*', 'Never', typeParameters: 'T extends Object*');
    isSubtype('T', 'Never', typeParameters: 'T extends Never');
    isSubtype('T & Never', 'Never', typeParameters: 'T extends Object');
    isSubtype('bottom', 'T & int', typeParameters: 'T extends Object');

    // Testing bottom types against type-parameter types.
    isSubtype('Null', 'T?', typeParameters: 'T extends Object');
    isSubtype('Null', 'T?', typeParameters: 'T extends Object?');
    isObliviousSubtype('Null', 'T', typeParameters: 'T extends Object');
    isObliviousSubtype('Null', 'T', typeParameters: 'T extends Object?');
    isSubtype('Never', 'T?', typeParameters: 'T extends Object');
    isSubtype('Never', 'T?', typeParameters: 'T extends Object?');
    isSubtype('Never', 'T', typeParameters: 'T extends Object');
    isSubtype('Never', 'T', typeParameters: 'T extends Object?');
    isObliviousSubtype('Never?', 'T', typeParameters: 'T extends Object?');
    isSubtype('T', 'Null', typeParameters: 'T extends Null');
    isSubtype('T?', 'Null', typeParameters: 'T extends Null');
    isNotSubtype('T', 'Null', typeParameters: 'T extends Object');
    isNotSubtype('T', 'Null', typeParameters: 'T extends Object?');
    isSubtype('T', 'Never', typeParameters: 'T extends Never');
    isObliviousSubtype('T', 'Never', typeParameters: 'T extends Never?');
    isObliviousSubtype('T?', 'Never', typeParameters: 'T extends Never');
    isObliviousSubtype('T?', 'Never', typeParameters: 'T extends Never?');
    isNotSubtype('T', 'Never', typeParameters: 'T extends Object');
    isNotSubtype('T', 'Never', typeParameters: 'T extends Object?');

    // Trivial tests for type-parameter types and intersection types.
    // T & B <: T & A if B <: A
    isSubtype('T* & int*', 'T* & int*', typeParameters: 'T extends Object*');
    isSubtype('T* & int*', 'T* & num*', typeParameters: 'T extends Object*');
    isSubtype('T* & num*', 'T* & num*', typeParameters: 'T extends Object*');
    isNotSubtype('T* & num*', 'T* & int*', typeParameters: 'T extends Object*');

    isSubtype('T & int', 'T & num', typeParameters: 'T extends Object');
    isSubtype('T & int', 'T & num', typeParameters: 'T extends Object?');
    isSubtype('T & int?', 'T & num?', typeParameters: 'T extends Object?');
    isObliviousSubtype('T & int?', 'T & num',
        typeParameters: 'T extends Object?');

    // T & B <: T extends A if B <: A
    // (Trivially satisfied since promoted bounds are always a isSubtype of the
    // original bound)
    isSubtype('T* & int*', 'T*', typeParameters: 'T extends int*');
    isSubtype('T* & int*', 'T*', typeParameters: 'T extends num*');
    isSubtype('T* & num*', 'T*', typeParameters: 'T extends num*');

    // T extends B <: T & A if B <: A
    isSubtype('T*', 'T* & int*', typeParameters: 'T extends int*');
    isSubtype('T', 'T & int', typeParameters: 'T extends int');
    isObliviousSubtype('T?', 'T & int', typeParameters: 'T extends int');
    isObliviousSubtype('T', 'T & int', typeParameters: 'T extends int?');
    isSubtype('T', 'T & int?', typeParameters: 'T extends int?');
    isObliviousSubtype('T?', 'T & int?', typeParameters: 'T extends int?');

    isSubtype('T*', 'T* & num*', typeParameters: 'T extends int*');
    isSubtype('T', 'T & num', typeParameters: 'T extends int');
    isObliviousSubtype('T?', 'T & num', typeParameters: 'T extends int');
    isObliviousSubtype('T', 'T & num', typeParameters: 'T extends int?');
    isSubtype('T', 'T & num?', typeParameters: 'T extends int?');
    isObliviousSubtype('T?', 'T & num?', typeParameters: 'T extends int?');

    isSubtype('T*', 'T* & num*', typeParameters: 'T extends num*');
    isSubtype('T', 'T & num', typeParameters: 'T extends num');
    isObliviousSubtype('T?', 'T & num', typeParameters: 'T extends num');
    isObliviousSubtype('T', 'T & num', typeParameters: 'T extends num?');
    isSubtype('T', 'T & num?', typeParameters: 'T extends num?');
    isObliviousSubtype('T?', 'T & num?', typeParameters: 'T extends num?');

    isNotSubtype('T*', 'T* & int*', typeParameters: 'T extends num*');

    // T extends A <: T extends A
    isSubtype('T*', 'T*', typeParameters: 'T extends num*');
    isSubtype('T', 'T', typeParameters: 'T extends num');
    isSubtype('T', 'T', typeParameters: 'T extends num?');
    isSubtype('T?', 'T?', typeParameters: 'T extends num');
    isSubtype('T?', 'T?', typeParameters: 'T extends num?');

    isSubtype('T', 'T', typeParameters: 'T');
    isNotSubtype('S', 'T', typeParameters: 'S, T');

    isSubtype('T*', 'T*', typeParameters: 'T extends Object*');
    isNotSubtype('S*', 'T*',
        typeParameters: 'S extends Object*, T extends Object*');

    isSubtype('T', 'T', typeParameters: 'T extends dynamic');
    isNotSubtype('S', 'T',
        typeParameters: 'S extends dynamic, T extends dynamic');

    // S <: T extends S
    isNotSubtype('S', 'T', typeParameters: 'S, T extends S');
    isSubtype('T*', 'S*', typeParameters: 'S extends Object*, T extends S*');

    isSubtype('T', 'S', typeParameters: 'S extends Object, T extends S');
    isSubtype('T', 'S?', typeParameters: 'S extends Object, T extends S');
    isObliviousSubtype('T?', 'S',
        typeParameters: 'S extends Object, T extends S');
    isSubtype('T?', 'S?', typeParameters: 'S extends Object, T extends S');

    isSubtype('T', 'S', typeParameters: 'S extends Object?, T extends S');
    isSubtype('T', 'S?', typeParameters: 'S extends Object?, T extends S');
    isObliviousSubtype('T?', 'S',
        typeParameters: 'S extends Object?, T extends S');
    isSubtype('T?', 'S?', typeParameters: 'S extends Object?, T extends S');

    isObliviousSubtype('T', 'S',
        typeParameters: 'S extends Object?, T extends S?');
    isSubtype('T', 'S?', typeParameters: 'S extends Object?, T extends S?');
    isObliviousSubtype('T?', 'S',
        typeParameters: 'S extends Object?, T extends S?');
    isSubtype('T?', 'S?', typeParameters: 'S extends Object?, T extends S?');

    isObliviousSubtype('T', 'S',
        typeParameters: 'S extends Object, T extends S?');
    isSubtype('T', 'S?', typeParameters: 'S extends Object, T extends S?');
    isObliviousSubtype('T?', 'S',
        typeParameters: 'S extends Object, T extends S?');
    isSubtype('T?', 'S?', typeParameters: 'S extends Object, T extends S?');

    isSubtype('T* & V*', 'S*',
        typeParameters: 'S extends Object*, T extends S*, V extends S*');
    isSubtype('T & V', 'S',
        typeParameters: 'S extends Object, T extends S, V extends S');
    isSubtype('T & V?', 'S?',
        typeParameters: 'S extends Object, T extends S, V extends S');
    isSubtype('T & V', 'S',
        typeParameters: 'S extends Object?, T extends S, V extends S');
    isSubtype('T & V', 'S',
        typeParameters: 'S extends Object?, T extends S?, V extends S');
    isObliviousSubtype('T & V', 'S',
        typeParameters: 'S extends Object?, T extends S?, V extends S?');

    // Non-trivial tests for intersection types.
    // S & B <: A if B <: A, A is not S (or a promotion thereof)
    isSubtype('S & int*', 'int*', typeParameters: 'S');
    isSubtype('S & int*', 'num*', typeParameters: 'S');
    isSubtype('S & num*', 'num*', typeParameters: 'S');
    isNotSubtype('S & num*', 'int*', typeParameters: 'S');
    isNotSubtype('S & num*', 'T', typeParameters: 'S, T');
    isNotSubtype('S & num*', 'T & num*', typeParameters: 'S, T');
    isSubtype('S & num', 'num', typeParameters: 'S extends Object?');
    isObliviousSubtype('S & num?', 'num', typeParameters: 'S extends Object?');
    isSubtype('S & num?', 'num?', typeParameters: 'S extends Object?');
    isSubtype('S & num?', 'num*', typeParameters: 'S extends Object?');

    // S extends B <: A if B <: A, A is not S (or a promotion thereof)
    isSubtype('S*', 'int*', typeParameters: 'S extends int*');
    isSubtype('S*', 'num*', typeParameters: 'S extends int*');
    isSubtype('S*', 'num*', typeParameters: 'S extends num*');
    isSubtype('S*', 'Object', typeParameters: 'S extends num*');
    isSubtype('S', 'Object', typeParameters: 'S extends num');
    isNotSubtype('S*', 'int*', typeParameters: 'S extends num*');
    isNotSubtype('S*', 'T', typeParameters: 'S extends num*, T');
    isNotSubtype('S*', 'T & num*', typeParameters: 'S extends num*, T');
    isObliviousSubtype('S?', 'Object', typeParameters: 'S extends num');
    isObliviousSubtype('S', 'Object', typeParameters: 'S extends num?');
    isObliviousSubtype('S?', 'Object', typeParameters: 'S extends num?');

    isNotSubtype('dynamic', 'int');
    isNotSubtype('dynamic', 'int*');
    isNotSubtype('dynamic', 'int?');
    isNotSubtype('void', 'int');
    isNotSubtype('void', 'int*');
    isNotSubtype('void', 'int?');
    isNotSubtype('Object', 'int');
    isNotSubtype('Object', 'int*');
    isNotSubtype('Object', 'int?');
    isNotSubtype('Object*', 'int');
    isNotSubtype('Object*', 'int*');
    isNotSubtype('Object*', 'int?');
    isNotSubtype('Object?', 'int');
    isNotSubtype('Object?', 'int*');
    isNotSubtype('Object?', 'int?');
    isNotSubtype('() ->* int*', 'int*');
    isNotSubtype('Typedef<Object*>*', 'int*');

    isSubtype('() -> int*', 'Function');
    isSubtype('() -> int*', 'Function*');
    isSubtype('() -> int*', 'Function?');
    isSubtype('() ->* int*', 'Function');
    isSubtype('() ->* int*', 'Function*');
    isSubtype('() ->* int*', 'Function?');
    isObliviousSubtype('() ->? int*', 'Function');
    isSubtype('() ->? int*', 'Function*');
    isSubtype('() ->? int*', 'Function?');

    isSubtype('() -> int*', 'Object');
    isSubtype('() -> int*', 'Object*');
    isSubtype('() -> int*', 'Object?');
    isSubtype('() ->* int*', 'Object');
    isSubtype('() ->* int*', 'Object*');
    isSubtype('() ->* int*', 'Object?');
    isObliviousSubtype('() ->? int*', 'Object');
    isSubtype('() ->? int*', 'Object*');
    isSubtype('() ->? int*', 'Object?');

    // Tests for "Null".
    isSubtype('Null', 'double*');
    isSubtype('Null', 'Comparable<Object*>*');
    isSubtype('Null', 'Comparable<Object*>?');
    isSubtype('Null', 'Typedef<Object*>*');
    isSubtype('Null', 'Typedef<Object*>?');
    isSubtype('Null', 'T', typeParameters: 'T extends Object*');
    isSubtype('Null', 'T?', typeParameters: 'T extends Object');
    isObliviousSubtype('Null', 'T', typeParameters: 'T extends Object?');
    isObliviousSubtype('Null', 'T', typeParameters: 'T extends Object');
    isObliviousSubtype('Null', 'Object');

    // Tests for bottom and top types.
    isSubtype('Null', 'Null');
    isNotSubtype('Null', 'bottom');
    isObliviousSubtype('Null', 'Never');
    isSubtype('bottom', 'Null');
    isSubtype('bottom', 'bottom');
    isSubtype('bottom', 'Never');
    isSubtype('Never', 'Null');
    isNotSubtype('Never', 'bottom');
    isSubtype('Never', 'Never');

    isSubtype('Null', 'Never?');
    isSubtype('Never?', 'Null');
    isSubtype('Never', 'Never?');
    isObliviousSubtype('Never?', 'Never');

    isSubtype('Object*', 'Object*');
    isSubtype('Object*', 'dynamic');
    isSubtype('Object*', 'void');
    isSubtype('Object*', 'Object?');
    isSubtype('dynamic', 'Object*');
    isSubtype('dynamic', 'dynamic');
    isSubtype('dynamic', 'void');
    isSubtype('dynamic', 'Object?');
    isSubtype('void', 'Object*');
    isSubtype('void', 'dynamic');
    isSubtype('void', 'void');
    isSubtype('void', 'Object?');
    isSubtype('Object?', 'Object*');
    isSubtype('Object?', 'dynamic');
    isSubtype('Object?', 'void');
    isSubtype('Object?', 'Object?');

    isSubtype('Never', 'Object?');
    isSubtype('Never', 'Object*');
    isSubtype('Never', 'dynamic');
    isSubtype('Never', 'void');
    isSubtype('bottom', 'Object?');
    isSubtype('bottom', 'Object*');
    isSubtype('bottom', 'dynamic');
    isSubtype('bottom', 'void');
    isSubtype('Null', 'Object?');
    isSubtype('Null', 'Object*');
    isSubtype('Null', 'dynamic');
    isSubtype('Null', 'void');

    isNotSubtype('Object?', 'Never');
    isNotSubtype('Object?', 'bottom');
    isNotSubtype('Object?', 'Null');
    isNotSubtype('Object*', 'Never');
    isNotSubtype('Object*', 'bottom');
    isNotSubtype('Object*', 'Null');
    isNotSubtype('dynamic', 'Never');
    isNotSubtype('dynamic', 'bottom');
    isNotSubtype('dynamic', 'Null');
    isNotSubtype('void', 'Never');
    isNotSubtype('void', 'bottom');
    isNotSubtype('void', 'Null');

    // Tests for Object against the top and the bottom types.
    isSubtype('bottom', 'Object');
    isSubtype('Never', 'Object');
    isSubtype('Object', 'dynamic');
    isSubtype('Object', 'void');
    isSubtype('Object', 'Object?');
    isSubtype('Object', 'Object*');
    isSubtype('Object*', 'Object');

    isNotSubtype('Object', 'bottom');
    isNotSubtype('Object', 'Null');
    isNotSubtype('Object', 'Never');
    isObliviousSubtype('dynamic', 'Object');
    isObliviousSubtype('void', 'Object');
    isObliviousSubtype('Object?', 'Object');

    // Check that the top types are equivalent.
    isSubtype(
        '<S extends Object*, T extends void, R extends Object?>'
            '(S, T, R) ->* void',
        '<U extends dynamic, V extends Object*, W extends void>'
            '(U, V, W) ->* void');

    {
      String d = '<T extends void>() ->* T';
      String e = '<T extends Object?>() ->* T';
      String f = '<T extends dynamic>() ->* T';
      String g = '<T extends Object*>() ->* T*';

      // d = e.
      isSubtype(d, e);
      isSubtype(e, d);

      // e = f.
      isSubtype(e, f);
      isSubtype(f, e);

      // f = g.
      isSubtype(f, g);
      isSubtype(g, f);
    }

    {
      String h = '<T extends List<dynamic>*>() ->* T*';
      String i = '<T extends List<Object*>*>() ->* T*';
      String j = '<T extends List<void>*>() ->* T*';
      String k = '<T extends List<Object?>*>() ->* T*';
      isSubtype(h, i);
      isSubtype(h, j);
      isSubtype(h, k);
      isSubtype(i, h);
      isSubtype(i, j);
      isSubtype(i, k);
      isSubtype(j, h);
      isSubtype(j, i);
      isSubtype(j, k);
      isSubtype(k, h);
      isSubtype(k, i);
      isSubtype(k, j);
    }

    // Tests for checking function types against other kinds of types.
    isNotSubtype('dynamic', '() ->* dynamic');
    isNotSubtype('FutureOr<() ->* void>*', '() ->* void');
    isSubtype('T & () ->* void', '() ->* void', typeParameters: 'T');
    isSubtype('T & () ->* void', '() ->* dynamic', typeParameters: 'T');
    isSubtype('T & () ->* void', '() ->* Object*', typeParameters: 'T');

    isSubtype('T & (void) ->* void', '(void) ->* void', typeParameters: 'T');
    isSubtype('T & (void) ->* void', '(dynamic) ->* dynamic',
        typeParameters: 'T');
    isSubtype('T & (void) ->* void', '(Object*) ->* Object*',
        typeParameters: 'T');

    isSubtype('T & (void) ->* void', '(void) ->* void', typeParameters: 'T');
    isSubtype('T & (void) ->* void', '(Iterable<int*>*) ->* dynamic',
        typeParameters: 'T');
    isSubtype('T & (void) ->* void', '(int*) ->* Object*', typeParameters: 'T');

    isNotSubtype('T & (void) ->* void', '(int*) ->* int*', typeParameters: 'T');

    isSubtype('T*', '() ->* void', typeParameters: 'T extends () ->* void');
    isSubtype('T', '() -> void', typeParameters: 'T extends () -> void');
    isObliviousSubtype('T?', '() -> void',
        typeParameters: 'T extends () -> void');
    isNotSubtype('T', '() ->* void', typeParameters: 'T');
    isNotSubtype('Typedef<void>*', '() ->* void');
    isSubtype('VoidFunction*', '() ->* void');
    isNotSubtype(
        'DefaultTypes<void, void, List<void>*, List<void>*, '
            'int*, (int*) ->* void, () ->* int>*',
        '() ->* void');
    isNotSubtype('void', '() ->* void');

    // Tests for checking typedef-types against other kinds of types.
    isNotSubtype('dynamic', 'T', typeParameters: 'T');
    isNotSubtype('Iterable<T>*', 'T', typeParameters: 'T');
    isNotSubtype('() ->* void', 'T', typeParameters: 'T');
    isNotSubtype('FutureOr<T>*', 'T', typeParameters: 'T');
    isSubtype('Id<T>*', 'T', typeParameters: 'T');
    isNotSubtype('VoidFunction*', 'T*',
        typeParameters: 'T extends () ->* void');
    isNotSubtype('void', 'T', typeParameters: 'T extends void');

    // Tests for checking typedef types against other kinds of types.
    isSubtype('dynamic', 'Id<dynamic>*');
    isNotSubtype('dynamic', 'Id<int*>*');

    isSubtype('() ->* void', 'Id<() ->* void>*');
    isSubtype('() -> void', 'Id<() -> void>');
    isSubtype('() -> void', 'Id<() ->? void>');
    isSubtype('() ->? void', 'Id<() ->? void>');
    isSubtype('() ->? void', 'Id<() -> void>?');
    isSubtype('() ->? void', 'Id<() ->? void>?');
    isSubtype('() -> void', 'VoidFunction');
    isSubtype('() -> void', 'VoidFunction?');
    isSubtype('() ->? void', 'VoidFunction?');

    isNotSubtype('() ->* void', 'Id<() ->* int>*');
    isNotSubtype('FutureOr<() ->* void>*', 'Id<() ->* void>*');
    isSubtype('FutureOr<() ->* void>*', 'Id<FutureOr<() ->* void>*>*');
    isSubtype('int*', 'Id<int*>*');
    isSubtype('T & () ->* void', 'Id<() ->* void>*', typeParameters: 'T');
    isSubtype('T & () ->* void', 'Id<() ->* dynamic>*', typeParameters: 'T');
    isSubtype('T & () ->* void', 'Id<() ->* Object*>*', typeParameters: 'T');
    isSubtype('Object', 'Id<Object>');
    isSubtype('Id<Object>', 'Object');
    isSubtype('Object*', 'Id<Object>');
    isSubtype('Id<Object>', 'Object*');
    isObliviousSubtype('dynamic', 'Id<Object>');
    isSubtype('Id<Object>', 'dynamic');
    isObliviousSubtype('void', 'Id<Object>');
    isSubtype('Id<Object>', 'void');
    isObliviousSubtype('Null', 'Id<Object>');
    isSubtype('Never', 'Id<Object>');
    isSubtype('Never', 'Id<Never>');
    isSubtype('Id<Never>', 'Never');
    isObliviousSubtype('Null', 'Id<Never>');
    isSubtype('Id<Never>', 'Null');
    isNotSubtype('Id<Object>', 'Never');
    isSubtype('Id<int>', 'num');
    isObliviousSubtype('Id<int?>', 'num');
    isObliviousSubtype('Id<int>?', 'num');
    isObliviousSubtype('Id<int?>?', 'num');
    isSubtype('Id<int>', 'num*');
    isSubtype('Id<int?>', 'num*');
    isSubtype('Id<int>?', 'num*');
    isSubtype('Id<int?>?', 'num*');
    isSubtype('Id<int>', 'num?');
    isSubtype('Id<int?>', 'num?');
    isSubtype('Id<int>?', 'num?');
    isSubtype('Id<int?>?', 'num?');

    isSubtype('T & (void) ->* void', 'Id<(void) ->* void>*',
        typeParameters: 'T');
    isSubtype('T & (void) ->* void', 'Id<(dynamic) ->* dynamic>*',
        typeParameters: 'T');
    isSubtype('T & (void) ->* void', 'Id<(Object*) ->* Object*>*',
        typeParameters: 'T');

    isSubtype('T & (void) ->* void', 'Id<(void) ->* void>*',
        typeParameters: 'T');
    isSubtype('T & (void) ->* void', 'Id<(Iterable<int*>*) ->* dynamic>*',
        typeParameters: 'T');
    isSubtype('T & (void) ->* void', 'Id<(int*) ->* Object*>*',
        typeParameters: 'T');

    isNotSubtype('T & (void) ->* void', 'Id<(int*) ->* int*>*',
        typeParameters: 'T');
    isNotSubtype('dynamic', 'T & dynamic', typeParameters: 'T extends dynamic');
    isNotSubtype('() ->* T*', 'T* & () ->* T*',
        typeParameters: 'T extends Object*');

    isNotSubtype('FutureOr<T & String*>*', 'T & String*', typeParameters: 'T');

    // TODO(dmitryas): Uncomment the following when type arguments are allowed
    // to be intersection types.
//    isSubtype('Id<T* & String*>*', 'T* & String*',
//        typeParameters: 'T extends Object*');
//    isSubtype('Id<T & String>', 'T & String',
//        typeParameters: 'T extends Object');
//    isSubtype('Id<T & String>', 'T & String',
//        typeParameters: 'T extends Object?');
//    isSubtype('Id<T & String?>', 'T & String?',
//        typeParameters: 'T extends Object?');
//    isSubtype('Id<T & String>', 'T & String?',
//        typeParameters: 'T extends Object?');
//    isObliviousSubtype('Id<T & String?>', 'T & String',
//        typeParameters: 'T extends Object?');
//    isObliviousSubtype('Id<T & String>?', 'T & String',
//        typeParameters: 'T extends Object');
//    isObliviousSubtype('Id<T & String>?', 'T & String?',
//        typeParameters: 'T extends Object');
//
//    isSubtype('Id<T* & String*>*', 'T*', typeParameters: 'T extends Object*');
//    isSubtype('Id<T & String>', 'T', typeParameters: 'T extends Object');
//    isSubtype('Id<T & String>', 'T?', typeParameters: 'T extends Object');
//    isSubtype('Id<T & String>', 'T', typeParameters: 'T extends Object?');
//    isSubtype('Id<T & String?>', 'T', typeParameters: 'T extends Object?');
//    isSubtype('Id<T & String>?', 'T?', typeParameters: 'T extends Object?');
//
//    isSubtype('Id<T* & String*>*', 'String*',
//        typeParameters: 'T extends Object*');
//    isNotSubtype('Id<T & String*>*', 'S & String*', typeParameters: 'T, S');

    isNotSubtype('void', 'T* & void', typeParameters: 'T extends Object*');
    isNotSubtype('void', 'T & void', typeParameters: 'T extends void');
    isNotSubtype('Object', 'T & Object', typeParameters: 'T extends Object');
    isNotSubtype('Object?', 'T & Object', typeParameters: 'T extends Object?');
    isNotSubtype('Object?', 'T & Object?', typeParameters: 'T extends Object?');
    isNotSubtype('Object*', 'T & Object*', typeParameters: 'T extends Object*');
    isNotSubtype('num', 'T & num', typeParameters: 'T extends num');
    isNotSubtype('FutureOr<num>', 'T & num', typeParameters: 'T extends num');

    isSubtype('T', 'Id<T>*', typeParameters: 'T');
    isSubtype('T', 'Id<Object*>*', typeParameters: 'T');
    isNotSubtype('T', 'Id<Comparable<int*>*>*', typeParameters: 'T');
    isSubtype('T*', 'Id<Comparable<int*>*>*',
        typeParameters: 'T extends Comparable<int*>*');

    isSubtype('Id<int*>*', 'Id<int*>*');
    isSubtype('Id<int*>*', 'Id<Object*>*');
    isNotSubtype('Id<Object*>*', 'Id<int*>*');
    isSubtype('Id<() ->* int*>*', 'Id<() ->* int*>*');
    isSubtype('Id<() ->* int*>*', 'Id<() ->* Object*>*');
    isNotSubtype('Id<() ->* Object*>*', 'Id<() ->* int*>*');

    isSubtype('void', 'Id<void>*');
    isNotSubtype('void', 'Id<Null>*');

    // The following function type tests are derived from
    // ../../../../../pkg/compiler/test/model/subtype_test.dart.
    isSubtype("() ->* int*", 'Function*');
    isNotSubtype('Function*', "() ->* int*");

    isSubtype("() ->* dynamic", "() ->* dynamic");
    isSubtype("() ->* dynamic", "() ->* void");
    isSubtype("() ->* void", "() ->* dynamic");

    isSubtype("() ->* int*", "() ->* void");
    isNotSubtype("() ->* void", "() ->* int*");
    isSubtype("() ->* void", "() ->* void");
    isSubtype("() ->* int*", "() ->* int*");
    isSubtype("() ->* int*", "() ->* Object*");
    isNotSubtype("() ->* int*", "() ->* double*");
    isNotSubtype("() ->* int*", "(int*) ->* void");
    isNotSubtype("() ->* void", "(int*) ->* int*");
    isNotSubtype("() ->* void", "(int*) ->* void");
    isSubtype("(int*) ->* int*", "(int*) ->* int*");
    isSubtype("(Object*) ->* int*", "(int*) ->* Object*");
    isNotSubtype("(int*) ->* int*", "(double*) ->* int*");
    isNotSubtype("() ->* int*", "(int*) ->* int*");
    isNotSubtype("(int*) ->* int*", "(int*, int*) ->* int*");
    isNotSubtype("(int*, int*) ->* int*", "(int*) ->* int*");
    isNotSubtype("(() ->* void) ->* void", "((int*) ->* void) ->* void");
    isNotSubtype("((int*) ->* void) ->* void", "(() ->* void) ->* void");

    // Optional positional parameters.
    isSubtype("([int*]) ->* void", "() ->* void");
    isSubtype("([int*]) ->* void", "(int*) ->* void");
    isNotSubtype("(int*) ->* void", "([int*]) ->* void");
    isSubtype("([int*]) ->* void", "([int*]) ->* void");
    isSubtype("([Object*]) ->* void", "([int*]) ->* void");
    isNotSubtype("([int*]) ->* void", "([Object*]) ->* void");
    isSubtype("(int*, [int*]) ->* void", "(int*) ->* void");
    isSubtype("(int*, [int*]) ->* void", "(int*, [int*]) ->* void");
    isNotSubtype("(int*) ->* void", "([int*]) ->* void");
    isSubtype("([int*, int*]) ->* void", "(int*) ->* void");
    isSubtype("([int*, int*]) ->* void", "(int*, [int*]) ->* void");
    isNotSubtype("([int*, int*]) ->* void", "(int*, [int*, int*]) ->* void");
    isSubtype("([int*, int*, int*]) ->* void", "(int*, [int*, int*]) ->* void");
    isNotSubtype("([int*]) ->* void", "(double*) ->* void");
    isNotSubtype("([int*]) ->* void", "([int*, int*]) ->* void");
    isSubtype("([int*, int*]) ->* void", "([int*]) ->* void");
    isSubtype("([Object*, int*]) ->* void", "([int*]) ->* void");

    // Optional named parameters.
    isSubtype("({int* a}) ->* void", "() ->* void");
    isNotSubtype("({int* a}) ->* void", "(int*) ->* void");
    isNotSubtype("(int*) ->* void", "({int* a}) ->* void");
    isSubtype("({int* a}) ->* void", "({int* a}) ->* void");
    isNotSubtype("({int* a}) ->* void", "({int* b}) ->* void");
    isSubtype("({Object* a}) ->* void", "({int* a}) ->* void");
    isNotSubtype("({int* a}) ->* void", "({Object* a}) ->* void");
    isSubtype("(int*, {int* a}) ->* void", "(int*, {int* a}) ->* void");
    isNotSubtype("({int* a}) ->* void", "({double* a}) ->* void");
    isNotSubtype("({int* a}) ->* void", "({int* a, int* b}) ->* void");
    isSubtype("({int* a, int* b}) ->* void", "({int* a}) ->* void");
    isSubtype(
        "({int* a, int* b, int* c}) ->* void", "({int* a, int* c}) ->* void");
    isSubtype(
        "({int* c, int* b, int* a}) ->* void", "({int* a, int* c}) ->* void");
    isSubtype(
        "({int* a, int* b, int* c}) ->* void", "({int* b, int* c}) ->* void");
    isSubtype(
        "({int* c, int* b, int* a}) ->* void", "({int* b, int* c}) ->* void");
    isSubtype("({int* a, int* b, int* c}) ->* void", "({int* c}) ->* void");
    isSubtype("({int* c, int* b, int* a}) ->* void", "({int* c}) ->* void");

    // Parsing of nullable and legacy types.
    isSubtype("int?", "int?");
    isSubtype("int*", "int*");
    isSubtype("(int) ->? int", "(int) ->? int");
    isSubtype("(int) ->* int", "(int) ->* int");
    isSubtype("(int, int*, int?) -> int?", "(int, int*, int?) -> int?");
    isSubtype("List<int>?", "List<int>?");
    isSubtype("List<int?>?", "List<int?>?");
    isSubtype("T & int?", "T & int?", typeParameters: "T extends Object?");
    isSubtype("T? & int?", "T? & int?", typeParameters: "T extends Object");
  }
}
