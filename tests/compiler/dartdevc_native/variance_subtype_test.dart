// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// SharedOptions=--enable-experiment=variance

// Tests runtime subtyping with explicit variance modifiers.

import 'dart:async';

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
  checkProperSubtype(generic1(Covariant, Lower), generic1(Covariant, Middle));

  // Covariant<Middle> <: Covariant<Middle>
  checkSubtype(generic1(Covariant, Middle), generic1(Covariant, Middle));

  // Contravariant<Upper> <: Contravariant<Middle>
  checkProperSubtype(
      generic1(Contravariant, Upper), generic1(Contravariant, Middle));

  // Contravariant<Middle> <: Contravariant<Middle>
  checkSubtype(
      generic1(Contravariant, Middle), generic1(Contravariant, Middle));

  // Invariant<Middle> <: Invariant<Middle>
  checkSubtype(generic1(Invariant, Middle), generic1(Invariant, Middle));

  // Invariant<dynamic> <:> Invariant<Object>
  checkSubtype(generic1(Invariant, dynamic), generic1(Invariant, Object));
  checkSubtype(generic1(Invariant, Object), generic1(Invariant, dynamic));

  // Invariant<FutureOr<dynamic>> <:> Invariant<dynamic>
  checkSubtype(
      generic1(Invariant, futureOrOf(dynamic)), generic1(Invariant, dynamic));
  checkSubtype(
      generic1(Invariant, dynamic), generic1(Invariant, futureOrOf(dynamic)));

  // Invariant<FutureOr<Null>> <:> Invariant<Future<Null>>
  checkSubtype(generic1(Invariant, futureOrOf(Null)),
      generic1(Invariant, generic1(Future, Null)));
  checkSubtype(generic1(Invariant, generic1(Future, Null)),
      generic1(Invariant, futureOrOf(Null)));

  // LegacyCovariant<Lower> <: LegacyCovariant<Middle>
  checkProperSubtype(
      generic1(LegacyCovariant, Lower), generic1(LegacyCovariant, Middle));

  // List<Covariant<Lower>> <: Iterable<Covariant<Middle>>
  checkProperSubtype(generic1(List, generic1(Covariant, Lower)),
      generic1(Iterable, generic1(Covariant, Middle)));

  // List<Contravariant<Upper>> <: Iterable<Contravariant<Middle>>
  checkProperSubtype(generic1(List, generic1(Contravariant, Upper)),
      generic1(Iterable, generic1(Contravariant, Middle)));

  // List<Invariant<Middle>> <: Iterable<Invariant<Middle>>
  checkProperSubtype(generic1(List, generic1(Invariant, Middle)),
      generic1(Iterable, generic1(Invariant, Middle)));

  // List<LegacyCovariant<Lower>> <: Iterable<LegacyCovariant<Middle>>
  checkProperSubtype(generic1(List, generic1(LegacyCovariant, Lower)),
      generic1(Iterable, generic1(LegacyCovariant, Middle)));

  // String -> Covariant<Lower> <: String -> Covariant<Middle>
  checkProperSubtype(function1(generic1(Covariant, Lower), String),
      function1(generic1(Covariant, Middle), String));

  // Covariant<Upper> -> String <: Covariant<Middle> -> String
  checkProperSubtype(function1(String, generic1(Covariant, Upper)),
      function1(String, generic1(Covariant, Middle)));

  // String -> Contravariant<Upper> <: String -> Contravariant<Middle>
  checkProperSubtype(function1(generic1(Contravariant, Upper), String),
      function1(generic1(Contravariant, Middle), String));

  // Contravariant<Lower> -> String <: Contravariant<Middle> -> String
  checkProperSubtype(function1(String, generic1(Contravariant, Lower)),
      function1(String, generic1(Contravariant, Middle)));

  // String -> Invariant<Middle> <: String -> Invariant<Middle>
  checkSubtype(function1(generic1(Invariant, Middle), String),
      function1(generic1(Invariant, Middle), String));

  // Invariant<Middle> -> String <: Invariant<Middle> -> String
  checkSubtype(function1(String, generic1(Invariant, Middle)),
      function1(String, generic1(Invariant, Middle)));

  // String -> LegacyCovariant<Lower> <: String -> LegacyCovariant<Middle>
  checkProperSubtype(function1(generic1(LegacyCovariant, Lower), String),
      function1(generic1(LegacyCovariant, Middle), String));

  // LegacyCovariant<Upper> -> String <: LegacyCovariant<Middle> -> String
  checkProperSubtype(function1(String, generic1(LegacyCovariant, Upper)),
      function1(String, generic1(LegacyCovariant, Middle)));

  // Covariant<Upper> </: Covariant<Middle>
  checkSubtypeFailure(generic1(Covariant, Upper), generic1(Covariant, Middle));

  // Contravariant<Lower> </: Contravariant<Middle>
  checkSubtypeFailure(
      generic1(Contravariant, Lower), generic1(Contravariant, Middle));

  // Invariant<Upper> </: Invariant<Middle>
  checkSubtypeFailure(generic1(Invariant, Upper), generic1(Invariant, Middle));

  // Invariant<Lower> </: Invariant<Middle>
  checkSubtypeFailure(generic1(Invariant, Lower), generic1(Invariant, Middle));

  // LegacyCovariant<Upper> </: LegacyCovariant<Middle>
  checkSubtypeFailure(
      generic1(LegacyCovariant, Upper), generic1(LegacyCovariant, Middle));

  // List<Covariant<Upper>> </: Iterable<Covariant<Middle>>
  checkSubtypeFailure(generic1(List, generic1(Covariant, Upper)),
      generic1(Iterable, generic1(Covariant, Middle)));

  // List<Contravariant<Lower>> </: Iterable<Contravariant<Middle>>
  checkSubtypeFailure(generic1(List, generic1(Contravariant, Lower)),
      generic1(Iterable, generic1(Contravariant, Middle)));

  // List<Invariant<Upper>> </: Iterable<Invariant<Middle>>
  checkSubtypeFailure(generic1(List, generic1(Invariant, Upper)),
      generic1(Iterable, generic1(Invariant, Middle)));

  // List<Invariant<Lower>> </: Iterable<Invariant<Middle>>
  checkSubtypeFailure(generic1(List, generic1(Invariant, Lower)),
      generic1(Iterable, generic1(Invariant, Middle)));

  // List<LegacyCovariant<Upper>> </: Iterable<LegacyCovariant<Middle>>
  checkSubtypeFailure(generic1(List, generic1(LegacyCovariant, Upper)),
      generic1(Iterable, generic1(LegacyCovariant, Middle)));

  // String -> Covariant<Upper> </: String -> Covariant<Middle>
  checkSubtypeFailure(function1(generic1(Covariant, Upper), String),
      function1(generic1(Covariant, Middle), String));

  // Covariant<Lower> -> String </: Covariant<Middle> -> String
  checkSubtypeFailure(function1(String, generic1(Covariant, Lower)),
      function1(String, generic1(Covariant, Middle)));

  // String -> Contravariant<Lower> </: String -> Contravariant<Middle>
  checkSubtypeFailure(function1(generic1(Contravariant, Lower), String),
      function1(generic1(Contravariant, Middle), String));

  // Contravariant<Upper> -> String </: Contravariant<Middle> -> String
  checkSubtypeFailure(function1(String, generic1(Contravariant, Upper)),
      function1(String, generic1(Contravariant, Middle)));

  // String -> Invariant<Upper> </: String -> Invariant<Middle>
  checkSubtypeFailure(function1(generic1(Invariant, Upper), String),
      function1(generic1(Invariant, Middle), String));

  // Invariant<Upper> -> String </: Invariant<Middle> -> String
  checkSubtypeFailure(function1(String, generic1(Invariant, Upper)),
      function1(String, generic1(Invariant, Middle)));

  // String -> Invariant<Lower> </: String -> Invariant<Middle>
  checkSubtypeFailure(function1(generic1(Invariant, Lower), String),
      function1(generic1(Invariant, Middle), String));

  // Invariant<Lower> -> String <: Invariant<Middle> -> String
  checkSubtypeFailure(function1(String, generic1(Invariant, Lower)),
      function1(String, generic1(Invariant, Middle)));

  // String -> LegacyCovariant<Upper> </: String -> LegacyCovariant<Middle>
  checkSubtypeFailure(function1(generic1(LegacyCovariant, Upper), String),
      function1(generic1(LegacyCovariant, Middle), String));

  // LegacyCovariant<Lower> -> String </: LegacyCovariant<Middle> -> String
  checkSubtypeFailure(function1(String, generic1(LegacyCovariant, Lower)),
      function1(String, generic1(LegacyCovariant, Middle)));
}
