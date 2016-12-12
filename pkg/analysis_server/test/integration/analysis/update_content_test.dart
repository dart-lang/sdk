// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateContentTest);
    defineReflectiveTests(UpdateContentTest_Driver);
  });
}

class AbstractUpdateContentTest extends AbstractAnalysisServerIntegrationTest {
  test_updateContent() async {
    String path = sourcePath('test.dart');
    String goodText = r'''
main() {
  print("Hello, world!");
}''';

    String badText = goodText.replaceAll(';', '');
    writeFile(path, badText);
    standardAnalysisSetup();

    // The contents on disk (badText) are missing a semicolon.
    await analysisFinished;
    expect(currentAnalysisErrors[path], isNotEmpty);

    // There should be no errors now because the contents on disk have been
    // overridden with goodText.
    sendAnalysisUpdateContent({path: new AddContentOverlay(goodText)});
    await analysisFinished;
    expect(currentAnalysisErrors[path], isEmpty);

    // There should be errors now because we've removed the semicolon.
    sendAnalysisUpdateContent({
      path: new ChangeContentOverlay(
          [new SourceEdit(goodText.indexOf(';'), 1, '')])
    });
    await analysisFinished;
    expect(currentAnalysisErrors[path], isNotEmpty);

    // There should be no errors now because we've added the semicolon back.
    sendAnalysisUpdateContent({
      path: new ChangeContentOverlay(
          [new SourceEdit(goodText.indexOf(';'), 0, ';')])
    });
    await analysisFinished;
    expect(currentAnalysisErrors[path], isEmpty);

    // Now there should be errors again, because the contents on disk are no
    // longer overridden.
    sendAnalysisUpdateContent({path: new RemoveContentOverlay()});
    await analysisFinished;
    expect(currentAnalysisErrors[path], isNotEmpty);
  }
}

@reflectiveTest
class UpdateContentTest extends AbstractUpdateContentTest {}

@reflectiveTest
class UpdateContentTest_Driver extends AbstractUpdateContentTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
