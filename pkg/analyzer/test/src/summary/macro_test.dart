// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/node_text_expectations.dart';
import 'elements_base.dart';
import 'macros_environment.dart';

main() {
  try {
    MacrosEnvironment.instance;
  } catch (_) {
    print('Cannot initialize environment. Skip macros tests.');
    test('fake', () {});
    return;
  }

  defineReflectiveSuite(() {
    defineReflectiveTests(MacroArgumentsTest);
    defineReflectiveTests(MacroTypesIntrospectTest);
    defineReflectiveTests(MacroTypesTest_keepLinking);
    defineReflectiveTests(MacroTypesTest_fromBytes);
    defineReflectiveTests(MacroDeclarationsIntrospectTest);
    defineReflectiveTests(MacroDeclarationsTest_keepLinking);
    defineReflectiveTests(MacroDeclarationsTest_fromBytes);
    defineReflectiveTests(MacroElementsTest_keepLinking);
    defineReflectiveTests(MacroElementsTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MacroArgumentsTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  test_error() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'Object',
        'bar': 'Object',
      },
      constructorParametersCode: '(this.foo, this.bar)',
      argumentsCode: '(0, const Object())',
      expectedErrors: 'Argument(annotation: 0, argument: 1, '
          'message: Not supported: InstanceCreationExpressionImpl)',
    );
  }

  test_kind_optionalNamed() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'int',
        'bar': 'int',
      },
      constructorParametersCode: '({this.foo = -1, this.bar = -2})',
      argumentsCode: '(foo: 1)',
      expected: r'''
foo: 1
bar: -2
''',
    );
  }

  test_kind_optionalPositional() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'int',
        'bar': 'int',
      },
      constructorParametersCode: '([this.foo = -1, this.bar = -2])',
      argumentsCode: '(1)',
      expected: r'''
foo: 1
bar: -2
''',
    );
  }

  test_kind_requiredNamed() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '({required this.foo})',
      argumentsCode: '(foo: 42)',
      expected: r'''
foo: 42
''',
    );
  }

  test_kind_requiredPositional() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(42)',
      expected: r'''
foo: 42
''',
    );
  }

  test_type_bool() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'bool',
        'bar': 'bool',
      },
      constructorParametersCode: '(this.foo, this.bar)',
      argumentsCode: '(true, false)',
      expected: r'''
foo: true
bar: false
''',
    );
  }

  test_type_double() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'double'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(1.2)',
      expected: r'''
foo: 1.2
''',
    );
  }

  test_type_double_negative() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'double'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(-1.2)',
      expected: r'''
foo: -1.2
''',
    );
  }

  test_type_int() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(42)',
      expected: r'''
foo: 42
''',
    );
  }

  test_type_int_negative() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(-42)',
      expected: r'''
foo: -42
''',
    );
  }

  test_type_list() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'List<Object?>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '([1, 2, true, 3, 4.2])',
      expected: r'''
foo: [1, 2, true, 3, 4.2]
''',
    );
  }

  test_type_map() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'Map<Object?, Object?>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '({1: true, "abc": 2.3})',
      expected: r'''
foo: {1: true, abc: 2.3}
''',
    );
  }

  test_type_null() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'Object?'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(null)',
      expected: r'''
foo: null
''',
    );
  }

  test_type_set() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'Set<Object?>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '({1, 2, 3})',
      expected: r'''
foo: {1, 2, 3}
''',
    );
  }

  test_type_string() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'String'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: "('aaa')",
      expected: r'''
foo: aaa
''',
    );
  }

  test_type_string_adjacent() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'String'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: "('aaa' 'bbb' 'ccc')",
      expected: r'''
foo: aaabbbccc
''',
    );
  }

  /// Build a macro with specified [fields], initialized in the constructor
  /// with [constructorParametersCode], and apply this macro  with
  /// [argumentsCode] to an empty class.
  ///
  /// The macro generates exactly one top-level constant `x`, with a textual
  /// dump of the field values. So, we check that the analyzer built these
  /// values, and the macro executor marshalled these values to the running
  /// macro isolate.
  Future<void> _assertTypesPhaseArgumentsText({
    required Map<String, String> fields,
    required String constructorParametersCode,
    required String argumentsCode,
    String? expected,
    String? expectedErrors,
  }) async {
    final dumpCode = fields.keys.map((name) {
      return "$name: \$$name\\\\n";
    }).join('');

    newFile('$testPackageLibPath/arguments_text.dart', '''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class ArgumentsTextMacro implements ClassTypesMacro {
${fields.entries.map((e) => '  final ${e.value} ${e.key};').join('\n')}

  const ArgumentsTextMacro${constructorParametersCode.trim()};

  FutureOr<void> buildTypesForClass(clazz, builder) {
    builder.declareType(
      'x',
      DeclarationCode.fromString(
        "const x = '$dumpCode';",
      ),
    );
  }
}
''');

    final library = await buildLibrary('''
import 'arguments_text.dart';

@ArgumentsTextMacro$argumentsCode
class A {}
''');

    final A = library.definingCompilationUnit.getClass('A')!;
    if (expectedErrors != null) {
      expect(A.errorsStrForClassElement, expectedErrors);
      return;
    } else {
      A.assertNoErrorsForClassElement();
    }

    if (expected != null) {
      final macroAugmentation = library.augmentations.first;
      final macroUnit = macroAugmentation.definingCompilationUnit;
      final x = macroUnit.topLevelVariables.single;
      expect(x.name, 'x');
      x as ConstTopLevelVariableElementImpl;
      final actual = (x.constantInitializer as SimpleStringLiteral).value;

      if (actual != expected) {
        print(actual);
      }
      expect(actual, expected);
    } else {
      fail("Either 'expected' or 'expectedErrors' must be provided.");
    }
  }
}

@reflectiveTest
class MacroDeclarationsIntrospectTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  /// Return the code for `IntrospectDeclarationsPhaseMacro`.
  String get _introspectDeclarationsPhaseCode {
    final path = 'test/src/summary/macro/introspect_declarations_phase.dart';
    final code = MacrosEnvironment.instance.packageAnalyzerFolder
        .getChildAssumingFile(path)
        .readAsStringSync();
    return code.replaceAll('/*macro*/', 'macro');
  }

  test_classDeclaration_imported_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
class B {}
class C implements A, B {}
''');

    await _assertIntrospectDeclarationsText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro()
class X extends C {}
''', r'''
class X
  superclass
    class C
      superclass
        class Object
      interfaces
        A
        B
''');
  }

  test_classDeclaration_imported_isAbstract() async {
    newFile('$testPackageLibPath/a.dart', r'''
abstract class A {}
''');

    await _assertIntrospectDeclarationsText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro()
class X extends A {}
''', r'''
class X
  superclass
    abstract class A
      superclass
        class Object
''');
  }

  test_classDeclaration_imported_mixins() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin M1 {}
mixin M2 {}
class C with M1, M2 {}
''');

    await _assertIntrospectDeclarationsText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro()
class X extends C {}
''', r'''
class X
  superclass
    class C
      superclass
        class Object
      mixins
        M1
        M2
''');
  }

  test_classDeclaration_imported_superclass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
class B extends A {}
''');

    await _assertIntrospectDeclarationsText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro()
class X extends B {}
''', r'''
class X
  superclass
    class B
      superclass
        class A
          superclass
            class Object
''');
  }

  test_classDeclaration_imported_typeParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T, U extends List<T>> {}
''');

    await _assertIntrospectDeclarationsText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro()
class X extends A {}
''', r'''
class X
  superclass
    class A
      superclass
        class Object
      typeParameters
        T
        U
          bound: List<T>
''');
  }

  test_classDeclaration_superclassOf() async {
    await _assertIntrospectDeclarationsText(r'''
class A {}

@IntrospectDeclarationsPhaseMacro()
class X extends A {}
''', r'''
class X
  superclass
    class A
      superclass
        class Object
''');
  }

  test_classDeclaration_superclassOf_implicit() async {
    await _assertIntrospectDeclarationsText(r'''
@IntrospectDeclarationsPhaseMacro()
class X {}
''', r'''
class X
''');
  }

  test_classDeclaration_superclassOf_unresolved() async {
    await _assertIntrospectDeclarationsText(r'''
@IntrospectDeclarationsPhaseMacro()
class X extends A {}
''', r'''
class X
  superclass
    notType A
''');
  }

  test_fieldDeclaration_isExternal() async {
    await _assertIntrospectDeclarationsText(r'''
@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
)
class X {
  external int a;
  int b = 0;
}
''', r'''
class X
  fields
    external a
      type: int
    b
      type: int
''');
  }

  test_fieldDeclaration_isFinal() async {
    await _assertIntrospectDeclarationsText(r'''
@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
)
class X {
  final int a = 0;
  int b = 0;
}
''', r'''
class X
  fields
    final a
      type: int
    b
      type: int
''');
  }

  test_fieldDeclaration_isLate() async {
    await _assertIntrospectDeclarationsText(r'''
@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
)
class X {
  late final int a;
  final int b = 0;
}
''', r'''
class X
  fields
    late final a
      type: int
    final b
      type: int
''');
  }

  test_fieldDeclaration_isStatic() async {
    await _assertIntrospectDeclarationsText(r'''
@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
)
class X {
  static int a = 0;
  int b = 0;
}
''', r'''
class X
  fields
    static a
      type: int
    b
      type: int
''');
  }

  test_fieldDeclaration_type_explicit() async {
    await _assertIntrospectDeclarationsText(r'''
@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
)
class X {
  int a = 0;
  List<String> b = [];
}
''', r'''
class X
  fields
    a
      type: int
    b
      type: List<String>
''');
  }

  /// Assert that the textual dump of the introspection information for
  /// annotated declarations is the same as [expected].
  Future<void> _assertIntrospectDeclarationsText(
    String declarationCode,
    String expected,
  ) async {
    var actual = await _getIntrospectDeclarationsText(declarationCode);
    if (actual != expected) {
      print(actual);
    }
    expect(actual, expected);
  }

  /// Use `IntrospectDeclarationsPhaseMacro` to generate top-level constants
  /// that contain textual dump of the introspection information for
  /// macro annotated declarations.
  Future<String> _getIntrospectDeclarationsText(String declarationCode) async {
    newFile(
      '$testPackageLibPath/introspect_shared.dart',
      _introspectSharedCode,
    );

    newFile(
      '$testPackageLibPath/introspect_declarations_phase.dart',
      _introspectDeclarationsPhaseCode,
    );

    var library = await buildLibrary('''
import 'introspect_declarations_phase.dart';
$declarationCode
''');

    for (final class_ in library.definingCompilationUnit.classes) {
      class_.assertNoErrorsForClassElement();
    }

    return library.definingCompilationUnit.topLevelVariables
        .whereType<ConstTopLevelVariableElementImpl>()
        .where((e) => e.name.startsWith('introspect_'))
        .map((e) => (e.constantInitializer as SimpleStringLiteral).value)
        .join('\n');
  }
}

abstract class MacroDeclarationsTest extends MacroElementsBaseTest {
  /// TODO(scheglov) Not quite correct - we should not add a synthetic one.
  /// Fix it when adding actual augmentation libraries.
  @SkippedTest(reason: 'Class augmentation are broken currently')
  test_class_constructor_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('A.named(int a);'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class A @35
        metadata
          Annotation
            atSign: @ @18
            name: SimpleIdentifier
              token: MyMacro @19
              staticElement: package:test/a.dart::@class::MyMacro
              staticType: null
            arguments: ArgumentList
              leftParenthesis: ( @26
              rightParenthesis: ) @27
            element: package:test/a.dart::@class::MyMacro::@constructor::new
        constructors
          synthetic @-1
          named @-1
            parameters
              requiredPositional a @-1
                type: int
''');
  }

  @SkippedTest(reason: 'Class augmentation are broken currently')
  test_class_field_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('int foo = 0;'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class A @35
        metadata
          Annotation
            atSign: @ @18
            name: SimpleIdentifier
              token: MyMacro @19
              staticElement: package:test/a.dart::@class::MyMacro
              staticType: null
            arguments: ArgumentList
              leftParenthesis: ( @26
              rightParenthesis: ) @27
            element: package:test/a.dart::@class::MyMacro::@constructor::new
        fields
          foo @-1
            type: int
            shouldUseTypeForInitializerInference: true
        constructors
          synthetic @-1
        accessors
          synthetic get foo @-1
            returnType: int
          synthetic set foo @-1
            parameters
              requiredPositional _foo @-1
                type: int
            returnType: void
''');
  }

  @SkippedTest(reason: 'Class augmentation are broken currently')
  test_class_getter_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('int get foo => 0;'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class A @35
        metadata
          Annotation
            atSign: @ @18
            name: SimpleIdentifier
              token: MyMacro @19
              staticElement: package:test/a.dart::@class::MyMacro
              staticType: null
            arguments: ArgumentList
              leftParenthesis: ( @26
              rightParenthesis: ) @27
            element: package:test/a.dart::@class::MyMacro::@constructor::new
        fields
          synthetic foo @-1
            type: int
        constructors
          synthetic @-1
        accessors
          get foo @-1
            returnType: int
''');
  }

  @SkippedTest(reason: 'Class augmentation are broken currently')
  test_class_method_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('int foo(double a) => 0;'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class A @35
        metadata
          Annotation
            atSign: @ @18
            name: SimpleIdentifier
              token: MyMacro @19
              staticElement: package:test/a.dart::@class::MyMacro
              staticType: null
            arguments: ArgumentList
              leftParenthesis: ( @26
              rightParenthesis: ) @27
            element: package:test/a.dart::@class::MyMacro::@constructor::new
        constructors
          synthetic @-1
        methods
          foo @-1
            parameters
              requiredPositional a @-1
                type: double
            returnType: int
''');
  }

  @SkippedTest(reason: 'Class augmentation are broken currently')
  test_class_setter_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('set foo(int a) {}'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class A @35
        metadata
          Annotation
            atSign: @ @18
            name: SimpleIdentifier
              token: MyMacro @19
              staticElement: package:test/a.dart::@class::MyMacro
              staticType: null
            arguments: ArgumentList
              leftParenthesis: ( @26
              rightParenthesis: ) @27
            element: package:test/a.dart::@class::MyMacro::@constructor::new
        fields
          synthetic foo @-1
            type: int
        constructors
          synthetic @-1
        accessors
          set foo @-1
            parameters
              requiredPositional a @-1
                type: int
            returnType: void
''');
  }

  test_unit_variable_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInLibrary(
      DeclarationCode.fromString('final x = 42;'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class A @35
        metadata
          Annotation
            atSign: @ @18
            name: SimpleIdentifier
              token: MyMacro @19
              staticElement: package:test/a.dart::@class::MyMacro
              staticType: null
            arguments: ArgumentList
              leftParenthesis: ( @26
              rightParenthesis: ) @27
            element: package:test/a.dart::@class::MyMacro::@constructor::new
        constructors
          synthetic @-1
    topLevelVariables
      static final x @-1
        type: int
        shouldUseTypeForInitializerInference: false
    accessors
      synthetic static get x @-1
        returnType: int
''');
  }
}

@reflectiveTest
class MacroDeclarationsTest_fromBytes extends MacroDeclarationsTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MacroDeclarationsTest_keepLinking extends MacroDeclarationsTest {
  @override
  bool get keepLinkingLibraries => true;
}

abstract class MacroElementsBaseTest extends ElementsBaseTest {
  String get _introspectSharedCode {
    return MacrosEnvironment.instance.packageAnalyzerFolder
        .getChildAssumingFile('test/src/summary/macro/introspect_shared.dart')
        .readAsStringSync();
  }

  @override
  Future<void> setUp() async {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
    );
  }
}

abstract class MacroElementsTest extends MacroElementsBaseTest {
  @FailingTest(reason: 'Fails because exceptions are reported as diagnostics')
  test_macroApplicationErrors_declarationsPhase_throwsException() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    throw 'foo bar';
  }
}
''');

    final library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    final A = library.getClass('A') as ClassElementImpl;
    final error = A.macroApplicationErrors.single;
    error as UnknownMacroApplicationError;

    expect(error.annotationIndex, 0);
    expect(error.message, 'foo bar');
    expect(error.stackTrace, contains('MyMacro.buildDeclarationsForClass'));
  }

  @FailingTest(reason: 'Fails because exceptions are reported as diagnostics')
  test_macroApplicationErrors_typesPhase_compileTimeError() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    unresolved;
  }
}
''');

    final library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    final A = library.getClass('A') as ClassElementImpl;
    final error = A.macroApplicationErrors.single;
    error as UnknownMacroApplicationError;

    expect(error.annotationIndex, 0);
    expect(error.message, contains('unresolved'));
    expect(error.stackTrace, contains('executeTypesMacro'));
  }

  @FailingTest(reason: 'Fails because exceptions are reported as diagnostics')
  test_macroApplicationErrors_typesPhase_throwsException() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    throw 'foo bar';
  }
}
''');

    final library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    final A = library.getClass('A') as ClassElementImpl;
    final error = A.macroApplicationErrors.single;
    error as UnknownMacroApplicationError;

    expect(error.annotationIndex, 0);
    expect(error.message, 'foo bar');
    expect(error.stackTrace, contains('MyMacro.buildTypesForClass'));
  }

  test_macroFlag_class() async {
    var library = await buildLibrary(r'''
macro class A {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      macro class A @12
        constructors
          synthetic @-1
''');
  }

  test_macroFlag_classAlias() async {
    var library = await buildLibrary(r'''
mixin M {}
macro class A = Object with M;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      macro class alias A @23
        supertype: Object
        mixins
          M
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                superKeyword: super @0
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: dart:core::@class::Object::@constructor::new
    mixins
      mixin M @6
        superclassConstraints
          Object
''');
  }
}

@reflectiveTest
class MacroElementsTest_fromBytes extends MacroElementsTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MacroElementsTest_keepLinking extends MacroElementsTest {
  @override
  bool get keepLinkingLibraries => true;
}

@reflectiveTest
class MacroTypesIntrospectTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  /// Return the code for `DeclarationTextMacro`.
  String get _declarationTextCode {
    var code = MacrosEnvironment.instance.packageAnalyzerFolder
        .getChildAssumingFile('test/src/summary/macro/declaration_text.dart')
        .readAsStringSync();
    return code.replaceAll('/*macro*/', 'macro');
  }

  test_classDeclaration_interfaces() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A implements B, C<int, String> {}
''', r'''
class A
  interfaces
    B
    C<int, String>
''');
  }

  test_classDeclaration_isAbstract() async {
    await _assertTypesPhaseIntrospectionText(r'''
abstract class A {}
''', r'''
abstract class A
''');
  }

  test_classDeclaration_mixins() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A with B, C<int, String> {}
''', r'''
class A
  mixins
    B
    C<int, String>
''');
  }

  test_classDeclaration_superclass() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B {}
''', r'''
class A
  superclass: B
''');
  }

  test_classDeclaration_superclass_nullable() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<int?> {}
''', r'''
class A
  superclass: B<int?>
''');
  }

  test_classDeclaration_superclass_typeArguments() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<String, List<int>> {}
''', r'''
class A
  superclass: B<String, List<int>>
''');
  }

  test_classDeclaration_typeParameters() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A<T, U extends List<T>> {}
''', r'''
class A
  typeParameters
    T
    U
      bound: List<T>
''');
  }

  test_functionTypeAnnotation_formalParameters_namedOptional_simpleFormalParameter() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<void Function(int a, {int? b, int? c})> {}
''', r'''
class A
  superclass: B<void Function(int a, {int? b}, {int? c})>
''');
  }

  test_functionTypeAnnotation_formalParameters_namedRequired_simpleFormalParameter() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<void Function(int a, {required int b, required int c})> {}
''', r'''
class A
  superclass: B<void Function(int a, {required int b}, {required int c})>
''');
  }

  test_functionTypeAnnotation_formalParameters_positionalOptional_simpleFormalParameter() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<void Function(int a, [int b, int c])> {}
''', r'''
class A
  superclass: B<void Function(int a, [int b], [int c])>
''');
  }

  /// TODO(scheglov) Tests for unnamed positional formal parameters.
  test_functionTypeAnnotation_formalParameters_positionalRequired_simpleFormalParameter() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<void Function(int a, double b)> {}
''', r'''
class A
  superclass: B<void Function(int a, double b)>
''');
  }

  test_functionTypeAnnotation_nullable() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<void Function()?> {}
''', r'''
class A
  superclass: B<void Function()?>
''');
  }

  test_functionTypeAnnotation_returnType() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<void Function()> {}
''', r'''
class A
  superclass: B<void Function()>
''');
  }

  test_functionTypeAnnotation_returnType_omitted() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<Function()> {}
''', r'''
class A
  superclass: B<OmittedType Function()>
''');
  }

  test_functionTypeAnnotation_typeParameters() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<void Function<T, U extends num>()> {}
''', r'''
class A
  superclass: B<void Function<T, U extends num>()>
''');
  }

  test_namedTypeAnnotation_prefixed() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends prefix.B {}
''', r'''
class A
  superclass: B
''');
  }

  /// Assert that the textual dump of the introspection information for
  /// the first declaration in [declarationCode] is the same as [expected].
  Future<void> _assertTypesPhaseIntrospectionText(
      String declarationCode, String expected) async {
    var actual = await _getDeclarationText(declarationCode);
    if (actual != expected) {
      print(actual);
    }
    expect(actual, expected);
  }

  /// The [declarationCode] is expected to start with a declaration. It may
  /// include other declaration below, for example to reference them in
  /// the first declaration.
  ///
  /// Use `DeclarationTextMacro` to generate a library that produces exactly
  /// one part, with exactly one top-level constant `x`, with a string
  /// literal initializer. We expect that the value of this literal is
  /// the textual dump of the introspection information for the first
  /// declaration.
  Future<String> _getDeclarationText(String declarationCode) async {
    newFile(
      '$testPackageLibPath/introspect_shared.dart',
      _introspectSharedCode,
    );

    newFile(
      '$testPackageLibPath/declaration_text.dart',
      _declarationTextCode,
    );

    var library = await buildLibrary('''
import 'declaration_text.dart';

@DeclarationTextMacro()
$declarationCode
''');

    final A = library.definingCompilationUnit.getClass('A')!;
    A.assertNoErrorsForClassElement();

    final macroAugmentation = library.augmentations.first;
    final macroUnit = macroAugmentation.definingCompilationUnit;
    final x = macroUnit.topLevelVariables.single;
    expect(x.name, 'x');
    x as ConstTopLevelVariableElementImpl;
    var x_literal = x.constantInitializer as SimpleStringLiteral;
    return x_literal.value;
  }
}

abstract class MacroTypesTest extends MacroElementsBaseTest {
  @override
  bool get retainDataForTesting => true;

  test_application_newInstance_withoutPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  FutureOr<void> buildTypesForClass(clazz, builder) {
    builder.declareType(
      'MyClass',
      DeclarationCode.fromString('class MyClass {}'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class A @35
        constructors
          synthetic @-1
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class MyClass {}
---
      definingUnit
        classes
          class MyClass @36
            constructors
              synthetic @-1
''');
  }

  test_application_newInstance_withoutPrefix_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro.named();

  FutureOr<void> buildTypesForClass(clazz, builder) {
    builder.declareType(
      'MyClass',
      DeclarationCode.fromString('class MyClass {}'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro.named()
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class A @41
        constructors
          synthetic @-1
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class MyClass {}
---
      definingUnit
        classes
          class MyClass @36
            constructors
              synthetic @-1
''');
  }

  test_application_newInstance_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    builder.declareType(
      'MyClass',
      DeclarationCode.fromString('class MyClass {}'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart' as prefix;

@prefix.MyMacro()
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  imports
    package:test/a.dart as prefix @19
  definingUnit
    classes
      class A @52
        constructors
          synthetic @-1
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class MyClass {}
---
      definingUnit
        classes
          class MyClass @36
            constructors
              synthetic @-1
''');
  }

  test_application_newInstance_withPrefix_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro.named();

  buildTypesForClass(clazz, builder) {
    builder.declareType(
      'MyClass',
      DeclarationCode.fromString('class MyClass {}'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart' as prefix;

@prefix.MyMacro.named()
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  imports
    package:test/a.dart as prefix @19
  definingUnit
    classes
      class A @58
        constructors
          synthetic @-1
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class MyClass {}
---
      definingUnit
        classes
          class MyClass @36
            constructors
              synthetic @-1
''');
  }

  test_imports_class() async {
    useEmptyByteStore();

    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'a.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  FutureOr<void> buildTypesForClass(clazz, ClassTypeBuilder builder) async {
    final identifier = await builder.resolveIdentifier(
      Uri.parse('package:test/a.dart'),
      'A',
    );
    builder.declareType(
      'MyClass',
      DeclarationCode.fromParts([
        'class MyClass {\n  void foo(',
        identifier,
        ' _) {}\n}',
      ]),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'b.dart';

@MyMacro()
class X {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  imports
    package:test/b.dart
  definingUnit
    classes
      class X @35
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

import 'package:test/a.dart' as prefix0;

class MyClass {
  void foo(prefix0.A _) {}
}
---
      imports
        package:test/a.dart as prefix0 @62
      definingUnit
        classes
          class MyClass @78
            methods
              foo @95
                parameters
                  requiredPositional _ @109
                    type: A
                returnType: void
''');

    analyzerStatePrinterConfiguration.filesToPrintContent.add(
      getFile('$testPackageLibPath/test.macro.dart'),
    );

    if (keepLinkingLibraries) {
      assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1 file_3
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_12 dart:async
          library_4 package:macro/api.dart
          library_0
          library_10 dart:core synthetic
        cycle_1
          dependencies: cycle_0 dart:core package:macro/api.dart
          libraries: library_1
          apiSignature_1
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_1
          library_10 dart:core synthetic
        augmentationImports
          augmentation_3
        cycle_2
          dependencies: cycle_1 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_3
      content
---
library augment 'test.dart';

import 'package:test/a.dart' as prefix0;

class MyClass {
  void foo(prefix0.A _) {}
}
---
      kind: augmentation_3
        augmented: library_2
        library: library_2
        libraryImports
          library_0
          library_10 dart:core synthetic
      referencingFiles: file_2
      unlinkedKey: k03
libraryCycles
  /home/test/lib/a.dart
    current: cycle_0
      key: k04
    get: []
    put: [k04]
  /home/test/lib/b.dart
    current: cycle_1
      key: k05
    get: []
    put: [k05]
  /home/test/lib/test.dart
    current: cycle_2
      key: k06
    get: []
    put: [k06]
elementFactory
  hasElement
    package:test/a.dart
    package:test/b.dart
    package:test/test.dart
''');

      // When we discard the library, we remove its macro file.
      driverFor(testFile).changeFile(testFile.path);
      await driverFor(testFile).applyPendingFileChanges();
      assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_12 dart:async
          library_4 package:macro/api.dart
          library_0
          library_10 dart:core synthetic
        cycle_1
          dependencies: cycle_0 dart:core package:macro/api.dart
          libraries: library_1
          apiSignature_1
          users: cycle_6
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_2
      kind: library_16
        libraryImports
          library_1
          library_10 dart:core synthetic
        cycle_6
          dependencies: cycle_1 dart:core
          libraries: library_16
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
libraryCycles
  /home/test/lib/a.dart
    current: cycle_0
      key: k04
    get: []
    put: [k04]
  /home/test/lib/b.dart
    current: cycle_1
      key: k05
    get: []
    put: [k05]
  /home/test/lib/test.dart
    get: []
    put: [k06]
elementFactory
  hasElement
    package:test/a.dart
    package:test/b.dart
''');
    } else {
      assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1 file_3
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_12 dart:async
          library_4 package:macro/api.dart
          library_0
          library_10 dart:core synthetic
        cycle_1
          dependencies: cycle_0 dart:core package:macro/api.dart
          libraries: library_1
          apiSignature_1
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_1
          library_10 dart:core synthetic
        augmentationImports
          augmentation_3
        cycle_2
          dependencies: cycle_1 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_3
      content
---
library augment 'test.dart';

import 'package:test/a.dart' as prefix0;

class MyClass {
  void foo(prefix0.A _) {}
}
---
      kind: augmentation_3
        augmented: library_2
        library: library_2
        libraryImports
          library_0
          library_10 dart:core synthetic
      referencingFiles: file_2
      unlinkedKey: k03
libraryCycles
  /home/test/lib/a.dart
    current: cycle_0
      key: k04
    get: []
    put: [k04]
  /home/test/lib/b.dart
    current: cycle_1
      key: k05
    get: []
    put: [k05]
  /home/test/lib/test.dart
    current: cycle_2
      key: k06
    get: [k06]
    put: [k06]
elementFactory
  hasElement
    package:test/a.dart
    package:test/b.dart
    package:test/test.dart
  hasReader
    package:test/test.dart
''');
    }
  }
}

@reflectiveTest
class MacroTypesTest_fromBytes extends MacroTypesTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MacroTypesTest_keepLinking extends MacroTypesTest {
  @override
  bool get keepLinkingLibraries => true;
}

extension on ClassElement {
  String get errorsStrForClassElement {
    final element = this as ClassElementImpl;
    return element.macroApplicationErrors.map((e) {
      return e.toStringForTest();
    }).join('\n');
  }

  void assertNoErrorsForClassElement() {
    final actual = errorsStrForClassElement;
    expect(actual, isEmpty);
  }
}
