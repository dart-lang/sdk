// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeleteContextTest);
  });
}

@reflectiveTest
class DeleteContextTest extends AbstractAnalysisServerIntegrationTest {
  test_delete() async {
    String pathname = sourcePath('lib/main.dart');
    writeFile(pathname, '// dummy');
    writeFile(sourcePath('.packages'), 'foo:lib/');
    standardAnalysisSetup();

    String contextId =
        (await sendExecutionCreateContext(sourceDirectory.path)).id;

    ExecutionMapUriResult result =
        await sendExecutionMapUri(contextId, uri: 'package:foo/main.dart');
    expect(result.file, pathname);

    expect(await sendExecutionDeleteContext(contextId), isNull);

    // After the delete, expect this to fail.
    try {
      result =
          await sendExecutionMapUri(contextId, uri: 'package:foo/main.dart');
      fail('expected exception after context delete');
    } on ServerErrorMessage catch (message) {
      expect(message.error['code'], 'INVALID_PARAMETER');
    }
  }

  @override
  bool get enableNewAnalysisDriver => true;
}
