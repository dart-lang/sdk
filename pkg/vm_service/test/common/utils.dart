// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

// TODO(bkonyi): Share this logic with _ServiceTesteeRunner.launch.
Future<(Process, Uri)> spawnDartProcess(
  String script, {
  bool serveObservatory = true,
  bool pauseOnStart = true,
  bool disableServiceAuthCodes = false,
  bool subscribeToStdio = true,
}) async {
  final executable = Platform.executable;
  final tmpDir = await Directory.systemTemp.createTemp('dart_service');
  final serviceInfoUri = tmpDir.uri.resolve('service_info.json');
  final serviceInfoFile = await File.fromUri(serviceInfoUri).create();

  final arguments = [
    '--disable-dart-dev',
    '--observe=0',
    if (!serveObservatory) '--no-serve-observatory',
    if (pauseOnStart) '--pause-isolates-on-start',
    if (disableServiceAuthCodes) '--disable-service-auth-codes',
    '--write-service-info=$serviceInfoUri',
    ...Platform.executableArguments,
    Platform.script.resolve(script).toString(),
  ];
  final process = await Process.start(executable, arguments);
  if (subscribeToStdio) {
    process.stdout
        .transform(utf8.decoder)
        .listen((line) => print('TESTEE OUT: $line'));
    process.stderr
        .transform(utf8.decoder)
        .listen((line) => print('TESTEE ERR: $line'));
  }
  while ((await serviceInfoFile.length()) <= 5) {
    await Future.delayed(const Duration(milliseconds: 50));
  }
  final content = await serviceInfoFile.readAsString();
  final infoJson = json.decode(content);
  return (process, Uri.parse(infoJson['uri']));
}
