// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as service;

import 'common/service_test_common.dart';
import 'mark_main_isolate_as_system_isolate_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('mark_main_isolate_as_system_isolate_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest((service.VmService service, _) async {
          final vm = await service.getVM();
          expect(vm.isolates!.length, 1);
          expect(vm.isolates!.first.name, 'foo');
          expect(vm.systemIsolates!.length, greaterThanOrEqualTo(1));
          expect(
            vm.systemIsolates!.where((e) => e.name == 'main').isNotEmpty,
            true,
          );
        })
        .resumeIsolate()
        .run(
            testeeMain: testee_lib.main,
            extraArgs: ['--mark-main-isolate-as-system-isolate']);
