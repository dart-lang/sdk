// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:linter/src/diagnostic.dart' as diag;
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
      diag.analyzerPublicApiBadPartDirective.lowerCaseName;

  static String get badType => diag.analyzerPublicApiBadType.lowerCaseName;

  static String get experimentalInconsistency =>
      diag.analyzerPublicApiExperimentalInconsistency.lowerCaseName;

  static String get exportsNonPublicName =>
      diag.analyzerPublicApiExportsNonPublicName.lowerCaseName;

  static String get implInPublicApi =>
      diag.analyzerPublicApiImplInPublicApi.lowerCaseName;

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

  /// Overrides [LintRuleTest.assertDiagnosticsFromMarkup] because:
  ///
  /// * the `analyzer_public_api` rule emits multiple specific diagnostic codes
  ///   (e.g., [badType], [badPartDirective]) rather than a single lint code
  ///   matching [lintRule], so [name] must be specified
  /// * tests target various files (e.g., [libFile], [libSrcFile], or
  ///   `nonAnalyzer` package files) rather than the default [testFile]
  /// * some tests require mixed diagnostic types (such as lints alongside
  ///   analyzer errors like [diag.experimentalMemberUse]), supported via
  ///   [expectedDiagnostics]
  /// * passing [content] through [normalizeSource] before [TestCode.parse]
  ///   ensures that range offsets match the file written by [newFile]
  ///   regardless of platform line endings.
  @override
  Future<void> assertDiagnosticsFromMarkup(
    String content, {
    DiagnosticCode? code,
    String? filePath,
    String? name,
    List<ExpectedDiagnostic> Function(TestCode)? expectedDiagnostics,
  }) async {
    var testCode = TestCode.parse(normalizeSource(content));
    newFile(filePath ?? libFile, testCode.code);
    var diagnostics = expectedDiagnostics != null
        ? expectedDiagnostics(testCode)
        : [
            for (var range in testCode.ranges)
              if (code != null)
                error(code, range.sourceRange.offset, range.sourceRange.length)
              else
                lint(
                  range.sourceRange.offset,
                  range.sourceRange.length,
                  name: name,
                ),
          ];
    await assertDiagnosticsInFile(filePath ?? libFile, diagnostics);
  }

  @override
  void setUp() {
    super.setUp();

    var builder = PackageConfigFileBuilder()
      ..add(name: 'analyzer', rootFolder: getFolder(testPackageRootPath))
      ..add(
        name: 'nonAnalyzer',
        rootFolder: getFolder(nonAnalyzerPackageRootPath),
      )
      ..add(name: 'meta', rootFolder: addMeta().parent);
    newPackageConfigJsonFileFromBuilder(testPackageRootPath, builder);
  }

  test_badPartDirective() async {
    newFile(libSrcFile, '''
part of '../file.dart';
''');

    await assertDiagnosticsFromMarkup('''
[!part 'src/file.dart';!]
''', name: badPartDirective);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](B b);
}
''', name: badType);
  }

  test_badType_class_constructor_parameter_fieldFormal_withExplicitType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](B this.b);
  Object b;
}
''', name: badType);
  }

  test_badType_class_constructor_parameter_fieldFormal_withImplicitType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](this._b);
  // ignore: unused_field
  B _b;
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  C.[!named!](B b);
}
''', name: badType);
  }

  test_badType_class_constructor_parameter_superFormal_withExplicitType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C extends D {
  [!C!](B super.x);
}
class D {
  D(Object x);
}
''', name: badType);
  }

  test_badType_class_constructor_parameter_superFormal_withImplicitType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C extends D {
  [!C!](super.x) : super._();
}
class D {
  D._(B x);
}
''', name: badType);
  }

  test_badType_class_extends() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class [!C!] extends B {}
''', name: badType);
  }

  test_badType_class_field_type() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  B? [!f!];
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  static final [!b!] = B();
}
''', name: badType);
  }

  test_badType_class_getter() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  B get [!g!] => throw '';
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class [!C!] implements B {}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  void [!f!](B b) {}
}
''', name: badType);
  }

  test_badType_class_method_parameter_functionTyped_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  void [!f!](void g(B b)) {}
}
''', name: badType);
  }

  test_badType_class_method_parameter_functionTyped_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  void [!f!](B g()) {}
}
''', name: badType);
  }

  test_badType_class_method_parameter_withDefaultValue() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  void [!f!]({B? b = null}) {}
}
''', name: badType);
  }

  test_badType_class_method_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  B [!f!]() => throw '';
}
''', name: badType);
  }

  test_badType_class_method_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  void [!f!]<T extends B>() {}
}
''', name: badType);
  }

  test_badType_class_notIgnoredIfAnnotatedPublic() async {
    await assertDiagnosticsFromMarkup(filePath: libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
class [!C!] extends B {}
''', name: badType);
  }

  test_badType_class_operator() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  B operator[!-!]() => throw '';
}
''', name: badType);
  }

  test_badType_class_setter() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  set [!s!](B b) {}
}
''', name: badType);
  }

  test_badType_class_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class [!C!]<T extends B> {}
''', name: badType);
  }

  test_badType_class_with() async {
    newFile(libSrcFile, '''
mixin B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class [!C!] with B {}
''', name: badType);
  }

  test_badType_classTypeAlias_extends() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class [!C!] = B with M;
mixin M {}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class [!C!] = Object with M implements B;
mixin M {}
''', name: badType);
  }

  test_badType_classTypeAlias_notIgnoredIfAnnotatedPublic() async {
    await assertDiagnosticsFromMarkup(filePath: libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

@AnalyzerPublicApi()
class [!C!] = Object with M;
mixin M {}
''', name: badType);
  }

  test_badType_classTypeAlias_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class [!C!]<T extends B> = Object with M;
mixin M {}
''', name: badType);
  }

  test_badType_classTypeAlias_with() async {
    newFile(libSrcFile, '''
mixin B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class [!C!] = Object with B;
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

enum E {
  e1(null), e2(null);
  const E(this.f);
  final B? [!f!];
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

enum [!E!] implements B {
  e1, e2
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

enum E {
  e1, e2;
  void [!f!](B b) {}
}
''', name: badType);
  }

  test_badType_enum_method_parameter_functionTyped_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

enum E {
  e1, e2;
  void [!f!](void g(B b)) {}
}
''', name: badType);
  }

  test_badType_enum_method_parameter_functionTyped_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

enum E {
  e1, e2;
  void [!f!](B g()) {}
}
''', name: badType);
  }

  test_badType_enum_method_parameter_withDefaultValue() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

enum E {
  e1, e2;
  void [!f!]({B? b = null}) {}
}
''', name: badType);
  }

  test_badType_enum_method_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

enum E {
  e1, e2;
  B [!f!]() => throw '';
}
''', name: badType);
  }

  test_badType_enum_method_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

enum E {
  e1, e2;
  void [!f!]<T extends B>() {}
}
''', name: badType);
  }

  test_badType_enum_notIgnoredIfAnnotatedPublic() async {
    await assertDiagnosticsFromMarkup(filePath: libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
enum [!E!] implements B {
  e1, e2
}
''', name: badType);
  }

  test_badType_enum_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

enum /*[0*/E/*0]*/<T extends B> {
  /*[1*/e1/*1]*/, /*[2*/e2/*2]*/
}
''', name: badType);
  }

  test_badType_enum_with() async {
    newFile(libSrcFile, '''
mixin B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

enum [!E!] with B {
  e1, e2
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](void Function(B) f);
}
''', name: badType);
  }

  test_badType_explicit_functionType_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](B Function() f);
}
''', name: badType);
  }

  test_badType_explicit_functionType_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](void Function<T extends B>(T) f);
}
''', name: badType);
  }

  test_badType_explicit_interfaceType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](B x);
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](List<B> x);
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](({B b, int i}) x);
}
''', name: badType);
  }

  test_badType_explicit_recordType_unnamedField() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!]((B, int) x);
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension E on int {
  void [!f!](B b) {}
}
''', name: badType);
  }

  test_badType_extension_method_parameter_functionTyped_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension E on int {
  void [!f!](void g(B b)) {}
}
''', name: badType);
  }

  test_badType_extension_method_parameter_functionTyped_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension E on int {
  void [!f!](B g()) {}
}
''', name: badType);
  }

  test_badType_extension_method_parameter_withDefaultValue() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension E on int {
  void [!f!]({B? b = null}) {}
}
''', name: badType);
  }

  test_badType_extension_method_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension E on int {
  B [!f!]() => throw '';
}
''', name: badType);
  }

  test_badType_extension_method_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension E on int {
  void [!f!]<T extends B>() {}
}
''', name: badType);
  }

  test_badType_extension_notIgnoredIfAnnotatedPublic() async {
    await assertDiagnosticsFromMarkup(filePath: libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
extension [!E!] on B {}
''', name: badType);
  }

  test_badType_extension_on() async {
    newFile(libSrcFile, '''
mixin B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension [!E!] on B {}
''', name: badType);
  }

  test_badType_extension_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension [!E!]<T extends B> on List<T> {}
''', name: badType);
  }

  test_badType_extensionType_constructor_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type C._(int i) {
  [!C!](B b) : this._(0);
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type C(int i) {
  C.[!named!](B b) : this(0);
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type [!C!]._(_D _d) implements B {}
class _D implements B {}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type C(int i) {
  void [!f!](B b) {}
}
''', name: badType);
  }

  test_badType_extensionType_method_parameter_functionTyped_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type C(int i) {
  void [!f!](void g(B b)) {}
}
''', name: badType);
  }

  test_badType_extensionType_method_parameter_functionTyped_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type C(int i) {
  void [!f!](B g()) {}
}
''', name: badType);
  }

  test_badType_extensionType_method_parameter_withDefaultValue() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type C(int i) {
  void [!f!]({B? b = null}) {}
}
''', name: badType);
  }

  test_badType_extensionType_method_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type C(int i) {
  B [!f!]() => throw '';
}
''', name: badType);
  }

  test_badType_extensionType_method_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type C(int i) {
  void [!f!]<T extends B>() {}
}
''', name: badType);
  }

  test_badType_extensionType_notIgnoredIfAnnotatedPublic() async {
    await assertDiagnosticsFromMarkup(filePath: libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
extension type /*[0*/C/*0]*/(B /*[1*/b/*1]*/) {}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type [!C!](B? _f) {}
''', name: badType);
  }

  test_badType_extensionType_representation_type_publicConstructorName() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type C.[!named!](B? _f) {}
''', name: badType);
  }

  test_badType_extensionType_representation_type_publicFieldName() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type C._(B? [!f!]) {}
''', name: badType);
  }

  test_badType_extensionType_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

extension type [!C!]<T extends B>(int i) {}
''', name: badType);
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
    await assertDiagnosticsFromMarkup(filePath: libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
B [!F!]() => B();
''', name: badType);
  }

  test_badType_functionDeclaration_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

void [!F!](B b) {}
''', name: badType);
  }

  test_badType_functionDeclaration_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

B [!F!]() => B();
''', name: badType);
  }

  test_badType_functionDeclaration_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

void [!F!]<T extends B>(T t) {}
''', name: badType);
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
    await assertDiagnosticsFromMarkup(filePath: libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
typedef B [!F!]();
''', name: badType);
  }

  test_badType_functionTypeAlias_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

typedef void [!F!](B b);
''', name: badType);
  }

  test_badType_functionTypeAlias_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

typedef B [!F!]();
''', name: badType);
  }

  test_badType_functionTypeAlias_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

typedef void [!F!]<T extends B>(T t);
''', name: badType);
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
    await assertDiagnosticsFromMarkup(filePath: libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
typedef [!F!] = B Function();
''', name: badType);
  }

  test_badType_genericTypeAlias_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

typedef [!F!] = void Function(B b);
''', name: badType);
  }

  test_badType_genericTypeAlias_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

typedef [!F!] = B Function();
''', name: badType);
  }

  test_badType_genericTypeAlias_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

typedef [!F!] = void Function<T extends B>(T t);
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](this._f);
  // ignore: unused_field
  void Function(B) _f;
}
''', name: badType);
  }

  test_badType_implicit_functionType_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](this._f);
  // ignore: unused_field
  B Function() _f;
}
''', name: badType);
  }

  test_badType_implicit_functionType_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](this._f);
  // ignore: unused_field
  void Function<T extends B>(T) _f;
}
''', name: badType);
  }

  test_badType_implicit_interfaceType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](this._b);
  // ignore: unused_field
  B _b;
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](this._b);
  // ignore: unused_field
  List<B> _b;
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](this._b);
  // ignore: unused_field
  ({B b, int i}) _b;
}
''', name: badType);
  }

  test_badType_implicit_recordType_unnamedField() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

class C {
  [!C!](this._b);
  // ignore: unused_field
  (B, int) _b;
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

mixin M {
  B? [!f!];
}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

mixin [!M!] implements B {}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

mixin M {
  void [!f!](B b) {}
}
''', name: badType);
  }

  test_badType_mixin_method_parameter_functionTyped_parameter() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

mixin M {
  void [!f!](void g(B b)) {}
}
''', name: badType);
  }

  test_badType_mixin_method_parameter_functionTyped_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

mixin M {
  void [!f!](B g()) {}
}
''', name: badType);
  }

  test_badType_mixin_method_parameter_withDefaultValue() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

mixin M {
  void [!f!]({B? b = null}) {}
}
''', name: badType);
  }

  test_badType_mixin_method_returnType() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

mixin M {
  B [!f!]() => throw '';
}
''', name: badType);
  }

  test_badType_mixin_method_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

mixin M {
  void [!f!]<T extends B>() {}
}
''', name: badType);
  }

  test_badType_mixin_notIgnoredIfAnnotatedPublic() async {
    await assertDiagnosticsFromMarkup(filePath: libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}
@AnalyzerPublicApi()
mixin [!C!] implements B {}
''', name: badType);
  }

  test_badType_mixin_on() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

mixin [!M!] on B {}
''', name: badType);
  }

  test_badType_mixin_typeParameterBound() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

mixin [!M!]<T extends B> {}
''', name: badType);
  }

  test_badType_nonAnalyzer() async {
    newFile(libNonAnalyzerSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'package:nonAnalyzer/src/file.dart';

class [!C!] extends B {}
''', name: badType);
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

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

final [!b!] = B();
''', name: badType);
  }

  test_badType_topLevelVariableDeclaration() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
import 'src/file.dart';

B? [!v!];
''', name: badType);
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
    await assertDiagnosticsFromMarkup(filePath: libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

class B {}

@AnalyzerPublicApi()
B? [!v!];
''', name: badType);
  }

  test_experimentalInconsistency_class_constructor_parameter() async {
    await assertDiagnosticsFromMarkup(
      '''
import 'package:meta/meta.dart';

@experimental
class B {}

class C {
  /*[0*/C/*0]*/(/*[1*/B/*1]*/ b);
}
''',
      expectedDiagnostics: (testCode) => [
        lint(
          testCode.ranges[0].sourceRange.offset,
          testCode.ranges[0].sourceRange.length,
          name: experimentalInconsistency,
        ),
        error(
          diag.experimentalMemberUse,
          testCode.ranges[1].sourceRange.offset,
          testCode.ranges[1].sourceRange.length,
        ),
      ],
    );
  }

  test_experimentalInconsistency_class_constructor_parameter_ok() async {
    newFile(libFile, '''
import 'package:meta/meta.dart';

@experimental
class B {}

class C {
  @experimental
  C(B b);
}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_experimentalInconsistency_class_extends() async {
    await assertDiagnosticsFromMarkup(
      '''
import 'package:meta/meta.dart';

@experimental
class B {}

class /*[0*/C/*0]*/ extends /*[1*/B/*1]*/ {}
''',
      expectedDiagnostics: (testCode) => [
        lint(
          testCode.ranges[0].sourceRange.offset,
          testCode.ranges[0].sourceRange.length,
          name: experimentalInconsistency,
        ),
        error(
          diag.experimentalMemberUse,
          testCode.ranges[1].sourceRange.offset,
          testCode.ranges[1].sourceRange.length,
        ),
      ],
    );
  }

  test_experimentalInconsistency_class_extends_ok() async {
    newFile(libFile, '''
import 'package:meta/meta.dart';

@experimental
class B {}

@experimental
class C extends B {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_experimentalInconsistency_class_implements() async {
    await assertDiagnosticsFromMarkup(
      '''
import 'package:meta/meta.dart';

@experimental
class B {}

class /*[0*/C/*0]*/ implements /*[1*/B/*1]*/ {}
''',
      expectedDiagnostics: (testCode) => [
        lint(
          testCode.ranges[0].sourceRange.offset,
          testCode.ranges[0].sourceRange.length,
          name: experimentalInconsistency,
        ),
        error(
          diag.experimentalMemberUse,
          testCode.ranges[1].sourceRange.offset,
          testCode.ranges[1].sourceRange.length,
        ),
      ],
    );
  }

  test_experimentalInconsistency_class_implements_ok() async {
    newFile(libFile, '''
import 'package:meta/meta.dart';

@experimental
class B {}

@experimental
class C implements B {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_experimentalInconsistency_class_typeParameterBound() async {
    await assertDiagnosticsFromMarkup(
      '''
import 'package:meta/meta.dart';

@experimental
class B {}

class /*[0*/C/*0]*/<T extends /*[1*/B/*1]*/> {}
''',
      expectedDiagnostics: (testCode) => [
        lint(
          testCode.ranges[0].sourceRange.offset,
          testCode.ranges[0].sourceRange.length,
          name: experimentalInconsistency,
        ),
        error(
          diag.experimentalMemberUse,
          testCode.ranges[1].sourceRange.offset,
          testCode.ranges[1].sourceRange.length,
        ),
      ],
    );
  }

  test_experimentalInconsistency_class_typeParameterBound_ok() async {
    newFile(libFile, '''
import 'package:meta/meta.dart';

@experimental
class B {}

@experimental
class C<T extends B> {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_experimentalInconsistency_class_with() async {
    await assertDiagnosticsFromMarkup(
      '''
import 'package:meta/meta.dart';

@experimental
mixin B {}

class /*[0*/C/*0]*/ with /*[1*/B/*1]*/ {}
''',
      expectedDiagnostics: (testCode) => [
        lint(
          testCode.ranges[0].sourceRange.offset,
          testCode.ranges[0].sourceRange.length,
          name: experimentalInconsistency,
        ),
        error(
          diag.experimentalMemberUse,
          testCode.ranges[1].sourceRange.offset,
          testCode.ranges[1].sourceRange.length,
        ),
      ],
    );
  }

  test_experimentalInconsistency_class_with_ok() async {
    newFile(libFile, '''
import 'package:meta/meta.dart';

@experimental
mixin B {}

@experimental
class C with B {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_experimentalInconsistency_extension_on() async {
    await assertDiagnosticsFromMarkup(
      '''
import 'package:meta/meta.dart';

@experimental
mixin B {}

extension /*[0*/E/*0]*/ on /*[1*/B/*1]*/ {}
''',
      expectedDiagnostics: (testCode) => [
        lint(
          testCode.ranges[0].sourceRange.offset,
          testCode.ranges[0].sourceRange.length,
          name: experimentalInconsistency,
        ),
        error(
          diag.experimentalMemberUse,
          testCode.ranges[1].sourceRange.offset,
          testCode.ranges[1].sourceRange.length,
        ),
      ],
    );
  }

  test_experimentalInconsistency_extension_on_ok() async {
    newFile(libFile, '''
import 'package:meta/meta.dart';

@experimental
mixin B {}

@experimental
extension E on B {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_experimentalInconsistency_functionDeclaration_parameter() async {
    await assertDiagnosticsFromMarkup(
      '''
import 'package:meta/meta.dart';

@experimental
class B {}

void /*[0*/F/*0]*/(/*[1*/B/*1]*/ b) {}
''',
      expectedDiagnostics: (testCode) => [
        lint(
          testCode.ranges[0].sourceRange.offset,
          testCode.ranges[0].sourceRange.length,
          name: experimentalInconsistency,
        ),
        error(
          diag.experimentalMemberUse,
          testCode.ranges[1].sourceRange.offset,
          testCode.ranges[1].sourceRange.length,
        ),
      ],
    );
  }

  test_experimentalInconsistency_functionDeclaration_parameter_ok() async {
    newFile(libFile, '''
import 'package:meta/meta.dart';

@experimental
class B {}

@experimental
void F(B b) {}
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_experimentalInconsistency_functionTypeAlias_parameter() async {
    await assertDiagnosticsFromMarkup(
      '''
import 'package:meta/meta.dart';

@experimental
class B {}

typedef void /*[0*/F/*0]*/(/*[1*/B/*1]*/ b);
''',
      expectedDiagnostics: (testCode) => [
        lint(
          testCode.ranges[0].sourceRange.offset,
          testCode.ranges[0].sourceRange.length,
          name: experimentalInconsistency,
        ),
        error(
          diag.experimentalMemberUse,
          testCode.ranges[1].sourceRange.offset,
          testCode.ranges[1].sourceRange.length,
        ),
      ],
    );
  }

  test_experimentalInconsistency_functionTypeAlias_parameter_ok() async {
    newFile(libFile, '''
import 'package:meta/meta.dart';

@experimental
class B {}

@experimental
typedef void F(B b);
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_experimentalInconsistency_functionTypeAlias_typeParameterBound() async {
    await assertDiagnosticsFromMarkup(
      '''
import 'package:meta/meta.dart';

@experimental
class B {}

typedef void /*[0*/F/*0]*/<T extends /*[1*/B/*1]*/>(T t);
''',
      expectedDiagnostics: (testCode) => [
        lint(
          testCode.ranges[0].sourceRange.offset,
          testCode.ranges[0].sourceRange.length,
          name: experimentalInconsistency,
        ),
        error(
          diag.experimentalMemberUse,
          testCode.ranges[1].sourceRange.offset,
          testCode.ranges[1].sourceRange.length,
        ),
      ],
    );
  }

  test_experimentalInconsistency_functionTypeAlias_typeParameterBound_ok() async {
    newFile(libFile, '''
import 'package:meta/meta.dart';

@experimental
class B {}

@experimental
typedef void F<T extends B>(T t);
''');
    await assertNoDiagnosticsInFile(libFile);
  }

  test_experimentalInconsistency_mixin_on() async {
    await assertDiagnosticsFromMarkup(
      '''
import 'package:meta/meta.dart';

@experimental
class B {}

mixin /*[0*/M/*0]*/ on /*[1*/B/*1]*/ {}
''',
      expectedDiagnostics: (testCode) => [
        lint(
          testCode.ranges[0].sourceRange.offset,
          testCode.ranges[0].sourceRange.length,
          name: experimentalInconsistency,
        ),
        error(
          diag.experimentalMemberUse,
          testCode.ranges[1].sourceRange.offset,
          testCode.ranges[1].sourceRange.length,
        ),
      ],
    );
  }

  test_experimentalInconsistency_mixin_on_ok() async {
    newFile(libFile, '''
import 'package:meta/meta.dart';

@experimental
class B {}

@experimental
mixin M on B {}
''');
    await assertNoDiagnosticsInFile(libFile);
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

    await assertDiagnosticsFromMarkup('''
[!export 'package:nonAnalyzer/src/file.dart';!]
''', name: exportsNonPublicName);
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

    await assertDiagnosticsFromMarkup('''
[!export 'package:nonAnalyzer/file.dart';!]
''', name: exportsNonPublicName);
  }

  test_exportsNonPublicName_notIgnoredIfNotHidden() async {
    newFile(libSrcFile, '''
class B {}
class C {}
''');

    await assertDiagnosticsFromMarkup('''
[!export 'src/file.dart' hide C;!]
''', name: exportsNonPublicName);
  }

  test_exportsNonPublicName_notIgnoredIfShown() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
[!export 'src/file.dart' show B;!]
''', name: exportsNonPublicName);
  }

  test_exportsNonPublicName_topLevelVariable() async {
    newFile(libSrcFile, '''
Object? v;
''');

    await assertDiagnosticsFromMarkup('''
[!export 'src/file.dart';!]
''', name: exportsNonPublicName);
  }

  test_exportsNonPublicName_type() async {
    newFile(libSrcFile, '''
class B {}
''');

    await assertDiagnosticsFromMarkup('''
[!export 'src/file.dart';!]
''', name: exportsNonPublicName);
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
    await assertDiagnosticsFromMarkup('''
class [!FooImpl!] {}
''', name: implInPublicApi);
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
    await assertDiagnosticsFromMarkup(filePath: libSrcFile, '''
class AnalyzerPublicApi {
  const AnalyzerPublicApi();
}

@AnalyzerPublicApi()
class [!FooImpl!] {}
''', name: implInPublicApi);
  }
}
