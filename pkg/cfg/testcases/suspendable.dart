// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Future<int> async1() async => 42;

Future<int> async2(Future<int> a, Future<int> b) async {
  return (await a) + (await b);
}

Future<void> async3(Object x) async {
  final obj = await x; // ignore: await_only_futures
  print(obj);
}

Future<List<T>> async4<T>(T x) async {
  return [x];
}

Future<void> async5<T>(T x) async {
  final obj = await x; // ignore: await_only_futures
  print(obj);
}

Stream<int> asyncStar1(int a) async* {
  print('before');
  yield a;
  print('after');
}

Stream<int> asyncStar2(Stream<int> a) async* {
  print('before');
  yield* a;
  print('after');
}

Stream<int> asyncStar3(int a) async* {
  try {
    print('before');
    yield a;
    print('after');
  } finally {
    print('finally');
  }
}

Iterable<int> syncStar1(int a) sync* {
  yield a;
}

Iterable<int> syncStar2(List<int> a) sync* {
  yield* a;
}

Iterable<int> get syncStar3 sync* {
  yield 1;
  yield 2;
}

void main() {}
