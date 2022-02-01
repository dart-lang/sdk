// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumTest1);
    defineReflectiveTests(EnumTest2);
  });
}

@reflectiveTest
class EnumTest1 extends AbstractCompletionDriverTest with EnumTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class EnumTest2 extends AbstractCompletionDriverTest with EnumTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin EnumTestCases on AbstractCompletionDriverTest {
  @override
  bool get supportsAvailableSuggestions => true;

  Future<void> test_enumConstantName() async {
    await _check_locations(
      declaration: 'enum MyEnum { foo01 }',
      codeAtCompletion: 'foo0^',
      validator: (response) {
        check(response).hasReplacement(left: 4);

        if (isProtocolVersion2) {
          check(response).suggestions.matches([
            (suggestion) => suggestion
              ..completion.isEqualTo('MyEnum.foo01')
              ..isEnumConstant,
          ]);
          // No other suggestions.
        } else {
          check(response).suggestions.includesAll([
            (suggestion) => suggestion
              ..completion.isEqualTo('MyEnum.foo01')
              ..isEnumConstant,
            // The response includes much more, such as `MyEnum` itself.
            // We don't expect though that the client will show it.
            (suggestion) => suggestion
              ..completion.isEqualTo('MyEnum')
              ..isEnum,
          ]);
        }
      },
    );
  }

  Future<void> test_enumConstantName_imported_withPrefix() async {
    await addProjectFile('lib/a.dart', r'''
enum MyEnum { foo01 }
''');

    var response = await getTestCodeSuggestions('''
import 'a.dart' as prefix;

void f() {
  foo0^
}
''');

    check(response).hasReplacement(left: 4);

    if (isProtocolVersion2) {
      check(response).suggestions.matches([
        (suggestion) => suggestion
          ..completion.isEqualTo('prefix.MyEnum.foo01')
          ..isEnumConstant,
      ]);
    } else {
      // TODO(scheglov) This is wrong.
      check(response).suggestions.includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('MyEnum.foo01')
          ..isEnumConstant,
      ]);
    }
  }

  Future<void> test_enumName() async {
    await _check_locations(
      declaration: 'enum MyEnum { foo01 }',
      codeAtCompletion: 'MyEnu^',
      validator: (response) {
        check(response).hasReplacement(left: 5);

        if (isProtocolVersion2) {
          check(response).suggestions.matches([
            (suggestion) => suggestion
              ..completion.isEqualTo('MyEnum')
              ..isEnum,
          ]);
          // No enum constants.
        } else {
          check(response).suggestions.includesAll([
            (suggestion) => suggestion
              ..completion.isEqualTo('MyEnum')
              ..isEnum,
          ]);
        }
      },
    );
  }

  Future<void> test_enumName_imported_withPrefix() async {
    await addProjectFile('lib/a.dart', r'''
enum MyEnum { foo01 }
''');

    var response = await getTestCodeSuggestions('''
import 'a.dart' as prefix;

void f() {
  MyEnu^
}
''');

    check(response).hasReplacement(left: 5);

    if (isProtocolVersion2) {
      check(response).suggestions.matches([
        (suggestion) => suggestion
          ..completion.isEqualTo('prefix.MyEnum')
          ..isEnum,
      ]);
    } else {
      // TODO(scheglov) This is wrong.
      check(response).suggestions.includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('MyEnum')
          ..isEnum,
      ]);
    }
  }

  @FailingTest(reason: 'element.kind is LIBRARY')
  Future<void> test_importPrefix() async {
    await addProjectFile('lib/a.dart', r'''
enum MyEnum { v }
''');

    var response = await getTestCodeSuggestions('''
import 'a.dart' as prefix01;

void f() {
  prefix0^
}
''');

    check(response).hasReplacement(left: 7);

    if (isProtocolVersion2) {
      check(response).suggestions.matches([
        (suggestion) => suggestion
          ..completion.isEqualTo('prefix01')
          ..isImportPrefix,
      ]);
    } else {
      check(response).suggestions.includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('prefix01')
          ..isImportPrefix,
      ]);
    }
  }

  Future<void> test_importPrefix_dot() async {
    await addProjectFile('lib/a.dart', r'''
enum MyEnum { v }
''');

    var response = await getTestCodeSuggestions('''
import 'a.dart' as prefix;

void f() {
  prefix.^
}
''');

    check(response).hasEmptyReplacement();

    check(response).suggestions
      ..includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('MyEnum')
          ..isEnum,
      ])
      // TODO(scheglov) This is wrong.
      // Should include constants, as [test_nothing_imported_withPrefix] does.
      ..excludesAll([
        (suggestion) => suggestion.isEnumConstant,
      ]);
  }

  Future<void> test_nothing() async {
    await _check_locations(
      declaration: 'enum MyEnum { v }',
      codeAtCompletion: '^',
      validator: (response) {
        check(response).hasEmptyReplacement();

        check(response).suggestions
          ..includesAll([
            (suggestion) => suggestion
              ..completion.isEqualTo('MyEnum')
              ..isEnum,
            (suggestion) => suggestion
              ..completion.isEqualTo('MyEnum.v')
              ..isEnumConstant,
          ])
          ..excludesAll([
            (suggestion) => suggestion
              ..completion.startsWith('MyEnum')
              ..isConstructorInvocation,
          ]);
      },
    );
  }

  Future<void> test_nothing_imported_withPrefix() async {
    await addProjectFile('lib/a.dart', r'''
enum MyEnum { v }
''');

    var response = await getTestCodeSuggestions('''
import 'a.dart' as prefix;

void f() {
  ^
}
''');

    check(response).hasEmptyReplacement();

    if (isProtocolVersion2) {
      check(response).suggestions.includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('prefix.MyEnum')
          ..isEnum,
        (suggestion) => suggestion
          ..completion.isEqualTo('prefix.MyEnum.v')
          ..isEnumConstant,
      ]);
    } else {
      // TODO(scheglov) This is wrong.
      check(response).suggestions.includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('MyEnum')
          ..isEnum,
        (suggestion) => suggestion
          ..completion.isEqualTo('MyEnum.v')
          ..isEnumConstant,
      ]);
    }
  }

  Future<void> _check_locations({
    required String declaration,
    required String codeAtCompletion,
    required void Function(CompletionResponseForTesting response) validator,
  }) async {
    // local
    {
      var response = await getTestCodeSuggestions('''
$declaration
void f() {
  $codeAtCompletion
}
''');
      validator(response);
    }

    // imported
    {
      await addProjectFile('lib/a.dart', '''
$declaration
''');
      var response = await getTestCodeSuggestions('''
import 'a.dart';
void f() {
  $codeAtCompletion
}
''');
      validator(response);
    }

    // not imported
    {
      await addProjectFile('lib/a.dart', '''
$declaration
''');
      var response = await getTestCodeSuggestions('''
void f() {
  $codeAtCompletion
}
''');
      validator(response);
    }
  }
}
