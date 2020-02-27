// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

typedef Future<Null> Task();

class ForeignFuture implements Future<Null> {
  ForeignFuture(List<Task> tasks) {
    tasks.forEach(_addTask);
  }

  Future<Null>? _future;

  void _addTask(Task task) {
    _future = (_future == null) ? task() : _future!.then((_) => task());
  }

  Future<S> then<S>(FutureOr<S> onValue(Null _), {Function? onError}) {
    assert(_future != null);
    return _future!.then((_) {
      _future = null;
      return onValue(null);
    }, onError: (error, trace) {
      _future = null;
      if (onError != null) {
        onError(error, trace);
      }
    });
  }

  Stream<Null> asStream() {
    return new Stream.fromFuture(this);
  }

  Future<Null> catchError(onError, {bool test(Object error)?}) {
    print('Unimplemented catchError');
    return Future.value();
  }

  Future<Null> timeout(Duration timeLimit, {onTimeout()?}) {
    print('Unimplemented timeout');
    return Future.value();
  }

  Future<Null> whenComplete(action()) {
    print('Unimplemented whenComplete');
    return Future.value();
  }
}

var r1;

Future<Null> hello() async {
  r1 = 'hello';
  throw new Exception('error');
}

Future<String> world() async {
  try {
    await new ForeignFuture([hello]);
  } catch (e) {}
  return 'world';
}

void main() {
  asyncStart();
  () async {
    var r2 = await world();
    Expect.equals('hello', r1);
    Expect.equals('world', r2);
    asyncEnd();
  }();
}
