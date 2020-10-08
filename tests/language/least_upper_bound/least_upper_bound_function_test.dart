// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test least upper bound for a Function type and a type that doesn't match
// any of the cases for function types being subtypes of each other.

import 'dart:async';
import '../static_type_helper.dart';

bool condition = true;

void main() {
  void f1(void Function() x, Object y) {
    var z = condition ? x : y;
    z.expectStaticType<Exactly<Object>>();
  }

  void f2(int x, void Function<X>() y) {
    var z = condition ? x : y;
    z.expectStaticType<Exactly<Object>>();
  }

  void f3(double Function(int, int) x, FutureOr<Function> y) {
    var z = condition ? x : y;
    z.expectStaticType<Exactly<Object>>();
  }

  void f4(FutureOr<Function?> x, Function(int i, {int j}) y) {
    var z = condition ? x : y;
    z.expectStaticType<Exactly<Object?>>();
  }

  void f5(Function Function<Y>([Y y]) x, dynamic y) {
    var z = condition ? x : y;
    // Check that the type is a top type.
    z.expectStaticType<Exactly<dynamic>>();
    // Check that the type is `dynamic`.
    z.unknownMember;
  }

  void f6(Never x, Never Function() y) {
    var z = condition ? x : y;
    z.expectStaticType<Exactly<Never Function()>>();
  }

  void f7(Function(Function) x, Null y) {
    var z = condition ? x : y;
    z.expectStaticType<Exactly<Object?>>();
  }
}
