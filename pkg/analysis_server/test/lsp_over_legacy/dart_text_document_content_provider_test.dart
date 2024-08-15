// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
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

  @override
  Future<void> setUp() async {
    useEmptyByteStore();
    await super.setUp();
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

    var collector = EventsCollector(this);

    // Verify initial contents of the macro.
    var macroGeneratedContent =
        await getDartTextDocumentContent(testFileMacroUri);
    expect(macroGeneratedContent!.content, contains('void foo() {'));

    // Modify the file, changing its API signature.
    // So, the macro runs, and the macro generated file changes.
    newFile(
      testFilePath,
      content.replaceAll(
        'void foo() {}',
        'void foo2() {}',
      ),
    );

    // Note, 'dart/textDocumentContentDidChange' before 'AnalysisErrors'.
    // So, the IDE does not discard errors.
    await assertEventsText(collector, r'''
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: empty
dart/textDocumentContentDidChange
  uri: dart-macro+file:///home/test/lib/test.dart
AnalysisErrors
  file: /home/test/lib/test.macro.dart
  errors: empty
''');

    // Verify updated contents of the macro.
    macroGeneratedContent = await getDartTextDocumentContent(testFileMacroUri);
    expect(macroGeneratedContent!.content, contains('void foo2() {'));
  }
}
