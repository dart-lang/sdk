// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../summary/macros_environment.dart';
import 'context_collection_resolution.dart';
import 'resolution.dart';

main() {
  try {
    MacrosEnvironment.instance;
  } catch (_) {
    print('Cannot initialize environment. Skip macros tests.');
    return;
  }

  defineReflectiveSuite(() {
    defineReflectiveTests(MacroResolutionTest);
  });
}

@reflectiveTest
class MacroResolutionTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
    );

    newFile(
      '$testPackageLibPath/append.dart',
      getMacroCode('append.dart'),
    );

    newFile(
      '$testPackageLibPath/diagnostic.dart',
      getMacroCode('diagnostic.dart'),
    );

    newFile(
      '$testPackageLibPath/order.dart',
      getMacroCode('order.dart'),
    );

    newFile(
      '$testPackageLibPath/json_serializable.dart',
      getMacroCode('example/json_serializable.dart'),
    );
  }

  test_declareType_class() async {
    await assertNoErrorsInCode(r'''
import 'append.dart';

@DeclareType('B', 'class B {}')
class A {}

void f(B b) {}
''');
  }

  test_diagnostic_compilesWithError() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    unresolved;
  }
}
''');

    await assertErrorsInCode('''
import 'a.dart';

@MyMacro()
class A {}
''', [
      error(
        CompileTimeErrorCode.MACRO_ERROR,
        18,
        10,
        messageContains: [
          'Unhandled error',
          'package:test/a.dart',
          'unresolved',
          'MyMacro',
        ],
      ),
    ]);
  }

  test_diagnostic_cycle_class_constructorsOf() async {
    // Note, the errors are also reported when introspecting `A1` and `A2`
    // during running macro applications on `A3`, because we know that
    // `A1` and `A2` declarations are incomplete.
    await assertErrorsInCode('''
import 'order.dart';

@DeclarationsIntrospectConstructors('A2')
class A1 {}

@DeclarationsIntrospectConstructors('A1')
class A2 {}

@DeclarationsIntrospectConstructors('A1')
@DeclarationsIntrospectConstructors('A2')
class A3 {}
''', [
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        23,
        34,
        messageContains: ["'A2'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 34),
          message('/home/test/lib/test.dart', 78, 34)
        ],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        78,
        34,
        messageContains: ["'A1'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 34),
          message('/home/test/lib/test.dart', 78, 34)
        ],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        133,
        34,
        messageContains: ["'A1'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 34),
          message('/home/test/lib/test.dart', 78, 34)
        ],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        175,
        34,
        messageContains: ["'A2'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 34),
          message('/home/test/lib/test.dart', 78, 34)
        ],
      ),
    ]);
  }

  test_diagnostic_cycle_class_fieldsOf() async {
    // Note, the errors are also reported when introspecting `A1` and `A2`
    // during running macro applications on `A3`, because we know that
    // `A1` and `A2` declarations are incomplete.
    await assertErrorsInCode('''
import 'order.dart';

@DeclarationsIntrospectFields('A2')
class A1 {}

@DeclarationsIntrospectFields('A1')
class A2 {}

@DeclarationsIntrospectFields('A1')
@DeclarationsIntrospectFields('A2')
class A3 {}
''', [
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        23,
        28,
        messageContains: ["'A2'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 28),
          message('/home/test/lib/test.dart', 72, 28)
        ],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        72,
        28,
        messageContains: ["'A1'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 28),
          message('/home/test/lib/test.dart', 72, 28)
        ],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        121,
        28,
        messageContains: ["'A1'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 28),
          message('/home/test/lib/test.dart', 72, 28)
        ],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        157,
        28,
        messageContains: ["'A2'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 28),
          message('/home/test/lib/test.dart', 72, 28)
        ],
      ),
    ]);
  }

  test_diagnostic_cycle_class_methodsOf() async {
    // Note, the errors are also reported when introspecting `A1` and `A2`
    // during running macro applications on `A3`, because we know that
    // `A1` and `A2` declarations are incomplete.
    await assertErrorsInCode('''
import 'order.dart';

@DeclarationsIntrospectMethods('A2')
class A1 {}

@DeclarationsIntrospectMethods('A1')
class A2 {}

@DeclarationsIntrospectMethods('A1')
@DeclarationsIntrospectMethods('A2')
class A3 {}
''', [
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        23,
        29,
        messageContains: ["'A2'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 29),
          message('/home/test/lib/test.dart', 73, 29)
        ],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        73,
        29,
        messageContains: ["'A1'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 29),
          message('/home/test/lib/test.dart', 73, 29)
        ],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        123,
        29,
        messageContains: ["'A1'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 29),
          message('/home/test/lib/test.dart', 73, 29)
        ],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        160,
        29,
        messageContains: ["'A2'"],
        contextMessages: [
          message('/home/test/lib/test.dart', 23, 29),
          message('/home/test/lib/test.dart', 73, 29)
        ],
      ),
    ]);
  }

  test_diagnostic_notSupportedArgument() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTargetDeclaration()
  void foo() {}
}
''', [
      error(WarningCode.MACRO_WARNING, 75, 3),
    ]);
  }

  test_diagnostic_report_atDeclaration_class_error() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportErrorAtTargetDeclaration()
class A {}
''', [
      error(CompileTimeErrorCode.MACRO_ERROR, 67, 1),
    ]);
  }

  test_diagnostic_report_atDeclaration_class_info() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportInfoAtTargetDeclaration()
class A {}
''', [
      error(HintCode.MACRO_INFO, 66, 1),
    ]);
  }

  test_diagnostic_report_atDeclaration_class_warning() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTargetDeclaration()
class A {}
''', [
      error(WarningCode.MACRO_WARNING, 62, 1),
    ]);
  }

  test_diagnostic_report_atDeclaration_constructor() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTargetDeclaration()
  A.named();
}
''', [
      error(WarningCode.MACRO_WARNING, 72, 5),
    ]);
  }

  test_diagnostic_report_atDeclaration_field() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTargetDeclaration()
  final foo = 0;
}
''', [
      error(WarningCode.MACRO_WARNING, 76, 3),
    ]);
  }

  test_diagnostic_report_atDeclaration_method() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTargetDeclaration()
  void foo() {}
}
''', [
      error(WarningCode.MACRO_WARNING, 75, 3),
    ]);
  }

  test_diagnostic_report_atDeclaration_mixin() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTargetDeclaration()
mixin A {}
''', [
      error(WarningCode.MACRO_WARNING, 62, 1),
    ]);
  }

  test_diagnostic_report_atTarget_method() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtFirstMethod()
class A {
  void foo() {}
  void bar() {}
}
''', [
      error(WarningCode.MACRO_WARNING, 67, 3),
    ]);
  }

  test_diagnostic_report_contextMessages_superClassMethods() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void foo() {}
  void bar() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';
import 'diagnostic.dart';

@ReportWithContextMessages(forSuperClass: true)
class B extends A {}
''', [
      error(WarningCode.MACRO_WARNING, 98, 1, contextMessages: [
        message('/home/test/lib/a.dart', 17, 3),
        message('/home/test/lib/a.dart', 33, 3)
      ]),
    ]);
  }

  test_diagnostic_report_contextMessages_thisClassMethods() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportWithContextMessages()
class A {
  void foo() {}
  void bar() {}
}
''', [
      error(WarningCode.MACRO_WARNING, 62, 1, contextMessages: [
        message('/home/test/lib/test.dart', 73, 3),
        message('/home/test/lib/test.dart', 89, 3)
      ]),
    ]);
  }

  test_diagnostic_report_contextMessages_thisClassMethods_noTarget() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportWithContextMessages(withDeclarationTarget: false)
class A {
  void foo() {}
  void bar() {}
}
''', [
      error(WarningCode.MACRO_WARNING, 27, 56, contextMessages: [
        message('/home/test/lib/test.dart', 101, 3),
        message('/home/test/lib/test.dart', 117, 3)
      ]),
    ]);
  }

  test_diagnostic_throwsException() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    throw 12345;
  }
}
''');

    await assertErrorsInCode('''
import 'a.dart';

@MyMacro()
class A {}
''', [
      error(
        CompileTimeErrorCode.MACRO_ERROR,
        18,
        10,
        messageContains: [
          'Unhandled error',
          'package:test/a.dart',
          '12345',
          'MyMacro',
        ],
      ),
    ]);
  }

  test_example_jsonSerializable() async {
    newFile(testFile.path, r'''
import 'json_serializable.dart';

void f(Map<String, Object?> json) {
  var user = User.fromJson(json);
  user.toJson();
}

@JsonSerializable()
class User {
  final int age;
  final String name;
}
''');

    final session = contextFor(testFile).currentSession;
    final result = await session.getResolvedLibrary(testFile.path);

    assertResolvedLibraryResultText(result, r'''
ResolvedLibraryResult #0
  element: package:test/test.dart
  units
    ResolvedUnitResult #1
      path: /home/test/lib/test.dart
      uri: package:test/test.dart
      flags: exists isLibrary
    ResolvedUnitResult #2
      path: /home/test/lib/test.macro.dart
      uri: package:test/test.macro.dart
      flags: exists isAugmentation isMacroAugmentation
''');
  }

  test_getResolvedLibrary_macroAugmentation_hasErrors() async {
    newFile(
      '$testPackageLibPath/append.dart',
      getMacroCode('append.dart'),
    );

    newFile('$testPackageLibPath/test.dart', r'''
import 'append.dart';

@DeclareInType('  NotType foo() {}')
class A {}
''');

    final session = contextFor(testFile).currentSession;
    final result = await session.getResolvedLibrary(testFile.path);

    // 1. Has the macro augmentation unit.
    // 2. It has an error reported.
    assertResolvedLibraryResultText(result, configure: (configuration) {
      configuration.unitConfiguration
        ..nodeSelector = (unitResult) {
          if (unitResult.isMacroAugmentation) {
            return unitResult.findNode.namedType('NotType');
          }
          return null;
        }
        ..withContentPredicate = (unitResult) {
          return unitResult.isAugmentation;
        };
    }, r'''
ResolvedLibraryResult #0
  element: package:test/test.dart
  units
    ResolvedUnitResult #1
      path: /home/test/lib/test.dart
      uri: package:test/test.dart
      flags: exists isLibrary
    ResolvedUnitResult #2
      path: /home/test/lib/test.macro.dart
      uri: package:test/test.macro.dart
      flags: exists isAugmentation isMacroAugmentation
      content
---
library augment 'test.dart';

augment class A {
  NotType foo() {}
}
---
      errors
        50 +7 UNDEFINED_CLASS
      selectedNode: NamedType
        name: NotType
        element: <null>
        type: InvalidType
''');
  }

  test_getResolvedLibrary_reference_declaredGetter() async {
    newFile(
      '$testPackageLibPath/append.dart',
      getMacroCode('append.dart'),
    );

    newFile('$testPackageLibPath/test.dart', r'''
import 'append.dart';

@DeclareInLibrary('{{dart:core@int}} get x => 0;')
void f() {
  x;
}
''');

    final session = contextFor(testFile).currentSession;
    final result = await session.getResolvedLibrary(testFile.path);

    // 1. `get x` was declared.
    // 2. The reference to `x` can be resolved in the library unit.
    assertResolvedLibraryResultText(result, configure: (configuration) {
      configuration.unitConfiguration
        ..nodeSelector = (unitResult) {
          switch (unitResult.uriStr) {
            case 'package:test/test.dart':
              return unitResult.findNode.singleBlock;
          }
          return null;
        }
        ..withContentPredicate = (unitResult) {
          return unitResult.isAugmentation;
        };
    }, r'''
ResolvedLibraryResult #0
  element: package:test/test.dart
  units
    ResolvedUnitResult #1
      path: /home/test/lib/test.dart
      uri: package:test/test.dart
      flags: exists isLibrary
      selectedNode: Block
        leftBracket: {
        statements
          ExpressionStatement
            expression: SimpleIdentifier
              token: x
              staticElement: package:test/test.dart::@augmentation::package:test/test.macro.dart::@accessor::x
              staticType: int
            semicolon: ;
        rightBracket: }
    ResolvedUnitResult #2
      path: /home/test/lib/test.macro.dart
      uri: package:test/test.macro.dart
      flags: exists isAugmentation isMacroAugmentation
      content
---
library augment 'test.dart';

import 'dart:core' as prefix0;

prefix0.int get x => 0;
---
''');
  }
}
