// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetSuggestions2Test);
  });
}

@reflectiveTest
class GetSuggestions2Test extends AbstractAnalysisServerIntegrationTest {
  bool initialized = false;
  late String path;
  late String content;
  late int completionOffset;

  void setTestSource(String relPath, String content) {
    if (initialized) {
      fail('Call addTestUnit exactly once');
    }

    path = sourcePath(relPath);

    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');

    var nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');

    this.content =
        content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
  }

  Future<void> test_getSuggestions() async {
    setTestSource('test.dart', r'''
String test = '';
void f() {
  test.^
}
''');
    writeFile(path, content);
    await standardAnalysisSetup();
    await analysisFinished;
    var result = await sendCompletionGetSuggestions2(
      path,
      completionOffset,
      100,
    );
    expect(result.replacementOffset, completionOffset);
    expect(result.replacementLength, 0);
    result.suggestions.firstWhere(
      (CompletionSuggestion suggestion) => suggestion.completion == 'length',
    );
  }

  Future<void> test_getSuggestions_onlyOverlay() async {
    setTestSource('test.dart', r'''
String test = '';
void f() {
  test.^
}
''');
    // Create an overlay but do not write the file to "disk"
    //   writeFile(pathname, text);
    await standardAnalysisSetup();
    await sendAnalysisUpdateContent({path: AddContentOverlay(content)});
    await analysisFinished;
    var result = await sendCompletionGetSuggestions2(
      path,
      completionOffset,
      100,
    );
    expect(result.replacementOffset, completionOffset);
    expect(result.replacementLength, 0);
    result.suggestions.firstWhere(
      (CompletionSuggestion suggestion) => suggestion.completion == 'length',
    );
  }

  Future<void> test_getSuggestions_onlyOverlay_noWait() async {
    setTestSource('test.dart', r'''
String test = '';
void f() {
  test.^
}
''');
    await standardAnalysisSetup();
    await analysisFinished;
    // Create an overlay but do not write the file to "disk"
    //   writeFile(pathname, text);
    // Don't wait for any results except the completion notifications
    await sendAnalysisUpdateContent({path: AddContentOverlay(content)});
    var result = await sendCompletionGetSuggestions2(
      path,
      completionOffset,
      100,
    );
    expect(result.replacementOffset, completionOffset);
    expect(result.replacementLength, 0);
    result.suggestions.firstWhere(
      (CompletionSuggestion suggestion) => suggestion.completion == 'length',
    );
  }

  Future<void> test_getSuggestions_sourceMissing_noWait() async {
    path = sourcePath('does_not_exist.dart');
    // Do not write the file to "disk"
    //   writeFile(pathname, text);
    // Don't wait for any results except the completion notifications
    await standardAnalysisSetup();
    await analysisFinished;
    // Missing file and no overlay
    //sendAnalysisUpdateContent({path: new AddContentOverlay(content)});
    var result = await sendCompletionGetSuggestions2(path, 0, 100);
    expect(result, const TypeMatcher<CompletionGetSuggestions2Result>());
  }
}
