// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--vm-name=Walter

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'set_vm_name_rpc_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    VMTestHarness('set_vm_name_rpc_lib.dart', args)
        .addTest((VmService service) async {
      VM vm = await service.getVM();
      expect(vm.name, 'Walter');

      final completer = Completer<void>();
      late final StreamSubscription sub;
      sub = service.onVMEvent.listen((event) async {
        if (event.kind == EventKind.kVMUpdate) {
          expect(event.vm!.name, 'Barbara');
          await sub.cancel();
          await service.streamCancel(EventStreams.kVM);
          completer.complete();
        }
      });
      await service.streamListen(EventStreams.kVM);

      await service.setVMName('Barbara');
      await completer.future;
      vm = await service.getVM();
      expect(vm.name, 'Barbara');
    }).run(
      testeeMain: testee_lib.main,
      extraArgs: [
        '--vm-name=Walter',
        '--trace-service',
        '--trace-service-verbose',
      ],
    );
