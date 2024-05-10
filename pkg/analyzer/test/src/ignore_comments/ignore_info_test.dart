// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IgnoreInfoTest);
  });
}

@reflectiveTest
class IgnoreInfoTest extends PubPackageResolutionTest {
  test_name_multiple() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: foo, bar');
    expect(ignoredElements, hasLength(2));
    _expectIgnoredName(ignoredElements[0], name: 'foo', offset: 11);
    _expectIgnoredName(ignoredElements[1], name: 'bar', offset: 16);
  }

  test_name_withExtraCharacters() async {
    var ignoredElements =
        await _parseIgnoredElements('// ignore: http://google.com');
    expect(ignoredElements, isEmpty);
  }

  test_noIgnores() async {
    var ignoredElements = await _parseIgnoredElements('// ignore:');
    expect(ignoredElements, isEmpty);
  }

  test_noIgnores_trailingWhitespace() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: ');
    expect(ignoredElements, isEmpty);
  }

  test_noWhitespaceAfterColon() async {
    var ignoredElements = await _parseIgnoredElements('// ignore:foo');
    expect(ignoredElements, hasLength(1));
    _expectIgnoredName(ignoredElements[0], name: 'foo', offset: 10);
  }

  test_noWhitespaceAfterComma() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: foo,bar');
    expect(ignoredElements, hasLength(2));
    _expectIgnoredName(ignoredElements[0], name: 'foo', offset: 11);
    _expectIgnoredName(ignoredElements[1], name: 'bar', offset: 15);
  }

  test_noWhitespaceBeforeIgnore() async {
    var ignoredElements = await _parseIgnoredElements('//ignore: foo');
    expect(ignoredElements, hasLength(1));
    _expectIgnoredName(ignoredElements[0], name: 'foo', offset: 10);
  }

  test_trailingComma() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: foo,');
    expect(ignoredElements, hasLength(1));
    _expectIgnoredName(ignoredElements[0], name: 'foo', offset: 11);
  }

  test_trailingCommas() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: foo,,');
    expect(ignoredElements, hasLength(2));
    _expectIgnoredName(ignoredElements[0], name: 'foo', offset: 11);
    expect(ignoredElements[1], isA<IgnoredDiagnosticComment>());
  }

  test_trailingCommaSpace() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: foo, ');
    expect(ignoredElements, hasLength(1));
    _expectIgnoredName(ignoredElements[0], name: 'foo', offset: 11);
  }

  test_trailingSpace() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: foo ');
    expect(ignoredElements, hasLength(1));
    _expectIgnoredName(ignoredElements[0], name: 'foo', offset: 11);
  }

  test_trailingText() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: foo because');
    expect(ignoredElements, hasLength(2));
    _expectIgnoredName(ignoredElements[0], name: 'foo', offset: 11);
    expect(ignoredElements[1], isA<IgnoredDiagnosticComment>());
  }

  test_type() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: type=lint');
    expect(ignoredElements, hasLength(1));
    _expectIgnoredType(ignoredElements[0], type: 'lint', offset: 11, length: 9);
  }

  test_type_multiple() async {
    var ignoredElements =
        await _parseIgnoredElements('// ignore: type=lint, type=warning');
    expect(ignoredElements, hasLength(2));
    _expectIgnoredType(ignoredElements[0], type: 'lint', offset: 11, length: 9);
    _expectIgnoredType(ignoredElements[1],
        type: 'warning', offset: 22, length: 12);
  }

  test_type_nameWithExtraCharacters() async {
    var ignoredElements =
        await _parseIgnoredElements('// ignore: type=http://google.com');
    expect(ignoredElements, isEmpty);
  }

  test_type_nonIdentifierName() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: type=!!');
    expect(ignoredElements, isEmpty);
  }

  test_type_spaceAfterEqual() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: type= lint');
    expect(ignoredElements, hasLength(1));
    _expectIgnoredType(ignoredElements[0],
        type: 'lint', offset: 11, length: 10);
  }

  test_type_spaceBeforeEqual() async {
    var ignoredElements = await _parseIgnoredElements('// ignore: type =lint');
    expect(ignoredElements, hasLength(1));
    _expectIgnoredType(ignoredElements[0],
        type: 'lint', offset: 11, length: 10);
  }

  void _expectIgnoredName(
    IgnoredElement element, {
    required String name,
    required int offset,
  }) =>
      expect(
        element,
        isA<IgnoredDiagnosticName>()
            .having((e) => e.name, 'name', name)
            .having((e) => e.offset, 'offset', offset),
      );

  void _expectIgnoredType(
    IgnoredElement element, {
    required String type,
    required int offset,
    required int length,
  }) =>
      expect(
        element,
        isA<IgnoredDiagnosticType>()
            .having((e) => e.type, 'type', type)
            .having((e) => e.offset, 'offset', offset)
            .having((e) => e.length, 'length', length),
      );

  Future<List<IgnoredElement>> _parseIgnoredElements(String comment) async {
    await assertNoErrorsInCode('''
$comment
int x = 1;
''');
    var commentToken = result.unit.beginToken.precedingComments as CommentToken;
    return commentToken.ignoredElements.toList();
  }
}
