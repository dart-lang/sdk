// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.update.content.list;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
  test_updateContent_list() {
    String pathname = sourcePath('test.dart');
    String goodText = r'''
main() {
  print("Hello");
  print("World!");
}''';
    String badText = goodText.replaceAll('"', '');
    // Create a dummy file
    writeFile(pathname, '// dummy text');
    standardAnalysisSetup();
    // Override file contents with badText.
    sendAnalysisUpdateContent({
      pathname: new AddContentOverlay(badText)
    });
    return analysisFinished.then((_) {
      // The overridden contents (badText) are missing quotation marks.
      expect(currentAnalysisErrors[pathname], isNot(isEmpty));
    }).then((_) {
      // Prepare a set of edits which add the missing quotation marks, in the
      // order in which they appear in the file.  If these edits are applied in
      // the wrong order, some of the quotation marks will be in the wrong
      // places, and there will still be errors.
      List<SourceEdit> edits = '"'.allMatches(
          goodText).map((Match match) => new SourceEdit(match.start, 0, '"')).toList();
      sendAnalysisUpdateContent({
        pathname: new ChangeContentOverlay(edits)
      });
      return analysisFinished;
    }).then((_) {
      // There should be no errors now, assuming that quotation marks have been
      // inserted in all the correct places.
      expect(currentAnalysisErrors[pathname], isEmpty);
    });
  }
}

main() {
  runReflectiveTests(Test);
}
