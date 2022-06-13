// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--lazy-async-stacks

import 'dart:async';

import 'package:expect/expect.dart';

import 'utils.dart' show assertStack;

String effectOrder = '';
StackTrace? stackAfterYield = null;

void emit(String m) => effectOrder += m;

main() async {
  emit('1');
  await for (final value in produce()) {
    emit('5');
    Expect.equals('|value|', value);
  }
  emit('8');
  Expect.equals('12345678', effectOrder);

  assertStack(const <String>[
    r'^#0      produceInner .*$',
    r'^<asynchronous suspension>$',
    r'^#1      produce .*$',
    r'^<asynchronous suspension>$',
    r'^#2      main .*$',
    r'^<asynchronous suspension>$',
  ], stackAfterYield!);

  effectOrder = '';

  emit('1');
  await for (final value in produceYieldStar()) {
    emit('5');
    Expect.equals('|value|', value);
    break;
  }
  emit('6');
  Expect.equals('123456', effectOrder);
}

Stream<dynamic> produce() async* {
  emit('2');
  await for (String response in produceInner()) {
    emit('4');
    yield response;
  }
  emit('7');
}

Stream produceInner() async* {
  emit('3');
  yield '|value|';
  emit('6');
  stackAfterYield = StackTrace.current;
}

Stream<dynamic> produceYieldStar() async* {
  emit('2');
  await for (String response in produceInner()) {
    emit('4');
    yield response;
  }
  emit('x');
}

Stream produceInnerYieldStar() async* {
  emit('3');
  yield* Stream.fromIterable(['|value|', '|value2|']);
  emit('x');
}
