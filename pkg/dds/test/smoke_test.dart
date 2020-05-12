// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

Uri remoteVmServiceUri;

Future<Process> spawnDartProcess(String script) async {
  final executable = Platform.executable;
  final tmpDir = await Directory.systemTemp.createTemp('dart_service');
  final serviceInfoUri = tmpDir.uri.resolve('service_info.json');
  final serviceInfoFile = await File.fromUri(serviceInfoUri).create();

  final arguments = [
    '--disable-dart-dev',
    '--observe=0',
    '--pause-isolates-on-start',
    '--write-service-info=$serviceInfoUri',
    ...Platform.executableArguments,
    Platform.script.resolve(script).toString(),
  ];
  final process = await Process.start(executable, arguments);
  process.stdout
      .transform(utf8.decoder)
      .listen((line) => print('TESTEE OUT: $line'));
  process.stderr
      .transform(utf8.decoder)
      .listen((line) => print('TESTEE ERR: $line'));
  while ((await serviceInfoFile.length()) <= 5) {
    await Future.delayed(const Duration(milliseconds: 50));
  }
  final content = await serviceInfoFile.readAsString();
  final infoJson = json.decode(content);
  remoteVmServiceUri = Uri.parse(infoJson['uri']);
  return process;
}

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

    test('Smoke Test', () async {
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
      );
      expect(dds.isRunning, true);

      // Ensure basic websocket requests are forwarded correctly to the VM service.
      final service = await vmServiceConnectUri(dds.wsUri.toString());
      final version = await service.getVersion();
      expect(version.major > 0, true);
      expect(version.minor > 0, true);

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
