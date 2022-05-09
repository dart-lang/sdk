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
  Future<void> test_class_replacement_left() async {
    _checkContainers(
      declarations: 'var field = 0;',
      constructorParameters: 'this.f^',
      validator: (response) {
        check(response)
          ..hasReplacement(left: 1)
          ..suggestions.matchesInAnyOrder([
            (suggestion) => suggestion
              ..completion.isEqualTo('field')
              ..isField
              ..returnType.isEqualTo('int'),
          ]);
      },
    );
  }

  Future<void> test_class_replacement_right() async {
    _checkContainers(
      declarations: 'var field = 0;',
      constructorParameters: 'this.^f',
      validator: (response) {
        check(response)
          ..hasReplacement(right: 1)
          ..suggestions.matchesInAnyOrder([
            (suggestion) => suggestion
              ..completion.isEqualTo('field')
              ..isField
              ..returnType.isEqualTo('int'),
          ]);
      },
    );
  }

  Future<void> test_class_suggestions_instanceFields_local() async {
    var response = await getTestCodeSuggestions('''
class A {
  static final superStatic = 0;
  var inherited = 0;

  void superMethod() {}
  int get superGetter => 0;
  void superSetter(int _) {}
}

class B extends A {
  static final thisStatic = 0;

  var first = 0;
  var second = 1.2;

  B(this.^);
  B.otherConstructor() {}

  void thisMethod() {}
  int get thisGetter => 0;
  void thisSetter(int _) {}
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

  Future<void> test_class_suggestions_onlyNotSpecified_optionalNamed() async {
    _checkContainers(
      declarations: 'final int x; final int y;',
      constructorParameters: '{this.x, this.^}',
      validator: (response) {
        check(response)
          ..hasEmptyReplacement()
          ..suggestions.matchesInAnyOrder([
            (suggestion) => suggestion
              ..completion.isEqualTo('y')
              ..isField
              ..returnType.isEqualTo('int'),
          ]);
      },
    );
  }

  Future<void>
      test_class_suggestions_onlyNotSpecified_requiredPositional() async {
    _checkContainers(
      declarations: 'final int x; final int y;',
      constructorParameters: 'this.x, this.^',
      validator: (response) {
        check(response)
          ..hasEmptyReplacement()
          ..suggestions.matchesInAnyOrder([
            (suggestion) => suggestion
              ..completion.isEqualTo('y')
              ..isField
              ..returnType.isEqualTo('int'),
          ]);
      },
    );
  }

  Future<void> test_enum_suggestions_instanceFields() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v();

  static final zero = 0;
  final int first;
  final double second;

  E(this.^);
  E.otherConstructor();

  void myMethod() {}
  int get myGetter => 0;
  void mySetter(int _) {}
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

  Future<void> _checkContainers({
    required String declarations,
    required String constructorParameters,
    required void Function(CompletionResponseForTesting response) validator,
  }) async {
    // class
    {
      var response = await getTestCodeSuggestions('''
class A {
  $declarations
  A($constructorParameters);
}
''');
      validator(response);
    }
    // enum
    {
      var response = await getTestCodeSuggestions('''
enum E {
  v;
  $declarations
  E($constructorParameters);
}
''');
      validator(response);
    }
  }
}
