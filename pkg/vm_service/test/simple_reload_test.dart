// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'simple_reload_lib.dart' as testee_lib;

// Chop off the file name.
final baseDirectory = '${path.dirname(Platform.script.path)}/';

final baseUri = Platform.script.replace(path: baseDirectory);
final v2Uri = baseUri.resolveUri(
  Uri.parse('simple_reload/v2/main.dart'),
);

Future<String> invokeTest(VmService service, IsolateRef isolateRef) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  final result = await service.evaluate(
    isolateId,
    isolate.rootLib!.id!,
    'test()',
  ) as InstanceRef;
  expect(result.kind, InstanceKind.kString);
  return result.valueAsString!;
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('simple_reload_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      // Grab the VM.
      final vm = await service.getVM();
      final isolates = vm.isolates!;
      expect(isolates.length, 2);

      // Find the spawned isolate.
      final spawnedIsolate = isolates.firstWhere(
        (i) => i != isolateRef,
      );
      expect(spawnedIsolate, isNotNull);

      // Invoke test in v1.
      final v1 = await invokeTest(service, spawnedIsolate);
      expect(v1, 'apple');

      // Reload to v2.
      await service.reloadSources(
        spawnedIsolate.id!,
        rootLibUri: v2Uri.toString(),
      );

      final v2 = await invokeTest(service, spawnedIsolate);
      expect(v2, 'orange');
    }).run(testeeMain: testee_lib.main);
