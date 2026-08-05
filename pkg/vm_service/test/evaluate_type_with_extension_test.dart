// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_type_with_extension_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('evaluate_type_with_extension_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      await evaluateInFrameAndExpect(
        service,
        isolateId,
        'x.printAndReturnHello()',
        "Hello from String 'hello'",
        kind: InstanceKind.kString,
      );
    }).run(testeeMain: testee_lib.main);
