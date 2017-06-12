// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetLibraryDependenciesTest);
  });
}

@reflectiveTest
class GetLibraryDependenciesTest extends AbstractAnalysisServerIntegrationTest {
  @failingTest
  test_libraryDeps() async {
    // This fails with the new analysis driver ('Bad state: Should not be used
    // with the new analysis driver') - #29310.
    String pathname = sourcePath('test.dart');
    String text = r'''
class Foo {}

class Bar {
  Foo foo;
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;

    AnalysisGetLibraryDependenciesResult result =
        await sendAnalysisGetLibraryDependencies();
    List<String> libraries = result.libraries;
    Map<String, Map<String, List<String>>> packageMaps = result.packageMap;

    expect(libraries, contains(pathname));
    expect(libraries.any((String lib) => lib.endsWith('core/core.dart')), true);

    expect(packageMaps.keys, hasLength(1));
    Map<String, List<String>> map = packageMaps[packageMaps.keys.first];
    expect(map.keys, isEmpty);
  }
}
