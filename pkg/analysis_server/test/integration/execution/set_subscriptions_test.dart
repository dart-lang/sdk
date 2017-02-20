// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetSubscriptionsTest);
  });
}

@reflectiveTest
class SetSubscriptionsTest extends AbstractAnalysisServerIntegrationTest {
  // Bad state: Should not be used with the new analysis driver (#28806)
  @failingTest
  test_subscribe() async {
    writeFile(sourcePath('.packages'), 'foo:lib/');
    standardAnalysisSetup();
    await sendExecutionSetSubscriptions([ExecutionService.LAUNCH_DATA]);

    String contextId =
        (await sendExecutionCreateContext(sourceDirectory.path)).id;
    expect(contextId, isNotNull);

    String pathname = sourcePath('lib/main.dart');
    writeFile(pathname, 'void main() {}');

    ExecutionLaunchDataParams data = await onExecutionLaunchData.first;
    expect(data.kind, ExecutableKind.SERVER);
    expect(data.file, pathname);
  }

  @override
  bool get enableNewAnalysisDriver => true;
}
