// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing the behavior of `Type.toString`.
//
// The behavior is *unspecified*, but users may depend on it.
// This test ensures that we do not change the format inadvertently.
// If we decide to change the format, it should be deliberate and consistent.

import "dart:async" show FutureOr;

import "package:expect/expect.dart";

void expectType(Type type, Pattern text) {
  var typeString = "$type";
  if (typeString.contains("minified:")) {
    return; // No checks for minimized types.
  }
  if (text is String) {
    Expect.equals(text, typeString);
    return;
  }
  var match = text.matchAsPrefix(typeString);
  if (match != null && match.end == typeString.length) return;
  Expect.fail(
      "$typeString was not matched by $text${match == null ? "" : ", match: ${match[0]}"}");
}

void expect<T>(Pattern text) {
  expectType(T, text);
}

void main() {
  // Simple interface types.
  expect<int>("int");
  expect<Object>("Object");
  expect<Null>("Null");
  expect<Base>("Base");
  expect<Mixin>("Mixin");
  // Named mixin applications use their name.
  expect<MixinApplication>("MixinApplication");

  // Non-class, non-function types.
  expect<void>("void");
  expect<dynamic>("dynamic");
  expect<Function>("Function");
  // TODO: Add Never with NNBD.

  // Generic interface types.
  expect<List<int>>("List<int>");
  expect<Iterable<Object>>("Iterable<Object>");
  expect<Map<List<String>, Future<void>>>("Map<List<String>, Future<void>>");
  expect<GenericMixin<String>>("GenericMixin<String>");

  // Generic non-class, non-function type.
  expect<FutureOr<int>>("FutureOr<int>");
  expect<FutureOr<Object>>("Object");
  expect<FutureOr<FutureOr<Future<Object>>>>(
      "FutureOr<FutureOr<Future<Object>>>");
  expect<FutureOr<Null>>("Future<Null>?");
  // TODO: Add nullable types with NNBD.

  // Private names may be mangled.
  expect<_Private>(re(r'_Private\b.*$'));

  // Function types.
  expect<void Function()>("() => void");
  expect<String Function()>("() => String");
  expect<String Function(String)>("(String) => String");
  expect<String Function(int, [String])>("(int, [String]) => String");
  expect<String Function(int, {String z})>("(int, {String z}) => String");
  expect<int Function(void Function(String))>("((String) => void) => int");
  expect<int Function(void) Function(String)>("(String) => (void) => int");

  // A type alias is expanded to its type.
  expect<Typedef>("(dynamic) => dynamic");
  expect<Typedef<int>>("(int) => int");
  expectType(Typedef, "(dynamic) => dynamic");

  // Generic functions do not promise to preserve type variable names,
  // but do keep the structure of `<typevars>(params) => result`.

  // Cannot pass a generic type as type argument, so passing the Type object
  // derived from evaluating the typedef name.

  // Format: <T>() => void
  expectType(G0, re(r"<\w+>\(\) => void$"));
  // Format: <T>() => T
  expectType(G1, re(r"<(\w+)>\(\) => \1$"));
  // Format: <T>(T) => T
  expectType(G2, re(r"<(\w+)>\(\1\) => \1$"));
  // Format: <T>(<S>(S, T) => S) => T
  expectType(G3, re(r"<(\w+)>\(<(\w+)>\(\2, \1\) => \2\) => \1$"));
  // Format: <S>(S) => <T>(S, T) => S
  expectType(G4, re(r"<(\w+)>\(\1\) => <(\w+)>\(\1, \2\) => \1$"));
  // Format: <S, T>(S, T) => S
  expectType(G5, re(r"<(\w+), (\w+)>\(\1, \2\) => \1$"));

  // Format: <T>(<S>(S) => S) => T
  expectType(Weird, re(r"<(\w+)>\(<(\w+)>\(\2\) => \2\) => \1$"));

  // One with everything.
  expect<FutureOr<void Function([T Function<S, T>(Map<dynamic, Typedef<S>>)])>>(
      // Format: FutureOr<([<S, T>(Map<dynamic, (S) => S>) => T]) => void>
      re(r"FutureOr<\(\[<(\w+), (\w+)>\(Map<dynamic, "
          r"\(\1\) => \1>\) => \2\]\) => void>$"));
}

// Types to test against.
class _Private {}

class Base {}

mixin Mixin {}

class MixinApplication = Base with Mixin;

mixin GenericMixin<T> implements List<T> {}

typedef Typedef<T> = T Function(T);

// Generic function types.
typedef G0 = void Function<T>();
typedef G1 = T Function<T>();
typedef G2 = T Function<T>(T);
typedef G3 = T Function<T>(S Function<S>(S, T));
typedef G4 = S Function<T>(S, T) Function<S>(S);
typedef G5 = S Function<S, T>(S, T);

typedef Weird = Function Function<Function>(
    Function Function<Function>(Function));

RegExp re(String source) => RegExp(source);
