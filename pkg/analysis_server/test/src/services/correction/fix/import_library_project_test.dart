// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryProject1PrefixedTest);
    defineReflectiveTests(ImportLibraryProject1PrefixedWithShowTest);
    defineReflectiveTests(ImportLibraryProject1Test);
    defineReflectiveTests(ImportLibraryProject1WithShowTest);
    defineReflectiveTests(ImportLibraryProject2PrefixedTest);
    defineReflectiveTests(ImportLibraryProject2PrefixedWithShowTest);
    defineReflectiveTests(ImportLibraryProject2Test);
    defineReflectiveTests(ImportLibraryProject2WithShowTest);
    defineReflectiveTests(ImportLibraryProject3PrefixedTest);
    defineReflectiveTests(ImportLibraryProject3PrefixedWithShowTest);
    defineReflectiveTests(ImportLibraryProject3Test);
    defineReflectiveTests(ImportLibraryProject3WithShowTest);
  });
}

@reflectiveTest
class ImportLibraryProject1PrefixedTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT1_PREFIXED;

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await resolveTestCode('''
void f() {
  prefix.A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix;

void f() {
  prefix.A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib.dart', '''
const value = 0;
''');
    await resolveTestCode('''
void f() {
  lib.value;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib;

void f() {
  lib.value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension A on int {}
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(a.A a) {
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as a;

void f(a.A a) {
}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib.dart', '''
void foo() {}
''');
    await resolveTestCode('''
void f() {
  prefix.foo();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix;

void f() {
  prefix.foo();
}
''');
  }

  Future<void> test_withEnum_value() async {
    newFile('$testPackageLibPath/lib.dart', '''
enum E { one, two }
''');
    await resolveTestCode('''
void f() {
  lib.E.one;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib;

void f() {
  lib.E.one;
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject1PrefixedWithShowTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT1_PREFIXED_SHOW;

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await resolveTestCode('''
void f() {
  prefix.A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix show A;

void f() {
  prefix.A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib.dart', '''
const value = 0;
''');
    await resolveTestCode('''
void f() {
  lib.value;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib show value;

void f() {
  lib.value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension A on int {}
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix show A;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(a.A a) {
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as a show A;

void f(a.A a) {
}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix show A;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib.dart', '''
void foo() {}
''');
    await resolveTestCode('''
void f() {
  prefix.foo();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix show foo;

void f() {
  prefix.foo();
}
''');
  }

  Future<void> test_withEnum_value() async {
    newFile('$testPackageLibPath/lib.dart', '''
enum E { one, two }
''');
    await resolveTestCode('''
void f() {
  lib.E.one;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib show E;

void f() {
  lib.E.one;
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject1Test extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT1;

  Future<void> test_alreadyImported_package() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
''');
    await resolveTestCode('''
import 'lib.dart' show A;
void f() {
  A? a;
  B? b;
  print('\$a \$b');
}
''');
    await assertNoFix();
  }

  Future<void> test_classContainingWith() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await resolveTestCode('''
class B extends A with M {}

mixin M {}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

class B extends A with M {}

mixin M {}
''');
  }

  Future<void> test_extension_name() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
extension Ext on int {}
''');
    await resolveTestCode('''
/// This should import [Ext].
void f() {}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

/// This should import [Ext].
void f() {}
''');
  }

  Future<void> test_extension_notImported_binaryOperator() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  String operator -(String other) => this;
}
''');
    await resolveTestCode('''
void f(String s) {
  s - '2';
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  s - '2';
}
''');
  }

  Future<void> test_extension_notImported_field_onThisType_fromClass() async {
    newFile('$testPackageLibPath/lib2.dart', '''
import 'package:test/lib1.dart';

extension E on C {
  int m() => 0;
}
''');
    newFile('$testPackageLibPath/lib1.dart', '''
class C {}
''');
    await resolveTestCode('''
import 'package:test/lib1.dart';

class D extends C {
  int f = m();
}
''');
    await assertHasFix('''
import 'package:test/lib1.dart';
import 'package:test/lib2.dart';

class D extends C {
  int f = m();
}
''');
  }

  Future<void> test_extension_notImported_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
void f(String s) {
  s.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  s.m;
}
''');
  }

  Future<void> test_extension_notImported_getter_nullAware() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
void f(String? s) {
  s?.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String? s) {
  s?.m;
}
''');
  }

  Future<void> test_extension_notImported_getter_this() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
import 'package:test/lib1.dart';

extension E on A {
  int get g => 0;
}
''');
    await resolveTestCode('''
import 'package:test/lib1.dart';

class B extends A {
  void f() {
    g;
  }
}
''');
    await assertHasFix('''
import 'package:test/lib1.dart';
import 'package:test/lib2.dart';

class B extends A {
  void f() {
    g;
  }
}
''');
  }

  Future<void> test_extension_notImported_lint() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on int {
  void m() {}
}
''');
    await resolveTestCode('''
void f(int o) {
  o.m();
}
''');
    await assertHasFix('''
import 'lib.dart';

void f(int o) {
  o.m();
}
''', matchFixMessage: "Import library 'lib.dart'");
  }

  Future<void> test_extension_notImported_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  void m() {}
}
''');
    await resolveTestCode('''
void f(String s) {
  s.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  s.m();
}
''');
  }

  Future<void> test_extension_notImported_method_extendsGeneric() async {
    newFile('$testPackageLibPath/lib.dart', '''
import 'package:test/lib1.dart';

extension E<T extends num> on List<T> {
  void m() {}
}
''');
    await resolveTestCode('''
void f(List<int> l) {
  l.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(List<int> l) {
  l.m();
}
''');
  }

  Future<void> test_extension_notImported_method_nullAware() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  void m() {}
}
''');
    await resolveTestCode('''
void f(String? s) {
  s?.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String? s) {
  s?.m();
}
''');
  }

  Future<void> test_extension_notImported_method_onThisType_fromClass() async {
    newFile('$testPackageLibPath/lib2.dart', '''
import 'package:test/lib1.dart';

extension E on C {
  void m() {}
}
''');
    newFile('$testPackageLibPath/lib1.dart', '''
class C {}
''');
    await resolveTestCode('''
import 'package:test/lib1.dart';

class D extends C {
  void m2() {
    m();
  }
}
''');
    await assertHasFix('''
import 'package:test/lib1.dart';
import 'package:test/lib2.dart';

class D extends C {
  void m2() {
    m();
  }
}
''');
  }

  Future<void>
  test_extension_notImported_method_onThisType_fromExtension() async {
    newFile('$testPackageLibPath/lib2.dart', '''
import 'package:test/lib1.dart';

extension E on C {
  void m() {}
}
''');
    newFile('$testPackageLibPath/lib1.dart', '''
class C {}
''');
    await resolveTestCode('''
import 'package:test/lib1.dart';

extension F on C {
  void m2() {
    m();
  }
}
''');
    await assertHasFix('''
import 'package:test/lib1.dart';
import 'package:test/lib2.dart';

extension F on C {
  void m2() {
    m();
  }
}
''');
  }

  Future<void> test_extension_notImported_setter() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  set m(int v) {}
}
''');
    await resolveTestCode('''
void f(String s) {
  s.m = 2;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  s.m = 2;
}
''');
  }

  Future<void> test_extension_notImported_unaryOperator() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  String operator ~() => this;
}
''');
    await resolveTestCode('''
void f(String s) {
  ~s;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  ~s;
}
''');
  }

  Future<void> test_extensionType_name_notImported() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type ET(String it) {}
''');
    await resolveTestCode('''
void f(ET s) {
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(ET s) {
}
''');
  }

  Future<void> test_extensionType_notImported() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type ET(String it) {}
''');
    await resolveTestCode('''
void f(String s) {
  ET(s);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  ET(s);
}
''');
  }

  Future<void> test_invalidUri_interpolation() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class Test {
  const Test();
}
''');
    await resolveTestCode(r'''
import 'package:$foo/foo.dart';

void f() {
  Test();
}
''');
    await assertHasFix(
      r'''
import 'package:test/lib.dart';

import 'package:$foo/foo.dart';

void f() {
  Test();
}
''',
      errorFilter:
          (e) => e.diagnosticCode == CompileTimeErrorCode.undefinedFunction,
    );
  }

  Future<void> test_lib() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', '''
class Test {}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'my_pkg', rootPath: '$packagesRootPath/my_pkg'),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');

    await resolveTestCode('''
void f() {
  Test test = null;
  print(test);
}
''');

    await assertHasFix('''
import 'package:my_pkg/a.dart';

void f() {
  Test test = null;
  print(test);
}
''', expectedNumberOfFixesForKind: 1);
  }

  Future<void> test_lib_extension() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', '''
extension E on int {
  static String m() => '';
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'my_pkg', rootPath: '$packagesRootPath/my_pkg'),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');

    await resolveTestCode('''
f() {
  print(E.m());
}
''');

    await assertHasFix('''
import 'package:my_pkg/a.dart';

f() {
  print(E.m());
}
''', expectedNumberOfFixesForKind: 1);
  }

  Future<void> test_lib_src() async {
    newFile('$packagesRootPath/my_pkg/lib/src/a.dart', '''
class Test {}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'my_pkg', rootPath: '$packagesRootPath/my_pkg'),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');
    await resolveTestCode('''
void f() {
  Test test = null;
  print(test);
}
''');
    await assertNoFix();
  }

  Future<void> test_notInLib() async {
    newFile('/home/other/test/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
void f() {
  Test t;
  print(t);
}
''');
    await assertNoFix();
  }

  Future<void> test_relativeDirective() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import 'a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 2,
      matchFixMessage: "Import library 'a.dart'",
    );
    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 2,
      matchFixMessages: [
        "Import library 'package:test/a.dart'",
        "Import library 'a.dart'",
      ],
    );
  }

  Future<void> test_relativeDirective_alwaysUsePackageImports() async {
    createAnalysisOptionsFile(lints: [LintNames.always_use_package_imports]);
    newFile('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import 'package:test/a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 1,
      matchFixMessage: "Import library 'package:test/a.dart'",
    );
    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 1,
      matchFixMessages: ["Import library 'package:test/a.dart'"],
    );
  }

  Future<void> test_relativeDirective_downOneDirectory() async {
    newFile('$testPackageLibPath/dir/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import 'dir/a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 2,
      matchFixMessage: "Import library 'dir/a.dart'",
    );
  }

  Future<void> test_relativeDirective_noLint() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import 'package:test/a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 2,
      matchFixMessage: "Import library 'package:test/a.dart'",
    );
    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 2,
      matchFixMessages: [
        "Import library 'package:test/a.dart'",
        "Import library 'a.dart'",
      ],
    );
  }

  Future<void> test_relativeDirective_preferRelativeImports() async {
    createAnalysisOptionsFile(lints: [LintNames.prefer_relative_imports]);
    newFile('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import 'a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 1,
      matchFixMessage: "Import library 'a.dart'",
    );
    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 1,
      matchFixMessages: ["Import library 'a.dart'"],
    );
  }

  Future<void> test_relativeDirective_upOneDirectory() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    testFilePath = convertPath('$testPackageLibPath/dir/test.dart');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import '../a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 2,
      matchFixMessage: "Import library '../a.dart'",
    );
  }

  Future<void> test_unchecked_methodInvocation() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on Object? {
  void m() {}
}
''');
    await resolveTestCode('''
void f(Object? o) {
  o.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(Object? o) {
  o.m();
}
''');
  }

  Future<void> test_unchecked_operatorInvocation() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on Object? {
  int operator +(int other) => 0;
}
''');
    await resolveTestCode('''
void f(Object? o) {
  o + 1;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(Object? o) {
  o + 1;
}
''');
  }

  Future<void> test_unchecked_propertyAccess() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on Object? {
  int get getter => 0;
}
''');
    await resolveTestCode('''
void f(Object? o) {
  o.getter;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(Object? o) {
  o.getter;
}
''');
  }

  Future<void> test_withClass_annotation() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
@Test(0)
void f() {
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

@Test(0)
void f() {
}
''');
  }

  Future<void> test_withClass_catchClause() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
void f() {
  try {
    print(1);
  } on Test { // ignore: nullable_type_in_catch_clause
    print(2);
  }
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  try {
    print(1);
  } on Test { // ignore: nullable_type_in_catch_clause
    print(2);
  }
}
''');
  }

  Future<void> test_withClass_commentReference() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
/// [Test]
void f() {
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

/// [Test]
void f() {
}
''');
  }

  Future<void> test_withClass_hasOtherLibraryWithPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class One {}
''');
    newFile('$testPackageLibPath/b.dart', '''
class One {}
class Two {}
''');
    await resolveTestCode('''
import 'package:test/b.dart' show Two;
main () {
  new Two();
  new One();
}
''');
    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart' show Two;
main () {
  new Two();
  new One();
}
''');
  }

  Future<void> test_withClass_inParentFolder() async {
    testFilePath = convertPath('/home/test/bin/aaa/test.dart');
    newFile('/home/test/bin/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
void f() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import '../lib.dart';

void f() {
  Test t = null;
  print(t);
}
''');
  }

  Future<void> test_withClass_inRelativeFolder() async {
    testFilePath = convertPath('/home/test/bin/test.dart');
    newFile('/home/test/tool/sub/folder/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
void f() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import '../tool/sub/folder/lib.dart';

void f() {
  Test t = null;
  print(t);
}
''');
  }

  Future<void> test_withClass_inSameFolder() async {
    testFilePath = convertPath('/home/test/bin/test.dart');
    newFile('/home/test/bin/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
void f() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import 'lib.dart';

void f() {
  Test t = null;
  print(t);
}
''');
  }

  Future<void> test_withClass_instanceCreation_const() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestCode('''
void f() {
  return const Test();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  return const Test();
}
''');
  }

  Future<void> test_withClass_instanceCreation_const_namedConstructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test.named();
}
''');
    await resolveTestCode('''
void f() {
  const Test.named();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  const Test.named();
}
''');
  }

  Future<void> test_withClass_instanceCreation_implicit() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestCode('''
void f() {
  return Test();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  return Test();
}
''');
  }

  Future<void> test_withClass_instanceCreation_new() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestCode('''
void f() {
  return new Test();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  return new Test();
}
''');
  }

  Future<void> test_withClass_instanceCreation_new_namedConstructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  Test.named();
}
''');
    await resolveTestCode('''
void f() {
  new Test.named();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  new Test.named();
}
''');
  }

  Future<void> test_withClass_pub_other_inLib_dependencies() async {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
dependencies:
  aaa: any
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()..add(name: 'aaa', rootPath: aaaRoot.path),
    );

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:aaa/a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_other_inLib_devDependencies() async {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
dev_dependencies:
  aaa: any
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()..add(name: 'aaa', rootPath: aaaRoot.path),
    );

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertNoFix();
  }

  Future<void> test_withClass_pub_other_inLib_notListed() async {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()..add(name: 'aaa', rootPath: aaaRoot.path),
    );

    await resolveTestCode('''
void f(Test t) {}
''');

    // If `aaa` is not in `dependencies`, we will not suggest it.
    await assertNoFix();
  }

  Future<void> test_withClass_pub_other_inTest_dependencies() async {
    _createPackageAaa();
    putTestFileInTestDir();
    await resolveTestCode(r'''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:aaa/a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_other_inTest_devDependencies() async {
    _createPackageAaa();
    putTestFileInTestDir();
    await resolveTestCode(r'''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:aaa/a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_this() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_this_inLib_excludesTest() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageTestPath/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(Test t) {}
''');
    await assertNoFix();
  }

  Future<void> test_withClass_pub_this_inTest_includesTest() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageTestPath/a.dart', r'''
class Test {}
''');

    putTestFileInTestDir();
    await resolveTestCode(r'''
void f(Test t) {}
''');

    await assertHasFix('''
import 'a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_simpleIdentifier_lowerCase() async {
    newFile('$testPackageLibPath/lib.dart', '''
class eX {}
''');
    await resolveTestCode('''
void f() {
  eX;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  eX;
}
''');
  }

  Future<void> test_withClass_static_getter_annotation() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test();
  static const instance = Test();
}
''');
    await resolveTestCode('''
@Test.instance
void f() {
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

@Test.instance
void f() {
}
''');
  }

  Future<void> test_withEnum_value() async {
    newFile('$testPackageLibPath/lib.dart', '''
enum E { one, two }
''');
    await resolveTestCode('''
void f() {
  E.one;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  E.one;
}
''');
  }

  Future<void> test_withExtension_pub_this() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/a.dart', r'''
extension IntExtension on int {
  int get foo => 0;
}
''');

    await resolveTestCode('''
void f() {
  IntExtension(0).foo;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  IntExtension(0).foo;
}
''');
  }

  Future<void> test_withFunction() async {
    newFile('$testPackageLibPath/lib.dart', '''
myFunction() {}
''');
    await resolveTestCode('''
void f() {
  myFunction();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  myFunction();
}
''');
  }

  Future<void> test_withFunction_functionTopLevelVariable() async {
    newFile('$testPackageLibPath/lib.dart', '''
var myFunction = () {};
''');
    await resolveTestCode('''
void f() {
  myFunction();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  myFunction();
}
''');
  }

  Future<void> test_withFunction_functionTopLevelVariableIdentifier() async {
    newFile('$testPackageLibPath/lib.dart', '''
var myFunction = () {};
''');
    await resolveTestCode('''
void f() {
  myFunction;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  myFunction;
}
''');
  }

  Future<void> test_withFunction_identifier() async {
    newFile('$testPackageLibPath/lib.dart', '''
myFunction() {}
''');
    await resolveTestCode('''
void f() {
  myFunction;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  myFunction;
}
''');
  }

  @failingTest
  Future<void> test_withFunction_nonFunctionType() async {
    newFile('$testPackageLibPath/lib.dart', '''
int zero = 0;
''');
    await resolveTestCode('''
void f() {
  zero();
}
''');
    await assertNoFix();
  }

  Future<void> test_withFunction_unresolvedMethod() async {
    newFile('$testPackageLibPath/lib.dart', '''
myFunction() {}
''');
    await resolveTestCode('''
class A {
  void f() {
    myFunction();
  }
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

class A {
  void f() {
    myFunction();
  }
}
''');
  }

  Future<void> test_withFunctionTypeAlias() async {
    newFile('$testPackageLibPath/lib.dart', '''
typedef MyFunction();
''');
    await resolveTestCode('''
void f() {
  MyFunction t = null;
  print(t);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  MyFunction t = null;
  print(t);
}
''');
  }

  Future<void> test_withGetter_read() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
''');

    await resolveTestCode('''
void f() {
  foo;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo;
}
''');
  }

  Future<void> test_withGetter_readWrite() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
''');

    await resolveTestCode('''
void f() {
  foo++;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo++;
}
''');
  }

  /// Not really useful, but shows what we have.
  Future<void> test_withGetter_write() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
''');

    await resolveTestCode('''
void f() {
  foo = 0;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo = 0;
}
''');
  }

  Future<void> test_withMixin() async {
    newFile('$testPackageLibPath/lib.dart', '''
mixin Test {}
''');
    await resolveTestCode('''
class X = Object with Test;
''');
    await assertHasFix('''
import 'package:test/lib.dart';

class X = Object with Test;
''');
  }

  Future<void> test_withSetter_assignment() async {
    newFile('$testPackageLibPath/a.dart', '''
set foo(int _) {}
''');

    await resolveTestCode('''
void f() {
  foo = 0;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo = 0;
}
''');
  }

  Future<void> test_withTopLevelVariable_annotation() async {
    newFile('$testPackageLibPath/a.dart', '''
const foo = 0;
''');

    await resolveTestCode('''
@foo
void f() {}
''');

    await assertHasFix('''
import 'package:test/a.dart';

@foo
void f() {}
''');
  }

  Future<void> test_withTopLevelVariable_read() async {
    newFile('$testPackageLibPath/a.dart', '''
var foo = 0;
''');

    await resolveTestCode('''
void f() {
  foo;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo;
}
''');
  }

  Future<void> test_withTopLevelVariable_write() async {
    newFile('$testPackageLibPath/a.dart', '''
var foo = 0;
''');

    await resolveTestCode('''
void f() {
  foo = 0;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo = 0;
}
''');
  }

  void _createPackageAaa() {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
dependencies:
  aaa: any
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()..add(name: 'aaa', rootPath: aaaRoot.path),
    );
  }
}

@reflectiveTest
class ImportLibraryProject1WithShowTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT1_SHOW;

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await resolveTestCode('''
void f() {
  A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show A;

void f() {
  A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib.dart', '''
const value = 0;
''');
    await resolveTestCode('''
void f() {
  value;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show value;

void f() {
  value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension A on int {}
''');
    await resolveTestCode('''
void f(int i) {
  A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show A;

void f(int i) {
  A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(A a) {
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show A;

void f(A a) {
}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(int i) {
  A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show A;

void f(int i) {
  A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib.dart', '''
void foo() {}
''');
    await resolveTestCode('''
void f() {
  foo();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show foo;

void f() {
  foo();
}
''');
  }

  Future<void> test_withEnum_value() async {
    newFile('$testPackageLibPath/lib.dart', '''
enum E { one, two }
''');
    await resolveTestCode('''
void f() {
  E.one;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show E;

void f() {
  E.one;
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject2PrefixedTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT2_PREFIXED;

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  prefix.A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix;

void f() {
  prefix.A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const value = 0;
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  lib.value;
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as lib;

void f() {
  lib.value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension A on int {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(a.A a) {
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as a;

void f(a.A a) {
}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib1.dart', '''
void foo() {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  prefix.foo();
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix;

void f() {
  prefix.foo();
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject2PrefixedWithShowTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT2_PREFIXED_SHOW;

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  prefix.A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix show A;

void f() {
  prefix.A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const value = 0;
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  lib.value;
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as lib show value;

void f() {
  lib.value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension A on int {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix show A;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(a.A a) {
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as a show A;

void f(a.A a) {
}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix show A;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib1.dart', '''
void foo() {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  prefix.foo();
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix show foo;

void f() {
  prefix.foo();
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject2Test extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT2;

  Future<void> test_extension_name() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib1.dart', '''
extension Ext on int {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';''');
    await resolveTestCode('''
/// This should import [Ext].
void f() {}
''');
    await assertHasFix('''
import 'package:test/lib2.dart';

/// This should import [Ext].
void f() {}
''');
  }

  Future<void> test_extension_otherPackage_exported_fromSrc() async {
    var pkgRootPath = '$packagesRootPath/aaa';

    newFile('$pkgRootPath/lib/a.dart', r'''
export 'src/b.dart';
''');

    newFile('$pkgRootPath/lib/src/b.dart', r'''
extension IntExtension on int {
  int get foo => 0;
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()..add(name: 'aaa', rootPath: pkgRootPath),
    );

    updateTestPubspecFile('''
dependencies:
  aaa: any
''');

    await resolveTestCode('''
void f() {
  0.foo;
}
''');

    await assertHasFix('''
import 'package:aaa/a.dart';

void f() {
  0.foo;
}
''');
  }

  Future<void> test_lib() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', '''
export 'b.dart';
''');
    newFile('$packagesRootPath/my_pkg/lib/b.dart', '''
class Test {}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'my_pkg', rootPath: '$packagesRootPath/my_pkg'),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');
    await resolveTestCode('''
void f() {
  Test test = null;
  print(test);
}
''');
    await assertHasFix('''
import 'package:my_pkg/a.dart';

void f() {
  Test test = null;
  print(test);
}
''');
  }

  Future<void> test_lib_src() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', '''
export 'src/b.dart';
''');
    newFile('$packagesRootPath/my_pkg/lib/src/b.dart', '''
class Test {}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'my_pkg', rootPath: '$packagesRootPath/my_pkg'),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');
    await resolveTestCode('''
void f() {
  Test test = null;
  print(test);
}
''');
    await assertHasFix('''
import 'package:my_pkg/a.dart';

void f() {
  Test test = null;
  print(test);
}
''');
  }

  Future<void> test_lib_src_extension() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', '''
export 'src/b.dart';
''');
    newFile('$packagesRootPath/my_pkg/lib/src/b.dart', '''
extension E on int {
  static String m() => '';
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'my_pkg', rootPath: '$packagesRootPath/my_pkg'),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');
    await resolveTestCode('''
f() {
  print(E.m());
}
''');
    await assertHasFix('''
import 'package:my_pkg/a.dart';

f() {
  print(E.m());
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject2WithShowTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT2_SHOW;

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show A;

void f() {
  A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const value = 0;
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  value;
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show value;

void f() {
  value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension A on int {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show A;

void f(int i) {
  A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(A a) {
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show A;

void f(A a) {
}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show A;

void f(int i) {
  A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib1.dart', '''
void foo() {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  foo();
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show foo;

void f() {
  foo();
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject3PrefixedTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT3_PREFIXED;

  Future<void> test_inLibSrc_thisContextRoot_extension() async {
    newFile('$testPackageLibPath/src/lib.dart', '''
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode('''
f() {
  print(lib.E.m());
}
''');
    await assertHasFix('''
import 'package:test/src/lib.dart' as lib;

f() {
  print(lib.E.m());
}
''');
  }

  Future<void> test_withClass_pub_this_inLib_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(lib.Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' as lib;

void f(lib.Test t) {}
''');
  }

  Future<void> test_withClass_pub_this_inTest_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    putTestFileInTestDir();
    await resolveTestCode(r'''
void f(lib.Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' as lib;

void f(lib.Test t) {}
''');
  }
}

@reflectiveTest
class ImportLibraryProject3PrefixedWithShowTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT3_PREFIXED_SHOW;

  Future<void> test_inLibSrc_thisContextRoot_extension() async {
    newFile('$testPackageLibPath/src/lib.dart', '''
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode('''
f() {
  print(lib.E.m());
}
''');
    await assertHasFix('''
import 'package:test/src/lib.dart' as lib show E;

f() {
  print(lib.E.m());
}
''');
  }

  Future<void> test_withClass_pub_this_inLib_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(lib.Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' as lib show Test;

void f(lib.Test t) {}
''');
  }

  Future<void> test_withClass_pub_this_inTest_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    putTestFileInTestDir();
    await resolveTestCode(r'''
void f(lib.Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' as lib show Test;

void f(lib.Test t) {}
''');
  }
}

@reflectiveTest
class ImportLibraryProject3Test extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT3;

  Future<void> test_extension_name() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/src/lib1.dart', '''
extension Ext on int {}
''');
    await resolveTestCode('''
/// This should import [Ext].
void f() {}
''');
    await assertHasFix('''
import 'package:test/src/lib1.dart';

/// This should import [Ext].
void f() {}
''');
  }

  Future<void> test_inLibSrc_thisContextRoot_extension() async {
    newFile('$testPackageLibPath/src/lib.dart', '''
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode('''
f() {
  print(E.m());
}
''');
    await assertHasFix('''
import 'package:test/src/lib.dart';

f() {
  print(E.m());
}
''');
  }

  Future<void> test_withClass_pub_this_inLib_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_this_inTest_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    putTestFileInTestDir();
    await resolveTestCode(r'''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart';

void f(Test t) {}
''');
  }
}

@reflectiveTest
class ImportLibraryProject3WithShowTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT3_SHOW;

  Future<void> test_inLibSrc_thisContextRoot_extension() async {
    newFile('$testPackageLibPath/src/lib.dart', '''
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode('''
f() {
  print(E.m());
}
''');
    await assertHasFix('''
import 'package:test/src/lib.dart' show E;

f() {
  print(E.m());
}
''');
  }

  Future<void> test_withClass_pub_this_inLib_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' show Test;

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_this_inTest_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    putTestFileInTestDir();
    await resolveTestCode(r'''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' show Test;

void f(Test t) {}
''');
  }
}
