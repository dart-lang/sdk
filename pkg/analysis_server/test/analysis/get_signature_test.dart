// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisSignatureTest);
  });
}

@reflectiveTest
class AnalysisSignatureTest extends AbstractAnalysisTest {
  Future<AnalysisGetSignatureResult> prepareSignature(String search) {
    int offset = findOffset(search);
    return prepareSignatureAt(offset);
  }

  Future<AnalysisGetSignatureResult> prepareSignatureAt(int offset) async {
    await waitForTasksFinished();
    Request request =
        new AnalysisGetSignatureParams(testFile, offset).toRequest('0');
    Response response = await waitResponse(request);
    return new AnalysisGetSignatureResult.fromResponse(response);
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  test_function_required() async {
    addTestFile('''
/// one doc
one(String name, int length) {}
main() {
  one("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals("one"));
    expect(result.dartdoc, equals("one doc"));
    expect(result.parameters, hasLength(2));
    expect(result.parameters[0],
        equals(new ParameterInfo(ParameterKind.REQUIRED, "name", "String")));
    expect(result.parameters[1],
        equals(new ParameterInfo(ParameterKind.REQUIRED, "length", "int")));
  }

  test_function_optional() async {
    addTestFile('''
/// one doc
one(String name, [int length]) {}
main() {
  one("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals("one"));
    expect(result.dartdoc, equals("one doc"));
    expect(result.parameters, hasLength(2));
    expect(result.parameters[0],
        equals(new ParameterInfo(ParameterKind.REQUIRED, "name", "String")));
    expect(result.parameters[1],
        equals(new ParameterInfo(ParameterKind.OPTIONAL, "length", "int")));
  }

  test_function_named() async {
    addTestFile('''
/// one doc
one(String name, {int length}) {}
main() {
  one("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals("one"));
    expect(result.dartdoc, equals("one doc"));
    expect(result.parameters, hasLength(2));
    expect(result.parameters[0],
        equals(new ParameterInfo(ParameterKind.REQUIRED, "name", "String")));
    expect(result.parameters[1],
        equals(new ParameterInfo(ParameterKind.NAMED, "length", "int")));
  }

  @failingTest
  test_function_select_param_first() {
    // Placeholder for supporting telling the user which param is where the cursor is
    // https://github.com/dart-lang/sdk/issues/27034#issuecomment-238280507
    // eg. foo(1^, 2);
    fail('TODO');
  }

  @failingTest
  test_function_select_param_second() {
    // Placeholder for supporting telling the user which param is where the cursor is
    // https://github.com/dart-lang/sdk/issues/27034#issuecomment-238280507
    // eg. foo(1, ^2);
    fail('TODO');
  }

  @failingTest
  test_function_select_param_next() {
    // Placeholder for supporting telling the user which param is where the cursor is
    // https://github.com/dart-lang/sdk/issues/27034#issuecomment-238280507
    // eg. foo(1, ^);
    fail('TODO');
  }

  @failingTest
  test_constructor() async {
    fail('Requires implementation');
    addTestFile('''
/// MyClass doc
class MyClass {
  MyClass(String name, [int length], { int max }) {}
} 
main() {
  var a = new MyClass("Danny", /*^*/);
}
''');
    var result = await prepareSignature('/*^*/');
    expect(result.name, equals("MyClass"));
    expect(result.dartdoc, equals("MyClass doc"));
    expect(result.parameters, hasLength(3));
    expect(result.parameters[0],
        equals(new ParameterInfo(ParameterKind.REQUIRED, "name", "String")));
    expect(result.parameters[1],
        equals(new ParameterInfo(ParameterKind.OPTIONAL, "length", "int")));
    expect(result.parameters[2],
        equals(new ParameterInfo(ParameterKind.NAMED, "max", "int")));
  }

  @failingTest
  test_function_nested_call() {
    // eg. foo(bar(1, 2));
    fail('TODO');
  }

  @failingTest
  test_function_zero_arguments() {
    fail('TODO');
  }

  @failingTest
  test_function_no_dart_doc() {
    fail('TODO');
  }

  @failingTest
  test_function_expression() {
    // eg.
    // int Function(int) f(String s) => (int i) => int.parse(s) + i;
    // main() {
    //   print(f('3')(2));
    // }
    fail('TODO');
  }

  @failingTest
  test_constructor_named() {
    fail('TODO');
  }

  @failingTest
  test_constructor_factory() {
    fail('TODO');
  }

  @failingTest
  test_method_instance() {
    fail('TODO');
  }

  @failingTest
  test_method_static() {
    fail('TODO');
  }

  @failingTest
  test_irrelevant_parens() {
    // eg. method(something, (((1 * 2))));
    fail('TODO');
  }

  @failingTest
  test_error_content_modified() {
    // Content changed during response (CONTENT_MODIFIED)
    fail('TODO');
  }

  @failingTest
  test_error_file_not_analyzed() {
    // (valid path, but )
    // invalid file (GET_SIGNATURE_INVALID_FILE)
    fail('TODO');
  }

  @failingTest
  test_error_file_invalid_path() {
    // invalid file (GET_SIGNATURE_INVALID_FILE)
    fail('TODO');
  }

  @failingTest
  test_error_offset_invalid() {
    // invalid offset (GET_SIGNATURE_INVALID_OFFSET)
    fail('TODO');
  }

  @failingTest
  test_error_function_unknown() {
    // invalid function (GET_SIGNATURE_UNKNOWN_FUNCTION)
    fail('TODO');
  }
}
