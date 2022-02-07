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

  Future<void> test_unprefixed_imported() async {
    await addProjectFile('lib/a.dart', r'''
enum MyEnum { v }
''');

    var response = await getTestCodeSuggestions('''
import 'a.dart';

void f() {
  ^
}
''');

    _checkUnprefixed(response);
  }

  Future<void> test_unprefixed_local() async {
    var response = await getTestCodeSuggestions('''
enum MyEnum { v }

void f() {
  ^
}
''');

    _checkUnprefixed(response);
  }

  Future<void> test_unprefixed_notImported() async {
    await addProjectFile('lib/a.dart', r'''
enum MyEnum { v }
''');

    var response = await getTestCodeSuggestions('''
void f() {
  ^
}
''');

    _checkUnprefixed(response);
  }

  void _checkUnprefixed(CompletionResponseForTesting response) {
    check(response).suggestions
      ..includesAll([
        (suggestion) => suggestion.completion.isEqualTo('MyEnum.v'),
      ])
      ..excludesAll([
        (suggestion) => suggestion
          ..completion.startsWith('MyEnum')
          ..isConstructorInvocation,
      ]);
  }
}
