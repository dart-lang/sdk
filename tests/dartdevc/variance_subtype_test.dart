// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=variance

// Tests runtime subtyping with explicit variance modifiers.

import 'dart:_runtime' show typeRep;
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
  checkProperSubtype(typeRep<Covariant<Lower>>(), typeRep<Covariant<Middle>>());

  // Covariant<Middle> <: Covariant<Middle>
  checkSubtype(typeRep<Covariant<Middle>>(), typeRep<Covariant<Middle>>());

  // Contravariant<Upper> <: Contravariant<Middle>
  checkProperSubtype(
      typeRep<Contravariant<Upper>>(), typeRep<Contravariant<Middle>>());

  // Contravariant<Middle> <: Contravariant<Middle>
  checkSubtype(
      typeRep<Contravariant<Middle>>(), typeRep<Contravariant<Middle>>());

  // Invariant<Middle> <: Invariant<Middle>
  checkSubtype(typeRep<Invariant<Middle>>(), typeRep<Invariant<Middle>>());

  // Invariant<dynamic> <:> Invariant<Object?>
  checkMutualSubtype(
      typeRep<Invariant<dynamic>>(), typeRep<Invariant<Object?>>());

  // Invariant<FutureOr<dynamic>> <:> Invariant<dynamic>
  checkMutualSubtype(
      typeRep<Invariant<FutureOr<dynamic>>>(), typeRep<Invariant<dynamic>>());

  // Invariant<FutureOr<Null>> <:> Invariant<Future<Null>?>
  checkMutualSubtype(
      typeRep<Invariant<FutureOr<Null>>>(), typeRep<Invariant<Future<Null>?>>());

  // LegacyCovariant<Lower> <: LegacyCovariant<Middle>
  checkProperSubtype(
      typeRep<LegacyCovariant<Lower>>(), typeRep<LegacyCovariant<Middle>>());

  // List<Covariant<Lower>> <: Iterable<Covariant<Middle>>
  checkProperSubtype(typeRep<List<Covariant<Lower>>>(),
      typeRep<Iterable<Covariant<Middle>>>());

  // List<Contravariant<Upper>> <: Iterable<Contravariant<Middle>>
  checkProperSubtype(typeRep<List<Contravariant<Upper>>>(),
      typeRep<Iterable<Contravariant<Middle>>>());

  // List<Invariant<Middle>> <: Iterable<Invariant<Middle>>
  checkProperSubtype(typeRep<List<Invariant<Middle>>>(),
      typeRep<Iterable<Invariant<Middle>>>());

  // List<LegacyCovariant<Lower>> <: Iterable<LegacyCovariant<Middle>>
  checkProperSubtype(typeRep<List<LegacyCovariant<Lower>>>(),
      typeRep<Iterable<LegacyCovariant<Middle>>>());

  // String -> Covariant<Lower> <: String -> Covariant<Middle>
  checkProperSubtype(typeRep<Covariant<Lower> Function(String)>(),
      typeRep<Covariant<Middle> Function(String)>());

  // Covariant<Upper> -> String <: Covariant<Middle> -> String
  checkProperSubtype(typeRep<String Function(Covariant<Upper>)>(),
      typeRep<String Function(Covariant<Middle>)>());

  // String -> Contravariant<Upper> <: String -> Contravariant<Middle>
  checkProperSubtype(typeRep<Contravariant<Upper> Function(String)>(),
      typeRep<Contravariant<Middle> Function(String)>());

  // Contravariant<Lower> -> String <: Contravariant<Middle> -> String
  checkProperSubtype(typeRep<String Function(Contravariant<Lower>)>(),
      typeRep<String Function(Contravariant<Middle>)>());

  // String -> Invariant<Middle> <: String -> Invariant<Middle>
  checkSubtype(typeRep<String Function(Invariant<Middle>)>(),
      typeRep<String Function(Invariant<Middle>)>());

  // Invariant<Middle> -> String <: Invariant<Middle> -> String
  checkSubtype(typeRep<String Function(Invariant<Middle>)>(),
      typeRep<String Function(Invariant<Middle>)>());

  // String -> LegacyCovariant<Lower> <: String -> LegacyCovariant<Middle>
  checkProperSubtype(typeRep<LegacyCovariant<Lower> Function(String)>(),
      typeRep<LegacyCovariant<Middle> Function(String)>());

  // LegacyCovariant<Upper> -> String <: LegacyCovariant<Middle> -> String
  checkProperSubtype(typeRep<String Function(LegacyCovariant<Upper>)>(),
      typeRep<String Function(LegacyCovariant<Middle>)>());

  // Covariant<Upper> </: Covariant<Middle>
  checkSubtypeFailure(
      typeRep<Covariant<Upper>>(), typeRep<Covariant<Middle>>());

  // Contravariant<Lower> </: Contravariant<Middle>
  checkSubtypeFailure(
      typeRep<Contravariant<Lower>>(), typeRep<Contravariant<Middle>>());

  // Invariant<Upper> </: Invariant<Middle>
  checkSubtypeFailure(
      typeRep<Invariant<Upper>>(), typeRep<Invariant<Middle>>());

  // Invariant<Lower> </: Invariant<Middle>
  checkSubtypeFailure(
      typeRep<Invariant<Lower>>(), typeRep<Invariant<Middle>>());

  // LegacyCovariant<Upper> </: LegacyCovariant<Middle>
  checkSubtypeFailure(
      typeRep<LegacyCovariant<Upper>>(), typeRep<LegacyCovariant<Middle>>());

  // List<Covariant<Upper>> </: Iterable<Covariant<Middle>>
  checkSubtypeFailure(typeRep<List<Covariant<Upper>>>(),
      typeRep<Iterable<Covariant<Middle>>>());

  // List<Contravariant<Lower>> </: Iterable<Contravariant<Middle>>
  checkSubtypeFailure(typeRep<List<Contravariant<Lower>>>(),
      typeRep<Iterable<Contravariant<Middle>>>());

  // List<Invariant<Upper>> </: Iterable<Invariant<Middle>>
  checkSubtypeFailure(typeRep<List<Invariant<Upper>>>(),
      typeRep<Iterable<Invariant<Middle>>>());

  // List<Invariant<Lower>> </: Iterable<Invariant<Middle>>
  checkSubtypeFailure(typeRep<List<Invariant<Lower>>>(),
      typeRep<Iterable<Invariant<Middle>>>());

  // List<LegacyCovariant<Upper>> </: Iterable<LegacyCovariant<Middle>>
  checkSubtypeFailure(typeRep<List<LegacyCovariant<Upper>>>(),
      typeRep<Iterable<LegacyCovariant<Middle>>>());

  // String -> Covariant<Upper> </: String -> Covariant<Middle>
  checkSubtypeFailure(typeRep<Covariant<Upper> Function(String)>(),
      typeRep<Covariant<Middle> Function(String)>());

  // Covariant<Lower> -> String </: Covariant<Middle> -> String
  checkSubtypeFailure(typeRep<String Function(Covariant<Lower>)>(),
      typeRep<String Function(Covariant<Middle>)>());

  // String -> Contravariant<Lower> </: String -> Contravariant<Middle>
  checkSubtypeFailure(typeRep<Contravariant<Lower> Function(String)>(),
      typeRep<Contravariant<Middle> Function(String)>());

  // Contravariant<Upper> -> String </: Contravariant<Middle> -> String
  checkSubtypeFailure(typeRep<String Function(Contravariant<Upper>)>(),
      typeRep<String Function(Contravariant<Middle>)>());

  // String -> Invariant<Upper> </: String -> Invariant<Middle>
  checkSubtypeFailure(typeRep<Invariant<Upper> Function(String)>(),
      typeRep<Invariant<Middle> Function(String)>());

  // Invariant<Upper> -> String </: Invariant<Middle> -> String
  checkSubtypeFailure(typeRep<String Function(Invariant<Upper>)>(),
      typeRep<String Function(Invariant<Middle>)>());

  // String -> Invariant<Lower> </: String -> Invariant<Middle>
  checkSubtypeFailure(typeRep<Invariant<Lower> Function(String)>(),
      typeRep<Invariant<Middle> Function(String)>());

  // Invariant<Lower> -> String <: Invariant<Middle> -> String
  checkSubtypeFailure(typeRep<String Function(Invariant<Lower>)>(),
      typeRep<String Function(Invariant<Middle>)>());

  // String -> LegacyCovariant<Upper> </: String -> LegacyCovariant<Middle>
  checkSubtypeFailure(typeRep<LegacyCovariant<Upper> Function(String)>(),
      typeRep<LegacyCovariant<Middle> Function(String)>());

  // LegacyCovariant<Lower> -> String </: LegacyCovariant<Middle> -> String
  checkSubtypeFailure(typeRep<String Function(LegacyCovariant<Lower>)>(),
      typeRep<String Function(LegacyCovariant<Middle>)>());
}
