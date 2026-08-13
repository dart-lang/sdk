// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_editable_arguments_tests.dart';
import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EditableArgumentsTest);
  });
}

@reflectiveTest
class EditableArgumentsTest extends SharedLspOverLegacyTest
    with
        // Tests are defined in SharedEditableArgumentsTests because they
        // are shared and run for both LSP and Legacy servers.
        SharedEditableArgumentsTests {
  @override
  Future<void> setUp() async {
    await super.setUp();

    writeTestPackageConfig(flutter: true);
  }

  /// Over the legacy protocol, document versions are optional so we must also
  /// support this.
  test_textDocument_unversioned() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(String a1);

  @override
  Widget build(BuildContext context) => MyW^idget('value1');
}
''', open: openFileUnversioned);

    // Verify initial content has no version.
    expect(
      result!.textDocument,
      isA<OptionalVersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', testFileUri)
          .having((td) => td.version, 'version', isNull),
    );

    // Update the content.
    await replaceFileUnversioned(testFileUri, '${code.code}\n// extra comment');

    // Verify new results have no version.
    result = await getEditableArguments(testFileUri, code.position.position);
    expect(
      result!.textDocument,
      isA<OptionalVersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', testFileUri)
          .having((td) => td.version, 'version', isNull),
    );
  }

  /// Over the legacy protocol, document versions are optional so we must also
  /// support this.
  test_textDocument_unversioned_closedFile() async {
    var result = await getEditableArgumentsFor('''
class MyWidget extends StatelessWidget {
  const MyWidget(String a1);

  @override
  Widget build(BuildContext context) => MyW^idget('value1');
}
''', open: openFileUnversioned);

    // Verify initial content has no version.
    expect(
      result!.textDocument,
      isA<OptionalVersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', testFileUri)
          .having((td) => td.version, 'version', isNull),
    );

    // Close the file.
    await closeFile(testFileUri);

    // Verify new results have no version.
    result = await getEditableArguments(testFileUri, code.position.position);
    expect(
      result!.textDocument,
      isA<OptionalVersionedTextDocumentIdentifier>()
          .having((td) => td.uri, 'uri', testFileUri)
          .having((td) => td.version, 'version', isNull),
    );
  }
}
