// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryProject1Test);
    defineReflectiveTests(ImportLibraryProject2Test);
    defineReflectiveTests(ImportLibraryProject3Test);
  });
}

@reflectiveTest
class ImportLibraryProject1Test extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT1;

  Future<void> test_alreadyImported_package() async {
    addSource('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
''');
    await resolveTestCode('''
import 'lib.dart' show A;
main() {
  A? a;
  B? b;
  print('\$a \$b');
}
''');
    await assertNoFix();
  }

  Future<void> test_extension_notImported_field_onThisType_fromClass() async {
    addSource('$testPackageLibPath/lib2.dart', '''
import 'package:test/lib1.dart';

extension E on C {
  int m() => 0;
}
''');
    addSource('$testPackageLibPath/lib1.dart', '''
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
    addSource('$testPackageLibPath/lib.dart', '''
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

  Future<void> test_extension_notImported_method() async {
    addSource('$testPackageLibPath/lib.dart', '''
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
    addSource('$testPackageLibPath/lib.dart', '''
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

  Future<void> test_extension_notImported_method_onThisType_fromClass() async {
    addSource('$testPackageLibPath/lib2.dart', '''
import 'package:test/lib1.dart';

extension E on C {
  void m() {}
}
''');
    addSource('$testPackageLibPath/lib1.dart', '''
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
    addSource('$testPackageLibPath/lib2.dart', '''
import 'package:test/lib1.dart';

extension E on C {
  void m() {}
}
''');
    addSource('$testPackageLibPath/lib1.dart', '''
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

  Future<void> test_extension_notImported_operator() async {
    addSource('$testPackageLibPath/lib.dart', '''
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

  Future<void> test_extension_notImported_setter() async {
    addSource('$testPackageLibPath/lib.dart', '''
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

  Future<void> test_extension_otherPackage_exported_fromSrc() async {
    var pkgRootPath = '$packagesRootPath/aaa';

    newFile('$pkgRootPath/lib/a.dart', content: r'''
export 'src/b.dart';
''');

    newFile('$pkgRootPath/lib/src/b.dart', content: r'''
extension IntExtension on int {
  int get foo => 0;
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: pkgRootPath),
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

  Future<void> test_invalidUri_interpolation() async {
    addSource('$testPackageLibPath/lib.dart', r'''
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
    await assertHasFix(r'''
import 'package:test/lib.dart';

import 'package:$foo/foo.dart';

void f() {
  Test();
}
''',
        errorFilter: (e) =>
            e.errorCode == CompileTimeErrorCode.UNDEFINED_FUNCTION);
  }

  Future<void> test_lib() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', content: '''
class Test {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'my_pkg', rootPath: '$packagesRootPath/my_pkg'),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');

    await resolveTestCode('''
main() {
  Test test = null;
  print(test);
}
''');

    await assertHasFix('''
import 'package:my_pkg/a.dart';

main() {
  Test test = null;
  print(test);
}
''', expectedNumberOfFixesForKind: 1);
  }

  Future<void> test_lib_extension() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', content: '''
extension E on int {
  static String m() => '';
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
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
    newFile('$packagesRootPath/my_pkg/lib/src/a.dart', content: '''
class Test {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'my_pkg', rootPath: '$packagesRootPath/my_pkg'),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');
    await resolveTestCode('''
main() {
  Test test = null;
  print(test);
}
''');
    await assertNoFix();
  }

  Future<void> test_notInLib() async {
    addSource('/home/other/test/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
main() {
  Test t;
  print(t);
}
''');
    await assertNoFix();
  }

  Future<void> test_relativeDirective() async {
    addSource('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
main() { new Foo(); }
''');
    await assertHasFix('''
import 'a.dart';

main() { new Foo(); }
''',
        expectedNumberOfFixesForKind: 2,
        matchFixMessage: "Import library 'a.dart'");
    await assertHasFixesWithoutApplying(
        expectedNumberOfFixesForKind: 2,
        matchFixMessages: [
          "Import library 'package:test/a.dart'",
          "Import library 'a.dart'",
        ]);
  }

  Future<void> test_relativeDirective_downOneDirectory() async {
    addSource('$testPackageLibPath/dir/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
main() { new Foo(); }
''');
    await assertHasFix('''
import 'dir/a.dart';

main() { new Foo(); }
''',
        expectedNumberOfFixesForKind: 2,
        matchFixMessage: "Import library 'dir/a.dart'");
  }

  Future<void> test_relativeDirective_preferRelativeImports() async {
    createAnalysisOptionsFile(lints: [LintNames.prefer_relative_imports]);
    addSource('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
main() { new Foo(); }
''');
    await assertHasFix('''
import 'a.dart';

main() { new Foo(); }
''',
        expectedNumberOfFixesForKind: 2,
        matchFixMessage: "Import library 'a.dart'");
    await assertHasFixesWithoutApplying(
        expectedNumberOfFixesForKind: 2,
        matchFixMessages: [
          "Import library 'a.dart'",
          "Import library 'package:test/a.dart'",
        ]);
  }

  Future<void> test_relativeDirective_upOneDirectory() async {
    addSource('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    testFile = convertPath('$testPackageLibPath/dir/test.dart');
    await resolveTestCode('''
main() { new Foo(); }
''');
    await assertHasFix('''
import '../a.dart';

main() { new Foo(); }
''',
        expectedNumberOfFixesForKind: 2,
        matchFixMessage: "Import library '../a.dart'");
  }

  Future<void> test_withClass_annotation() async {
    addSource('$testPackageLibPath/lib.dart', '''
library lib;
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
@Test(0)
main() {
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

@Test(0)
main() {
}
''');
  }

  Future<void> test_withClass_catchClause() async {
    addSource('$testPackageLibPath/lib.dart', '''
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

  Future<void> test_withClass_hasOtherLibraryWithPrefix() async {
    addSource('$testPackageLibPath/a.dart', '''
library a;
class One {}
''');
    addSource('$testPackageLibPath/b.dart', '''
library b;
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
    testFile = convertPath('/home/test/bin/aaa/test.dart');
    addSource('/home/test/bin/lib.dart', '''
library lib;
class Test {}
''');
    await resolveTestCode('''
main() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import '../lib.dart';

main() {
  Test t = null;
  print(t);
}
''');
  }

  Future<void> test_withClass_inRelativeFolder() async {
    testFile = convertPath('/home/test/bin/test.dart');
    addSource('/home/test/tool/sub/folder/lib.dart', '''
library lib;
class Test {}
''');
    await resolveTestCode('''
main() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import '../tool/sub/folder/lib.dart';

main() {
  Test t = null;
  print(t);
}
''');
  }

  Future<void> test_withClass_inSameFolder() async {
    testFile = convertPath('/home/test/bin/test.dart');
    addSource('/home/test/bin/lib.dart', '''
library lib;
class Test {}
''');
    await resolveTestCode('''
main() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import 'lib.dart';

main() {
  Test t = null;
  print(t);
}
''');
  }

  Future<void> test_withClass_instanceCreation_const() async {
    addSource('$testPackageLibPath/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestCode('''
main() {
  return const Test();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

main() {
  return const Test();
}
''');
  }

  Future<void> test_withClass_instanceCreation_const_namedConstructor() async {
    addSource('$testPackageLibPath/lib.dart', '''
class Test {
  const Test.named();
}
''');
    await resolveTestCode('''
main() {
  const Test.named();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

main() {
  const Test.named();
}
''');
  }

  Future<void> test_withClass_instanceCreation_implicit() async {
    addSource('$testPackageLibPath/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestCode('''
main() {
  return Test();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

main() {
  return Test();
}
''');
  }

  Future<void> test_withClass_instanceCreation_new() async {
    addSource('$testPackageLibPath/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestCode('''
main() {
  return new Test();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

main() {
  return new Test();
}
''');
  }

  Future<void> test_withClass_instanceCreation_new_namedConstructor() async {
    addSource('$testPackageLibPath/lib.dart', '''
class Test {
  Test.named();
}
''');
    await resolveTestCode('''
main() {
  new Test.named();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

main() {
  new Test.named();
}
''');
  }

  Future<void> test_withClass_pub_other_inLib_dependencies() async {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', content: '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
dependencies:
  aaa: any
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRoot.path),
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
    newFile('${aaaRoot.path}/lib/a.dart', content: '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
dev_dependencies:
  aaa: any
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRoot.path),
    );

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertNoFix();
  }

  Future<void> test_withClass_pub_other_inLib_notListed() async {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', content: '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRoot.path),
    );

    await resolveTestCode('''
void f(Test t) {}
''');

    // If `aaa` is not in `dependencies`, we will not suggest it.
    await assertNoFix();
  }

  Future<void> test_withClass_pub_other_inTest_dependencies() async {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', content: '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
dependencies:
  aaa: any
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRoot.path),
    );

    var b = newFile('$testPackageTestPath/b.dart', content: r'''
void f(Test t) {}
''');

    await resolveFile2(b.path);

    await assertHasFix('''
import 'package:aaa/a.dart';

void f(Test t) {}
''', target: b.path);
  }

  Future<void> test_withClass_pub_other_inTest_devDependencies() async {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', content: '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
dev_dependencies:
  aaa: any
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRoot.path),
    );

    var b = newFile('$testPackageTestPath/b.dart', content: r'''
void f(Test t) {}
''');

    await resolveFile2(b.path);

    await assertHasFix('''
import 'package:aaa/a.dart';

void f(Test t) {}
''', target: b.path);
  }

  Future<void> test_withClass_pub_this() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/a.dart', content: r'''
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

    newFile('$testPackageTestPath/a.dart', content: r'''
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

    newFile('$testPackageTestPath/a.dart', content: r'''
class Test {}
''');

    var b = newFile('$testPackageTestPath/b.dart', content: r'''
void f(Test t) {}
''');

    await resolveFile2(b.path);

    await assertHasFix('''
import 'a.dart';

void f(Test t) {}
''', target: b.path);
  }

  Future<void> test_withExtension_pub_this() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/a.dart', content: r'''
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
    addSource('$testPackageLibPath/lib.dart', '''
library lib;
myFunction() {}
''');
    await resolveTestCode('''
main() {
  myFunction();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

main() {
  myFunction();
}
''');
  }

  Future<void> test_withFunction_functionTopLevelVariable() async {
    addSource('$testPackageLibPath/lib.dart', '''
var myFunction = () {};
''');
    await resolveTestCode('''
main() {
  myFunction();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

main() {
  myFunction();
}
''');
  }

  Future<void> test_withFunction_functionTopLevelVariableIdentifier() async {
    addSource('$testPackageLibPath/lib.dart', '''
var myFunction = () {};
''');
    await resolveTestCode('''
main() {
  myFunction;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

main() {
  myFunction;
}
''');
  }

  Future<void> test_withFunction_identifier() async {
    addSource('$testPackageLibPath/lib.dart', '''
library lib;
myFunction() {}
''');
    await resolveTestCode('''
main() {
  myFunction;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

main() {
  myFunction;
}
''');
  }

  @failingTest
  Future<void> test_withFunction_nonFunctionType() async {
    addSource('$testPackageLibPath/lib.dart', '''
int zero = 0;
''');
    await resolveTestCode('''
main() {
  zero();
}
''');
    await assertNoFix();
  }

  Future<void> test_withFunction_unresolvedMethod() async {
    addSource('$testPackageLibPath/lib.dart', '''
library lib;
myFunction() {}
''');
    await resolveTestCode('''
class A {
  main() {
    myFunction();
  }
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

class A {
  main() {
    myFunction();
  }
}
''');
  }

  Future<void> test_withFunctionTypeAlias() async {
    addSource('$testPackageLibPath/lib.dart', '''
library lib;
typedef MyFunction();
''');
    await resolveTestCode('''
main() {
  MyFunction t = null;
  print(t);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

main() {
  MyFunction t = null;
  print(t);
}
''');
  }

  Future<void> test_withGetter_read() async {
    addSource('$testPackageLibPath/a.dart', '''
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
    addSource('$testPackageLibPath/a.dart', '''
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
    addSource('$testPackageLibPath/a.dart', '''
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
    addSource('$testPackageLibPath/lib.dart', '''
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
    addSource('$testPackageLibPath/a.dart', '''
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
    addSource('$testPackageLibPath/a.dart', '''
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
    addSource('$testPackageLibPath/a.dart', '''
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
    addSource('$testPackageLibPath/a.dart', '''
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
}

@reflectiveTest
class ImportLibraryProject2Test extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT2;

  Future<void> test_lib() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', content: '''
export 'b.dart';
''');
    newFile('$packagesRootPath/my_pkg/lib/b.dart', content: '''
class Test {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'my_pkg', rootPath: '$packagesRootPath/my_pkg'),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');
    await resolveTestCode('''
main() {
  Test test = null;
  print(test);
}
''');
    await assertHasFix('''
import 'package:my_pkg/a.dart';

main() {
  Test test = null;
  print(test);
}
''');
  }

  Future<void> test_lib_src() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', content: '''
export 'src/b.dart';
''');
    newFile('$packagesRootPath/my_pkg/lib/src/b.dart', content: '''
class Test {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'my_pkg', rootPath: '$packagesRootPath/my_pkg'),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');
    await resolveTestCode('''
main() {
  Test test = null;
  print(test);
}
''');
    await assertHasFix('''
import 'package:my_pkg/a.dart';

main() {
  Test test = null;
  print(test);
}
''');
  }

  Future<void> test_lib_src_extension() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', content: '''
export 'src/b.dart';
''');
    newFile('$packagesRootPath/my_pkg/lib/src/b.dart', content: '''
extension E on int {
  static String m() => '';
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
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
class ImportLibraryProject3Test extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT3;

  Future<void> test_inLibSrc_thisContextRoot_extension() async {
    addSource('$testPackageLibPath/src/lib.dart', '''
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

    newFile('$testPackageLibPath/src/a.dart', content: r'''
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

    newFile('$testPackageLibPath/src/a.dart', content: r'''
class Test {}
''');

    var b = newFile('$testPackageTestPath/b.dart', content: r'''
void f(Test t) {}
''');

    await resolveFile2(b.path);

    await assertHasFix('''
import 'package:test/src/a.dart';

void f(Test t) {}
''', target: b.path);
  }
}
