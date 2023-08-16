// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeDefinitionTest);
  });
}

@reflectiveTest
class TypeDefinitionTest extends AbstractLspAnalysisServerTest {
  Uri get sdkCoreUri {
    final sdkCorePath = convertPath('/sdk/lib/core/core.dart');
    return pathContext.toUri(sdkCorePath);
  }

  Future<void> test_currentFile() async {
    final contents = '''
class [[A]] {}

final [[a^]] = A();
''';

    final ranges = rangesFromMarkers(contents);
    final targetRange = ranges[0];
    final originRange = ranges[1];
    final result = await _getResult(contents);
    expect(result.originSelectionRange, originRange);
    expect(result.targetUri, mainFileUri);
    expect(result.targetSelectionRange, targetRange);
    expect(result.targetRange, rangeOfString(contents, 'class A {}'));
  }

  Future<void> test_doubleLiteral() async {
    final contents = '''
const a = [[12^.3]];
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'double');
  }

  Future<void> test_getter() async {
    final contents = '''
class A {
  String get aaa => '';
}

void f() {
  final a = A();
  print(a.[[a^aa]]);
}
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_intLiteral() async {
    final contents = '''
const a = [[12^3]];
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'int');
  }

  /// Checks a result when the client does not support [LocationLink], only
  /// the original LSP [Location].
  Future<void> test_location() async {
    final contents = '''
const a^ = 'test string';
''';

    final result = await _getLocationResult(contents);
    expect(result.uri, sdkCoreUri);
    _expectNameRange(result.range, 'String');
  }

  Future<void> test_nonDartFile() async {
    final contents = '''
const a = '^';
''';

    newFile(pubspecFilePath, withoutMarkers(contents));
    await initialize();
    final results = await getTypeDefinitionAsLocation(
        mainFileUri, positionFromMarker(contents));
    expect(results, isEmpty);
  }

  Future<void> test_otherFile() async {
    final otherFilePath = join(projectFolderPath, 'lib', 'other.dart');
    final otherFileUri = pathContext.toUri(otherFilePath);
    final contents = '''
import 'other.dart';

final [[a^]] = A();
''';

    final otherContents = '''
class [[A]] {}
''';

    newFile(otherFilePath, withoutMarkers(otherContents));
    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    expect(result.targetUri, otherFileUri);
    expect(result.targetSelectionRange, rangeFromMarkers(otherContents));
    expect(result.targetRange, rangeOfString(otherContents, 'class A {}'));
  }

  Future<void> test_parameter() async {
    final contents = '''
void f(String a) {
  f([['te^st']]);
}
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_parameterName() async {
    final contents = '''
void f({String a}) {
  f([[a^]]: 'test');
}
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_setter() async {
    final contents = '''
class A {
  set aaa(String value) {}
}

void f() {
  final a = A();
  a.[[a^aa]] = '';
}
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_stringLiteral() async {
    final contents = '''
const a = [['te^st string']];
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_type() async {
    final contents = '''
[[St^ring]] a = '';
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_unopenedFile() async {
    final contents = '''
const a = [['^']];
''';

    newFile(mainFilePath, withoutMarkers(contents));
    final result = await _getResult(contents, inOpenFile: false);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableDeclaration() async {
    final contents = '''
const [[a^]] = 'test string';
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableDeclaration_inferredType() async {
    final contents = '''
var [[a^]] = 'test string';
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableReference() async {
    final contents = '''
void f() {
  const a = 'test string';
  print([[a^]]);
}
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableReference_inferredType() async {
    final contents = '''
void f() {
  var a = 'test string';
  print([[a^]]);
}
''';

    final result = await _getResult(contents);
    expect(result.originSelectionRange, rangeFromMarkers(contents));
    _expectSdkCoreType(result, 'String');
  }

  /// Expects [range] looks consistent with a range of an elements code.
  ///
  /// This is used for SDK sources where the exact location is not known to the
  /// test.
  void _expectCodeRange(Range range) {
    expect(range.start.line, isPositive);
    expect(range.end.line, isPositive);
    // And a range that spans multiple lines.
    expect(range.start.line, lessThan(range.end.line));
  }

  /// Expects [range] looks consistent with a range of an elements name.
  ///
  /// This is used for SDK sources where the exact location is not known to the
  /// test.
  void _expectNameRange(Range range, String name) {
    expect(range.start.line, isPositive);
    expect(range.end.line, isPositive);
    // Expect a single line, with the length matching `name`.
    expect(range.start.line, range.end.line);
    expect(
      range.end.character - range.start.character,
      name.length,
    );
  }

  /// Expects [range] looks consistent with a range of an elements code.
  ///
  /// This is used for SDK sources where the exact location is not known to the
  /// test.
  void _expectSdkCoreType(LocationLink result, String typeName) {
    expect(result.targetUri, sdkCoreUri);
    _expectNameRange(result.targetSelectionRange, typeName);
    _expectCodeRange(result.targetRange);
  }

  /// Gets the type definition as an LSP Location object.
  Future<Location> _getLocationResult(String contents) async {
    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));
    final results = await getTypeDefinitionAsLocation(
        mainFileUri, positionFromMarker(contents));
    return results.single;
  }

  /// Advertises support for the LSP LocationLink type and gets the type
  /// definition using that.
  Future<LocationLink> _getResult(String contents,
      {Uri? fileUri, bool inOpenFile = true}) async {
    fileUri ??= mainFileUri;
    await initialize(
      textDocumentCapabilities:
          withLocationLinkSupport(emptyTextDocumentClientCapabilities),
    );
    if (inOpenFile) {
      await openFile(fileUri, withoutMarkers(contents));
    }
    final results = await getTypeDefinitionAsLocationLinks(
      mainFileUri,
      positionFromMarker(contents),
    );
    return results.single;
  }
}
