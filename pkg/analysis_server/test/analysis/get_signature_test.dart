// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisSignatureTest);
  });
}

@reflectiveTest
class AnalysisSignatureTest extends PubPackageAnalysisServerTest {
  Future<Response> prepareRawSignature(String search) {
    var offset = findOffset(search);
    return prepareRawSignatureAt(offset);
  }

  Future<Response> prepareRawSignatureAt(int offset, {String? file}) async {
    var request = AnalysisGetSignatureParams(file ?? testFile.path, offset)
        .toRequest('0');
    return handleRequest(request);
  }

  Future<AnalysisGetSignatureResult> prepareSignature(String search) {
    var offset = findOffset(search);
    return prepareSignatureAt(offset);
  }

  Future<AnalysisGetSignatureResult> prepareSignatureAt(int offset,
      {String? file}) async {
    var response = await prepareRawSignatureAt(offset, file: file);
    return AnalysisGetSignatureResult.fromResponse(response);
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_constructor() async {
    newFile(testFilePath, '''
/// MyClass doc
class MyClass {
  /// MyClass constructor doc
  MyClass(String name, {int length}) {}
}
void f() {
  var a = new MyClass("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('MyClass'));
    expect(result.dartdoc, equals('MyClass constructor doc'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(result.parameters[1],
        equals(ParameterInfo(ParameterKind.OPTIONAL_NAMED, 'length', 'int')));
  }

  Future<void> test_constructor_factory() async {
    newFile(testFilePath, '''
/// MyClass doc
class MyClass {
  /// MyClass private constructor doc
  MyClass._() {}
  /// MyClass factory constructor doc
  factory MyClass(String name, {int length}) {
    return new MyClass._();
  }
}
void f() {
  var a = new MyClass("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('MyClass'));
    expect(result.dartdoc, equals('MyClass factory constructor doc'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(result.parameters[1],
        equals(ParameterInfo(ParameterKind.OPTIONAL_NAMED, 'length', 'int')));
  }

  Future<void> test_constructor_named() async {
    newFile(testFilePath, '''
/// MyClass doc
class MyClass {
  /// MyClass.foo constructor doc
  MyClass.foo(String name, {int length}) {}
}
void f() {
  var a = new MyClass.foo("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('MyClass.foo'));
    expect(result.dartdoc, equals('MyClass.foo constructor doc'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(result.parameters[1],
        equals(ParameterInfo(ParameterKind.OPTIONAL_NAMED, 'length', 'int')));
  }

  Future<void> test_does_not_walk_up_over_closure() async {
    newFile(testFilePath, '''
one(String name, int length) {}
void f() {
  one("Danny", () {
    /*^*/
  });
}
''');
    var response = await prepareRawSignature('/*^*/');
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.GET_SIGNATURE_UNKNOWN_FUNCTION,
    );
  }

  Future<void> test_error_file_not_analyzed() async {
    var response = await prepareRawSignatureAt(0,
        file: convertPath('/not/in/project.dart'));
    var error = response.error!;
    expect(error.code, equals(RequestErrorCode.GET_SIGNATURE_INVALID_FILE));
  }

  Future<void> test_error_function_unknown() async {
    newFile(testFilePath, '''
someFunc(/*^*/);
''');
    var response = await prepareRawSignature('/*^*/');
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.GET_SIGNATURE_UNKNOWN_FUNCTION,
    );
  }

  Future<void> test_error_offset_invalid() async {
    newFile(testFilePath, '''
a() {}
''');
    var response = await prepareRawSignatureAt(1000);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.GET_SIGNATURE_INVALID_OFFSET,
    );
  }

  Future<void> test_function_expression() async {
    newFile(testFilePath, '''
/// f doc
int Function(String) f(String s) => (int i) => int.parse(s) + i;
void f() {
  print(f('3'/*^*/)(2));
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('f'));
    expect(result.dartdoc, equals('f doc'));
    expect(result.parameters, hasLength(1));
    expect(
        result.parameters[0],
        equals(
            ParameterInfo(ParameterKind.REQUIRED_POSITIONAL, 's', 'String')));
  }

  Future<void> test_function_from_other_file() async {
    newFile('$testPackageLibPath/other.dart', '''
/// one doc
one(String name, int length) {}
void f() {
  one("Danny", /*^*/);
}
''');
    newFile(testFilePath, '''
import 'other.dart';
void f() {
  one("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('one'));
    expect(result.dartdoc, equals('one doc'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(
        result.parameters[1],
        equals(
            ParameterInfo(ParameterKind.REQUIRED_POSITIONAL, 'length', 'int')));
  }

  Future<void> test_function_irrelevant_parens() async {
    newFile(testFilePath, '''
/// one doc
one(String name, int length) {}
void f() {
  one("Danny", (((1 * 2/*^*/))));
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('one'));
    expect(result.dartdoc, equals('one doc'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(
        result.parameters[1],
        equals(
            ParameterInfo(ParameterKind.REQUIRED_POSITIONAL, 'length', 'int')));
  }

  Future<void> test_function_named() async {
    newFile(testFilePath, '''
/// one doc
one(String name, {int length}) {}
void f() {
  one("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('one'));
    expect(result.dartdoc, equals('one doc'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(result.parameters[1],
        equals(ParameterInfo(ParameterKind.OPTIONAL_NAMED, 'length', 'int')));
  }

  Future<void> test_function_named_with_default_int() async {
    newFile(testFilePath, '''
/// one doc
one(String name, {int length = 1}) {}
void f() {
  one("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('one'));
    expect(result.dartdoc, equals('one doc'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(
        result.parameters[1],
        equals(ParameterInfo(ParameterKind.OPTIONAL_NAMED, 'length', 'int',
            defaultValue: '1')));
  }

  Future<void> test_function_named_with_default_string() async {
    newFile(testFilePath, '''
/// one doc
one(String name, {String email = "a@b.c"}) {}
void f() {
  one("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('one'));
    expect(result.dartdoc, equals('one doc'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(
        result.parameters[1],
        equals(ParameterInfo(ParameterKind.OPTIONAL_NAMED, 'email', 'String',
            defaultValue: '"a@b.c"')));
  }

  Future<void> test_function_nested_call_inner() async {
    // eg. foo(bar(1, 2));
    newFile(testFilePath, '''
/// one doc
one(String one) {}
/// two doc
String two(String two) { return ""; }
void f() {
  one(two(/*^*/));
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('two'));
    expect(result.dartdoc, equals('two doc'));
    expect(result.parameters, hasLength(1));
    expect(
        result.parameters[0],
        equals(
            ParameterInfo(ParameterKind.REQUIRED_POSITIONAL, 'two', 'String')));
  }

  Future<void> test_function_nested_call_outer() async {
    // eg. foo(bar(1, 2));
    newFile(testFilePath, '''
/// one doc
one(String one) {}
/// two doc
String two(String two) { return ""; }
void f() {
  one(two(),/*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('one'));
    expect(result.dartdoc, equals('one doc'));
    expect(result.parameters, hasLength(1));
    expect(
        result.parameters[0],
        equals(
            ParameterInfo(ParameterKind.REQUIRED_POSITIONAL, 'one', 'String')));
  }

  Future<void> test_function_no_dart_doc() async {
    newFile(testFilePath, '''
one(String name, int length) {}
void f() {
  one("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('one'));
    expect(result.dartdoc, isNull);
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(
        result.parameters[1],
        equals(
            ParameterInfo(ParameterKind.REQUIRED_POSITIONAL, 'length', 'int')));
  }

  Future<void> test_function_optional() async {
    newFile(testFilePath, '''
/// one doc
one(String name, [int length]) {}
void f() {
  one("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('one'));
    expect(result.dartdoc, equals('one doc'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(
        result.parameters[1],
        equals(
            ParameterInfo(ParameterKind.OPTIONAL_POSITIONAL, 'length', 'int')));
  }

  Future<void> test_function_optional_with_default() async {
    newFile(testFilePath, '''
/// one doc
one(String name, [int length = 11]) {}
void f() {
  one("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('one'));
    expect(result.dartdoc, equals('one doc'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(
        result.parameters[1],
        equals(ParameterInfo(ParameterKind.OPTIONAL_POSITIONAL, 'length', 'int',
            defaultValue: '11')));
  }

  Future<void> test_function_required() async {
    newFile(testFilePath, '''
/// one doc
one(String name, int length) {}
void f() {
  one("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('one'));
    expect(result.dartdoc, equals('one doc'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(
        result.parameters[1],
        equals(
            ParameterInfo(ParameterKind.REQUIRED_POSITIONAL, 'length', 'int')));
  }

  Future<void> test_function_zero_arguments() async {
    newFile(testFilePath, '''
/// one doc
one() {}
void f() {
  one(/*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('one'));
    expect(result.dartdoc, equals('one doc'));
    expect(result.parameters, hasLength(0));
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = AnalysisGetSignatureParams('test.dart', 0).toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request =
        AnalysisGetSignatureParams(convertPath('/foo/../bar/test.dart'), 0)
            .toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_method_instance() async {
    newFile(testFilePath, '''
/// MyClass doc
class MyClass {
  /// MyClass constructor doc
  MyClass(String name, {int length}) {}
  /// MyClass instance method
  myMethod(String name, {int length}) {}
}
void f() {
  var a = new MyClass("Danny");
  a.myMethod("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('myMethod'));
    expect(result.dartdoc, equals('MyClass instance method'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(result.parameters[1],
        equals(ParameterInfo(ParameterKind.OPTIONAL_NAMED, 'length', 'int')));
  }

  Future<void> test_method_static() async {
    newFile(testFilePath, '''
/// MyClass doc
class MyClass {
  /// MyClass constructor doc
  MyClass(String name, {int length}) {}
  /// MyClass static method
  static void myStaticMethod(String name, {int length}) {}
}
void f() {
  MyClass.myStaticMethod("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals('myStaticMethod'));
    expect(result.dartdoc, equals('MyClass static method'));
    expect(result.parameters, hasLength(2));
    expect(
        result.parameters[0],
        equals(ParameterInfo(
            ParameterKind.REQUIRED_POSITIONAL, 'name', 'String')));
    expect(result.parameters[1],
        equals(ParameterInfo(ParameterKind.OPTIONAL_NAMED, 'length', 'int')));
  }
}
