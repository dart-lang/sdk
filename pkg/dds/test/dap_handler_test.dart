// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds/src/dap/protocol_generated.dart';
import 'package:dds_service_extensions/src/dap.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/test_helper.dart';

void main() {
  late Process process;
  DartDevelopmentService? dds;

  setUp(() async {
    process = await spawnDartProcess(
      'get_cached_cpu_samples_script.dart',
      disableServiceAuthCodes: true,
    );
  });

  tearDown(() async {
    await dds?.shutdown();
    process.kill();
  });

  test('DDS responds to DAP message', () async {
    Uri serviceUri = remoteVmServiceUri;
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    serviceUri = dds!.wsUri!;
    expect(dds!.isRunning, true);
    final service = await vmServiceConnectUri(serviceUri.toString());

    final setBreakpointsRequest = Request(
      command: 'setBreakpoints',
      seq: 9,
      arguments: SetBreakpointsArguments(
        breakpoints: [
          SourceBreakpoint(line: 20),
          SourceBreakpoint(line: 30),
        ],
        source: Source(
          name: 'main.dart',
          path: '/file/to/main.dart',
        ),
      ),
    );

    // TODO(helinx): Check result format after using better typing from JSON.
    final result = await service.handleDap(jsonEncode(setBreakpointsRequest));
    expect(result.message, isNotNull);
    expect(result.message['type'], 'response');
    expect(result.message['success'], true);
    expect(result.message['command'], 'setBreakpoints');
    expect(result.message['body'], isNotNull);
  });
}
