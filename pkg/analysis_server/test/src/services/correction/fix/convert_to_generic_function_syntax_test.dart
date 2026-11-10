// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferGenericFunctionTypeAliasesBulkTest);
    defineReflectiveTests(PreferGenericFunctionTypeAliasesTest);
    defineReflectiveTests(UseFunctionTypeSyntaxForParametersBulkTest);
    defineReflectiveTests(UseFunctionTypeSyntaxForParametersTest);
  });
}

@reflectiveTest
class PreferGenericFunctionTypeAliasesBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_generic_function_type_aliases;

  Future<void> test_singleFile() async {
    await parseTestCode('''
typedef String F(int x);
typedef F2<P, R>(P x);
''');
    await assertHasFix('''
typedef F = String Function(int x);
typedef F2<P, R> = Function(P x);
''', isParse: true);
  }
}

@reflectiveTest
class PreferGenericFunctionTypeAliasesTest
    extends FixProcessorForBuiltInLintRuleTest {
  @override
  FixKind get kind => DartFixKind.convertToGenericFunctionSyntax;

  @override
  String get lintCode => LintNames.prefer_generic_function_type_aliases;

  Future<void> test_functionTypeAlias_noParameterTypes() async {
    await resolveTestCode('''
typedef String F(x);
''');
    await assertNoFix();
  }

  Future<void> test_functionTypeAlias_noReturnType_noTypeParameters() async {
    await resolveTestCode('''
typedef String F(int x);
''');
    await assertHasFix('''
typedef F = String Function(int x);
''');
  }

  Future<void> test_functionTypeAlias_noReturnType_typeParameters() async {
    await resolveTestCode('''
typedef F<P, R>(P x);
''');
    await assertHasFix('''
typedef F<P, R> = Function(P x);
''');
  }

  Future<void> test_functionTypeAlias_returnType_noTypeParameters() async {
    await resolveTestCode('''
typedef String F(int x);
''');
    await assertHasFix('''
typedef F = String Function(int x);
''');
  }

  Future<void> test_functionTypeAlias_returnType_typeParameters() async {
    await resolveTestCode('''
typedef R F<P, R>(P x);
''');
    await assertHasFix('''
typedef F<P, R> = R Function(P x);
''');
  }
}

@reflectiveTest
class UseFunctionTypeSyntaxForParametersBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_function_type_syntax_for_parameters;

  Future<void> test_singleFile() async {
    await parseTestCode('''
g(String f(int x), int h()) {}
''');
    await assertHasFix('''
g(String Function(int x) f, int Function() h) {}
''', isParse: true);
  }

  Future<void> test_singleFile_declaring() async {
    await parseTestCode('''
class E(final int f(String s), var g(int x)) {}
''');
    await assertHasFix('''
class E(final int Function(String s) f, var Function(int x) g) {}
''', isParse: true);
  }

  @failingTest
  Future<void> test_singleFile_nested() async {
    // Only the outer function gets converted.
    await parseTestCode('''
g(String f(int h())) {}
''');
    await assertHasFix('''
g(String Function(int Function() h) f) {}
''', isParse: true);
  }
}

@reflectiveTest
class UseFunctionTypeSyntaxForParametersTest
    extends FixProcessorForBuiltInLintRuleTest {
  @override
  FixKind get kind => DartFixKind.convertToGenericFunctionSyntax;

  @override
  String get lintCode => LintNames.use_function_type_syntax_for_parameters;

  Future<void> test_functionTypedParameter_declaring_annotation() async {
    await resolveTestCode('''
class E(@deprecated final int ^f(String s)) {}
''');
    await assertHasFix('''
class E(@deprecated final int Function(String s) f) {}
''');
  }

  Future<void> test_functionTypedParameter_declaring_defaultValue() async {
    await resolveTestCode('''
int id(String s) => 0;
class E({final int ^f(String s) = id}) {}
''');
    await assertHasFix('''
int id(String s) => 0;
class E({final int Function(String s) f = id}) {}
''');
  }

  Future<void> test_functionTypedParameter_declaring_docComment() async {
    await resolveTestCode('''
class E(
  /// The callback.
  final int ^f(String s),
) {}
''');
    await assertHasFix('''
class E(
  /// The callback.
  final int Function(String s) f,
) {}
''');
  }

  Future<void> test_functionTypedParameter_declaring_enum() async {
    await resolveTestCode('''
int id(String s) => 0;
enum E(final int ^f(String s)) {
  a(id);
}
''');
    await assertHasFix('''
int id(String s) => 0;
enum E(final int Function(String s) f) {
  a(id);
}
''');
  }

  Future<void>
  test_functionTypedParameter_declaring_extensionType_final() async {
    await resolveTestCode('''
extension type E(final int ^f(String s)) {}
''');
    await assertHasFix('''
extension type E(final int Function(String s) f) {}
''');
  }

  Future<void> test_functionTypedParameter_declaring_extensionType_var() async {
    // `var` is illegal on a representation field. The field stays final.
    await resolveTestCode('''
extension type E(var int ^f(String s)) {}
''');
    await assertHasFix('''
extension type E(int Function(String s) f) {}
''', filter: (diagnostic) => '${diagnostic.diagnosticCode}' == lintCode);
  }

  Future<void> test_functionTypedParameter_declaring_final() async {
    await resolveTestCode('''
class E(final int ^f(String s)) {}
''');
    await assertHasFix('''
class E(final int Function(String s) f) {}
''');
  }

  Future<void> test_functionTypedParameter_declaring_nullable() async {
    await resolveTestCode('''
class E(final int ^f(String s)?) {}
''');
    await assertHasFix('''
class E(final int Function(String s)? f) {}
''');
  }

  Future<void> test_functionTypedParameter_declaring_requiredNamed() async {
    await resolveTestCode('''
class E({required final int ^f(String s)}) {}
''');
    await assertHasFix('''
class E({required final int Function(String s) f}) {}
''');
  }

  Future<void> test_functionTypedParameter_declaring_typeParameters() async {
    await resolveTestCode('''
class E(final void ^f<T>(T t)) {}
''');
    await assertHasFix('''
class E(final void Function<T>(T t) f) {}
''');
  }

  Future<void> test_functionTypedParameter_declaring_var() async {
    await resolveTestCode('''
class E(var ^f(String s)) {}
''');
    await assertHasFix('''
class E(var Function(String s) f) {}
''');
  }

  Future<void> test_functionTypedParameter_declaring_varWithReturnType() async {
    await resolveTestCode('''
class E(var int ^f(String s)) {}
''');
    await assertHasFix('''
class E(var int Function(String s) f) {}
''');
  }

  Future<void> test_functionTypedParameter_fieldFormal() async {
    await resolveTestCode('''
class C {
  String Function(int) f;
  C(String this.f(int x));
}
''');
    await assertHasFix('''
class C {
  String Function(int) f;
  C(String Function(int x) this.f);
}
''');
  }

  Future<void> test_functionTypedParameter_fieldFormal_final() async {
    await resolveTestCode('''
class C {
  String Function(int) f;
  C(final String this.f(int x));
}
''');
    await assertHasFix('''
class C {
  String Function(int) f;
  C(String Function(int x) this.f);
}
''', filter: (diagnostic) => '${diagnostic.diagnosticCode}' == lintCode);
  }

  Future<void> test_functionTypedParameter_noParameterTypes() async {
    await resolveTestCode('''
g(String f(x)) {}
''');
    await assertNoFix();
  }

  Future<void> test_functionTypedParameter_nullable() async {
    await resolveTestCode('''
g(List<String> f()?) {}
''');
    await assertHasFix('''
g(List<String> Function()? f) {}
''');
  }

  Future<void> test_functionTypedParameter_ordinaryMethod_final() async {
    await resolveTestCode('''
class C {
  void m(final int ^f(String s)) {}
}
''');
    await assertHasFix('''
class C {
  void m(int Function(String s) f) {}
}
''', filter: (diagnostic) => '${diagnostic.diagnosticCode}' == lintCode);
  }

  Future<void> test_functionTypedParameter_primaryConstructor() async {
    await resolveTestCode('''
class C(String ^f(int x)) {}
''');
    await assertHasFix('''
class C(String Function(int x) f) {}
''');
  }

  Future<void> test_functionTypedParameter_requiredNamed() async {
    await resolveTestCode('''
g({required List<Object?> f()}) {}
''');
    await assertHasFix('''
g({required List<Object?> Function() f}) {}
''');
  }

  Future<void> test_functionTypedParameter_returnType() async {
    await resolveTestCode('''
g(String f(int x)) {}
''');
    await assertHasFix('''
g(String Function(int x) f) {}
''');
  }

  Future<void> test_functionTypedParameter_superParameter() async {
    await resolveTestCode('''
class C {
  C(String Function(int x) f);
}
class D extends C {
  D(String super.f(int x));
}
''');
    await assertHasFix('''
class C {
  C(String Function(int x) f);
}
class D extends C {
  D(String Function(int x) super.f);
}
''');
  }

  Future<void> test_functionTypedParameter_superParameter_final() async {
    await resolveTestCode('''
class C {
  C(String Function(int x) f);
}
class D extends C {
  D(final String super.f(int x));
}
''');
    await assertHasFix('''
class C {
  C(String Function(int x) f);
}
class D extends C {
  D(String Function(int x) super.f);
}
''', filter: (diagnostic) => '${diagnostic.diagnosticCode}' == lintCode);
  }

  Future<void> test_typeParameters() async {
    await resolveTestCode('''
void f(void a<E>()) {}
''');
    await assertHasFix('''
void f(void Function<E>() a) {}
''');
  }
}
