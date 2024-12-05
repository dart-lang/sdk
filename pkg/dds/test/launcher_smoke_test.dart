// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/dds_launcher.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/test_helper.dart';

void main() {
  group('DDS', () {
    late Process process;
    late DartDevelopmentServiceLauncher dds;

    setUp(() async {
      process = await spawnDartProcess('smoke.dart');
    });

    tearDown(() async {
      await dds.shutdown();
      process.kill();
    });

    void createSmokeTest(bool useAuthCodes) {
      test(
        'Launcher Smoke Test with ${useAuthCodes ? "" : "no"} authentication codes',
        () async {
          dds = await DartDevelopmentServiceLauncher.start(
            remoteVmServiceUri: remoteVmServiceUri,
            enableAuthCodes: useAuthCodes,
          );

          // Ensure basic websocket requests are forwarded correctly to the VM service.
          final service = await vmServiceConnectUri(dds.wsUri.toString());
          final version = await service.getVersion();
          expect(version.major! > 0, true);
          expect(version.minor! >= 0, true);

          expect(
            dds.uri.pathSegments,
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
              .single) as Map<String, dynamic>;
          expect(jsonResponse['result']['type'], 'Version');
          expect(jsonResponse['result']['major'] > 0, true);
          expect(jsonResponse['result']['minor'] >= 0, true);
        },
      );
    }

    createSmokeTest(true);
    createSmokeTest(false);
  });
}
