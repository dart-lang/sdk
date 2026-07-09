// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MainFirstPositionalParameterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MainFirstPositionalParameterTest extends PubPackageResolutionTest {
  test_positionalOptional_listOfInt() async {
    await resolveTestCodeWithDiagnostics('''
void main([List<int> args = const []]) {}
//         ^^^^^^^^^
// [diag.mainFirstPositionalParameterType] The type of the first positional parameter of the 'main' function must be a supertype of 'List<String>'.
''');
  }

  test_positionalRequired_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
void main(dynamic args) {}
''');
  }

  test_positionalRequired_functionTypedFormal() async {
    await resolveTestCodeWithDiagnostics('''
void main(void args()) {}
//        ^^^^
// [diag.mainFirstPositionalParameterType] The type of the first positional parameter of the 'main' function must be a supertype of 'List<String>'.
''');
  }

  test_positionalRequired_iterableOfString() async {
    await resolveTestCodeWithDiagnostics('''
void main(Iterable<String> args) {}
''');
  }

  test_positionalRequired_listOfInt() async {
    await resolveTestCodeWithDiagnostics('''
void main(List<int> args) {}
//        ^^^^^^^^^
// [diag.mainFirstPositionalParameterType] The type of the first positional parameter of the 'main' function must be a supertype of 'List<String>'.
''');
  }

  test_positionalRequired_listOfString() async {
    await resolveTestCodeWithDiagnostics('''
void main(List<String> args) {}
''');
  }

  test_positionalRequired_listOfStringQuestion() async {
    await resolveTestCodeWithDiagnostics('''
void main(List<String?> args) {}
''');
  }

  test_positionalRequired_listQuestionOfString() async {
    await resolveTestCodeWithDiagnostics('''
void main(List<String>? args) {}
''');
  }

  test_positionalRequired_object() async {
    await resolveTestCodeWithDiagnostics('''
void main(Object args) {}
''');
  }

  test_positionalRequired_objectQuestion() async {
    await resolveTestCodeWithDiagnostics('''
void main(Object? args) {}
''');
  }
}
