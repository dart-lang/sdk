// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 29;
const LINE_B = LINE_A + 5;
const LINE_C = LINE_B + 6;

class A {}

class B extends A {}

class C extends Object with ListMixin<C> implements List<C> {
  int length = 0;
  C operator [](int index) => throw UnimplementedError();
  void operator []=(int index, C value) {}
}

void testFunction4<T4 extends List<T4>>() {
  debugger();
  print("T4 = $T4");
}

void testFunction3<T3, S3 extends T3>() {
  debugger();
  print("T3 = $T3");
  print("S3 = $S3");
}

void testFunction2<E extends String>(List<E> x) {
  debugger();
  print("x = $x");
}

void testFunction() {
  testFunction2<String>(<String>["a", "b", "c"]);
  testFunction3<A, B>();
  testFunction4<C>();
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    {
      // Can add List<E extends String> to List<String> directly.
      final expression = '''
      () {
        List<E> y = List<E>.from(["hello"]);
        x.addAll(y);
        return x.last;
      }()
      ''';
      await evaluateInFrameAndExpect(
        service,
        isolateId,
        expression,
        'hello',
        kind: InstanceKind.kString,
      );
    }
    {
      final expression = '''
      () {
        List<E> y = [];
        y.addAll(x);
        return y.last;
      }()
      ''';
      // Can't add List<String> to List<E extends String> directly.
      try {
        await service.evaluateInFrame(isolateId, 0, expression);
        fail("Can't add List<String> to List<E extends String> directly.");
      } on RPCError catch (e) {
        expect(e.code, RPCErrorKind.kExpressionCompilationError.code);
        expect(
          e.details,
          contains(
            "The argument type '_GrowableList<String>' can't be assigned "
            "to the parameter type 'Iterable<E>'",
          ),
        );
      }
    }
    {
      // Can add List<String> to List<E extends String> via cast.
      final expression = '''
      () {
        List<E> y = [];
        y.addAll(x.cast());
        return y.toString();
      }()
      ''';
      await evaluateInFrameAndExpect(
        service,
        isolateId,
        expression,
        // Notice how "hello" was added a few evaluations back.
        '[a, b, c, hello]',
        kind: InstanceKind.kString,
      );
    }
    {
      // Can create List<String> from List<E extends String>.
      final expression = '''
      () {
        List<E> y = List<E>.from(x);
        return y.toString();
      }()
      ''';
      await evaluateInFrameAndExpect(
        service,
        isolateId,
        expression,
        // Notice how "hello" was added a few evaluations back.
        '[a, b, c, hello]',
        kind: InstanceKind.kString,
      );
    }
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (VmService service, IsolateRef isolateRef) async {
    // This is just to make sure the VM doesn't crash.
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'S3.toString()',
      'B',
      kind: InstanceKind.kString,
    );
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    // This is just to make sure the VM doesn't crash.
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'T4.toString()',
      'C',
      kind: InstanceKind.kString,
    );
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_type_arguments_test.dart',
      testeeConcurrent: testFunction,
    );
