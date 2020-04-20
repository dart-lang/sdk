// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that for an unnamed async closure, the following three
// types are all appropriately matched:
// - The static return type
// - The return type of reified runtime type of a tearoff of the function or
//   method
// - The reified type of the future returned by the function or method
//
// Specific attention is paid to the following conditions:
// - The static return type is determined by type inference
// - The static return type is `dynamic`
// - The function or method immediately returns a value or future with a
//   different type (possibly using `=>` syntax)

import 'dart:async';

import 'package:expect/expect.dart';

class A {}

class B extends A {}

Future quick() async {}

Future<A> futureA() => new Future<A>.value(new A());

Future<B> futureB() => new Future<B>.value(new B());

void checkFutureObject(dynamic tearoff) {
  Expect.isTrue(tearoff is Future<Object> Function());
  Expect.isFalse(tearoff is Future<A> Function());
  dynamic f = tearoff();
  Expect.isTrue(f is Future<Object>);
  Expect.isFalse(f is Future<A>);
}

void checkFutureDynamic(dynamic tearoff) {
  Expect.isTrue(tearoff is Future<dynamic> Function());
  Expect.isFalse(tearoff is Future<A> Function());
  dynamic f = tearoff();
  Expect.isTrue(f is Future<dynamic>);
  Expect.isFalse(f is Future<A>);
}

void checkFutureA(dynamic tearoff) {
  Expect.isTrue(tearoff is Future<A> Function());
  Expect.isFalse(tearoff is Future<B> Function());
  dynamic f = tearoff();
  Expect.isTrue(f is Future<A>);
  Expect.isFalse(f is Future<B>);
}

main() {
  var f_inferred_futureObject = () async {
    await quick();
    if (false) {
      return 0;
    } else {
      return new A();
    }
  };

  var f_inferred_A = () async {
    await quick();
    if (false) {
      return new A();
    } else {
      return new B();
    }
  };

  Future<dynamic> Function() f_futureDynamic = () async {
    await quick();
    if (false) {
      return 0;
    } else {
      return new B();
    }
  };

  Future<A> Function() f_A = () async {
    await quick();
    if (false) {
      return new A();
    } else {
      return new B();
    }
  };

  Future<A> Function() f_immediateReturn_B = () async {
    if (false) {
      return new A();
    } else {
      return new B();
    }
  };

  Future<A> Function() f_immediateReturn_FutureB = () async {
    if (false) {
      return new A();
    } else {
      return futureB();
    }
  };

  Future<A> Function() f_expressionSyntax_B =
      () async => false ? new A() : new B();

  Future<A> Function() f_expressionSyntax_FutureB =
      () async => false ? futureA() : futureB();

  // Not executed
  void checkStaticTypes() {
    // Check that f_inferred_futureObject's static return type is
    // `Future<Object>`, by verifying that its return value can be assigned to
    // `Future<Object>` but not `Future<int>`.
    Future<Object> v1 = f_inferred_futureObject();
    Future<int> v2 = f_inferred_futureObject();
    //               ^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] STATIC_TYPE_WARNING.INVALID_ASSIGNMENT
    //                                      ^
    // [cfe] A value of type 'Future<Object>' can't be assigned to a variable of type 'Future<int>'.

    // Check that f_inferred_A's static return type is `Future<A>`, by verifying
    // that its return value can be assigned to `Future<A>` but not
    // `Future<B>`.
    Future<A> v3 = f_inferred_A();
    Future<B> v4 = f_inferred_A();
    //             ^^^^^^^^^^^^^^
    // [analyzer] STATIC_TYPE_WARNING.INVALID_ASSIGNMENT
    //                         ^
    // [cfe] A value of type 'Future<A>' can't be assigned to a variable of type 'Future<B>'.
  }

  checkFutureObject(f_inferred_futureObject);
  checkFutureA(f_inferred_A);
  checkFutureDynamic(f_futureDynamic);
  checkFutureA(f_A);
  checkFutureA(f_immediateReturn_B);
  checkFutureA(f_immediateReturn_FutureB);
  checkFutureA(f_expressionSyntax_B);
  checkFutureA(f_expressionSyntax_FutureB);
}
