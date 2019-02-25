// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ServerTest);
  });
}

@reflectiveTest
class ServerTest extends AbstractLspAnalysisServerIntegrationTest {
  test_exit_afterShutdown() async {
    await sendShutdown();
    sendExit();

    await client.channel.closed.timeout(const Duration(seconds: 10),
        onTimeout: () =>
            fail('Server channel did not close within 10 seconds'));

    final exitCode = await client.exitCode.timeout(const Duration(seconds: 10),
        onTimeout: () => fail('Server process did not exit within 10 seconds'));

    expect(exitCode, equals(0));
  }

  test_exit_withoutShutdown() async {
    sendExit();

    await client.channel.closed.timeout(const Duration(seconds: 10),
        onTimeout: () =>
            fail('Server channel did not close within 10 seconds'));

    final exitCode = await client.exitCode.timeout(const Duration(seconds: 10),
        onTimeout: () => fail('Server process did not exit within 10 seconds'));

    expect(exitCode, equals(1));
  }
}
