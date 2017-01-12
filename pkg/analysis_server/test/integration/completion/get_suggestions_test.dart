// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetSuggestionsTest);
  });
}

class AbstractGetSuggestionsTest extends AbstractAnalysisServerIntegrationTest {
  String path;
  String content;
  int completionOffset;

  void setTestSource(String relPath, String content) {
    path = sourcePath(relPath);
    expect(completionOffset, isNull, reason: 'Call addTestUnit exactly once');
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    this.content = content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
  }

  test_getSuggestions() async {
    setTestSource(
        'test.dart',
        r'''
String test = '';
main() {
  test.^
}
''');
    writeFile(path, content);
    await standardAnalysisSetup();
    await analysisFinished;
    CompletionGetSuggestionsResult result =
        await sendCompletionGetSuggestions(path, completionOffset);
    String completionId = result.id;
    CompletionResultsParams param = await onCompletionResults.firstWhere(
        (CompletionResultsParams param) =>
            param.id == completionId && param.isLast);
    expect(param.replacementOffset, completionOffset);
    expect(param.replacementLength, 0);
    param.results.firstWhere(
        (CompletionSuggestion suggestion) => suggestion.completion == 'length');
  }

  test_getSuggestions_onlyOverlay() async {
    setTestSource(
        'test.dart',
        r'''
String test = '';
main() {
  test.^
}
''');
    // Create an overlay but do not write the file to "disk"
    //   writeFile(pathname, text);
    await standardAnalysisSetup();
    await sendAnalysisUpdateContent({path: new AddContentOverlay(content)});
    await analysisFinished;
    CompletionGetSuggestionsResult result =
        await sendCompletionGetSuggestions(path, completionOffset);
    String completionId = result.id;
    CompletionResultsParams param = await onCompletionResults.firstWhere(
        (CompletionResultsParams param) =>
            param.id == completionId && param.isLast);
    expect(param.replacementOffset, completionOffset);
    expect(param.replacementLength, 0);
    param.results.firstWhere(
        (CompletionSuggestion suggestion) => suggestion.completion == 'length');
  }

  test_getSuggestions_onlyOverlay_noWait() async {
    setTestSource(
        'test.dart',
        r'''
String test = '';
main() {
  test.^
}
''');
    // Create an overlay but do not write the file to "disk"
    //   writeFile(pathname, text);
    // Don't wait for any results except the completion notifications
    standardAnalysisSetup(subscribeStatus: false);
    sendAnalysisUpdateContent({path: new AddContentOverlay(content)});
    sendCompletionGetSuggestions(path, completionOffset);
    CompletionResultsParams param = await onCompletionResults
        .firstWhere((CompletionResultsParams param) => param.isLast);
    expect(param.replacementOffset, completionOffset);
    expect(param.replacementLength, 0);
    param.results.firstWhere(
        (CompletionSuggestion suggestion) => suggestion.completion == 'length');
  }

  test_getSuggestions_sourceMissing_noWait() {
    path = sourcePath('does_not_exist.dart');
    // Do not write the file to "disk"
    //   writeFile(pathname, text);
    // Don't wait for any results except the completion notifications
    standardAnalysisSetup(subscribeStatus: false);
    // Missing file and no overlay
    //sendAnalysisUpdateContent({path: new AddContentOverlay(content)});
    var errorToken = 'exception from server';
    return sendCompletionGetSuggestions(path, 0).catchError((e) {
      // Exception expected
      return errorToken;
    }).then((result) {
      expect(result, same(errorToken));
    });
  }
}

@reflectiveTest
class GetSuggestionsTest extends AbstractGetSuggestionsTest {}
