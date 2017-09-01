// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:expect/expect.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/util.dart';

import 'test_client.dart';

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addFlag('force', abbr: 'f');
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);

  TestClient client = new TestClient(force: argResults['force']);
  BuildUri buildUri =
      new BuildUri.fromUrl('https://build.chromium.org/p/client.dart/builders/'
          'vm-kernel-linux-debug-x64-be/builds/1884/steps/'
          'vm%20tests/logs/stdio');
  BuildResult result = await client.readResult(buildUri);

  void checkTest(String testName, String expectedStatus) {
    TestStatus status;
    for (TestStatus s in result.results) {
      if (s.config.testName == testName) {
        status = s;
        break;
      }
    }
    Expect.isNotNull(status, "TestStatus for '$testName' not found.");
    Expect.equals(
        expectedStatus, status.status, "Unexpected status for '$testName'.");
  }

  checkTest('corelib_2/map_keys2_test', 'fail');
  client.close();
}
