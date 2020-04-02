// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapUriTest);
  });
}

@reflectiveTest
class MapUriTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_mapUri() async {
    var pathname = sourcePath('lib/main.dart');
    writeFile(pathname, '// dummy');
    writeFile(sourcePath('.packages'), 'foo:lib/');
    standardAnalysisSetup();

    var contextId =
        (await sendExecutionCreateContext(sourceDirectory.path))?.id;

    {
      var result =
          await sendExecutionMapUri(contextId, uri: 'package:foo/main.dart');
      expect(result.file, pathname);
    }

    {
      var result = await sendExecutionMapUri(contextId, file: pathname);
      expect(result.uri, 'package:foo/main.dart');
    }
  }
}
