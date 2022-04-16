// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart'
    as macro;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/kernel_compilation_service.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'element_text.dart';
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
    defineReflectiveTests(MacroElementsKeepLinkingTest);
    defineReflectiveTests(MacroElementsFromBytesTest);
  });
}

@reflectiveTest
class MacroElementsFromBytesTest extends MacroElementsTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MacroElementsKeepLinkingTest extends MacroElementsTest {
  @override
  bool get keepLinkingLibraries => true;
}

class MacroElementsTest extends ElementsBaseTest {
  @override
  bool get keepLinkingLibraries => false;

  /// The path for external packages.
  String get packagesRootPath => '/packages';

  /// Return the code for `DeclarationTextMacro`.
  String get _declarationTextCode {
    var code = MacrosEnvironment.instance.packageAnalyzerFolder
        .getChildAssumingFile('test/src/summary/macro/declaration_text.dart')
        .readAsStringSync();
    return code.replaceAll('/*macro*/', 'macro');
  }

  Future<void> setUp() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
    );

    macroKernelBuilder = FrontEndServerMacroKernelBuilder();
    macroExecutor = macro.MultiMacroExecutor();
  }

  Future<void> tearDown() async {
    await macroExecutor?.close();
    KernelCompilationService.disposeDelayed(
      const Duration(milliseconds: 100),
    );
  }

  test_arguments_typesPhase_kind_optionalNamed() async {
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

  test_arguments_typesPhase_kind_optionalPositional() async {
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

  test_arguments_typesPhase_kind_requiredNamed() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '({required this.foo})',
      argumentsCode: '(foo: 42)',
      expected: r'''
foo: 42
''',
    );
  }

  test_arguments_typesPhase_kind_requiredPositional() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(42)',
      expected: r'''
foo: 42
''',
    );
  }

  test_arguments_typesPhase_type_bool() async {
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

  test_arguments_typesPhase_type_double() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'double'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(1.2)',
      expected: r'''
foo: 1.2
''',
    );
  }

  test_arguments_typesPhase_type_double_negative() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'double'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(-1.2)',
      expected: r'''
foo: -1.2
''',
    );
  }

  test_arguments_typesPhase_type_int() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(42)',
      expected: r'''
foo: 42
''',
    );
  }

  test_arguments_typesPhase_type_int_negative() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(-42)',
      expected: r'''
foo: -42
''',
    );
  }

  test_arguments_typesPhase_type_list() async {
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

  test_arguments_typesPhase_type_map() async {
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

  test_arguments_typesPhase_type_null() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'Object?'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(null)',
      expected: r'''
foo: null
''',
    );
  }

  test_arguments_typesPhase_type_string() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'String'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: "('aaa')",
      expected: r'''
foo: aaa
''',
    );
  }

  test_build_types() async {
    newFile2('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
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
''', preBuildSequence: [
      {'package:test/a.dart'}
    ]);

    checkElementText(
        library,
        r'''
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
            element: package:test/a.dart::@class::MyMacro::@constructor::•
        constructors
          synthetic @-1
  parts
    package:test/_macro_types.dart
      classes
        class MyClass @6
          constructors
            synthetic @-1
  exportScope
    A: package:test/test.dart;A
    MyClass: package:test/test.dart;package:test/_macro_types.dart;MyClass
''',
        withExportScope: true);
  }

  test_introspect_types_ClassDeclaration_interfaces() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A implements B, C<int, String> {}
''', r'''
class A
  interfaces
    B
    C<int, String>
''');
  }

  test_introspect_types_ClassDeclaration_isAbstract() async {
    await _assertTypesPhaseIntrospectionText(r'''
abstract class A {}
''', r'''
abstract class A
''');
  }

  test_introspect_types_ClassDeclaration_mixins() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A with B, C<int, String> {}
''', r'''
class A
  mixins
    B
    C<int, String>
''');
  }

  test_introspect_types_ClassDeclaration_superclass() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B {}
''', r'''
class A
  superclass: B
''');
  }

  test_introspect_types_ClassDeclaration_superclass_nullable() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<int?> {}
''', r'''
class A
  superclass: B<int?>
''');
  }

  test_introspect_types_ClassDeclaration_superclass_typeArguments() async {
    await _assertTypesPhaseIntrospectionText(r'''
class A extends B<String, List<int>> {}
''', r'''
class A
  superclass: B<String, List<int>>
''');
  }

  test_introspect_types_ClassDeclaration_typeParameters() async {
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
                staticElement: dart:core::@class::Object::@constructor::•
    mixins
      mixin M @6
        superclassConstraints
          Object
''');
  }

  void writeTestPackageConfig(
    PackageConfigFileBuilder config, {
    MacrosEnvironment? macrosEnvironment,
  }) {
    config = config.copy();

    config.add(
      name: 'test',
      rootPath: testPackageRootPath,
    );

    if (macrosEnvironment != null) {
      var packagesRootFolder = getFolder(packagesRootPath);
      macrosEnvironment.packageSharedFolder.copyTo(packagesRootFolder);
      config.add(
        name: '_fe_analyzer_shared',
        rootPath: getFolder('$packagesRootPath/_fe_analyzer_shared').path,
      );
    }

    newPackageConfigJsonFile(
      testPackageRootPath,
      config.toContent(
        toUriStr: toUriStr,
      ),
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
    required String expected,
  }) async {
    final dumpCode = fields.keys.map((name) {
      return "$name: \$$name\\\\n";
    }).join('');

    newFile2('$testPackageLibPath/arguments_text.dart', '''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class ArgumentsTextMacro implements ClassTypesMacro {
${fields.entries.map((e) => '  final${e.value} ${e.key}').join('\n')}

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
    ''', preBuildSequence: [
      {'package:test/arguments_text.dart'}
    ]);

    final x = library.parts.single.topLevelVariables.single;
    expect(x.name, 'x');
    x as ConstTopLevelVariableElementImpl;
    final actual = (x.constantInitializer as SimpleStringLiteral).value;

    if (actual != expected) {
      print(actual);
    }
    expect(actual, expected);
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
    newFile2(
      '$testPackageLibPath/declaration_text.dart',
      _declarationTextCode,
    );

    var library = await buildLibrary('''
import 'declaration_text.dart';

@DeclarationTextMacro()
$declarationCode
''', preBuildSequence: [
      {'package:test/declaration_text.dart'}
    ]);

    var x = library.parts.single.topLevelVariables.single;
    expect(x.name, 'x');
    x as ConstTopLevelVariableElementImpl;
    var x_literal = x.constantInitializer as SimpleStringLiteral;
    return x_literal.value;
  }
}
