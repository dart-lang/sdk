// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests horizontal inference for a variety of types of invocations.

// SharedOptions=--enable-experiment=inference-update-1

import '../static_type_helper.dart';

testFunctionExpressionInvocation() {
  (<T>(T t, void Function(T) f) => t)(0, (x) {
    x.expectStaticType<Exactly<int>>();
  }).expectStaticType<Exactly<int>>();
}

testInstanceCreation() {
  C(0, (x) {
    x.expectStaticType<Exactly<int>>();
  }).expectStaticType<Exactly<C<int>>>();
}

testInstanceMethodInvocation(B b) {
  b.instanceMethod(0, (x) {
    x.expectStaticType<Exactly<int>>();
  }).expectStaticType<Exactly<int>>();
}

testStaticMethodInvocation() {
  B.staticMethod(0, (x) {
    x.expectStaticType<Exactly<int>>();
  }).expectStaticType<Exactly<int>>();
}

testTopLevelFunctionInvocation() {
  topLevelFunction(0, (x) {
    x.expectStaticType<Exactly<int>>();
  }).expectStaticType<Exactly<int>>();
}

testLocalFunctionInvocation() {
  T localFunction<T>(T t, void Function(T) f) => throw '';
  localFunction(0, (x) {
    x.expectStaticType<Exactly<int>>();
  }).expectStaticType<Exactly<int>>();
}

abstract class B {
  T instanceMethod<T>(T t, void Function(T) f);
  static T staticMethod<T>(T t, void Function(T) f) => throw '';
}

T topLevelFunction<T>(T t, void Function(T) f) => throw '';

class C<T> {
  C(T t, void Function(T) f);
}

main() {}
