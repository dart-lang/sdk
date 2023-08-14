// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Note: we pass --save-debugging-info=* without --dwarf-stack-traces to
// make this test pass on vm-aot-dwarf-* builders.
//
// VMOptions=--save-debugging-info=$TEST_COMPILATION_DIR/debug.so
// VMOptions=--dwarf-stack-traces --save-debugging-info=$TEST_COMPILATION_DIR/debug.so

import 'dart:async';

import 'package:expect/expect.dart';

import 'harness.dart' as harness;

String effectOrder = '';
StackTrace? stackAfterYield = null;

void emit(String m) => effectOrder += m;

main() async {
  if (harness.shouldSkip()) {
    return;
  }

  harness.configure(currentExpectations);
  await harness.runTest(() async {
    emit('1');
    await for (final value in produce()) {
      emit('5');
      Expect.equals('|value|', value);
    }
    emit('8');
    Expect.equals('12345678', effectOrder);

    effectOrder = '';

    emit('1');
    await for (final value in produceYieldStar()) {
      emit('5');
      Expect.equals('|value|', value);
      break;
    }
    emit('6');
    Expect.equals('123456', effectOrder);

    return Future.error('error', stackAfterYield!);
  });
  harness.updateExpectations();
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

// CURRENT EXPECTATIONS BEGIN
final currentExpectations = [
  """
#0    produceInner (%test%)
<asynchronous suspension>
#1    produce (%test%)
<asynchronous suspension>
#2    main.<anonymous closure> (%test%)
<asynchronous suspension>
#3    runTest (harness.dart)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>"""
];
// CURRENT EXPECTATIONS END
