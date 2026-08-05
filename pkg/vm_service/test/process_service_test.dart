// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'process_service_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('process_service_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolate) async {
      final isolateId = isolate.id!;
      final setup = await service.callServiceExtension(
        'ext.dart.io.setup',
        isolateId: isolateId,
      );
      try {
        SpawnedProcessList all = await service.getSpawnedProcesses(isolateId);
        expect(all.processes.length, equals(3));

        final first = await service.getSpawnedProcessById(
          isolateId,
          all.processes[0].id,
        );

        expect(io.Platform.resolvedExecutable, contains(first.name.trim()));
        expect(first.pid, equals(setup.json!['pids']![0]));
        expect(first.arguments.contains('foobar'), isFalse);
        expect(first.startedAt, greaterThan(0));

        final second = await service.getSpawnedProcessById(
          isolateId,
          all.processes[1].id,
        );

        expect(io.Platform.resolvedExecutable, contains(second.name.trim()));
        expect(second.pid, equals(setup.json!['pids']![1]));
        expect(second.arguments.contains('foobar'), isTrue);
        expect(second.pid != first.pid, isTrue);
        expect(second.startedAt, greaterThan(0));
        expect(second.startedAt, greaterThanOrEqualTo(first.startedAt));

        final third = await service.getSpawnedProcessById(
          isolateId,
          all.processes[2].id,
        );

        expect(io.Platform.resolvedExecutable, contains(third.name.trim()));
        expect(third.pid, equals(setup.json!['pids']![2]));
        expect(third.pid != first.pid, isTrue);
        expect(third.pid != second.pid, isTrue);
        expect(third.startedAt, greaterThanOrEqualTo(second.startedAt));

        await service.callServiceExtension(
          'ext.dart.io.closeStdin',
          isolateId: isolateId,
        );
        all = await service.getSpawnedProcesses(isolateId);
        expect(all.processes.length, equals(2));
      } finally {
        await service.callServiceExtension(
          'ext.dart.io.cleanup',
          isolateId: isolateId,
        );
      }
    }).run(testeeMain: testee_lib.main);
