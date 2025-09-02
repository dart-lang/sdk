// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/language/pull/4210.

// ignore_for_file: unused_element

import '../static_type_helper.dart';

void testLocalFunctions() {
  withoutReturnSync() sync* {
    yield 1;
  }

  withoutReturnSync.expectStaticType<Exactly<Iterable<int> Function()>>();
  withoutReturnSync().expectStaticType<Exactly<Iterable<int>>>();

  withReturnSync() sync* {
    yield 1;
    return;
  }

  // `return;` should not make the element type nullable.
  withReturnSync.expectStaticType<Exactly<Iterable<int> Function()>>();
  withReturnSync().expectStaticType<Exactly<Iterable<int>>>();

  // No compile-time error occurs when the return type is declared.
  Iterable<int> withReturnSync2() sync* {
    yield 1;
    return;
  }

  withReturnSync2.expectStaticType<Exactly<Iterable<int> Function()>>();
  withReturnSync2().expectStaticType<Exactly<Iterable<int>>>();

  withoutReturnAsync() async* {
    yield 1;
  }

  withoutReturnAsync.expectStaticType<Exactly<Stream<int> Function()>>();
  withoutReturnAsync().expectStaticType<Exactly<Stream<int>>>();

  withReturnAsync() async* {
    yield 1;
    return;
  }

  // `return;` should not make the element type nullable.
  withReturnAsync.expectStaticType<Exactly<Stream<int> Function()>>();
  withReturnAsync().expectStaticType<Exactly<Stream<int>>>();

  // No compile-time error occurs when the return type is declared.
  Stream<int> withReturnAsync2() async* {
    yield 1;
    return;
  }

  withReturnAsync2.expectStaticType<Exactly<Stream<int> Function()>>();
  withReturnAsync2().expectStaticType<Exactly<Stream<int>>>();

  withoutReturnGenericSync<X>() sync* {
    yield 1 as X;
  }

  withoutReturnGenericSync
      .expectStaticType<Exactly<Iterable<X> Function<X>()>>();
  withoutReturnGenericSync<int>().expectStaticType<Exactly<Iterable<int>>>();

  withReturnGenericSync<X>() sync* {
    yield 1 as X;
    return;
  }

  // `return;` should not make the element type nullable.
  withReturnGenericSync.expectStaticType<Exactly<Iterable<X> Function<X>()>>();
  withReturnGenericSync<int>().expectStaticType<Exactly<Iterable<int>>>();

  // No compile-time error occurs when the return type is declared.
  Iterable<X> withReturnGenericSync2<X>() sync* {
    yield 1 as X;
    return;
  }

  withReturnGenericSync2.expectStaticType<Exactly<Iterable<X> Function<X>()>>();
  withReturnGenericSync2<int>().expectStaticType<Exactly<Iterable<int>>>();

  withoutReturnGenericAsync<X>() async* {
    yield 1 as X;
  }

  withoutReturnGenericAsync
      .expectStaticType<Exactly<Stream<X> Function<X>()>>();
  withoutReturnGenericAsync<int>().expectStaticType<Exactly<Stream<int>>>();

  withReturnGenericAsync<X>() async* {
    yield 1 as X;
    return;
  }

  // `return;` should not make the element type nullable.
  withReturnGenericAsync.expectStaticType<Exactly<Stream<X> Function<X>()>>();
  withReturnGenericAsync<int>().expectStaticType<Exactly<Stream<int>>>();

  // No compile-time error occurs when the return type is declared.
  Stream<X> withReturnGenericAsync2<X>() async* {
    yield 1 as X;
    return;
  }

  withReturnGenericAsync2.expectStaticType<Exactly<Stream<X> Function<X>()>>();
  withReturnGenericAsync2<int>().expectStaticType<Exactly<Stream<int>>>();
}

void testFunctionLiterals() {
  final withoutReturnSync = () sync* {
    yield 1;
  };
  withoutReturnSync.expectStaticType<Exactly<Iterable<int> Function()>>();
  withoutReturnSync().expectStaticType<Exactly<Iterable<int>>>();

  final withReturnSync = () sync* {
    yield 1;
    return;
  };
  // `return;` should not make the element type nullable.
  withReturnSync.expectStaticType<Exactly<Iterable<int> Function()>>();
  withReturnSync().expectStaticType<Exactly<Iterable<int>>>();

  // No compile-time error occurs when the return type is declared.
  final Iterable<int> Function() withReturnSync2 = () sync* {
    yield 1;
    return;
  };
  withReturnSync2.expectStaticType<Exactly<Iterable<int> Function()>>();
  withReturnSync2().expectStaticType<Exactly<Iterable<int>>>();

  final withoutReturnAsync = () async* {
    yield 1;
  };
  withoutReturnAsync.expectStaticType<Exactly<Stream<int> Function()>>();
  withoutReturnAsync().expectStaticType<Exactly<Stream<int>>>();

  final withReturnAsync = () async* {
    yield 1;
    return;
  };
  // `return;` should not make the element type nullable.
  withReturnAsync.expectStaticType<Exactly<Stream<int> Function()>>();
  withReturnAsync().expectStaticType<Exactly<Stream<int>>>();

  // No compile-time error occers when the return type is declared.
  final Stream<int> Function() withReturnAsync2 = () async* {
    yield 1;
    return;
  };
  withReturnAsync2.expectStaticType<Exactly<Stream<int> Function()>>();
  withReturnAsync2().expectStaticType<Exactly<Stream<int>>>();

  final withoutReturnGenericSync = <X>() sync* {
    yield 1 as X;
  };
  withoutReturnGenericSync
      .expectStaticType<Exactly<Iterable<X> Function<X>()>>();
  withoutReturnGenericSync<int>().expectStaticType<Exactly<Iterable<int>>>();

  final withReturnGenericSync = <X>() sync* {
    yield 1 as X;
    return;
  };
  // `return;` should not make the element type nullable.
  withReturnGenericSync.expectStaticType<Exactly<Iterable<X> Function<X>()>>();
  withReturnGenericSync<int>().expectStaticType<Exactly<Iterable<int>>>();

  // No compile-time error occurs when the return type is declared.
  final Iterable<X> Function<X>() withReturnGenericSync2 = <X>() sync* {
    yield 1 as X;
    return;
  };
  withReturnGenericSync2.expectStaticType<Exactly<Iterable<X> Function<X>()>>();
  withReturnGenericSync2<int>().expectStaticType<Exactly<Iterable<int>>>();

  final withoutReturnGenericAsync = <X>() async* {
    yield 1 as X;
  };
  withoutReturnGenericAsync
      .expectStaticType<Exactly<Stream<X> Function<X>()>>();
  withoutReturnGenericAsync<int>().expectStaticType<Exactly<Stream<int>>>();

  final withReturnGenericAsync = <X>() async* {
    yield 1 as X;
    return;
  };
  // `return;` should not make the element type nullable.
  withReturnGenericAsync.expectStaticType<Exactly<Stream<X> Function<X>()>>();
  withReturnGenericAsync<int>().expectStaticType<Exactly<Stream<int>>>();

  // No compile-time error occers when the return type is declared.
  final Stream<X> Function<X>() withReturnGenericAsync2 = <X>() async* {
    yield 1 as X;
    return;
  };
  withReturnGenericAsync2.expectStaticType<Exactly<Stream<X> Function<X>()>>();
  withReturnGenericAsync2<int>().expectStaticType<Exactly<Stream<int>>>();
}

void main() {
  testLocalFunctions();
  testFunctionLiterals();
}
