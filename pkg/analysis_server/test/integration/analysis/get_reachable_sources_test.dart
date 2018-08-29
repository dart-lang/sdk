// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetReachableSourcesTest);
  });
}

@reflectiveTest
class GetReachableSourcesTest extends AbstractAnalysisServerIntegrationTest {
  @failingTest
  test_reachable() async {
    // This fails with the new analysis driver ('Bad state: Should not be used
    // with the new analysis driver') - #29311.
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

    AnalysisGetReachableSourcesResult result =
        await sendAnalysisGetReachableSources(pathname);
    Map<String, List<String>> sources = result.sources;
    List<String> keys = sources.keys.toList();
    String url = new File(pathname).uri.toString();

    expect(keys, contains('dart:core'));
    expect(keys, contains('dart:collection'));
    expect(keys, contains('dart:math'));
    expect(keys, contains(url));
    expect(sources[url], contains('dart:core'));
  }
}
