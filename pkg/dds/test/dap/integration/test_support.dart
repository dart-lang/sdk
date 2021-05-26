// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_server.dart';

late DapTestClient dapClient;
late DapTestServer dapServer;

final _testFolders = <Directory>[];

/// Creates a file in a temporary folder to be used as an application for testing.
File createTestFile(String content) {
  final testAppDir = Directory.systemTemp.createTempSync('dart-sdk-dap-test');
  _testFolders.add(testAppDir);
  final testFile = File(path.join(testAppDir.path, 'test_file.dart'));
  testFile.writeAsStringSync(content);
  return testFile;
}

/// Expects [actual] to equal the lines [expected], ignoring differences in line
/// endings.
void expectLines(String actual, List<String> expected) {
  expect(actual.replaceAll('\r\n', '\n'), equals(expected.join('\n')));
}

/// Starts a DAP server and a DAP client that connects to it for use in tests.
FutureOr<void> startServerAndClient() async {
  // TODO(dantup): An Out-of-process option.
  dapServer = await InProcessDapTestServer.create();
  dapClient = await DapTestClient.connect(dapServer.port);
}

/// Shuts down the DAP server and client created by [startServerAndClient].
FutureOr<void> stopServerAndClient() async {
  await dapClient.stop();
  await dapServer.stop();

  // Clean up any temp folders created during the test run.
  _testFolders.forEach((dir) => dir.deleteSync(recursive: true));
}
