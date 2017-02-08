// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapUriTest);
    defineReflectiveTests(MapUriTest_Driver);
  });
}

class AbstractMapUriTest extends AbstractAnalysisServerIntegrationTest {
  Future test_mapUri() async {
    String pathname = sourcePath('lib/main.dart');
    writeFile(pathname, '// dummy');
    writeFile(sourcePath('.packages'), 'foo:lib/');
    standardAnalysisSetup();

    String contextId =
        (await sendExecutionCreateContext(sourceDirectory.path))?.id;
    ExecutionMapUriResult result =
        await sendExecutionMapUri(contextId, uri: 'package:foo/main.dart');
    expect(result.file, pathname);
  }
}

@reflectiveTest
class MapUriTest extends AbstractMapUriTest {}

@reflectiveTest
class MapUriTest_Driver extends AbstractMapUriTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @failingTest
  @override
  Future test_mapUri() => super.test_mapUri();
}
