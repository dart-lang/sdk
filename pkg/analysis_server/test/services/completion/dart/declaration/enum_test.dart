// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';
import '../completion_printer.dart' as printer;

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
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) => true,
    );
  }

  Future<void> test_enumConstantName() async {
    await _check_locations(
      declaration: '''
enum MyEnum { foo01 }
enum OtherEnum { foo02 }
''',
      declarationForContextType: 'void useMyEnum(MyEnum _) {}',
      codeAtCompletion: 'useMyEnum(foo0^);',
      validator: (response, context) {
        if (isProtocolVersion2) {
          assertResponseText(response, r'''
replacement
  left: 4
suggestions
  MyEnum.foo01
    kind: enumConstant
''');
        } else {
          _configureWithMyEnum();
          // The response includes much more, such as `MyEnum` itself.
          // We don't expect though that the client will show it.
          if (context == _Context.local) {
            assertResponseText(response, r'''
replacement
  left: 4
suggestions
  MyEnum
    kind: enum
  MyEnum.foo01
    kind: enumConstant
''');
          }
        }
      },
    );
  }

  Future<void> test_enumConstantName_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum MyEnum { foo01 }
enum OtherEnum { foo02 }
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    var response = await getTestCodeSuggestions('''
import 'a.dart' as prefix;

void useMyEnum(prefix.MyEnum _) {}

void f() {
  useMyEnum(foo0^);
}
''');

    if (isProtocolVersion2) {
      assertResponseText(response, r'''
replacement
  left: 4
suggestions
  prefix.MyEnum.foo01
    kind: enumConstant
''');
    } else {
      _configureWithMyEnum();
      // TODO(scheglov) This is wrong.
      assertResponseText(response, r'''
replacement
  left: 4
suggestions
  MyEnum
    kind: enum
  MyEnum.foo01
    kind: enumConstant
  OtherEnum.foo02
    kind: enumConstant
''');
    }
  }

  Future<void> test_enumName() async {
    await _check_locations(
      declaration: 'enum MyEnum { foo01 }',
      codeAtCompletion: 'MyEnu^',
      validator: (response, context) {
        if (isProtocolVersion2) {
          // No enum constants.
          assertResponseText(response, r'''
replacement
  left: 5
suggestions
  MyEnum
    kind: enum
''');
        } else {
          _configureWithMyEnum();
          switch (context) {
            case _Context.local:
              assertResponseText(response, r'''
replacement
  left: 5
suggestions
  MyEnum
    kind: enum
''');
              break;
            case _Context.imported:
            case _Context.notImported:
              assertResponseText(response, r'''
replacement
  left: 5
suggestions
  MyEnum
    kind: enum
  MyEnum.foo01
    kind: enumConstant
''');
              break;
          }
        }
      },
    );
  }

  Future<void> test_enumName_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum MyEnum { foo01 }
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    var response = await getTestCodeSuggestions('''
import 'a.dart' as prefix;

void f() {
  MyEnu^
}
''');

    if (isProtocolVersion2) {
      assertResponseText(response, r'''
replacement
  left: 5
suggestions
  prefix.MyEnum
    kind: enum
''');
    } else {
      _configureWithMyEnum();
      // TODO(scheglov) This is wrong.
      assertResponseText(response, r'''
replacement
  left: 5
suggestions
  MyEnum
    kind: enum
  MyEnum.foo01
    kind: enumConstant
''');
    }
  }

  Future<void> test_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum MyEnum { v }
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    var response = await getTestCodeSuggestions('''
import 'a.dart' as prefix01;

void f() {
  prefix0^
}
''');

    if (isProtocolVersion2) {
      // TODO(scheglov) The kind should be a prefix.
      assertResponseText(response, r'''
replacement
  left: 7
suggestions
  prefix01
    kind: library
''');
    } else {
      _configureWithMyEnum();
      // TODO(scheglov) This is wrong.
      assertResponseText(response, r'''
replacement
  left: 7
suggestions
  MyEnum
    kind: enum
  MyEnum.v
    kind: enumConstant
''');
    }
  }

  Future<void> test_importPrefix_dot() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum MyEnum { v }
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    var response = await getTestCodeSuggestions('''
import 'a.dart' as prefix;

void f() {
  prefix.^
}
''');

    // TODO(scheglov) This is wrong.
    // Should include constants, as [test_nothing_imported_withPrefix] does.
    assertResponseText(response, r'''
suggestions
  MyEnum
    kind: enum
''');
  }

  Future<void> test_nothing() async {
    _configureWithMyEnum();

    await _check_locations(
      declaration: 'enum MyEnum { foo01 }',
      declarationForContextType: 'void useMyEnum(MyEnum _) {}',
      codeAtCompletion: 'useMyEnum(^);',
      validator: (response, context) {
        if (isProtocolVersion2) {
          assertResponseText(response, r'''
suggestions
  MyEnum
    kind: enum
  MyEnum.foo01
    kind: enumConstant
''');
        } else {
          switch (context) {
            case _Context.local:
            case _Context.imported:
              assertResponseText(response, r'''
suggestions
  MyEnum
    kind: enum
  MyEnum.foo01
    kind: enumConstant
''');
              break;
            case _Context.notImported:
              assertResponseText(response, r'''
suggestions
  MyEnum
    kind: enum
  MyEnum.foo01
    kind: enumConstant
  useMyEnum
    kind: functionInvocation
''');
              break;
          }
        }
      },
    );
  }

  Future<void> test_nothing_imported_withPrefix() async {
    _configureWithMyEnum();

    newFile('$testPackageLibPath/a.dart', r'''
enum MyEnum { foo01 }
''');

    var response = await getTestCodeSuggestions('''
import 'a.dart' as prefix;

void useMyEnum(prefix.MyEnum _) {}

void f() {
  useMyEnum(^);
}
''');

    if (isProtocolVersion2) {
      assertResponseText(response, r'''
suggestions
  prefix.MyEnum
    kind: enum
  prefix.MyEnum.foo01
    kind: enumConstant
''');
    } else {
      // TODO(scheglov) This is wrong.
      assertResponseText(response, r'''
suggestions
  MyEnum
    kind: enum
  MyEnum.foo01
    kind: enumConstant
''');
    }
  }

  Future<void> _check_locations({
    required String declaration,
    String declarationForContextType = '',
    required String codeAtCompletion,
    required void Function(
      CompletionResponseForTesting response,
      _Context context,
    )
        validator,
  }) async {
    // local
    {
      var response = await getTestCodeSuggestions('''
$declaration
$declarationForContextType
void f() {
  $codeAtCompletion
}
''');
      validator(response, _Context.local);
    }

    // imported
    {
      newFile('$testPackageLibPath/a.dart', '''
$declaration
''');
      if (isProtocolVersion1) {
        await waitForSetWithUri('package:test/a.dart');
      }
      var response = await getTestCodeSuggestions('''
import 'a.dart';
$declarationForContextType
void f() {
  $codeAtCompletion
}
''');
      validator(response, _Context.imported);
    }

    // not imported
    {
      newFile('$testPackageLibPath/a.dart', '''
$declaration
''');
      newFile('$testPackageLibPath/context_type.dart', '''
import 'a.dart'; // ignore: unused_import
$declarationForContextType
''');
      if (isProtocolVersion1) {
        await waitForSetWithUri('package:test/a.dart');
      }
      var response = await getTestCodeSuggestions('''
import 'context_type.dart';
void f() {
  $codeAtCompletion
}
''');
      validator(response, _Context.notImported);
    }
  }

  void _configureWithMyEnum() {
    printerConfiguration.filter = (suggestion) {
      final completion = suggestion.completion;
      return completion.contains('MyEnum') || completion.contains('foo0');
    };
  }
}

enum _Context { local, imported, notImported }
