// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:test_runner/src/browser_controller.dart';
import 'package:test_runner/src/configuration.dart';

void main() async {
  var configuration = TestConfiguration(
    configuration: Configuration.parse(
        const String.fromEnvironment("test_runner.configuration"),
        {'runtime': 'vm'}),
    isVerbose: false,
    localIP: '127.0.0.1',
    testDriverErrorPort: 0,
    testServerPort: 0,
    testServerCrossOriginPort: 0,
  );
  await configuration.startServers();
  try {
    var testRunner =
        BrowserTestRunner(configuration, '127.0.0.1', 1, (_) => FakeBrowser());
    await testRunner.start();
    try {
      Expect.isTrue(testRunner.testingServerStarted);
      Expect.equals(1, testRunner.numBrowsers);
    } finally {
      await testRunner.terminate();
    }
  } finally {
    configuration.stopServers();
  }
}

class FakeBrowser extends Browser {
  Future<bool> start(String url) => Future.value(true);
  Future<bool> close() => Future.value(true);
  Future<String> version = Future.value('fake version');
}
