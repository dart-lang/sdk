// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that async/await syntax works for synchronously completed futures.
// Such futures are used by Flutter (see http://dartbug.com/32098).

import 'dart:async';

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

class SynchronousFuture<T> implements Future<T> {
  final T v;

  SynchronousFuture(this.v);

  Future<E> then<E>(FutureOr<E> f(T v), {Function onError}) {
    final u = f(v);
    return u is Future<dynamic>
        ? (u as Future<dynamic>).then((v) => v as E)
        : new SynchronousFuture<E>(u);
  }

  Stream<T> asStream() => throw 'unimplemented';
  Future<T> catchError(Function onError, {bool test(dynamic error)}) =>
      throw 'unimplemented';
  Future<T> timeout(Duration timeLimit, {dynamic onTimeout()}) =>
      throw 'unimplemented';
  Future<T> whenComplete(dynamic action()) => throw 'unimplemented';
}

void main() {
  var stage = 0;
  asyncTest(() async {
    int v;
    Expect.equals(0, stage++);
    v = await new SynchronousFuture<int>(stage);
    Expect.equals(1, v);
    Expect.equals(1, stage++);
    v = await new SynchronousFuture<int>(stage);
    Expect.equals(2, v);
    Expect.equals(2, stage++);
    v = await new SynchronousFuture<int>(stage);
    Expect.equals(3, v);
    Expect.equals(3, stage++);
  });
}
