// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

main() async {
  await returnsString();
  await returnsFutureOrString();
  await returnsAwaitFutureOrString();
  await returnsFutureString();
  await returnsAwaitFutureString();
  await returnsObject();
  await returnsFutureOrObject();
  await returnsAwaitFutureOrObject();
  await returnsFutureObject();
  await returnsAwaitFutureObject();
}

Future<String> returnsString() async => 'a';
Future<String> returnsFutureOrString() async => getFutureOr<String>('a');
Future<String> returnsAwaitFutureOrString() async =>
    await getFutureOr<String>('a');
Future<String> returnsFutureString() async => getFuture<String>('a');
FutureOr<String> returnsAwaitFutureString() async =>
    await getFuture<String>('a');

Future<Object> returnsObject() async => Object();
Future<Object> returnsFutureOrObject() async => getFutureOr<Object>(Object());
Future<Object> returnsAwaitFutureOrObject() async =>
    await getFutureOr<Object>(Object());
Future<Object> returnsFutureObject() async => getFuture<Object>(Object());
FutureOr<Object> returnsAwaitFutureObject() async =>
    await getFuture<Object>(Object());

FutureOr<T> getFutureOr<T>(T v) async => v;
Future<T> getFuture<T>(T v) async => v;
