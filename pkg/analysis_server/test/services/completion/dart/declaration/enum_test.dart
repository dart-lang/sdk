// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  @failingTest
  Future<void> test_inside_implicitThis_constants() async {
    await computeSuggestions('''
enum E {
  a1, a2;

  void f() {
    a^;
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  a1
    kind: enumConstant
  a2
    kind: enumConstant
''');
  }

  Future<void> test_inside_implicitThis_getter() async {
    await computeSuggestions('''
enum E {
  v;

  int get a1 => 0;

  void f() {
    a^;
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  a1
    kind: getter
''');
  }

  Future<void> test_inside_implicitThis_method() async {
    await computeSuggestions('''
enum E {
  v;

  void a1() {}

  void f() {
    a^;
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  a1
    kind: methodInvocation
''');
  }
}

mixin EnumTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  @override
  Future<void> setUp() async {
    await super.setUp();
    allowedIdentifiers = {'values'};
  }

  Future<void> test_afterCascade() async {
    await computeSuggestions('''
enum E {
  o0, t0
}
void f() {
  E..^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterCascade_partial() async {
    await computeSuggestions('''
enum E {
  o0, t0
}
void f() {
  E..o^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_afterPeriod() async {
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0.^
}
''');
    assertResponse(r'''
suggestions
  o0
    kind: enumConstant
  t0
    kind: enumConstant
  values
    kind: field
''');
  }

  Future<void> test_afterPeriod_beforeStatement() async {
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0.^
  int g;
}
''');
    assertResponse(r'''
suggestions
  o0
    kind: enumConstant
  t0
    kind: enumConstant
  values
    kind: field
''');
  }

  Future<void> test_afterPeriod_deprecated() async {
    await computeSuggestions('''
@deprecated enum E0 {
  o0, t0
}
void f() {
  E0.^
}
''');
    assertResponse(r'''
suggestions
  o0
    kind: enumConstant
    deprecated: true
  t0
    kind: enumConstant
    deprecated: true
  values
    kind: field
    deprecated: true
''');
  }

  Future<void> test_afterPeriod_partial() async {
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0.o^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  o0
    kind: enumConstant
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  o0
    kind: enumConstant
  t0
    kind: enumConstant
  values
    kind: field
''');
    }
  }

  Future<void> test_afterPeriod_throughTypedef() async {
    newFile('$testPackageLibPath/a.dart', '''
enum E0 {
  a0,
  _b0,
  c0
}
void f() {
  E0._b0;
}
''');
    await computeSuggestions('''
import 'a.dart';

typedef A = E0;

void f() {
  A.^;
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: enumConstant
  c0
    kind: enumConstant
  values
    kind: field
''');
  }

  Future<void> test_betweenPeriods() async {
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0.^.
}
''');
    assertResponse(r'''
suggestions
  o0
    kind: enumConstant
  t0
    kind: enumConstant
  values
    kind: field
''');
  }

  Future<void> test_betweenPeriods_partial() async {
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0.^.o
}
''');
    assertResponse(r'''
suggestions
  o0
    kind: enumConstant
  t0
    kind: enumConstant
  values
    kind: field
''');
  }

  Future<void> test_enumConstantName() async {
    await _check_locations(
      declaration: '''
enum E0 { foo01 }
enum E1 { foo02 }
''',
      declarationForContextType: 'void useMyEnum(E0 _) {}',
      codeAtCompletion: 'useMyEnum(foo0^);',
      validator: (response, context) {
        if (isProtocolVersion2) {
          assertResponse(r'''
replacement
  left: 4
suggestions
  E0.foo01
    kind: enumConstant
''');
        } else {
          _configureWithMyEnum();
          // The response includes much more, such as `MyEnum` itself.
          // We don't expect though that the client will show it.
          if (context == _Context.local) {
            assertResponse(r'''
replacement
  left: 4
suggestions
  E0.foo01
    kind: enumConstant
''');
          }
        }
      },
    );
  }

  Future<void> test_enumConstantName_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E0 { foo01 }
enum E1 { foo02 }
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    await computeSuggestions('''
import 'a.dart' as p0;

void useMyEnum(p0.E0 _) {}

void f() {
  useMyEnum(foo0^);
}
''');

    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 4
suggestions
  p0.E0.foo01
    kind: enumConstant
''');
    } else {
      _configureWithMyEnum();
      // TODO(scheglov) This is wrong.
      assertResponse(r'''
replacement
  left: 4
suggestions
  E0.foo01
    kind: enumConstant
  E1.foo02
    kind: enumConstant
''');
    }
  }

  Future<void> test_enumName() async {
    await _check_locations(
      declaration: 'enum E0 { foo01 }',
      codeAtCompletion: 'E^',
      referencesDeclaration: false,
      validator: (response, context) {
        if (isProtocolVersion2) {
          // No enum constants.
          assertResponse(r'''
replacement
  left: 1
suggestions
  E0
    kind: enum
''');
        } else {
          _configureWithMyEnum();
          switch (context) {
            case _Context.local:
              assertResponse(r'''
replacement
  left: 1
suggestions
''');
            case _Context.imported:
            case _Context.notImported:
              assertResponse(r'''
replacement
  left: 1
suggestions
  E0.foo01
    kind: enumConstant
''');
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

    await computeSuggestions('''
import 'a.dart' as p0;

void f() {
  MyEnu^
}
''');

    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 5
suggestions
  p0.MyEnum
    kind: enum
''');
    } else {
      _configureWithMyEnum();
      // TODO(scheglov) This is wrong.
      assertResponse(r'''
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

    await computeSuggestions('''
import 'a.dart' as p0;

void f() {
  p0^
}
''');

    if (isProtocolVersion2) {
      // TODO(scheglov) The kind should be a prefix.
      assertResponse(r'''
replacement
  left: 2
suggestions
  p0
    kind: library
''');
    } else {
      _configureWithMyEnum();
      // TODO(scheglov) This is wrong.
      assertResponse(r'''
replacement
  left: 2
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
enum E0 { v }
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    await computeSuggestions('''
import 'a.dart' as p0;

void f() {
  p0.^
}
''');

    // TODO(scheglov) This is wrong.
    // Should include constants, as [test_nothing_imported_withPrefix] does.
    assertResponse(r'''
suggestions
  E0
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
          assertResponse(r'''
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
              assertResponse(r'''
suggestions
  MyEnum
    kind: enum
  MyEnum.foo01
    kind: enumConstant
''');
            case _Context.notImported:
              assertResponse(r'''
suggestions
  MyEnum
    kind: enum
  MyEnum.foo01
    kind: enumConstant
  useMyEnum
    kind: functionInvocation
''');
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

    await computeSuggestions('''
import 'a.dart' as p0;

void useMyEnum(p0.MyEnum _) {}

void f() {
  useMyEnum(^);
}
''');

    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  p0.MyEnum
    kind: enum
  p0.MyEnum.foo01
    kind: enumConstant
''');
    } else {
      // TODO(scheglov) This is wrong.
      assertResponse(r'''
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
    bool referencesDeclaration = true,
    required void Function(
      CompletionResponseForTesting response,
      _Context context,
    ) validator,
  }) async {
    // local
    {
      await computeSuggestions('''
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
      await computeSuggestions('''
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
import 'a.dart';${referencesDeclaration ? '' : ' // ignore: unused_import'}
$declarationForContextType
''');
      if (isProtocolVersion1) {
        await waitForSetWithUri('package:test/a.dart');
      }
      await computeSuggestions('''
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
