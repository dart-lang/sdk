// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldFormalParameterTest1);
    defineReflectiveTests(FieldFormalParameterTest2);
  });
}

@reflectiveTest
class FieldFormalParameterTest1 extends AbstractCompletionDriverTest
    with SuperFormalParameterTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class FieldFormalParameterTest2 extends AbstractCompletionDriverTest
    with SuperFormalParameterTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin SuperFormalParameterTestCases on AbstractCompletionDriverTest {
  @override
  bool get supportsAvailableSuggestions => true;

  /// https://github.com/dart-lang/sdk/issues/39028
  Future<void> test_mixin_constructor() async {
    var response = await getTestCodeSuggestions('''
mixin M {
  var field = 0;
  M(this.^);
}
''');

    check(response).suggestions.isEmpty;
  }

  Future<void> test_replacement_left() async {
    var response = await getTestCodeSuggestions('''
class A {
  var field = 0;
  A(this.f^);
}
''');

    check(response)
      ..hasReplacement(left: 1)
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('field')
          ..isField
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_replacement_right() async {
    var response = await getTestCodeSuggestions('''
class A {
  var field = 0;
  A(this.^f);
}
''');

    check(response)
      ..hasReplacement(right: 1)
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('field')
          ..isField
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_suggestions_onlyLocal() async {
    var response = await getTestCodeSuggestions('''
class A {
  var inherited = 0;
}

class B extends A {
  var first = 0;
  var second = 1.2;
  B(this.^);
  B.constructor() {}
  void method() {}
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isField
          ..returnType.isEqualTo('int'),
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isField
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_suggestions_onlyNotSpecified_optionalNamed() async {
    var response = await getTestCodeSuggestions('''
class Point {
  final int x;
  final int y;
  Point({this.x, this.^});
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('y')
          ..isField
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_suggestions_onlyNotSpecified_requiredPositional() async {
    var response = await getTestCodeSuggestions('''
class Point {
  final int x;
  final int y;
  Point(this.x, this.^);
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('y')
          ..isField
          ..returnType.isEqualTo('int'),
      ]);
  }
}
