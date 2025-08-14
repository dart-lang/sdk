// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:linter/src/lint_codes.dart';
import 'package:linter/src/rules/analyzer_public_api.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalyzerPublicApiTest);
  });
}

@reflectiveTest
class AnalyzerPublicApiTest extends LintRuleTest {
  static String get badPartDirective =>
      LinterLintCode.analyzerPublicApiBadPartDirective.name;

  static String get badType => LinterLintCode.analyzerPublicApiBadType.name;

  static String get exportsNonPublicName =>
      LinterLintCode.analyzerPublicApiExportsNonPublicName.name;

  static String get implInPublicApi =>
      LinterLintCode.analyzerPublicApiImplInPublicApi.name;

  String get libFile => '$testPackageRootPath/lib/file.dart';

  String get libFile2 => '$testPackageRootPath/lib/file2.dart';

  String get libNonAnalyzerFile => '$nonAnalyzerPackageRootPath/lib/file.dart';

  String get libNonAnalyzerSrcFile =>
      '$nonAnalyzerPackageRootPath/lib/src/file.dart';

  String get libSrcFile => '$testPackageRootPath/lib/src/file.dart';

  String get libSrcFile2 => '$testPackageRootPath/lib/src/file2.dart';

  @override
  String get lintRule => AnalyzerPublicApi.ruleName;

  String get nonAnalyzerPackageRootPath => '$workspaceRootPath/nonAnalyzer';

  @override
  String get testPackageRootPath => '$workspaceRootPath/analyzer';

  @override
  void setUp() {
    super.setUp();

    var builder =
        PackageConfigFileBuilder()
          ..add(name: 'analyzer', rootPath: testPackageRootPath)
          ..add(name: 'nonAnalyzer', rootPath: nonAnalyzerPackageRootPath);
    newPackageConfigJsonFileFromBuilder(testPackageRootPath, builder);
  }

  test_badPartDirective() async {
    newFile(libSrcFile, '''
part of '../file.dart';
''');
    newFile(libFile, '''
part 'src/file.dart';
''');
    await assertDiagnosticsInFile(libFile, [
      lint(0, 21, name: badPartDirective),
    ]);
  }

  test_badPartDirective_ignoredIfPublicPart() async {
    newFile(libFile, '''
part of 'file2.dart';
''');
    newFile(libFile2, '''
part 'file.dart';
''');
    await assertNoDiagnosticsInFile(libFile2);
  }

  test_badPartDirective_ignoredInInternalLibrary() async {
    newFile(libSrcFile, '''
part of 'file2.dart';
''');
    newFile(libSrcFile2, '''
part 'file.dart';
''');
    await assertNoDiagnosticsInFile(libSrcFile2);
  }

  test_badType_class_constructor_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(B b);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_class_constructor_parameter_fieldFormal_withExplicitType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(B this.b);
  Object b;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_class_constructor_parameter_fieldFormal_withImplicitType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(this._b);
  // ignore: unused_field
  B _b;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_class_constructor_parameter_ignoredInPrivateConstructor() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C._(B b);
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_class_constructor_parameter_inNamedConstructor() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C.named(B b);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(39, 5, name: badType)]);
  }

  test_badType_class_constructor_parameter_superFormal_withExplicitType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C extends D {
  C(B super.x);
}
class D {
  D(Object x);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(47, 1, name: badType)]);
  }

  test_badType_class_constructor_parameter_superFormal_withImplicitType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C extends D {
  C(super.x) : super._();
}
class D {
  D._(B x);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(47, 1, name: badType)]);
  }

  test_badType_class_extends() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C extends B {}
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_class_field_type() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  B? f;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(40, 1, name: badType)]);
  }

  test_badType_class_field_type_ignoredInPrivateField() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  // ignore: unused_field
  B? _f;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_class_field_withImplicitType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  static final b = B();
}
''');
    await assertDiagnosticsInFile(libFile, [lint(50, 1, name: badType)]);
  }

  test_badType_class_getter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  B get g => throw '';
}
''');
    await assertDiagnosticsInFile(libFile, [lint(43, 1, name: badType)]);
  }

  test_badType_class_ignoredForInternalDeclarations() async {
    newFile(libSrcFile, '''
class B {}
class C extends B {}
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_badType_class_ignoredForPrivateDeclarations() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

// ignore: unused_element
class _C extends B {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_class_implements() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C implements B {}
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_class_method_ignoredIfPrivate() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  // ignore: unused_element
  B _f(B b) => b;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_class_method_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  void f(B b) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(42, 1, name: badType)]);
  }

  test_badType_class_method_parameter_functionTyped_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  void f(void g(B b)) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(42, 1, name: badType)]);
  }

  test_badType_class_method_parameter_functionTyped_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  void f(B g()) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(42, 1, name: badType)]);
  }

  test_badType_class_method_parameter_withDefaultValue() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  void f({B? b = null}) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(42, 1, name: badType)]);
  }

  test_badType_class_method_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  B f() => throw '';
}
''');
    await assertDiagnosticsInFile(libFile, [lint(39, 1, name: badType)]);
  }

  test_badType_class_method_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  void f<T extends B>() {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(42, 1, name: badType)]);
  }

  test_badType_class_notIgnoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
class C extends B {}
''');
    await assertDiagnosticsInFile(libSrcFile, [lint(96, 1, name: badType)]);
  }

  test_badType_class_operator() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  B operator-() => throw '';
}
''');
    await assertDiagnosticsInFile(libFile, [lint(47, 1, name: badType)]);
  }

  test_badType_class_setter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  set s(B b) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(41, 1, name: badType)]);
  }

  test_badType_class_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C<T extends B> {}
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_class_with() async {
    newFile(libSrcFile, '''
mixin B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C with B {}
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_classTypeAlias_extends() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C = B with M;
mixin M {}
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_classTypeAlias_ignoredForInternalDeclarations() async {
    newFile(libSrcFile, '''
class B {}
class C = B with M;
mixin M {}
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_badType_classTypeAlias_ignoredForPrivateDeclarations() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

// ignore: unused_element
class _C = B with M;
mixin M {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_classTypeAlias_implements() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C = Object with M implements B;
mixin M {}
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_classTypeAlias_notIgnoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

@AnalyzerPublicApi()
class C = Object with M;
mixin M {}
''');
    await assertDiagnosticsInFile(libSrcFile, [lint(85, 1, name: badType)]);
  }

  test_badType_classTypeAlias_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C<T extends B> = Object with M;
mixin M {}
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_classTypeAlias_with() async {
    newFile(libSrcFile, '''
mixin B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C = Object with B;
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_enum_constructor_parameter() async {
    // Constructors aren't callable from outside of the enum, so they aren't
    // public API.
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1(null), e2(null);
  const E(B? b);
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_enum_constructor_parameter_fieldFormal_withExplicitType() async {
    // Constructors aren't callable from outside of the enum, so they aren't
    // public API.
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1(null), e2(null);
  const E(B? this.b);
  final Object? b;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_enum_constructor_parameter_fieldFormal_withImplicitType_ok() async {
    // Constructors aren't callable from outside of the enum, so they aren't
    // public API.
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1(null), e2(null);
  const E(this._b);
  // ignore: unused_field
  final B? _b;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_enum_constructor_parameter_inNamedConstructor_ok() async {
    // Constructors aren't callable from outside of the enum, so they aren't
    // public API.
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1.named(null), e2.named(null);
  const E.named(B? b);
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_enum_field_type() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1(null), e2(null);
  const E(this.f);
  final B? f;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(86, 1, name: badType)]);
  }

  test_badType_enum_field_type_ignoredInPrivateField() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1(null), e2(null);
  const E(this._f);
  // ignore: unused_field
  final B? _f;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_enum_ignoredForInternalDeclarations() async {
    newFile(libSrcFile, '''
class B {}
enum E implements B {
  e1, e2
}
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_badType_enum_ignoredForPrivateDeclarations() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

// ignore: unused_element
enum _E implements B {
  // ignore: unused_field
  e1, e2
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_enum_implements() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E implements B {
  e1, e2
}
''');
    await assertDiagnosticsInFile(libFile, [lint(30, 1, name: badType)]);
  }

  test_badType_enum_method_ignoredIfPrivate() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1, e2;
  // ignore: unused_element
  B _f(B b) => b;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_enum_method_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1, e2;
  void f(B b) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(51, 1, name: badType)]);
  }

  test_badType_enum_method_parameter_functionTyped_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1, e2;
  void f(void g(B b)) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(51, 1, name: badType)]);
  }

  test_badType_enum_method_parameter_functionTyped_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1, e2;
  void f(B g()) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(51, 1, name: badType)]);
  }

  test_badType_enum_method_parameter_withDefaultValue() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1, e2;
  void f({B? b = null}) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(51, 1, name: badType)]);
  }

  test_badType_enum_method_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1, e2;
  B f() => throw '';
}
''');
    await assertDiagnosticsInFile(libFile, [lint(48, 1, name: badType)]);
  }

  test_badType_enum_method_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E {
  e1, e2;
  void f<T extends B>() {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(51, 1, name: badType)]);
  }

  test_badType_enum_notIgnoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
enum E implements B {
  e1, e2
}
''');
    await assertDiagnosticsInFile(libSrcFile, [lint(95, 1, name: badType)]);
  }

  test_badType_enum_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E<T extends B> {
  e1, e2
}
''');
    await assertDiagnosticsInFile(libFile, [
      lint(30, 1, name: badType),
      lint(49, 2, name: badType),
      lint(53, 2, name: badType),
    ]);
  }

  test_badType_enum_with() async {
    newFile(libSrcFile, '''
mixin B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

enum E with B {
  e1, e2
}
''');
    await assertDiagnosticsInFile(libFile, [lint(30, 1, name: badType)]);
  }

  test_badType_explicit_dynamicType_ok() async {
    newFile(libFile, '''
class C {
  C(dynamic x);
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_explicit_functionType_parameterType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(void Function(B) f);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_explicit_functionType_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(B Function() f);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_explicit_functionType_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(void Function<T extends B>(T) f);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_explicit_interfaceType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(B x);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_explicit_interfaceType_ok() async {
    newFile(libFile, '''
class C {
  C(Object x);
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_explicit_interfaceType_okIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

@AnalyzerPublicApi()
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(B x);
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_explicit_interfaceType_typeArgument() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(List<B> x);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_explicit_neverType_ok() async {
    newFile(libFile, '''
class C {
  C(List<Never> x);
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_explicit_recordType_namedField() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(({B b, int i}) x);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_explicit_recordType_unnamedField() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C((B, int) x);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_explicit_typeParameterType_ok() async {
    newFile(libFile, '''
class C<T> {
  C(T x);
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_explicit_voidType_ok() async {
    newFile(libFile, '''
class C {
  C(List<void> x);
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_extension_ignoredForInternalDeclarations() async {
    newFile(libSrcFile, '''
class B {}
extension E on B {}
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_badType_extension_ignoredForPrivateDeclarations() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

// ignore: unused_element
extension _E on B {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_extension_ignoredForUnnamedDeclarations() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

// ignore: unused_element
extension on B {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_extension_method_ignoredIfPrivate() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension E on int {
  // ignore: unused_element
  B _f(B b) => b;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_extension_method_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension E on int {
  void f(B b) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(53, 1, name: badType)]);
  }

  test_badType_extension_method_parameter_functionTyped_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension E on int {
  void f(void g(B b)) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(53, 1, name: badType)]);
  }

  test_badType_extension_method_parameter_functionTyped_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension E on int {
  void f(B g()) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(53, 1, name: badType)]);
  }

  test_badType_extension_method_parameter_withDefaultValue() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension E on int {
  void f({B? b = null}) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(53, 1, name: badType)]);
  }

  test_badType_extension_method_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension E on int {
  B f() => throw '';
}
''');
    await assertDiagnosticsInFile(libFile, [lint(50, 1, name: badType)]);
  }

  test_badType_extension_method_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension E on int {
  void f<T extends B>() {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(53, 1, name: badType)]);
  }

  test_badType_extension_notIgnoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
extension E on B {}
''');
    await assertDiagnosticsInFile(libSrcFile, [lint(100, 1, name: badType)]);
  }

  test_badType_extension_on() async {
    newFile(libSrcFile, '''
mixin B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension E on B {}
''');
    await assertDiagnosticsInFile(libFile, [lint(35, 1, name: badType)]);
  }

  test_badType_extension_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension E<T extends B> on List<T> {}
''');
    await assertDiagnosticsInFile(libFile, [lint(35, 1, name: badType)]);
  }

  test_badType_extensionType_constructor_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C._(int i) {
  C(B b) : this._(0);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(55, 1, name: badType)]);
  }

  test_badType_extensionType_constructor_parameter_ignoredInPrivateConstructor() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C(int i) {
  // ignore: unused_element
  C._(B b) : this(0);
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_extensionType_constructor_parameter_inNamedConstructor() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C(int i) {
  C.named(B b) : this(0);
}
''');
    await assertDiagnosticsInFile(libFile, [lint(55, 5, name: badType)]);
  }

  test_badType_extensionType_ignoredForInternalDeclarations() async {
    newFile(libSrcFile, '''
class B {}
extension type C(B b) {}
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_badType_extensionType_ignoredForPrivateDeclarations() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

// ignore: unused_element
extension type _C(B b) {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_extensionType_implements() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C._(_D _d) implements B {}
class _D implements B {}
''');
    await assertDiagnosticsInFile(libFile, [lint(40, 1, name: badType)]);
  }

  test_badType_extensionType_method_ignoredIfPrivate() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C(int i) {
  // ignore: unused_element
  B _f(B b) => b;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_extensionType_method_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C(int i) {
  void f(B b) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(58, 1, name: badType)]);
  }

  test_badType_extensionType_method_parameter_functionTyped_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C(int i) {
  void f(void g(B b)) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(58, 1, name: badType)]);
  }

  test_badType_extensionType_method_parameter_functionTyped_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C(int i) {
  void f(B g()) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(58, 1, name: badType)]);
  }

  test_badType_extensionType_method_parameter_withDefaultValue() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C(int i) {
  void f({B? b = null}) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(58, 1, name: badType)]);
  }

  test_badType_extensionType_method_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C(int i) {
  B f() => throw '';
}
''');
    await assertDiagnosticsInFile(libFile, [lint(55, 1, name: badType)]);
  }

  test_badType_extensionType_method_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C(int i) {
  void f<T extends B>() {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(58, 1, name: badType)]);
  }

  test_badType_extensionType_notIgnoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
extension type C(B b) {}
''');
    await assertDiagnosticsInFile(libSrcFile, [
      lint(105, 1, name: badType),
      lint(109, 1, name: badType),
    ]);
  }

  test_badType_extensionType_representation_type_ignoredIfFullyPrivate() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C._(B? _f) {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_extensionType_representation_type_noConstructorName() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C(B? _f) {}
''');
    await assertDiagnosticsInFile(libFile, [lint(40, 1, name: badType)]);
  }

  test_badType_extensionType_representation_type_publicConstructorName() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C.named(B? _f) {}
''');
    await assertDiagnosticsInFile(libFile, [lint(42, 5, name: badType)]);
  }

  test_badType_extensionType_representation_type_publicFieldName() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C._(B? f) {}
''');
    await assertDiagnosticsInFile(libFile, [lint(47, 1, name: badType)]);
  }

  test_badType_extensionType_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

extension type C<T extends B>(int i) {}
''');
    await assertDiagnosticsInFile(libFile, [lint(40, 1, name: badType)]);
  }

  test_badType_functionDeclaration_ignoredForInternalDeclarations() async {
    newFile(libSrcFile, '''
class B {}
B F() => B();
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_badType_functionDeclaration_ignoredForPrivateDeclarations() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

// ignore: unused_element
B _F() => B();
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_functionDeclaration_local_ok() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

f() {
  // ignore: unused_element
  g(B b) {}
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_functionDeclaration_notIgnoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
B F() => B();
''');
    await assertDiagnosticsInFile(libSrcFile, [lint(92, 1, name: badType)]);
  }

  test_badType_functionDeclaration_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

void F(B b) {}
''');
    await assertDiagnosticsInFile(libFile, [lint(30, 1, name: badType)]);
  }

  test_badType_functionDeclaration_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

B F() => B();
''');
    await assertDiagnosticsInFile(libFile, [lint(27, 1, name: badType)]);
  }

  test_badType_functionDeclaration_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

void F<T extends B>(T t) {}
''');
    await assertDiagnosticsInFile(libFile, [lint(30, 1, name: badType)]);
  }

  test_badType_functionTypeAlias_ignoredForInternalDeclarations() async {
    newFile(libSrcFile, '''
class B {}
typedef B F();
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_badType_functionTypeAlias_ignoredForPrivateDeclarations() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

// ignore: unused_element
typedef B _F();
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_functionTypeAlias_notIgnoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
typedef B F();
''');
    await assertDiagnosticsInFile(libSrcFile, [lint(100, 1, name: badType)]);
  }

  test_badType_functionTypeAlias_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

typedef void F(B b);
''');
    await assertDiagnosticsInFile(libFile, [lint(38, 1, name: badType)]);
  }

  test_badType_functionTypeAlias_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

typedef B F();
''');
    await assertDiagnosticsInFile(libFile, [lint(35, 1, name: badType)]);
  }

  test_badType_functionTypeAlias_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

typedef void F<T extends B>(T t);
''');
    await assertDiagnosticsInFile(libFile, [lint(38, 1, name: badType)]);
  }

  test_badType_genericTypeAlias_ignoredForInternalDeclarations() async {
    newFile(libSrcFile, '''
class B {}
typedef F = B Function();
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_badType_genericTypeAlias_ignoredForPrivateDeclarations() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

// ignore: unused_element
typedef _F = B Function();
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_genericTypeAlias_notIgnoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
typedef F = B Function();
''');
    await assertDiagnosticsInFile(libSrcFile, [lint(98, 1, name: badType)]);
  }

  test_badType_genericTypeAlias_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

typedef F = void Function(B b);
''');
    await assertDiagnosticsInFile(libFile, [lint(33, 1, name: badType)]);
  }

  test_badType_genericTypeAlias_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

typedef F = B Function();
''');
    await assertDiagnosticsInFile(libFile, [lint(33, 1, name: badType)]);
  }

  test_badType_genericTypeAlias_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

typedef F = void Function<T extends B>(T t);
''');
    await assertDiagnosticsInFile(libFile, [lint(33, 1, name: badType)]);
  }

  test_badType_ignoredInNonAnalyzerLib() async {
    newFile(libNonAnalyzerSrcFile, '''
class B {}
''');
    newFile(libNonAnalyzerFile, '''
import 'src/file.dart';

class C extends B {}
''');
    await assertNoDiagnosticsInFile(libNonAnalyzerFile);
  }

  test_badType_implicit_dynamicType_ok() async {
    newFile(libFile, '''
class C {
  C(this._x);
  // ignore: unused_field
  dynamic _x;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_implicit_functionType_parameterType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(this._f);
  // ignore: unused_field
  void Function(B) _f;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_implicit_functionType_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(this._f);
  // ignore: unused_field
  B Function() _f;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_implicit_functionType_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(this._f);
  // ignore: unused_field
  void Function<T extends B>(T) _f;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_implicit_interfaceType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(this._b);
  // ignore: unused_field
  B _b;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_implicit_interfaceType_ok() async {
    newFile(libFile, '''
class C {
  C(this._x);
  // ignore: unused_field
  Object _x;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_implicit_interfaceType_okIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

@AnalyzerPublicApi()
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(this._b);
  // ignore: unused_field
  B _b;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_implicit_interfaceType_typeArgument() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(this._b);
  // ignore: unused_field
  List<B> _b;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_implicit_neverType_ok() async {
    newFile(libFile, '''
class C {
  C(this._x);
  // ignore: unused_field
  List<Never> _x;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_implicit_recordType_namedField() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(this._b);
  // ignore: unused_field
  ({B b, int i}) _b;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_implicit_recordType_unnamedField() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

class C {
  C(this._b);
  // ignore: unused_field
  (B, int) _b;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(37, 1, name: badType)]);
  }

  test_badType_implicit_typeParameterType_ok() async {
    newFile(libFile, '''
class C<T> {
  C(this._x);
  // ignore: unused_field
  T _x;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_implicit_voidType_ok() async {
    newFile(libFile, '''
class C {
  C(this._x);
  // ignore: unused_field
  List<void> _x;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_mixin_field_type() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M {
  B? f;
}
''');
    await assertDiagnosticsInFile(libFile, [lint(40, 1, name: badType)]);
  }

  test_badType_mixin_field_type_ignoredInPrivateField() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M {
  // ignore: unused_field
  B? _f;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_mixin_ignoredForInternalDeclarations() async {
    newFile(libSrcFile, '''
class B {}
mixin M implements B {}
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_badType_mixin_ignoredForPrivateDeclarations() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

// ignore: unused_element
mixin _M implements B {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_mixin_implements() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M implements B {}
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_mixin_method_ignoredIfPrivate() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M {
  // ignore: unused_element
  B _f(B b) => b;
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_mixin_method_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M {
  void f(B b) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(42, 1, name: badType)]);
  }

  test_badType_mixin_method_parameter_functionTyped_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M {
  void f(void g(B b)) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(42, 1, name: badType)]);
  }

  test_badType_mixin_method_parameter_functionTyped_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M {
  void f(B g()) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(42, 1, name: badType)]);
  }

  test_badType_mixin_method_parameter_withDefaultValue() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M {
  void f({B? b = null}) {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(42, 1, name: badType)]);
  }

  test_badType_mixin_method_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M {
  B f() => throw '';
}
''');
    await assertDiagnosticsInFile(libFile, [lint(39, 1, name: badType)]);
  }

  test_badType_mixin_method_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M {
  void f<T extends B>() {}
}
''');
    await assertDiagnosticsInFile(libFile, [lint(42, 1, name: badType)]);
  }

  test_badType_mixin_notIgnoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
mixin C implements B {}
''');
    await assertDiagnosticsInFile(libSrcFile, [lint(96, 1, name: badType)]);
  }

  test_badType_mixin_on() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M on B {}
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_mixin_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

mixin M<T extends B> {}
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_nonAnalyzer() async {
    newFile(libNonAnalyzerSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'package:nonAnalyzer/src/file.dart';

class C extends B {}
''');
    await assertDiagnosticsInFile(libFile, [lint(51, 1, name: badType)]);
  }

  test_badType_nonAnalyzer_ignoredIfAnnotatedPublic() async {
    newFile(libNonAnalyzerSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

@AnalyzerPublicApi()
class B {}
''');
    newFile(libFile, '''
import 'package:nonAnalyzer/src/file.dart';

class C extends B {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_nonAnalyzer_ignoredIfImportedViaBarrelFile() async {
    newFile(libNonAnalyzerFile, '''
export 'src/file.dart';
''');
    newFile(libNonAnalyzerSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'package:nonAnalyzer/file.dart';

class C extends B {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_nonAnalyzer_ignoredIfInLib() async {
    newFile(libNonAnalyzerFile, '''
class B {}
''');
    newFile(libFile, '''
import 'package:nonAnalyzer/file.dart';

class C extends B {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_topLevelVariable_withImplicitType() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

final b = B();
''');
    await assertDiagnosticsInFile(libFile, [lint(31, 1, name: badType)]);
  }

  test_badType_topLevelVariableDeclaration() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

B? v;
''');
    await assertDiagnosticsInFile(libFile, [lint(28, 1, name: badType)]);
  }

  test_badType_topLevelVariableDeclaration_ignoredForInternalDeclarations() async {
    newFile(libSrcFile, '''
class B {}

B? v;
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_badType_topLevelVariableDeclaration_ignoredIfPrivate() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
import 'src/file.dart';

// ignore: unused_element
B? _v;
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_badType_topLevelVariableDeclaration_notIgnoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}

@AnalyzerPublicApi()
B? v;
''');
    await assertDiagnosticsInFile(libSrcFile, [lint(94, 1, name: badType)]);
  }

  test_exportsNonPublicName_ignoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}
''');
    newFile(libSrcFile2, '''
import 'file.dart';

@AnalyzerPublicApi()
class B {}
''');
    newFile(libFile, '''
export 'src/file2.dart';
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_exportsNonPublicName_ignoredIfAnnotatedPublic_getter() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}
''');
    newFile(libSrcFile2, '''
import 'file.dart';

@AnalyzerPublicApi()
int get x => 7;
''');
    newFile(libFile, '''
export 'src/file2.dart';
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_exportsNonPublicName_ignoredIfAnnotatedPublic_setter() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}
''');
    newFile(libSrcFile2, '''
import 'file.dart';

@AnalyzerPublicApi()
set x(int value) {}
''');
    newFile(libFile, '''
export 'src/file2.dart';
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_exportsNonPublicName_ignoredIfHidden() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
export 'src/file.dart' hide B;
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_exportsNonPublicName_ignoredIfNotShown() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}
''');
    newFile(libSrcFile2, '''
import 'file.dart';

class B {}
@AnalyzerPublicApi()
class C {}
''');
    newFile(libFile, '''
export 'src/file2.dart' show C;
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_exportsNonPublicName_ignoredInInternalLibraries() async {
    newFile(libSrcFile, '''
export 'file.dart';
class B {}
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_exportsNonPublicName_nonAnalyzer() async {
    newFile(libNonAnalyzerSrcFile, '''
class B {}
''');
    newFile(libFile, '''
export 'package:nonAnalyzer/src/file.dart';
''');
    await assertDiagnosticsInFile(libFile, [
      lint(0, 43, name: exportsNonPublicName),
    ]);
  }

  test_exportsNonPublicName_nonAnalyzer_ignoredIfAnnotatedPublic() async {
    newFile(libNonAnalyzerSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

@AnalyzerPublicApi()
class B {}
''');
    newFile(libFile, '''
export 'package:nonAnalyzer/src/file.dart' show B;
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_exportsNonPublicName_nonAnalyzer_inLib() async {
    newFile(libNonAnalyzerFile, '''
class B {}
''');
    newFile(libFile, '''
export 'package:nonAnalyzer/file.dart';
''');
    await assertDiagnosticsInFile(libFile, [
      lint(0, 39, name: exportsNonPublicName),
    ]);
  }

  test_exportsNonPublicName_notIgnoredIfNotHidden() async {
    newFile(libSrcFile, '''
class B {}
class C {}
''');
    newFile(libFile, '''
export 'src/file.dart' hide C;
''');
    await assertDiagnosticsInFile(libFile, [
      lint(0, 30, name: exportsNonPublicName),
    ]);
  }

  test_exportsNonPublicName_notIgnoredIfShown() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
export 'src/file.dart' show B;
''');
    await assertDiagnosticsInFile(libFile, [
      lint(0, 30, name: exportsNonPublicName),
    ]);
  }

  test_exportsNonPublicName_topLevelVariable() async {
    newFile(libSrcFile, '''
Object? v;
''');
    newFile(libFile, '''
export 'src/file.dart';
''');
    await assertDiagnosticsInFile(libFile, [
      lint(0, 23, name: exportsNonPublicName),
    ]);
  }

  test_exportsNonPublicName_type() async {
    newFile(libSrcFile, '''
class B {}
''');
    newFile(libFile, '''
export 'src/file.dart';
''');
    await assertDiagnosticsInFile(libFile, [
      lint(0, 23, name: exportsNonPublicName),
    ]);
  }

  test_exportsNonPublicName_type_ignoredIfExportingFromAnotherPublicLib() async {
    newFile(libFile, '''
class B {}
''');
    newFile(libFile2, '''
export 'file.dart';
''');
    await assertNoDiagnosticsInFile(libFile2);
  }

  test_implInPublicApi() async {
    newFile(libFile, '''
class FooImpl {}
''');
    await assertDiagnosticsInFile(libFile, [lint(6, 7, name: implInPublicApi)]);
  }

  test_implInPublicApi_ignoredForInternalDeclarations() async {
    newFile(libSrcFile, '''
class FooImpl {}
''');
    await assertNoDiagnosticsInFile(libSrcFile);
  }

  test_implInPublicApi_ignoredForPrivateDeclarations() async {
    newFile(libFile, '''
// ignore: unused_element
class _FooImpl {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_implInPublicApi_notIgnoredIfAnnotatedPublic() async {
    newFile(libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

@AnalyzerPublicApi()
class FooImpl {}
''');
    await assertDiagnosticsInFile(libSrcFile, [
      lint(85, 7, name: implInPublicApi),
    ]);
  }
}
