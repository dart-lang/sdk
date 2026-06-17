// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_function_type_parameters_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'evaluate_function_type_parameters_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'S.toString()',
            'String',
          );
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'TBool.toString()',
            'bool',
          );
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'S.toString()',
            'String',
          );
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'TString.toString()',
            'String',
          );
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'TDouble.toString()',
            'double',
          );
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'TInt.toString()',
            'int',
          );
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'x',
            '3',
          );
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'S.toString()',
            'String',
          );
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'T.toString()',
            'int',
          );
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'S.toString()',
            'bool',
          );
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_E')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            'T.toString()',
            'dynamic',
          );
          await evaluateInFrameAndExpect(
            service,
            isolateId,
            't',
            '42',
          );
        })
        .run(testeeMain: testee_lib.main);
