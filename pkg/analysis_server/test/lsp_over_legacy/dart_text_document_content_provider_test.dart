// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartTextDocumentContentProviderTest);
  });
}

@reflectiveTest
class DartTextDocumentContentProviderTest extends LspOverLegacyTest {
  /// Tells the server we support custom URIs, otherwise we won't be allowed to
  /// fetch any content from a URI.
  Future<void> enableCustomUriSupport() async {
    var request = createLegacyRequest(
        ServerSetClientCapabilitiesParams([], supportsUris: true));
    await handleRequest(request);
  }

  Future<void> test_valid_content() async {
    addMacros([declareInTypeMacro()]);

    var content = '''
import 'macros.dart';

@DeclareInType('void foo() {}')
class A {}
''';
    newFile(testFilePath, content);
    await waitForTasksFinished();
    await enableCustomUriSupport();

    // Fetch the content for the custom URI scheme.
    var macroGeneratedContent =
        await getDartTextDocumentContent(testFileMacroUri);

    // Verify the contents appear correct without doing an exact string
    // check that might make this text fragile.
    expect(
      macroGeneratedContent!.content,
      allOf([
        contains('augment class A'),
        contains('void foo() {'),
      ]),
    );
  }

  Future<void> test_valid_eventAndModifiedContent() async {
    addMacros([declareInTypeMacro()]);

    var content = '''
import 'macros.dart';

@DeclareInType('void foo() {}')
class A {}
''';
    newFile(testFilePath, content);
    await waitForTasksFinished();
    await enableCustomUriSupport();

    // Verify initial contents of the macro.
    var macroGeneratedContent =
        await getDartTextDocumentContent(testFileMacroUri);
    expect(macroGeneratedContent!.content, contains('void foo() {'));

    // Modify the file and expect a change event.
    newFile(testFilePath, content.replaceAll('void foo() {', 'void foo2() {'));
    await dartTextDocumentContentDidChangeNotifications
        .firstWhere((notification) => notification.uri == testFileMacroUri);

    // Verify updated contents of the macro.
    macroGeneratedContent = await getDartTextDocumentContent(testFileMacroUri);
    expect(macroGeneratedContent!.content, contains('void foo2() {'));
  }
}
