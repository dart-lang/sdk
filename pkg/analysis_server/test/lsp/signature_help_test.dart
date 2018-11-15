// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionTest);
  });
}

@reflectiveTest
class CompletionTest extends AbstractLspAnalysisServerTest {
  test_signature_help_named() async {
    final content = '''
    /// Does foo.
    foo(String s, int i, {bool b = true}) {
      foo(^);
    }
    ''';

    final expectedLabel = 'foo(String s, {bool b = true})';
    final expectedDoc = 'Does foo.';

    testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('bool b = true', null),
      ],
    );
  }

  test_signature_help_named_multiple() async {
    final content = '''
    /// Does foo.
    foo(String s, int i, {bool b = true, bool a}) {
      foo(^);
    }
    ''';

    final expectedLabel = 'foo(String s, {bool b = true, bool a})';
    final expectedDoc = 'Does foo.';

    testSignature(
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

  test_signature_help_optional() async {
    final content = '''
    /// Does foo.
    foo(String s, [bool b = true]) {
      foo(^);
    }
    ''';

    final expectedLabel = 'foo(String s, [bool b = true])';
    final expectedDoc = 'Does foo.';

    testSignature(
      content,
      expectedLabel,
      expectedDoc,
      [
        new ParameterInformation('String s', null),
        new ParameterInformation('bool b = true', null),
      ],
    );
  }

  test_signature_help_optional_multiple() async {
    final content = '''
    /// Does foo.
    foo(String s, [bool b = true, bool a]) {
      foo(^);
    }
    ''';

    final expectedLabel = 'foo(String s, [bool b = true, bool a])';
    final expectedDoc = 'Does foo.';

    testSignature(
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

  test_signature_help_simple() async {
    final content = '''
    /// Does foo.
    foo(String s, int i) {
      foo(^);
    }
    ''';
    final expectedLabel = 'foo(String s, int i)';
    final expectedDoc = 'Does foo.';

    testSignature(
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
    List<ParameterInformation> expectedParams,
  ) async {
    await initialize();
    await openFile(mainFileUri, withoutMarkers(fileContent));
    final res =
        await getSignatureHelp(mainFileUri, positionFromMarker(fileContent));

    expect(res.activeParameter, isNull);
    expect(res.activeSignature, equals(0));
    expect(res.signatures, hasLength(1));
    final sig = res.signatures.first;
    // TODO(dantup): Add test + support for plain text.
    expect(sig.label, equals(expectedLabel));
    expect(
        sig.documentation.valueEquals(
          new MarkupContent(MarkupKind.Markdown, expectedDoc),
        ),
        isTrue);
    expect(sig.parameters, equals(expectedParams));
  }
}
