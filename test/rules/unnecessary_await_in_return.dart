// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_await_in_return`

import 'dart:async';

final future = Future.value(1);
final futureFuture = Future<Future<int>>.value(Future<int>.value(1));

Future<int> f1a() async => await future; // LINT
Future<int> f1b() async {
  return await future; // LINT
}

Future<int> f2a() async => future; // OK
Future<int> f2b() async {
  return future; // OK
}

Future<int> f3a() async => await futureFuture; // OK
Future<int> f3b() async {
  return await futureFuture; // OK
}

Future<dynamic> f4a() async => await future; // OK
Future<dynamic> f4b() async {
  return await future; // OK
}

Future<Object> f5a() async => await future; // OK
Future<Object> f5b() async {
  return await future; // OK
}

class A {
  Future<int> f1a() async => await future; // LINT
  Future<int> f1b() async {
    return await future; // LINT
  }

  Future<int> f2a() async => future; // OK
  Future<int> f2b() async {
    return future; // OK
  }

  Future<int> f3a() async => await futureFuture; // OK
  Future<int> f3b() async {
    return await futureFuture; // OK
  }

  Future<dynamic> f4a() async => await future; // OK
  Future<dynamic> f4b() async {
    return await future; // OK
  }

  Future<Object> f5a() async => await future; // OK
  Future<Object> f5b() async {
    return await future; // OK
  }
}
