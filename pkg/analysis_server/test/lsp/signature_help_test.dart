// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SignatureHelpTest);
  });
}

mixin SignatureHelpMixin on AbstractLspAnalysisServerTest {
  Future<void> expectNoSignature(String fileContent) async {
    final res =
        await getSignatureHelp(mainFileUri, positionFromMarker(fileContent));
    expect(res, isNull);
  }

  Future<void> testSignature(
    String fileContent,
    String expectedLabel,
    String expectedDoc,
    List<ParameterInformation> expectedParams, {
    MarkupKind? expectedFormat = MarkupKind.Markdown,
    SignatureHelpContext? context,
  }) async {
    final res = (await getSignatureHelp(
        mainFileUri, positionFromMarker(fileContent), context))!;

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
    final doc = sig.documentation!;
    if (expectedFormat == null) {
      // Plain string.
      expect(doc.valueEquals(expectedDoc), isTrue);
    } else {
      final expected = MarkupContent(kind: expectedFormat, value: expectedDoc);
      expect(doc.valueEquals(expected), isTrue);
    }
  }
}

@reflectiveTest
class SignatureHelpTest extends AbstractLspAnalysisServerTest
    with SignatureHelpMixin {
  Future<void> assertArgsDocumentation(
    String? preference, {
    required bool includesSummary,
    required bool includesFull,
  }) {
    final content = '''
    class A {
      /// Summary.
      ///
      /// Full.
      A();
    }

    final a = A(^);
    ''';

    return assertDocumentation(
      preference,
      content,
      includesSummary: includesSummary,
      includesFull: includesFull,
    );
  }

  /// Checks whether the correct types of documentation are returned in
  /// signature help for function arguments based on [preference].
  Future<void> assertDocumentation(
    String? preference,
    String content, {
    required bool includesSummary,
    required bool includesFull,
  }) async {
    final initialAnalysis = waitForAnalysisComplete();
    await provideConfig(
      () => initialize(
        workspaceCapabilities:
            withConfigurationSupport(emptyWorkspaceClientCapabilities),
      ),
      {
        if (preference != null) 'documentation': preference,
      },
    );
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final signatureHelp =
        await getSignatureHelp(mainFileUri, positionFromMarker(content));
    final docs = signatureHelp!.signatures.single.documentation?.map(
      (markup) => markup.value,
      (string) => string,
    );

    if (includesSummary) {
      expect(docs, contains('Summary.'));
    } else {
      expect(docs, isNot(contains('Summary.')));
    }

    if (includesFull) {
      expect(docs, contains('Full.'));
    } else {
      expect(docs, isNot(contains('Full.')));
    }
  }

  Future<void> test_dartDocMacro() async {
    final content = '''
    /// {@template template_name}
    /// This is shared content.
    /// {@endtemplate}
    const String bar = null;

    /// {@macro template_name}
    foo(String s, int i) {
      foo(^);
    }
    ''';
    final expectedLabel = 'foo(String s, int i)';
    final expectedDoc = 'This is shared content.';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'int i'),
      ],
      expectedFormat: null,
    );
  }

  Future<void> test_dartDocPreference_full() => assertArgsDocumentation('full',
      includesSummary: true, includesFull: true);

  Future<void> test_dartDocPreference_none() => assertArgsDocumentation('none',
      includesSummary: false, includesFull: false);

  Future<void> test_dartDocPreference_summary() =>
      assertArgsDocumentation('summary',
          includesSummary: true, includesFull: false);

  /// No preference should result in full docs.
  Future<void> test_dartDocPreference_unset() =>
      assertArgsDocumentation(null, includesSummary: true, includesFull: true);

  Future<void> test_error_methodInvocation_importPrefix() async {
    final content = '''
import 'dart:async' as prefix;

void f() {
  prefix(^);
}
''';

    await initialize(
      textDocumentCapabilities: withSignatureHelpContentFormat(
        emptyTextDocumentClientCapabilities,
        [MarkupKind.Markdown],
      ),
    );
    await openFile(mainFileUri, withoutMarkers(content));

    // Expect no result.
    final res = await getSignatureHelp(
      mainFileUri,
      positionFromMarker(content),
    );
    expect(res, isNull);
  }

  Future<void> test_formats_markdown() async {
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
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'int i'),
      ],
      expectedFormat: MarkupKind.Markdown,
    );
  }

  Future<void> test_formats_notSupported() async {
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
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'int i'),
      ],
      expectedFormat: null,
    );
  }

  Future<void> test_formats_plainTextOnly() async {
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
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'int i'),
      ],
      expectedFormat: MarkupKind.PlainText,
    );
  }

  Future<void> test_formats_plainTextPreferred() async {
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
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'int i'),
      ],
      expectedFormat: MarkupKind.Markdown,
    );
  }

  Future<void> test_manualTrigger_invalidLocation() async {
    // If the user invokes signature help, we should show it even if it's a
    // location where we wouldn't automatically trigger (for example in a string).
    final content = '''
    /// Does foo.
    foo(String s, int i) {
      foo('this is a (^test');
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
          ParameterInformation(label: 'String s'),
          ParameterInformation(label: 'int i'),
        ],
        expectedFormat: MarkupKind.Markdown,
        context: SignatureHelpContext(
          triggerKind: SignatureHelpTriggerKind.Invoked,
          isRetrigger: false,
        ));
  }

  Future<void> test_noDefaultConstructor() async {
    final content = '''
    class A {
      A._();
    }

    final a = A(^);
    ''';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await expectNoSignature(content);
  }

  Future<void> test_nonDartFile() async {
    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.PlainText]));
    await openFile(pubspecFileUri, simplePubspecContent);
    final res = await getSignatureHelp(pubspecFileUri, startOfDocPos);
    expect(res, isNull);
  }

  Future<void> test_params_multipleNamed() async {
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
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'bool b = true'),
        ParameterInformation(label: 'bool a'),
      ],
    );
  }

  Future<void> test_params_multipleNamed_retrigger() async {
    final content = '''
    /// Does foo.
    foo(String s, {bool b = true, bool a}) {
      foo('s',^);
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
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'bool b = true'),
        ParameterInformation(label: 'bool a'),
      ],
    );
  }

  Future<void> test_params_multipleOptional() async {
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
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'bool b = true'),
        ParameterInformation(label: 'bool a'),
      ],
    );
  }

  Future<void> test_params_named() async {
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
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'bool b = true'),
      ],
    );
  }

  Future<void> test_params_optional() async {
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
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'bool b = true'),
      ],
    );
  }

  Future<void> test_params_recordType() async {
    final content = '''
/// Does something.
void f((String, int) r) {
  f(^);
}
''';

    final expectedLabel = 'f((String, int) r)';
    final expectedDoc = 'Does something.';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        ParameterInformation(label: '(String, int) r'),
      ],
    );
  }

  Future<void> test_params_requiredNamed() async {
    // This test requires support for the "required" keyword.
    final content = '''
    /// Does foo.
    foo(String s, {bool? b = true, required bool a}) {
      foo(^);
    }
    ''';

    final expectedLabel = 'foo(String s, {bool? b = true, required bool a})';
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
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'bool? b = true'),
        ParameterInformation(label: 'required bool a'),
      ],
    );
  }

  Future<void> test_simple() async {
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
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'int i'),
      ],
    );
  }

  Future<void> test_triggerCharacter_invalidLocation() async {
    // The client will automatically trigger when the user types ( so we need to
    // ignore it when we're not in a suitable location.
    final content = '''
    /// Does foo.
    foo(String s, int i) {
      foo('this is a (^test');
    }
    ''';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));

    // Expect no result.
    final res = await getSignatureHelp(
      mainFileUri,
      positionFromMarker(content),
      SignatureHelpContext(
        triggerKind: SignatureHelpTriggerKind.TriggerCharacter,
        isRetrigger: false,
      ),
    );
    expect(res, isNull);
  }

  Future<void> test_triggerCharacter_validLocation() async {
    final content = '''
    /// Does foo.
    foo(String s, int i) {
      foo(^
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
          ParameterInformation(label: 'String s'),
          ParameterInformation(label: 'int i'),
        ],
        expectedFormat: MarkupKind.Markdown,
        context: SignatureHelpContext(
          triggerKind: SignatureHelpTriggerKind.Invoked,
          isRetrigger: false,
        ));
  }

  Future<void> test_typeArgs_dartDocPreference_full() =>
      assertArgsDocumentation('full',
          includesSummary: true, includesFull: true);

  Future<void> test_typeArgs_dartDocPreference_none() =>
      assertArgsDocumentation('none',
          includesSummary: false, includesFull: false);

  Future<void> test_typeArgs_dartDocPreference_summary() =>
      assertArgsDocumentation('summary',
          includesSummary: true, includesFull: false);

  /// No preference should result in full docs.
  Future<void> test_typeArgs_dartDocPreference_unset() =>
      assertArgsDocumentation(null, includesSummary: true, includesFull: true);

  Future<void> test_typeParams_class() async {
    final content = '''
    /// My Foo.
    class Foo<T1, T2 extends String> {}

    class Bar extends Foo<^> {}
    ''';

    const expectedLabel = 'class Foo<T1, T2 extends String>';
    const expectedDoc = 'My Foo.';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        ParameterInformation(label: 'T1'),
        ParameterInformation(label: 'T2 extends String'),
      ],
    );
  }

  Future<void> test_typeParams_function() async {
    final content = '''
    /// My Foo.
    void foo<T1, T2 extends String>() {
      foo<^>();
    }
    ''';

    const expectedLabel = 'void foo<T1, T2 extends String>()';
    const expectedDoc = 'My Foo.';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        ParameterInformation(label: 'T1'),
        ParameterInformation(label: 'T2 extends String'),
      ],
    );
  }

  Future<void> test_typeParams_method() async {
    final content = '''
    class Foo {
      /// My Foo.
      void foo<T1, T2 extends String>() {
        foo<^>();
      }
    }
    ''';

    const expectedLabel = 'void foo<T1, T2 extends String>()';
    const expectedDoc = 'My Foo.';

    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        ParameterInformation(label: 'T1'),
        ParameterInformation(label: 'T2 extends String'),
      ],
    );
  }

  Future<void> test_unopenFile() async {
    final content = '''
    /// Does foo.
    foo(String s, int i) {
      foo(^);
    }
    ''';
    final expectedLabel = 'foo(String s, int i)';
    final expectedDoc = 'Does foo.';

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
        textDocumentCapabilities: withSignatureHelpContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        ParameterInformation(label: 'String s'),
        ParameterInformation(label: 'int i'),
      ],
    );
  }
}
