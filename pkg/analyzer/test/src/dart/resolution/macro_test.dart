// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/summary2/macro_application.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/test_support.dart';
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
import 'package:macros/macros.dart';

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
          'Macro application failed due to a bug in the macro.',
        ],
        contextMessages: [
          ExpectedContextMessage(testFile, 18, 10, textContains: [
            'package:test/a.dart',
            'MyMacro',
            'unresolved',
          ]),
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
        contextMessages: [message(testFile, 23, 34), message(testFile, 78, 34)],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        78,
        34,
        messageContains: ["'A1'"],
        contextMessages: [message(testFile, 23, 34), message(testFile, 78, 34)],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        133,
        34,
        messageContains: ["'A1'"],
        contextMessages: [message(testFile, 23, 34), message(testFile, 78, 34)],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        175,
        34,
        messageContains: ["'A2'"],
        contextMessages: [message(testFile, 23, 34), message(testFile, 78, 34)],
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
        contextMessages: [message(testFile, 23, 28), message(testFile, 72, 28)],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        72,
        28,
        messageContains: ["'A1'"],
        contextMessages: [message(testFile, 23, 28), message(testFile, 72, 28)],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        121,
        28,
        messageContains: ["'A1'"],
        contextMessages: [message(testFile, 23, 28), message(testFile, 72, 28)],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        157,
        28,
        messageContains: ["'A2'"],
        contextMessages: [message(testFile, 23, 28), message(testFile, 72, 28)],
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
        contextMessages: [message(testFile, 23, 29), message(testFile, 73, 29)],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        73,
        29,
        messageContains: ["'A1'"],
        contextMessages: [message(testFile, 23, 29), message(testFile, 73, 29)],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        123,
        29,
        messageContains: ["'A1'"],
        contextMessages: [message(testFile, 23, 29), message(testFile, 73, 29)],
      ),
      error(
        CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
        160,
        29,
        messageContains: ["'A2'"],
        contextMessages: [message(testFile, 23, 29), message(testFile, 73, 29)],
      ),
    ]);
  }

  test_diagnostic_definitionApplication_sameLibrary() async {
    await assertErrorsInCode('''
import 'package:macros/macros.dart';

macro class MyMacro implements ClassDefinitionMacro {
  const MyMacro();

  @override
  buildDefinitionForClass(declaration, builder) async {}
}

@MyMacro()
class A {}
''', [
      error(
          CompileTimeErrorCode.MACRO_DEFINITION_APPLICATION_SAME_LIBRARY_CYCLE,
          185,
          7),
    ]);
  }

  test_diagnostic_definitionApplication_sameLibraryCycle() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:macros/macros.dart';
import 'test.dart';

macro class MyMacro implements ClassDefinitionMacro {
  const MyMacro();

  @override
  buildDefinitionForClass(declaration, builder) async {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

@MyMacro()
class A {}
''', [
      error(
          CompileTimeErrorCode.MACRO_DEFINITION_APPLICATION_SAME_LIBRARY_CYCLE,
          19,
          7),
    ]);
  }

  test_diagnostic_invalidTarget_wantsClassOrMixin_hasFunction() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@TargetClassOrMixinMacro()
void f() {}
''', [
      error(CompileTimeErrorCode.INVALID_MACRO_APPLICATION_TARGET, 27, 26),
    ]);
  }

  test_diagnostic_invalidTarget_wantsClassOrMixin_hasLibrary() async {
    await assertErrorsInCode('''
@TargetClassOrMixinMacro()
library;

import 'diagnostic.dart';
''', [
      error(CompileTimeErrorCode.INVALID_MACRO_APPLICATION_TARGET, 0, 26),
    ]);
  }

  test_diagnostic_notAllowedDeclaration_declarations_class() async {
    await assertErrorsInCode('''
import 'append.dart';

class A {
  @DeclareInLibrary('class B {}')
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.MACRO_NOT_ALLOWED_DECLARATION, 35, 31),
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

  test_diagnostic_report_argumentError_instanceCreation() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@MacroWithArguments(0, const Object())
class A {}
''', [
      error(CompileTimeErrorCode.MACRO_APPLICATION_ARGUMENT_ERROR, 50, 14),
    ]);
  }

  test_diagnostic_report_atDeclaration_class_error() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportErrorAtTargetDeclaration()
class A {}
''', [
      error(CompileTimeErrorCode.MACRO_ERROR, 67, 1,
          correctionContains: 'Correction message'),
    ]);
  }

  test_diagnostic_report_atDeclaration_class_info() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportInfoAtTargetDeclaration()
class A {}
''', [
      error(HintCode.MACRO_INFO, 66, 1,
          correctionContains: 'Correction message'),
    ]);
  }

  test_diagnostic_report_atDeclaration_class_warning() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTargetDeclaration()
class A {}
''', [
      error(WarningCode.MACRO_WARNING, 62, 1,
          correctionContains: 'Correction message'),
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

  test_diagnostic_report_atTypeAnnotation_class_constructor_formalParameter_positional_super_typed() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  final int foo;
  A(int this.foo);
}

class B extends A {
  @ReportAtTypeAnnotation([
    'positionalFormalParameterType 0',
  ])
  B(int super.foo);
}
''', [
      error(WarningCode.MACRO_WARNING, 172, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_class_constructor_formalParameter_positional_super_untyped() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  final int foo;
  A(int this.foo);
}

class B extends A {
  @ReportAtTypeAnnotation([
    'positionalFormalParameterType 0',
  ])
  B(super.foo);
}
''', [
      error(WarningCode.MACRO_WARNING, 178, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_class_constructor_formalParameter_positional_this_typed() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  final int foo;
  @ReportAtTypeAnnotation([
    'positionalFormalParameterType 0',
  ])
  A(int this.foo);
}
''', [
      error(WarningCode.MACRO_WARNING, 130, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_class_constructor_formalParameter_positional_this_untyped() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  final int foo;
  @ReportAtTypeAnnotation([
    'positionalFormalParameterType 0',
  ])
  A(this.foo);
}
''', [
      error(WarningCode.MACRO_WARNING, 135, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_class_extends() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'superclass',
])
class A extends Object {}
''', [
      error(WarningCode.MACRO_WARNING, 88, 6),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_field_type() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'variableType',
  ])
  int foo = 0;
}
''', [
      error(WarningCode.MACRO_WARNING, 92, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_function_formalParameter_named() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'namedFormalParameterType 0',
])
void foo(int a, {String? b, bool? c}) {}
''', [
      error(WarningCode.MACRO_WARNING, 105, 7),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_function_formalParameter_positional() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'positionalFormalParameterType 1',
])
void foo(int a, String b) {}
''', [
      error(WarningCode.MACRO_WARNING, 109, 6),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_function_returnType() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
])
int foo() => 0;
''', [
      error(WarningCode.MACRO_WARNING, 72, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_functionType_formalParameter_named() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
  'namedFormalParameterType 1',
])
int Function(bool a, {int b, String c}) foo() => throw 0;
''', [
      error(WarningCode.MACRO_WARNING, 133, 6),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_functionType_formalParameter_positional() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
  'positionalFormalParameterType 1',
])
int Function(int a, String b) foo() => throw 0;
''', [
      error(WarningCode.MACRO_WARNING, 129, 6),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_functionType_formalParameter_positional2() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
  'positionalFormalParameterType 1',
])
int Function(int, String) foo() => throw 0;
''', [
      error(WarningCode.MACRO_WARNING, 127, 6),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_functionType_returnType() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
  'returnType',
])
int Function() foo() => throw 0;
''', [
      error(WarningCode.MACRO_WARNING, 88, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_kind_functionType() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
])
void Function() foo() => throw 0;
''', [
      error(WarningCode.MACRO_WARNING, 72, 15),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_kind_omittedType_fieldType() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'variableType',
  ])
  final foo = 0;
}
''', [
      error(WarningCode.MACRO_WARNING, 98, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_kind_omittedType_formalParameterType() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'positionalFormalParameterType 0',
])
void foo(a) {}
''', [
      error(WarningCode.MACRO_WARNING, 102, 1),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_kind_omittedType_functionReturnType() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
])
foo() => throw 0;
''', [
      error(WarningCode.MACRO_WARNING, 72, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_kind_omittedType_methodReturnType() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'returnType',
  ])
  foo() => throw 0;
}
''', [
      error(WarningCode.MACRO_WARNING, 90, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_kind_omittedType_topLevelVariableType() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'variableType',
])
final foo = 0;
''', [
      error(WarningCode.MACRO_WARNING, 80, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_kind_recordType() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
])
(int, String) foo() => throw 0;
''', [
      error(WarningCode.MACRO_WARNING, 72, 13),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_method_formalParameter_positional() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'positionalFormalParameterType 1',
  ])
  void foo(int a, String b) {}
}
''', [
      error(WarningCode.MACRO_WARNING, 127, 6),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_method_returnType() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'returnType',
  ])
  int foo() => 0;
}
''', [
      error(WarningCode.MACRO_WARNING, 90, 3),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_namedTypeArgument() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
  'namedTypeArgument 1',
])
Map<int, String> foo() => throw 0;
''', [
      error(WarningCode.MACRO_WARNING, 106, 6),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_notFileOfMacroApplication() async {
    newFile(testFile.path, '''
import 'append.dart';
import 'diagnostic.dart'; // ignore: unused_import

class A {
  @DeclareInType("""
  @{{package:test/diagnostic.dart@ReportAtTypeAnnotation}}([
    'field foo',
  ])
  void starter() {}""")
  final int foo = 0;
}
''');

    var session = contextFor(testFile).currentSession;
    var result = await session.getResolvedLibrary(testFile.path);

    // The diagnostic is reported on the field, declared in the user code,
    // not on the macro application generated by other macro application
    // into a library augmentation.
    assertResolvedLibraryResultText(result, configure: (configuration) {
      configuration.unitConfiguration.withContentPredicate = (unitResult) {
        return unitResult.isMacroPart;
      };
    }, r'''
ResolvedLibraryResult #0
  element: <testLibrary>
  units
    ResolvedUnitResult #1
      path: /home/test/lib/test.dart
      uri: package:test/test.dart
      flags: exists isLibrary
      errors
        220 +3 MACRO_WARNING
    ResolvedUnitResult #2
      path: /home/test/lib/test.macro.dart
      uri: package:test/test.macro.dart
      flags: exists isMacroPart isPart
      content
---
part of 'package:test/test.dart';

import 'package:test/diagnostic.dart' as prefix0;

augment class A {
  @prefix0.ReportAtTypeAnnotation([
    'field foo',
  ])
  void starter() {}
}
---
''');
  }

  test_diagnostic_report_atTypeAnnotation_record_namedField() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'variableType',
    'namedField 1',
  ])
  final (bool, {int a, String b})? foo = null;
}
''', [
      error(WarningCode.MACRO_WARNING, 133, 6),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_record_positionalField() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'variableType',
    'positionalField 1',
  ])
  final (int, String)? foo = null;
}
''', [
      error(WarningCode.MACRO_WARNING, 129, 6),
    ]);
  }

  test_diagnostic_report_atTypeAnnotation_typeAlias_aliasedType() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'aliasedType',
])
typedef A = List<int>;
''', [
      error(WarningCode.MACRO_WARNING, 85, 9),
    ]);
  }

  test_diagnostic_report_contextMessages_superClassMethods() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
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
      error(WarningCode.MACRO_WARNING, 98, 1,
          contextMessages: [message(a, 17, 3), message(a, 33, 3)]),
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
        message(testFile, 73, 3),
        message(testFile, 89, 3)
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
      error(
        WarningCode.MACRO_WARNING,
        27,
        56,
        contextMessages: [message(testFile, 101, 3), message(testFile, 117, 3)],
        correctionContains: 'Correction message',
      ),
    ]);
  }

  test_diagnostic_report_internalException_declarationsPhase() async {
    LibraryMacroApplier.testThrowExceptionDeclarations = true;
    try {
      await assertErrorsInCode('''
import 'diagnostic.dart';

@NothingMacro()
class A {}
''', [
        error(CompileTimeErrorCode.MACRO_INTERNAL_EXCEPTION, 27, 15),
      ]);
    } finally {
      LibraryMacroApplier.testThrowExceptionDeclarations = false;
    }
  }

  test_diagnostic_report_internalException_definitionsPhase() async {
    LibraryMacroApplier.testThrowExceptionDefinitions = true;
    try {
      await assertErrorsInCode('''
import 'diagnostic.dart';

@NothingMacro()
class A {}
''', [
        error(CompileTimeErrorCode.MACRO_INTERNAL_EXCEPTION, 27, 15),
      ]);
    } finally {
      LibraryMacroApplier.testThrowExceptionDefinitions = false;
    }
  }

  test_diagnostic_report_internalException_typesPhase() async {
    LibraryMacroApplier.testThrowExceptionTypes = true;
    try {
      await assertErrorsInCode('''
import 'diagnostic.dart';

@NothingMacro()
class A {}
''', [
        error(CompileTimeErrorCode.MACRO_INTERNAL_EXCEPTION, 27, 15),
      ]);
    } finally {
      LibraryMacroApplier.testThrowExceptionTypes = false;
    }
  }

  test_diagnostic_throwsException() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:macros/macros.dart';

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
          'Macro application failed due to a bug in the macro.'
        ],
        contextMessages: [
          ExpectedContextMessage(testFile, 18, 10, textContains: [
            'package:test/a.dart',
            '12345',
            'MyMacro',
          ]),
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

    var session = contextFor(testFile).currentSession;
    var result = await session.getResolvedLibrary(testFile.path);

    assertResolvedLibraryResultText(result, r'''
ResolvedLibraryResult #0
  element: <testLibrary>
  units
    ResolvedUnitResult #1
      path: /home/test/lib/test.dart
      uri: package:test/test.dart
      flags: exists isLibrary
    ResolvedUnitResult #2
      path: /home/test/lib/test.macro.dart
      uri: package:test/test.macro.dart
      flags: exists isMacroPart isPart
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

    var session = contextFor(testFile).currentSession;
    var result = await session.getResolvedLibrary(testFile.path);

    // 1. Has the macro augmentation unit.
    // 2. It has an error reported.
    assertResolvedLibraryResultText(result, configure: (configuration) {
      configuration.unitConfiguration
        ..nodeSelector = (unitResult) {
          if (unitResult.isMacroPart) {
            return unitResult.findNode.namedType('NotType');
          }
          return null;
        }
        ..withContentPredicate = (unitResult) {
          return unitResult.isMacroPart;
        };
    }, r'''
ResolvedLibraryResult #0
  element: <testLibrary>
  units
    ResolvedUnitResult #1
      path: /home/test/lib/test.dart
      uri: package:test/test.dart
      flags: exists isLibrary
    ResolvedUnitResult #2
      path: /home/test/lib/test.macro.dart
      uri: package:test/test.macro.dart
      flags: exists isMacroPart isPart
      content
---
part of 'package:test/test.dart';

augment class A {
  NotType foo() {}
}
---
      errors
        55 +7 UNDEFINED_CLASS
      selectedNode: NamedType
        name: NotType
        element: <null>
        element2: <null>
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

    var session = contextFor(testFile).currentSession;
    var result = await session.getResolvedLibrary(testFile.path);

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
          return unitResult.isMacroPart;
        };
    }, r'''
ResolvedLibraryResult #0
  element: <testLibrary>
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
              staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x#element
              staticType: int
            semicolon: ;
        rightBracket: }
    ResolvedUnitResult #2
      path: /home/test/lib/test.macro.dart
      uri: package:test/test.macro.dart
      flags: exists isMacroPart isPart
      content
---
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

prefix0.int get x => 0;
---
''');
  }

  test_macroDiagnostics_report_atAnnotation_identifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await assertErrorsInCode(r'''
import 'diagnostic.dart';
import 'a.dart';

@ReportAtTargetAnnotation(1)
@a
class X {}
''', [
      error(WarningCode.MACRO_WARNING, 73, 2),
    ]);
  }

  test_macroDiagnostics_report_atDeclaration_class_method_typeParameter() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtDeclaration([
    'typeParameter 0',
  ])
  void foo<T>() {}
}
''', [
      error(WarningCode.MACRO_WARNING, 101, 1),
    ]);
  }

  test_macroDiagnostics_report_atDeclaration_class_typeParameter() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtDeclaration([
  'typeParameter 1',
])
class A<T, U, V> {}
''', [
      error(WarningCode.MACRO_WARNING, 85, 1),
    ]);
  }

  test_macroDiagnostics_report_atDeclaration_function_typeParameter() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtDeclaration([
  'typeParameter 0',
])
void foo<T>() {}
''', [
      error(WarningCode.MACRO_WARNING, 83, 1),
    ]);
  }

  test_macroDiagnostics_report_atDeclaration_mixin_typeParameter() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtDeclaration([
  'typeParameter 0',
])
mixin A<T> {}
''', [
      error(WarningCode.MACRO_WARNING, 82, 1),
    ]);
  }

  test_macroDiagnostics_report_atDeclaration_typeAlias_typeParameter() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtDeclaration([
  'typeParameter 0',
])
typedef A<T> = List<T>;
''', [
      error(WarningCode.MACRO_WARNING, 84, 1),
    ]);
  }

  /// Test that macros are compiled using the packages file of the package
  /// that uses the macro.
  test_macroInPackage() async {
    var myMacroRootPath = '$workspaceRootPath/my_macro';
    writePackageConfig(
      myMacroRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'my_macro', rootPath: myMacroRootPath),
    );

    newAnalysisOptionsYamlFile(
      myMacroRootPath,
      analysisOptionsContent(experiments: experiments),
    );

    newFile(
      '$myMacroRootPath/lib/append.dart',
      getMacroCode('append.dart'),
    );

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'my_macro', rootPath: myMacroRootPath),
      macrosEnvironment: MacrosEnvironment.instance,
    );

    await assertNoErrorsInCode(r'''
import 'package:my_macro/append.dart';

@DeclareType('B', 'class B {}')
class A {}

void f(B b) {}
''');
  }

  test_withLints() async {
    writeTestPackageAnalysisOptionsFile(analysisOptionsContent(
      rules: ['unnecessary_this'],
      experiments: ['enhanced-parts', 'macros'],
    ));

    /// A macro that will produce an augmented class with `unnecessary_this`
    /// violations.
    var macroFile = newFile(
      '$testPackageLibPath/auto_to_string.dart',
      getMacroCode('example/auto_to_string.dart'),
    );
    await assertErrorsInFile2(macroFile, []);

    var testFile = newFile('$testPackageLibPath/test.dart', r'''
import 'auto_to_string.dart';

@AutoToString()
class User {
  final String name;
  final int age;
  User(this.name, this.age);
}
''');
    await assertErrorsInFile2(testFile, []);

    var macroGeneratedFile = getFile('$testPackageLibPath/test.macro.dart');
    await assertErrorsInFile2(macroGeneratedFile, [
      // No lints.
    ]);
  }
}
