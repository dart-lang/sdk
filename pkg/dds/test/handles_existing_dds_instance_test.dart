// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

void main() async {
  late Process process;
  late DartDevelopmentService dds;

  setUp(() async {
    process = await spawnDartProcess(
      'handles_existing_dds_instance_script.dart',
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  test('Handle the VM already having an existing DDS instance', () async {
    // Connect a first DDS instance to the VM Service.
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );

    // Trying to connect a second DDS instance should fail, and provide the
    // URI of the first.
    try {
      await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
      );
      fail('Unexpected successful connection.');
    } on ExistingDartDevelopmentServiceException catch (e) {
      expect(
        e.errorCode,
        DartDevelopmentServiceException.existingDdsInstanceError,
      );
      expect(e.ddsUri, isNotNull);
      // Expect the base VM Service URL, not the WS version.
      expect(e.ddsUri!.scheme, anyOf('http', 'https'));
      expect(e.ddsUri!.path, isNot(endsWith('/ws')));
      // And expect it to match the original instance we spawned.
      expect(e.ddsUri, dds.uri);
      expect(e.toString(), contains('A DDS instance is already connected'));
    }
  });
}
