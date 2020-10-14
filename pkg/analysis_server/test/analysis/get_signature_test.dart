// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisSignatureTest);
  });
}

@reflectiveTest
class AnalysisSignatureTest extends AbstractAnalysisTest {
  Future<Response> prepareRawSignature(String search) {
    var offset = findOffset(search);
    return prepareRawSignatureAt(offset);
  }

  Future<Response> prepareRawSignatureAt(int offset, {String file}) async {
    await waitForTasksFinished();
    var request =
        AnalysisGetSignatureParams(file ?? testFile, offset).toRequest('0');
    return waitResponse(request);
  }

  Future<AnalysisGetSignatureResult> prepareSignature(String search) {
    var offset = findOffset(search);
    return prepareSignatureAt(offset);
  }

  Future<AnalysisGetSignatureResult> prepareSignatureAt(int offset,
      {String file}) async {
    var response = await prepareRawSignatureAt(offset, file: file);
    return AnalysisGetSignatureResult.fromResponse(response);
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  Future<void> test_constructor() async {
    addTestFile('''
/// MyClass doc
class MyClass {
  /// MyClass constructor doc
  MyClass(String name, {int length}) {}
}
main() {
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
    addTestFile('''
/// MyClass doc
class MyClass {
  /// MyClass private constructor doc
  MyClass._() {}
  /// MyClass factory constructor doc
  factory MyClass(String name, {int length}) {
    return new MyClass._();
  }
}
main() {
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
    addTestFile('''
/// MyClass doc
class MyClass {
  /// MyClass.foo constructor doc
  MyClass.foo(String name, {int length}) {}
}
main() {
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
    addTestFile('''
one(String name, int length) {}
main() {
  one("Danny", () {
    /*^*/
  });
}
''');
    var result = await prepareRawSignature('/*^*/');
    expect(result.error, isNotNull);
    expect(result.error.code,
        equals(RequestErrorCode.GET_SIGNATURE_UNKNOWN_FUNCTION));
  }

  Future<void> test_error_file_not_analyzed() async {
    var result = await prepareRawSignatureAt(0,
        file: convertPath('/not/in/project.dart'));
    expect(result.error, isNotNull);
    expect(
        result.error.code, equals(RequestErrorCode.GET_SIGNATURE_INVALID_FILE));
  }

  Future<void> test_error_function_unknown() async {
    addTestFile('''
someFunc(/*^*/);
''');
    var result = await prepareRawSignature('/*^*/');
    expect(result.error, isNotNull);
    expect(result.error.code,
        equals(RequestErrorCode.GET_SIGNATURE_UNKNOWN_FUNCTION));
  }

  Future<void> test_error_offset_invalid() async {
    addTestFile('''
a() {}
''');
    var result = await prepareRawSignatureAt(1000);
    expect(result.error, isNotNull);
    expect(result.error.code,
        equals(RequestErrorCode.GET_SIGNATURE_INVALID_OFFSET));
  }

  Future<void> test_function_expression() async {
    addTestFile('''
/// f doc
int Function(String) f(String s) => (int i) => int.parse(s) + i;
main() {
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
    newFile('/project/bin/other.dart', content: '''
/// one doc
one(String name, int length) {}
main() {
  one("Danny", /*^*/);
}
''');
    addTestFile('''
import 'other.dart';
main() {
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
    addTestFile('''
/// one doc
one(String name, int length) {}
main() {
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
    addTestFile('''
/// one doc
one(String name, {int length}) {}
main() {
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
    addTestFile('''
/// one doc
one(String name, {int length = 1}) {}
main() {
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
    addTestFile('''
/// one doc
one(String name, {String email = "a@b.c"}) {}
main() {
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
    addTestFile('''
/// one doc
one(String one) {}
/// two doc
String two(String two) { return ""; }
main() {
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
    addTestFile('''
/// one doc
one(String one) {}
/// two doc
String two(String two) { return ""; }
main() {
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
    addTestFile('''
one(String name, int length) {}
main() {
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
    addTestFile('''
/// one doc
one(String name, [int length]) {}
main() {
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
    addTestFile('''
/// one doc
one(String name, [int length = 11]) {}
main() {
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
    addTestFile('''
/// one doc
one(String name, int length) {}
main() {
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
    addTestFile('''
/// one doc
one() {}
main() {
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
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request =
        AnalysisGetSignatureParams(convertPath('/foo/../bar/test.dart'), 0)
            .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_method_instance() async {
    addTestFile('''
/// MyClass doc
class MyClass {
  /// MyClass constructor doc
  MyClass(String name, {int length}) {}
  /// MyClass instance method
  myMethod(String name, {int length}) {}
}
main() {
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
    addTestFile('''
/// MyClass doc
class MyClass {
  /// MyClass constructor doc
  MyClass(String name, {int length}) {}
  /// MyClass static method
  static void myStaticMethod(String name, {int length}) {}
}
main() {
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
