// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetKytheEntriesTest);
  });
}

@reflectiveTest
class GetKytheEntriesTest extends AbstractAnalysisServerIntegrationTest {
  test_getKytheEntries() async {
    writeFile(sourcePath('WORKSPACE'), '');
    String pathname = sourcePath('pkg/test.dart');
    String text = r'''
class Foo {}

class Bar {
  Foo foo;
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    await analysisFinished;

    KytheGetKytheEntriesResult result =
        await sendKytheGetKytheEntries(pathname);
    expect(result.entries, isNotEmpty);
    expect(result.files, isEmpty);
  }
}
