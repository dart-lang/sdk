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
    var sdkCorePath = convertPath('/sdk/lib/core/core.dart');
    return pathContext.toUri(sdkCorePath);
  }

  @override
  void setUp() {
    super.setUp();

    setLocationLinkSupport();
  }

  Future<void> test_currentFile() async {
    var code = TestCode.parse('''
class /*[0*/A/*0]*/ {}

final /*[1*/a^/*1]*/ = A();
''');

    var ranges = code.ranges.ranges;
    var targetRange = ranges[0];
    var originRange = ranges[1];
    var result = await _getResult(code);
    expect(result.originSelectionRange, originRange);
    expect(result.targetUri, mainFileUri);
    expect(result.targetSelectionRange, targetRange);
    expect(result.targetRange, rangeOfString(code, 'class A {}'));
  }

  Future<void> test_dotShorthand_class() async {
    var code = TestCode.parse('''
void f() {
  A a = ./*[0*/gett^er/*0]*/;
}

class /*[1*/A/*1]*/ {
  static A get getter => A();
}
  ''');

    var ranges = code.ranges.ranges;
    var originRange = ranges[0];
    var targetRange = ranges[1];
    var result = await _getResult(code);
    expect(result.originSelectionRange, originRange);
    expect(result.targetUri, mainFileUri);
    expect(result.targetSelectionRange, targetRange);
    expect(
      result.targetRange,
      rangeOfPattern(code, RegExp(r'class A \{.*\}', dotAll: true)),
    );
  }

  Future<void> test_dotShorthand_enum() async {
    var code = TestCode.parse('''
void f() {
  A a = ./*[0*/on^e/*0]*/;
}

enum /*[1*/A/*1]*/ { one }
  ''');

    var ranges = code.ranges.ranges;
    var originRange = ranges[0];
    var targetRange = ranges[1];
    var result = await _getResult(code);
    expect(result.originSelectionRange, originRange);
    expect(result.targetUri, mainFileUri);
    expect(result.targetSelectionRange, targetRange);
    expect(result.targetRange, rangeOfString(code, 'enum A { one }'));
  }

  Future<void> test_dotShorthand_extensionType() async {
    var code = TestCode.parse('''
void f() {
  A a = ./*[0*/gett^er/*0]*/;
}

extension type /*[1*/A/*1]*/(int x) {
  static A get getter => A(1);
}
  ''');

    var ranges = code.ranges.ranges;
    var originRange = ranges[0];
    var targetRange = ranges[1];
    var result = await _getResult(code);
    expect(result.originSelectionRange, originRange);
    expect(result.targetUri, mainFileUri);
    expect(result.targetSelectionRange, targetRange);
    expect(
      result.targetRange,
      rangeOfPattern(
        code,
        RegExp(r'extension type A\(int x\) \{.*\}', dotAll: true),
      ),
    );
  }

  Future<void> test_doubleLiteral() async {
    var code = TestCode.parse('''
const a = [!12^.3!];
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'double');
  }

  Future<void> test_doubleLiteral_wildcard() async {
    var code = TestCode.parse('''
const _ = [!12^.3!];
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'double');
  }

  Future<void> test_getter() async {
    var code = TestCode.parse('''
class A {
  String get aaa => '';
}

void f() {
  final a = A();
  print(a.[!a^aa!]);
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_getter_synthetic() async {
    var code = TestCode.parse('''
class A {
  String aaa = '';
}

void f() {
  final a = A();
  print(a.[!a^aa!]);
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_intLiteral() async {
    var code = TestCode.parse('''
const a = [!12^3!];
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'int');
  }

  /// Checks a result when the client does not support [LocationLink], only
  /// the original LSP [Location].
  Future<void> test_location() async {
    setLocationLinkSupport(false);

    var code = TestCode.parse('''
const a^ = 'test string';
''');

    var result = await _getLocationResult(code);
    expect(result.uri, sdkCoreUri);
    _expectNameRange(result.range, 'String');
  }

  Future<void> test_namedParameter_closure() async {
    var code = TestCode.parse('''
void bar(void Function(String, {required int? value}) f) {}
void foo() {
  bar((str, {required [!val^ue!]}) {});
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'int');
  }

  Future<void> test_nonDartFile() async {
    var code = TestCode.parse('''
const a = '^';
''');

    newFile(pubspecFilePath, code.code);
    await initialize();
    var results = await getTypeDefinitionAsLocation(
      mainFileUri,
      code.position.position,
    );
    expect(results, isEmpty);
  }

  Future<void> test_optionalNamedParameter_closure() async {
    var code = TestCode.parse('''
void bar(void Function() f) {}
void foo() {
  bar(({String [!s^tr!] = ''}) {});
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_optionalPositionalParameter_closure() async {
    var code = TestCode.parse('''
void bar(void Function() f) {}
void foo() {
  bar(([String [!s^tr!] = '']) {});
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_otherFile() async {
    var otherFilePath = join(projectFolderPath, 'lib', 'other.dart');
    var otherFileUri = pathContext.toUri(otherFilePath);
    var code = TestCode.parse('''
import 'other.dart';

final [!a^!] = A();
''');

    var otherCode = TestCode.parse('''
class [!A!] {}
''');

    newFile(otherFilePath, otherCode.code);
    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    expect(result.targetUri, otherFileUri);
    expect(result.targetSelectionRange, otherCode.range.range);
    expect(result.targetRange, rangeOfString(otherCode, 'class A {}'));
  }

  Future<void> test_parameter() async {
    var code = TestCode.parse('''
void f(String a) {
  f([!'te^st'!]);
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_parameter_closure() async {
    var code = TestCode.parse('''
void bar(void Function(String) f) {}
void foo() {
  bar(([!st^r!]) {});
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_parameter_named_closure() async {
    var code = TestCode.parse('''
void bar({required void Function(String) f}) {}
void foo() {
  bar(f: ([!st^r!]) {});
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_parameter_wildcard() async {
    var code = TestCode.parse('''
void f(String _) {
  f([!'te^st'!]);
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_parameterName() async {
    var code = TestCode.parse('''
void f({String? a}) {
  f([!a^!]: 'test');
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_setter() async {
    var code = TestCode.parse('''
class A {
  set aaa(String value) {}
}

void f() {
  final a = A();
  a.[!a^aa!] = '';
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_stringLiteral() async {
    var code = TestCode.parse('''
const a = [!'te^st string'!];
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_type() async {
    var code = TestCode.parse('''
[!St^ring!] a = '';
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_type_underscore() async {
    var code = TestCode.parse('''
class _ { }

_ a = _();
_ f() => [!^a!];
''');

    var result = await _getResult(code);
    expect(result.targetUri, mainFileUri);
    expect(result.targetRange, rangeOfString(code, 'class _ { }'));
  }

  Future<void> test_typedParameter_closure() async {
    var code = TestCode.parse('''
void bar(void Function(String) f) {}
void foo() {
  bar((String [!s^tr!]) {});
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_unopenedFile() async {
    var code = TestCode.parse('''
const a = [!'^'!];
''');

    newFile(mainFilePath, code.code);
    var result = await _getResult(code, inOpenFile: false);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableDeclaration() async {
    var code = TestCode.parse('''
const [!a^!] = 'test string';
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableDeclaration_forInLoop() async {
    var code = TestCode.parse('''
void f() {
  for (final [!a^!] in ['']) {
  }
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableDeclaration_forLoop() async {
    var code = TestCode.parse('''
void f() {
  for (var [!i^!] = 0; i < 1; i++) {
  }
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'int');
  }

  Future<void> test_variableDeclaration_inferredType() async {
    var code = TestCode.parse('''
var [!a^!] = 'test string';
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableReference() async {
    var code = TestCode.parse('''
void f() {
  const a = 'test string';
  print([!a^!]);
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableReference_forInLoop() async {
    var code = TestCode.parse('''
void f() {
  for (final a in ['']) {
    print([!a^!]);
  }
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'String');
  }

  Future<void> test_variableReference_forLoop() async {
    var code = TestCode.parse('''
void f() {
  for (var i = 0; i < 1; i++) {
    print([!i^!]);
  }
}
''');

    var result = await _getResult(code);
    expect(result.originSelectionRange, code.range.range);
    _expectSdkCoreType(result, 'int');
  }

  Future<void> test_variableReference_inferredType() async {
    var code = TestCode.parse('''
void f() {
  var a = 'test string';
  print([!a^!]);
}
''');

    var result = await _getResult(code);
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
    expect(range.end.character - range.start.character, name.length);
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
    var results = await getTypeDefinitionAsLocation(
      mainFileUri,
      code.position.position,
    );
    return results.single;
  }

  /// Advertises support for the LSP LocationLink type and gets the type
  /// definition using that.
  Future<LocationLink> _getResult(
    TestCode code, {
    Uri? fileUri,
    bool inOpenFile = true,
  }) async {
    fileUri ??= mainFileUri;
    await initialize();
    if (inOpenFile) {
      await openFile(fileUri, code.code);
    }
    var results = await getTypeDefinitionAsLocationLinks(
      mainFileUri,
      code.position.position,
    );
    return results.single;
  }
}
