// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

class Base<T> {
  String field;

  Base(this.field);
  String foo() => 'Base-$field';
}

class Sub<T> extends Base<T> {
  String field;

  Sub(this.field) : super(field);
  String foo() {
    debugger();
    return 'Sub-$field';
  }
}

class ISub<T> implements Base<T> {
  String field;

  ISub(this.field);
  String foo() => 'ISub-$field';
}

class Box<T> {
  T value;

  @pragma('vm:never-inline')
  void setValue(T value) {
    this.value = value;
  }
}

final objects = <Base>[
  new Base<int>('b'),
  new Sub<double>('a'),
  new ISub<bool>('c')
];

String triggerTypeTestingStubGeneration() {
  final Box<Object> box = new Box<Base>();
  for (int i = 0; i < 1000000; ++i) {
    box.setValue(objects.last);
  }
  return 'tts-generated';
}

void testFunction() {
  // Triggers the debugger, which will evaluate an expression in the context of
  // [Sub<double>], which will make a subclass of [Base<T>].
  print(objects[1].foo());

  triggerTypeTestingStubGeneration();

  // Triggers the debugger, which will evaluate an expression in the context of
  // [Sub<double>], which will make a subclass of [Base<T>].
  print(objects[1].foo());
}

Future triggerEvaluation(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();

  // Make sure we are in the right place.
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(2));
  expect(stack['frames'][0].function.name, equals('foo'));
  expect(stack['frames'][0].function.dartOwner.name, equals('Sub'));

  // Trigger an evaluation, which will create a new subclass of Base<T>.
  final dynamic result =
      await isolate.evalFrame(0, 'this.field + " world \$T"');
  if (result is DartError) {
    throw 'Got an error "$result", expected result of expression evaluation.';
  }
  expect(result.valueAsString, equals('a world double'));

  // Trigger an optimization of a type testing stub (and usage of it).
  final dynamic result2 =
      await isolate.evalFrame(0, 'triggerTypeTestingStubGeneration()');
  if (result2 is DartError) {
    throw 'Got an error "$result", expected result of expression evaluation.';
  }
  expect(result2.valueAsString, equals('tts-generated'));
}

final testSteps = <IsolateTest>[
  hasStoppedAtBreakpoint,
  triggerEvaluation,
  resumeIsolate,
  hasStoppedAtBreakpoint,
  triggerEvaluation,
  resumeIsolate,
];

main(args) => runIsolateTests(args, testSteps, testeeConcurrent: testFunction);
