// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/cider/signature_help.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'cider_service.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CiderSignatureHelpComputerTest);
  });
}

@reflectiveTest
class CiderSignatureHelpComputerTest extends CiderServiceTest {
  late _CorrectionContext _correctionContext;

  void test_noDefaultConstructor() async {
    var result = await _compute('''
class A {
  A._();
}

final a = A(^);
''');

    expect(result, null);
  }

  void test_params_multipleNamed() async {
    var content = '''
/// Does foo.
foo(String s, {bool b = true, bool a}) {
  foo(^);
}
''';
    var expectedLabel = 'foo(String s, {bool b = true, bool a})';

    await testSignature(content, expectedLabel, 'Does foo.', [
      ParameterInformation(label: 'String s'),
      ParameterInformation(label: 'bool b = true'),
      ParameterInformation(label: 'bool a'),
    ], CharacterLocation(3, 7));
  }

  void test_params_multipleOptional() async {
    var content = '''
/// Does foo.
foo(String s, [bool b = true, bool a]) {
  foo(^);
}
''';

    var expectedLabel = 'foo(String s, [bool b = true, bool a])';
    await testSignature(content, expectedLabel, 'Does foo.', [
      ParameterInformation(label: 'String s'),
      ParameterInformation(label: 'bool b = true'),
      ParameterInformation(label: 'bool a'),
    ], CharacterLocation(3, 7));
  }

  void test_retrigger_validLocation() async {
    var content = '''
/// Does foo.
foo(String s, {bool b = true, bool a}) {
  foo('ssss',^);
}
''';
    var expectedLabel = 'foo(String s, {bool b = true, bool a})';

    await testSignature(content, expectedLabel, 'Does foo.', [
      ParameterInformation(label: 'String s'),
      ParameterInformation(label: 'bool b = true'),
      ParameterInformation(label: 'bool a'),
    ], CharacterLocation(3, 7));
  }

  void test_simple() async {
    var content = '''
/// Does foo.
foo(String s, int i) {
  foo(^);
}
''';
    var expectedLabel = 'foo(String s, int i)';
    await testSignature(content, expectedLabel, 'Does foo.', [
      ParameterInformation(label: 'String s'),
      ParameterInformation(label: 'int i'),
    ], CharacterLocation(3, 7));
  }

  void test_triggerCharacter_validLocation() async {
    var content = '''
/// Does foo.
foo(String s, int i) {
  foo(^
}
''';

    var expectedLabel = 'foo(String s, int i)';
    await testSignature(content, expectedLabel, 'Does foo.', [
      ParameterInformation(label: 'String s'),
      ParameterInformation(label: 'int i'),
    ], CharacterLocation(3, 7));
  }

  void test_typeParams_class() async {
    var content = '''
/// My Foo.
class Foo<T1, T2 extends String> {}

class Bar extends Foo<^> {}
''';

    await testSignature(
      content,
      'class Foo<T1, T2 extends String>',
      'My Foo.',
      [
        ParameterInformation(label: 'T1'),
        ParameterInformation(label: 'T2 extends String'),
      ],
      CharacterLocation(4, 23),
    );
  }

  void test_typeParams_function() async {
    var content = '''
/// My Foo.
void foo<T1, T2 extends String>() {
  foo<^>();
}
''';

    await testSignature(
      content,
      'void foo<T1, T2 extends String>()',
      'My Foo.',
      [
        ParameterInformation(label: 'T1'),
        ParameterInformation(label: 'T2 extends String'),
      ],
      CharacterLocation(3, 7),
    );
  }

  void test_typeParams_method() async {
    var content = '''
class Foo {
  /// My Foo.
  void foo<T1, T2 extends String>() {
    foo<^>();
  }
}
''';

    await testSignature(
      content,
      'void foo<T1, T2 extends String>()',
      'My Foo.',
      [
        ParameterInformation(label: 'T1'),
        ParameterInformation(label: 'T2 extends String'),
      ],
      CharacterLocation(4, 9),
    );
  }

  Future<void> testSignature(
    String content,
    String expectedLabel,
    String expectedDoc,
    List<ParameterInformation> expectedParameters,
    CharacterLocation leftParenLocation,
  ) async {
    var result = await _compute(content);
    var signature = result!.signatureHelp.signatures.first;
    var expected = MarkupContent(kind: MarkupKind.Markdown, value: expectedDoc);
    expect(signature.label, expectedLabel);
    expect(signature.documentation!.valueEquals(expected), isTrue);
    expect(
      ListEquality().equals(expectedParameters, signature.parameters),
      isTrue,
    );
    expect(result.callStart == leftParenLocation, isTrue);
  }

  Future<SignatureHelpResponse?> _compute(String content) {
    _updateFile(content);

    return CiderSignatureHelpComputer(fileResolver).compute2(
      convertPath(testPath),
      _correctionContext.line,
      _correctionContext.character,
    );
  }

  void _updateFile(String content) {
    var offset = content.indexOf('^');
    expect(offset, isPositive, reason: 'Expected to find ^');
    expect(content.indexOf('^', offset + 1), -1, reason: 'Expected only one ^');

    var lineInfo = LineInfo.fromContent(content);
    var location = lineInfo.getLocation(offset);

    content = content.substring(0, offset) + content.substring(offset + 1);
    newFile(testPath, content);

    _correctionContext = _CorrectionContext(
      content,
      offset,
      location.lineNumber - 1,
      location.columnNumber - 1,
    );
  }
}

class _CorrectionContext {
  final String content;
  final int offset;
  final int line;
  final int character;

  _CorrectionContext(this.content, this.offset, this.line, this.character);
}
