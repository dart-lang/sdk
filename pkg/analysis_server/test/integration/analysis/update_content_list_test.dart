// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateContentTest);
  });
}

@reflectiveTest
class UpdateContentTest extends AbstractAnalysisServerIntegrationTest {
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
    sendAnalysisUpdateContent({pathname: new AddContentOverlay(badText)});
    return analysisFinished.then((_) {
      // The overridden contents (badText) are missing quotation marks.
      expect(currentAnalysisErrors[pathname], isNotEmpty);
    }).then((_) {
      // Prepare a set of edits which add the missing quotation marks, in the
      // order in which they appear in the file.  If these edits are applied in
      // the wrong order, some of the quotation marks will be in the wrong
      // places, and there will still be errors.
      List<SourceEdit> edits = '"'
          .allMatches(goodText)
          .map((Match match) => new SourceEdit(match.start, 0, '"'))
          .toList();
      sendAnalysisUpdateContent({pathname: new ChangeContentOverlay(edits)});
      return analysisFinished;
    }).then((_) {
      // There should be no errors now, assuming that quotation marks have been
      // inserted in all the correct places.
      expect(currentAnalysisErrors[pathname], isEmpty);
    });
  }
}
