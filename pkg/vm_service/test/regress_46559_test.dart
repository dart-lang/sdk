// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'regress_46559_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'regress_46559_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .addCustomTest((VmService vm, IsolateRef isolateRef) async {
      print('waiting for response');
      final response = await vm.callServiceExtension(
        'ext.foo',
        isolateId: isolateRef.id!,
        args: {'foo': 'bar'},
      );
      print('got response');
      print(response.json);
    }).run(testeeMain: testee_lib.main);
