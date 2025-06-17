// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateContentTest);
  });
}

@reflectiveTest
class UpdateContentTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_updateContent_list() async {
    var pathname = sourcePath('test.dart');
    var goodText = r'''
void f() {
  print("Hello");
  print("World!");
}''';
    var badText = goodText.replaceAll('"', '');
    // Create a dummy file
    writeFile(pathname, '// dummy text');
    await standardAnalysisSetup();
    await analysisFinished;
    // Override file contents with badText.
    await sendAnalysisUpdateContent({pathname: AddContentOverlay(badText)});
    await analysisFinished;
    // The overridden contents (badText) are missing quotation marks.
    expect(currentAnalysisErrors[pathname], isNotEmpty);
    // Prepare a set of edits which add the missing quotation marks, in the
    // order in which they appear in the file.  If these edits are applied in
    // the wrong order, some of the quotation marks will be in the wrong
    // places, and there will still be errors.
    var edits =
        '"'
            .allMatches(goodText)
            .map((Match match) => SourceEdit(match.start, 0, '"'))
            .toList();
    await sendAnalysisUpdateContent({pathname: ChangeContentOverlay(edits)});
    await analysisFinished;
    // There should be no errors now, assuming that quotation marks have been
    // inserted in all the correct places.
    expect(currentAnalysisErrors[pathname], isEmpty);
  }
}
