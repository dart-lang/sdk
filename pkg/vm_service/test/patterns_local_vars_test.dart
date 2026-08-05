// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';
import 'patterns_local_vars_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('patterns_local_vars_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      Stack stack = await service.getStack(isolateRef.id!);
      final Set<String> vars =
          stack.frames![0].vars!.map((v) => v.name!).toSet();
      expect(vars, <String>{'obj', 'x1', 'y1'});
    }).run(
      testeeMain: testee_lib.main,
      extraArgs: extraDebuggingArgs,
    );
