// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_type_arguments_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('evaluate_type_arguments_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
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
            // We wouldnt be able to add List<String> to List<E extends String>,
            // but the CFE now uses static types for "dart:" definitions, making this
            // adding List<E extends String> to List<E extends String>.
            await evaluateInFrameAndExpect(
              service,
              isolateId,
              expression,
              'hello',
              kind: InstanceKind.kString,
            );
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
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          // This is just to make sure the VM doesn't crash.
          final isolateId = isolateRef.id!;
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'S3.toString()',
            'B',
            kind: InstanceKind.kString,
          );
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          // This is just to make sure the VM doesn't crash.
          final isolateId = isolateRef.id!;
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'T4.toString()',
            'C',
            kind: InstanceKind.kString,
          );
        })
        .run(testeeMain: testee_lib.main);
