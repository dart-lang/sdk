// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=variance

// Tests runtime subtyping with explicit variance modifiers.

import 'dart:_foreign_helper' show TYPE_REF;
import 'dart:async' show FutureOr;

import 'runtime_utils.dart';

class Upper {}

class Middle extends Upper {}

class Lower extends Middle {}

class Covariant<out T> {}

class Contravariant<in T> {}

class Invariant<inout T> {}

class LegacyCovariant<T> {}

void main() {
  // Covariant<Lower> <: Covariant<Middle>
  checkProperSubtype(
      TYPE_REF<Covariant<Lower>>(), TYPE_REF<Covariant<Middle>>());

  // Covariant<Middle> <: Covariant<Middle>
  checkSubtype(TYPE_REF<Covariant<Middle>>(), TYPE_REF<Covariant<Middle>>());

  // Contravariant<Upper> <: Contravariant<Middle>
  checkProperSubtype(
      TYPE_REF<Contravariant<Upper>>(), TYPE_REF<Contravariant<Middle>>());

  // Contravariant<Middle> <: Contravariant<Middle>
  checkSubtype(
      TYPE_REF<Contravariant<Middle>>(), TYPE_REF<Contravariant<Middle>>());

  // Invariant<Middle> <: Invariant<Middle>
  checkSubtype(TYPE_REF<Invariant<Middle>>(), TYPE_REF<Invariant<Middle>>());

  // Invariant<dynamic> <:> Invariant<Object?>
  checkMutualSubtype(
      TYPE_REF<Invariant<dynamic>>(), TYPE_REF<Invariant<Object?>>());

  // Invariant<FutureOr<dynamic>> <:> Invariant<dynamic>
  checkMutualSubtype(
      TYPE_REF<Invariant<FutureOr<dynamic>>>(), TYPE_REF<Invariant<dynamic>>());

  // Invariant<FutureOr<Null>> <:> Invariant<Future<Null>?>
  checkMutualSubtype(TYPE_REF<Invariant<FutureOr<Null>>>(),
      TYPE_REF<Invariant<Future<Null>?>>());

  // LegacyCovariant<Lower> <: LegacyCovariant<Middle>
  checkProperSubtype(
      TYPE_REF<LegacyCovariant<Lower>>(), TYPE_REF<LegacyCovariant<Middle>>());

  // List<Covariant<Lower>> <: Iterable<Covariant<Middle>>
  checkProperSubtype(TYPE_REF<List<Covariant<Lower>>>(),
      TYPE_REF<Iterable<Covariant<Middle>>>());

  // List<Contravariant<Upper>> <: Iterable<Contravariant<Middle>>
  checkProperSubtype(TYPE_REF<List<Contravariant<Upper>>>(),
      TYPE_REF<Iterable<Contravariant<Middle>>>());

  // List<Invariant<Middle>> <: Iterable<Invariant<Middle>>
  checkProperSubtype(TYPE_REF<List<Invariant<Middle>>>(),
      TYPE_REF<Iterable<Invariant<Middle>>>());

  // List<LegacyCovariant<Lower>> <: Iterable<LegacyCovariant<Middle>>
  checkProperSubtype(TYPE_REF<List<LegacyCovariant<Lower>>>(),
      TYPE_REF<Iterable<LegacyCovariant<Middle>>>());

  // String -> Covariant<Lower> <: String -> Covariant<Middle>
  checkProperSubtype(TYPE_REF<Covariant<Lower> Function(String)>(),
      TYPE_REF<Covariant<Middle> Function(String)>());

  // Covariant<Upper> -> String <: Covariant<Middle> -> String
  checkProperSubtype(TYPE_REF<String Function(Covariant<Upper>)>(),
      TYPE_REF<String Function(Covariant<Middle>)>());

  // String -> Contravariant<Upper> <: String -> Contravariant<Middle>
  checkProperSubtype(TYPE_REF<Contravariant<Upper> Function(String)>(),
      TYPE_REF<Contravariant<Middle> Function(String)>());

  // Contravariant<Lower> -> String <: Contravariant<Middle> -> String
  checkProperSubtype(TYPE_REF<String Function(Contravariant<Lower>)>(),
      TYPE_REF<String Function(Contravariant<Middle>)>());

  // String -> Invariant<Middle> <: String -> Invariant<Middle>
  checkSubtype(TYPE_REF<String Function(Invariant<Middle>)>(),
      TYPE_REF<String Function(Invariant<Middle>)>());

  // Invariant<Middle> -> String <: Invariant<Middle> -> String
  checkSubtype(TYPE_REF<String Function(Invariant<Middle>)>(),
      TYPE_REF<String Function(Invariant<Middle>)>());

  // String -> LegacyCovariant<Lower> <: String -> LegacyCovariant<Middle>
  checkProperSubtype(TYPE_REF<LegacyCovariant<Lower> Function(String)>(),
      TYPE_REF<LegacyCovariant<Middle> Function(String)>());

  // LegacyCovariant<Upper> -> String <: LegacyCovariant<Middle> -> String
  checkProperSubtype(TYPE_REF<String Function(LegacyCovariant<Upper>)>(),
      TYPE_REF<String Function(LegacyCovariant<Middle>)>());

  // Covariant<Upper> </: Covariant<Middle>
  checkSubtypeFailure(
      TYPE_REF<Covariant<Upper>>(), TYPE_REF<Covariant<Middle>>());

  // Contravariant<Lower> </: Contravariant<Middle>
  checkSubtypeFailure(
      TYPE_REF<Contravariant<Lower>>(), TYPE_REF<Contravariant<Middle>>());

  // Invariant<Upper> </: Invariant<Middle>
  checkSubtypeFailure(
      TYPE_REF<Invariant<Upper>>(), TYPE_REF<Invariant<Middle>>());

  // Invariant<Lower> </: Invariant<Middle>
  checkSubtypeFailure(
      TYPE_REF<Invariant<Lower>>(), TYPE_REF<Invariant<Middle>>());

  // LegacyCovariant<Upper> </: LegacyCovariant<Middle>
  checkSubtypeFailure(
      TYPE_REF<LegacyCovariant<Upper>>(), TYPE_REF<LegacyCovariant<Middle>>());

  // List<Covariant<Upper>> </: Iterable<Covariant<Middle>>
  checkSubtypeFailure(TYPE_REF<List<Covariant<Upper>>>(),
      TYPE_REF<Iterable<Covariant<Middle>>>());

  // List<Contravariant<Lower>> </: Iterable<Contravariant<Middle>>
  checkSubtypeFailure(TYPE_REF<List<Contravariant<Lower>>>(),
      TYPE_REF<Iterable<Contravariant<Middle>>>());

  // List<Invariant<Upper>> </: Iterable<Invariant<Middle>>
  checkSubtypeFailure(TYPE_REF<List<Invariant<Upper>>>(),
      TYPE_REF<Iterable<Invariant<Middle>>>());

  // List<Invariant<Lower>> </: Iterable<Invariant<Middle>>
  checkSubtypeFailure(TYPE_REF<List<Invariant<Lower>>>(),
      TYPE_REF<Iterable<Invariant<Middle>>>());

  // List<LegacyCovariant<Upper>> </: Iterable<LegacyCovariant<Middle>>
  checkSubtypeFailure(TYPE_REF<List<LegacyCovariant<Upper>>>(),
      TYPE_REF<Iterable<LegacyCovariant<Middle>>>());

  // String -> Covariant<Upper> </: String -> Covariant<Middle>
  checkSubtypeFailure(TYPE_REF<Covariant<Upper> Function(String)>(),
      TYPE_REF<Covariant<Middle> Function(String)>());

  // Covariant<Lower> -> String </: Covariant<Middle> -> String
  checkSubtypeFailure(TYPE_REF<String Function(Covariant<Lower>)>(),
      TYPE_REF<String Function(Covariant<Middle>)>());

  // String -> Contravariant<Lower> </: String -> Contravariant<Middle>
  checkSubtypeFailure(TYPE_REF<Contravariant<Lower> Function(String)>(),
      TYPE_REF<Contravariant<Middle> Function(String)>());

  // Contravariant<Upper> -> String </: Contravariant<Middle> -> String
  checkSubtypeFailure(TYPE_REF<String Function(Contravariant<Upper>)>(),
      TYPE_REF<String Function(Contravariant<Middle>)>());

  // String -> Invariant<Upper> </: String -> Invariant<Middle>
  checkSubtypeFailure(TYPE_REF<Invariant<Upper> Function(String)>(),
      TYPE_REF<Invariant<Middle> Function(String)>());

  // Invariant<Upper> -> String </: Invariant<Middle> -> String
  checkSubtypeFailure(TYPE_REF<String Function(Invariant<Upper>)>(),
      TYPE_REF<String Function(Invariant<Middle>)>());

  // String -> Invariant<Lower> </: String -> Invariant<Middle>
  checkSubtypeFailure(TYPE_REF<Invariant<Lower> Function(String)>(),
      TYPE_REF<Invariant<Middle> Function(String)>());

  // Invariant<Lower> -> String <: Invariant<Middle> -> String
  checkSubtypeFailure(TYPE_REF<String Function(Invariant<Lower>)>(),
      TYPE_REF<String Function(Invariant<Middle>)>());

  // String -> LegacyCovariant<Upper> </: String -> LegacyCovariant<Middle>
  checkSubtypeFailure(TYPE_REF<LegacyCovariant<Upper> Function(String)>(),
      TYPE_REF<LegacyCovariant<Middle> Function(String)>());

  // LegacyCovariant<Lower> -> String </: LegacyCovariant<Middle> -> String
  checkSubtypeFailure(TYPE_REF<String Function(LegacyCovariant<Lower>)>(),
      TYPE_REF<String Function(LegacyCovariant<Middle>)>());
}
