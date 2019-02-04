// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SignatureHelpTest);
  });
}

@reflectiveTest
class SignatureHelpTest extends AbstractLspAnalysisServerTest {
  test_formats_markdown() async {
    final content = '''
    /// Does foo.
    foo(String s, int i) {
      foo(^);
    }
    ''';
    final expectedLabel = 'foo(String s, int i)';
    final expectedDoc = 'Does foo.';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('int i', null),
      ],
      expectedFormat: MarkupKind.Markdown,
    );
  }

  test_formats_notSupported() async {
    final content = '''
    /// Does foo.
    foo(String s, int i) {
      foo(^);
    }
    ''';
    final expectedLabel = 'foo(String s, int i)';
    final expectedDoc = 'Does foo.';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('int i', null),
      ],
      expectedFormat: null,
    );
  }

  test_formats_plainTextOnly() async {
    final content = '''
    /// Does foo.
    foo(String s, int i) {
      foo(^);
    }
    ''';
    final expectedLabel = 'foo(String s, int i)';
    final expectedDoc = 'Does foo.';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.PlainText]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('int i', null),
      ],
      expectedFormat: MarkupKind.PlainText,
    );
  }

  test_formats_plainTextPreferred() async {
    final content = '''
    /// Does foo.
    foo(String s, int i) {
      foo(^);
    }
    ''';
    final expectedLabel = 'foo(String s, int i)';
    final expectedDoc = 'Does foo.';

    // We say we prefer PlainText as a client, but since we only really
    // support Markdown and the client supports it, we expect the server
    // to provide Markdown.
    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities,
            [MarkupKind.PlainText, MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('int i', null),
      ],
      expectedFormat: MarkupKind.Markdown,
    );
  }

  test_params_multipleNamed() async {
    final content = '''
    /// Does foo.
    foo(String s, {bool b = true, bool a}) {
      foo(^);
    }
    ''';

    final expectedLabel = 'foo(String s, {bool b = true, bool a})';
    final expectedDoc = 'Does foo.';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('bool b = true', null),
        new ParameterInformation('bool a', null),
      ],
    );
  }

  test_params_multipleOptional() async {
    final content = '''
    /// Does foo.
    foo(String s, [bool b = true, bool a]) {
      foo(^);
    }
    ''';

    final expectedLabel = 'foo(String s, [bool b = true, bool a])';
    final expectedDoc = 'Does foo.';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('bool b = true', null),
        new ParameterInformation('bool a', null),
      ],
    );
  }

  test_params_named() async {
    final content = '''
    /// Does foo.
    foo(String s, {bool b = true}) {
      foo(^);
    }
    ''';

    final expectedLabel = 'foo(String s, {bool b = true})';
    final expectedDoc = 'Does foo.';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('bool b = true', null),
      ],
    );
  }

  test_params_optional() async {
    final content = '''
    /// Does foo.
    foo(String s, [bool b = true]) {
      foo(^);
    }
    ''';

    final expectedLabel = 'foo(String s, [bool b = true])';
    final expectedDoc = 'Does foo.';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('bool b = true', null),
      ],
    );
  }

  test_simple() async {
    final content = '''
    /// Does foo.
    foo(String s, int i) {
      foo(^);
    }
    ''';
    final expectedLabel = 'foo(String s, int i)';
    final expectedDoc = 'Does foo.';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('int i', null),
      ],
    );
  }

  test_unopenFile() async {
    final content = '''
    /// Does foo.
    foo(String s, int i) {
      foo(^);
    }
    ''';
    final expectedLabel = 'foo(String s, int i)';
    final expectedDoc = 'Does foo.';

    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('int i', null),
      ],
    );
  }

  Future<void> testSignature(
    String fileContent,
    String expectedLabel,
    String expectedDoc,
    List<ParameterInformation> expectedParams, {
    MarkupKind expectedFormat = MarkupKind.Markdown,
  }) async {
    final res =
        await getSignatureHelp(mainFileUri, positionFromMarker(fileContent));

    // TODO(dantup): Update this when there is clarification on how to handle
    // no valid selected parameter.
    expect(res.activeParameter, -1);
    expect(res.activeSignature, equals(0));
    expect(res.signatures, hasLength(1));
    final sig = res.signatures.first;
    expect(sig.label, equals(expectedLabel));
    expect(sig.parameters, equals(expectedParams));

    // Test the format matches the tests expectation.
    // For clients that don't support MarkupContent it'll be a plain string,
    // but otherwise it'll be a MarkupContent of type PlainText or Markdown.
    final doc = sig.documentation;
    if (expectedFormat == null) {
      // Plain string.
      expect(doc.valueEquals(expectedDoc), isTrue);
    } else {
      final expected = new MarkupContent(expectedFormat, expectedDoc);
      expect(doc.valueEquals(expected), isTrue);
    }
  }
}
