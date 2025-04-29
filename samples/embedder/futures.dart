// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';

void main() async {
  print(
    'returnRegularFuture returns: '
    '${await returnRegularFuture(5)}',
  );
  print(
    'sumIntStream(useAsyncStar = false) returns: '
    '${await sumIntStream(5, 1, false)}',
  );
  print(
    'sumIntStream(useAsyncStar = true) returns: '
    '${await sumIntStream(5, 1, true)}',
  );
}

Future<int> returnRegularFuture(int delayMs) async {
  await Future.delayed(Duration(milliseconds: 5));
  return 256;
}

Future<int> returnMicrotaskFuture(int delayMs) => Future.microtask(() async {
  await Future.delayed(Duration(milliseconds: delayMs));
  return 256;
});

Stream<int> produceIntStreamWithAsyncStar(int count, int delayMs) async* {
  final delay = Duration(milliseconds: delayMs);

  for (var i = 0; i < count; i++) {
    await Future.delayed(delay);
    yield i;
  }
}

Stream<int> produceIntStreamWithController(int count, int delayMs) {
  final delay = Duration(milliseconds: delayMs);

  final sc = StreamController<int>();
  (() async {
    for (var i = 0; i < count; i++) {
      await Future.delayed(delay);
      sc.add(i);
    }
    sc.close();
  })();
  return sc.stream;
}

Future<int> sumIntStream(int count, int delayMs, bool useAsyncStar) async {
  final stream = useAsyncStar
      ? produceIntStreamWithAsyncStar(count, delayMs)
      : produceIntStreamWithController(count, delayMs);
  var sum = 0;
  await for (var value in stream) {
    sum += value;
  }
  return sum;
}

Future<int> awaitAndMultiply(Future<int> a, Future<int> b) async =>
    (await a) * (await b);

class AwaitAndMultiplyCall {
  final _a = Completer<int>();
  final _b = Completer<int>();

  Future<int> getA() => _a.future;
  Future<int> getB() => _b.future;

  @pragma('vm:entry-point', 'call')
  void setA(int value) => _a.complete(value);
  @pragma('vm:entry-point', 'call')
  void setB(int value) => _b.complete(value);
}

@pragma('vm:entry-point', 'call')
AwaitAndMultiplyCall awaitAndMultiplyC(int callbackPtr, int contextPtr) {
  final call = AwaitAndMultiplyCall();
  () async {
    Pointer<NativeFunction<Void Function(Pointer<Opaque>, Int64)>>.fromAddress(
      callbackPtr,
    ).asFunction<void Function(Pointer<Opaque>, int)>()(
      Pointer<Opaque>.fromAddress(contextPtr),
      await awaitAndMultiply(call.getA(), call.getB()),
    );
  }();
  return call;
}

@pragma('vm:entry-point', 'call')
// C-friendly wrapper over [returnRegularFuture].
void returnRegularFutureC(
  int delayMs,
  bool useMicrotask,
  int callbackPtr,
  int contextPtr,
) async =>
    Pointer<NativeFunction<Void Function(Pointer<Opaque>, Int64)>>.fromAddress(
      callbackPtr,
    ).asFunction<void Function(Pointer<Opaque>, int)>()(
      Pointer<Opaque>.fromAddress(contextPtr),
      await (useMicrotask
          ? returnMicrotaskFuture(delayMs)
          : returnRegularFuture(delayMs)),
    );

@pragma('vm:entry-point', 'call')
// C-friendly wrapper over [sumIntStream].
void sumIntStreamC(
  int count,
  int delayMs,
  bool useAsyncStar,
  int callbackPtr,
  int contextPtr,
) async =>
    Pointer<NativeFunction<Void Function(Pointer<Opaque>, Int64)>>.fromAddress(
      callbackPtr,
    ).asFunction<void Function(Pointer<Opaque>, int)>()(
      Pointer<Opaque>.fromAddress(contextPtr),
      await sumIntStream(count, delayMs, useAsyncStar),
    );
