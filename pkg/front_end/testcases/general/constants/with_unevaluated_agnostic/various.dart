// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "various_lib.dart" deferred as lib;

const bool barFromEnv = const bool.fromEnvironment("bar");
const bool hasBarEnv = const bool.hasEnvironment("bar");
const bool? barFromEnvOrNull0 = const bool.fromEnvironment("bar") ? true : null;
const bool barFromEnvOrNull =
    const bool.fromEnvironment("bar", defaultValue: barFromEnvOrNull0!);
const bool notBarFromEnvOrNull = !barFromEnvOrNull;
const bool conditionalOnNull = barFromEnvOrNull ? true : false;
const bool nullAwareOnNull = barFromEnvOrNull ?? true;
const bool andOnNull = barFromEnvOrNull && true;
const bool andOnNull2 = true && barFromEnvOrNull;
const bool orOnNull = barFromEnvOrNull || true;
const bool orOnNull2 = barFromEnvOrNull || false;
const bool orOnNull3 = true || barFromEnvOrNull;
const bool orOnNull4 = false || barFromEnvOrNull;

const fromDeferredLib = lib.x;

class Foo<E> {
  final bool saved;
  final bool saved2;
  const bool initialized =
      const bool.fromEnvironment("foo", defaultValue: barFromEnv);
  final E value;

  const Foo(this.value,
      {this.saved2: const bool.fromEnvironment("foo", defaultValue: barFromEnv),
      bool x: const bool.fromEnvironment("foo", defaultValue: barFromEnv)})
      : saved = x;
}

const x = const Foo<int>(42);

const bool? y = true;
const bool z = !(y!);

const maybeInt = bool.fromEnvironment("foo") ? 42 : true;
const bool isItInt = maybeInt is int ? true : false;
const maybeInt2 = z ? 42 : true;
const bool isItInt2 = maybeInt2 is int ? true : false;
const maybeInt3 = z ? 42 : null;
const bool isItInt3 = maybeInt3 is int ? true : false;

const dynamic listOfNull = [null];
const bool isListOfNull = listOfNull is List<Null>;
const dynamic listOfInt = [42];
const bool isListOfInt = listOfInt is List<int>;
const bool isList = listOfInt is List;
const dynamic setOfInt = {42};
const bool isSetOfInt = setOfInt is Set<int>;
const dynamic mapOfInt = {42: 42};
const bool isMapOfInt = mapOfInt is Map<int, int>;
const dynamic listOfListOfInt = [
  [42]
];
const bool isListOfListOfInt = listOfListOfInt is List<List<int>>;
const dynamic setOfSetOfInt = {
  {42}
};
const bool isSetOfSetOfInt = setOfSetOfInt is Set<Set<int>>;
const dynamic mapOfMapOfInt1 = {
  {42: 42}: 42
};
const dynamic mapOfMapOfInt2 = {
  42: {42: 42}
};
const bool isMapOfMapOfInt1 = mapOfMapOfInt1 is Map<Map<int, int>, int>;
const bool isMapOfMapOfInt2 = mapOfMapOfInt2 is Map<int, Map<int, int>>;

const Symbol symbolWithUnevaluatedParameter =
    const Symbol(String.fromEnvironment("foo"));
const Symbol symbolWithInvalidName = const Symbol("42");

class A {
  const A();

  A operator -() => this;
}

class B implements A {
  const B();

  B operator -() => this;
}

class C implements A {
  const C();

  C operator -() => this;
}

class Class<T extends A> {
  const Class(T t);
  const Class.redirect(dynamic t) : this(t);
  const Class.method(T t) : this(-t);
}

class Subclass<T extends A> extends Class<T> {
  const Subclass(dynamic t) : super(t);
}

const c0 = bool.fromEnvironment("x") ? null : const Class<B>.redirect(C());
const c1 = bool.fromEnvironment("x") ? null : const Class<A>.method(A());
const c2 = bool.fromEnvironment("x") ? null : const Subclass<B>(C());
const c3 = bool.fromEnvironment("x") ? null : const Class<A>(A());
const c4 = bool.fromEnvironment("x") ? null : const Class<B>.redirect(B());
const c5 = bool.fromEnvironment("x") ? null : const Subclass<A>(A());
const c6 = bool.fromEnvironment("x") ? null : const Subclass<B>(B());

typedef F = int Function(int, {int named});
const f = F;

class ConstClassWithF {
  final F foo;
  const ConstClassWithF(this.foo);
}

int procedure(int i, {int named}) => i;
ConstClassWithF constClassWithF1 = const ConstClassWithF(procedure);
const ConstClassWithF constClassWithF2 = const ConstClassWithF(procedure);

const bool unevaluatedBool = bool.fromEnvironment("foo");
const bool notUnevaluatedBool = !unevaluatedBool;
const bool? unevaluatedBoolOrNull =
    bool.fromEnvironment("bar") ? unevaluatedBool : null;
const bool unevaluatedBoolNotNull = unevaluatedBoolOrNull!;

main() {
  print(c0);
  print(c1);
  print(c2);
  print(c3);
  print(c4);
  print(c5);
  print(c6);
  print(x);
  print(x.saved);
  print(x.value);
}
