// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/test_helper.dart';

void main() {
  group('DDS', () {
    Process process;
    DartDevelopmentService dds;

    setUp(() async {
      process = await spawnDartProcess('smoke.dart');
    });

    tearDown(() async {
      await dds?.shutdown();
      process?.kill();
      dds = null;
      process = null;
    });

    bool useAuthCodes = false;
    for (int i = 0; i < 2; ++i) {
      test('Smoke Test with ${useAuthCodes ? "" : "no "} authentication codes',
          () async {
        dds = await DartDevelopmentService.startDartDevelopmentService(
          remoteVmServiceUri,
          enableAuthCodes: useAuthCodes,
        );
        expect(dds.isRunning, true);

        // Ensure basic websocket requests are forwarded correctly to the VM service.
        final service = await vmServiceConnectUri(dds.wsUri.toString());
        final version = await service.getVersion();
        expect(version.major > 0, true);
        expect(version.minor > 0, true);

        expect(
          remoteVmServiceUri.pathSegments,
          useAuthCodes ? isNotEmpty : isEmpty,
        );

        // Ensure we can still make requests of the VM service via HTTP.
        HttpClient client = HttpClient();
        final request = await client.getUrl(remoteVmServiceUri.replace(
          pathSegments: [
            if (remoteVmServiceUri.pathSegments.isNotEmpty)
              remoteVmServiceUri.pathSegments.first,
            'getVersion',
          ],
        ));
        final response = await request.close();
        final Map<String, dynamic> jsonResponse = (await response
            .transform(utf8.decoder)
            .transform(json.decoder)
            .single);
        expect(jsonResponse['result']['type'], 'Version');
        expect(jsonResponse['result']['major'] > 0, true);
        expect(jsonResponse['result']['minor'] > 0, true);
      });

      useAuthCodes = true;
    }

    test('startup fails when VM service has existing clients', () async {
      Uri httpToWebSocketUri(Uri httpUri) {
        final segments = (httpUri.pathSegments.isNotEmpty)
            ? (httpUri.pathSegments.toList()..removeLast())
            : <String>[];
        segments.add('ws');
        return httpUri.replace(
          scheme: 'ws',
          pathSegments: segments,
        );
      }

      final _ = await vmServiceConnectUri(
        httpToWebSocketUri(remoteVmServiceUri).toString(),
      );
      try {
        dds = await DartDevelopmentService.startDartDevelopmentService(
          remoteVmServiceUri,
        );
        fail(
            'DDS startup should fail if there are existing VM service clients.');
      } on DartDevelopmentServiceException catch (e) {
        expect(e.message,
            'Existing VM service clients prevent DDS from taking control.');
      }
    });
  });

  test('Invalid args test', () async {
    // null VM Service URI
    expect(
        () async =>
            await DartDevelopmentService.startDartDevelopmentService(null),
        throwsA(TypeMatcher<ArgumentError>()));

    // Non-HTTP VM Service URI scheme
    expect(
        () async => await DartDevelopmentService.startDartDevelopmentService(
              Uri.parse('dart-lang://localhost:1234'),
            ),
        throwsA(TypeMatcher<ArgumentError>()));

    // Non-HTTP VM Service URI scheme
    expect(
        () async => await DartDevelopmentService.startDartDevelopmentService(
              Uri.parse('http://localhost:1234'),
              serviceUri: Uri.parse('dart-lang://localhost:2345'),
            ),
        throwsA(TypeMatcher<ArgumentError>()));
  });
}
