// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B {}

class C extends B {}

void fn<T>() => null;
void fn2<R>() => null;
T voidToT<T>() => null as T;
S voidToS<S>() => null as S;
void positionalTToVoid<T>(T i) => null;
void positionalSToVoid<S>(S i) => null;
void positionalNullableTToVoid<T>(T? i) => null;
void positionalNullableSToVoid<S>(S? i) => null;
void optionalTToVoid<T>([List<T> i = const <Never>[]]) => null;
void optionalSToVoid<S>([List<S> i = const <Never>[]]) => null;
void optionalNullableTToVoid<T>([T? i]) => null;
void optionalNullableSToVoid<S>([S? i]) => null;
void namedTToVoid<T>({List<T> i = const <Never>[]}) => null;
void namedSToVoid<S>({List<S> i = const <Never>[]}) => null;
void namedNullableTToVoid<T>({T? i}) => null;
void namedNullableSToVoid<S>({S? i}) => null;
void requiredTToVoid<T>({required T i}) => null;
void requiredSToVoid<S>({required S i}) => null;
void requiredNullableTToVoid<T>({required T? i}) => null;
void requiredNullableSToVoid<S>({required S? i}) => null;

void positionalTToVoidWithBound<T extends B>(T i) => null;
void optionalTToVoidWithBound<T extends B>([List<T> i = const <Never>[]]) =>
    null;
void namedTToVoidWithBound<T extends B>({List<T> i = const <Never>[]}) => null;

class A<T extends B> {
  void fn(T i) => null;
}
