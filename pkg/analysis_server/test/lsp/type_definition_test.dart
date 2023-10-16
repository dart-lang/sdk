// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
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

  @override
  void setUp() {
    super.setUp();

    setLocationLinkSupport();
  }

  Future<void> test_currentFile() async {
    final code = TestCode.parse('''
class /*[0*/A/*0]*/ {}

final /*[1*/a^/*1]*/ = A();
''');

    final ranges = code.ranges.ranges;
    final targetRange = ranges[0];
    final originRange = ranges[1];
    final result = await _getResult(code);
    expect(result.originSelectionRange, originRange);
    expect(result.targetUri, mainFileUri);
    expect(result.targetSelectionRange, targetRange);
    expect(result.targetRange, rangeOfString(code.code, 'class A {}'));
  }

  Future<void> test_doubleLiteral() async {
    final code = TestCode.parse('''
const a = [!12^.3!];
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'double');
  }

  Future<void> test_getter() async {
    final code = TestCode.parse('''
class A {
  String get aaa => '';
}

void f() {
  final a = A();
  print(a.[!a^aa!]);
}
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_intLiteral() async {
    final code = TestCode.parse('''
const a = [!12^3!];
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'int');
  }

  /// Checks a result when the client does not support [LocationLink], only
  /// the original LSP [Location].
  Future<void> test_location() async {
    setLocationLinkSupport(false);

    final code = TestCode.parse('''
const a^ = 'test string';
''');

    final result = await _getLocationResult(code);
    expect(result.uri, sdkCoreUri);
    _expectNameRange(result.range, 'String');
  }

  Future<void> test_nonDartFile() async {
    final code = TestCode.parse('''
const a = '^';
''');

    newFile(pubspecFilePath, code.code);
    await initialize();
    final results =
        await getTypeDefinitionAsLocation(mainFileUri, code.position.position);
    expect(results, isEmpty);
  }

  Future<void> test_otherFile() async {
    final otherFilePath = join(projectFolderPath, 'lib', 'other.dart');
    final otherFileUri = pathContext.toUri(otherFilePath);
    final code = TestCode.parse('''
import 'other.dart';

final [!a^!] = A();
''');

    final otherCode = TestCode.parse('''
class [!A!] {}
''');

    newFile(otherFilePath, otherCode.code);
    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    expect(result.targetUri, otherFileUri);
    expect(result.targetSelectionRange, otherCode.range.range);
    expect(result.targetRange, rangeOfString(otherCode.code, 'class A {}'));
  }

  Future<void> test_parameter() async {
    final code = TestCode.parse('''
void f(String a) {
  f([!'te^st'!]);
}
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_parameterName() async {
    final code = TestCode.parse('''
void f({String a}) {
  f([!a^!]: 'test');
}
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_setter() async {
    final code = TestCode.parse('''
class A {
  set aaa(String value) {}
}

void f() {
  final a = A();
  a.[!a^aa!] = '';
}
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_stringLiteral() async {
    final code = TestCode.parse('''
const a = [!'te^st string'!];
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_type() async {
    final code = TestCode.parse('''
[!St^ring!] a = '';
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_unopenedFile() async {
    final code = TestCode.parse('''
const a = [!'^'!];
''');

    newFile(mainFilePath, code.code);
    final result = await _getResult(code, inOpenFile: false);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableDeclaration() async {
    final code = TestCode.parse('''
const [!a^!] = 'test string';
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableDeclaration_inferredType() async {
    final code = TestCode.parse('''
var [!a^!] = 'test string';
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableReference() async {
    final code = TestCode.parse('''
void f() {
  const a = 'test string';
  print([!a^!]);
}
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableReference_inferredType() async {
    final code = TestCode.parse('''
void f() {
  var a = 'test string';
  print([!a^!]);
}
''');

    final result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
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
  Future<Location> _getLocationResult(TestCode code) async {
    await initialize();
    await openFile(mainFileUri, code.code);
    final results =
        await getTypeDefinitionAsLocation(mainFileUri, code.position.position);
    return results.single;
  }

  /// Advertises support for the LSP LocationLink type and gets the type
  /// definition using that.
  Future<LocationLink> _getResult(TestCode code,
      {Uri? fileUri, bool inOpenFile = true}) async {
    fileUri ??= mainFileUri;
    await initialize();
    if (inOpenFile) {
      await openFile(fileUri, code.code);
    }
    final results = await getTypeDefinitionAsLocationLinks(
      mainFileUri,
      code.position.position,
    );
    return results.single;
  }
}
