// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../services/refactoring/abstract_rename.dart';
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
    addSource('/home/test/lib/lib.dart', '''
class A {}
class B {}
''');
    await resolveTestCode('''
import 'lib.dart' show A;
main() {
  A a;
  B b;
  print('\$a \$b');
}
''');
    await assertNoFix();
  }

  Future<void> test_invalidUri_interpolation() async {
    addSource('/home/test/lib/lib.dart', r'''
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
    newFile('/.pub-cache/my_pkg/lib/a.dart', content: 'class Test {}');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'my_pkg', rootPath: '/.pub-cache/my_pkg'),
    );

    newFile('/home/test/pubspec.yaml', content: r'''
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
    newFile('/.pub-cache/my_pkg/lib/a.dart', content: '''
extension E on int {
  static String m() => '';
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'my_pkg', rootPath: '/.pub-cache/my_pkg'),
    );

    newFile('/home/test/pubspec.yaml', content: r'''
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
    newFile('/.pub-cache/my_pkg/lib/src/a.dart', content: 'class Test {}');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'my_pkg', rootPath: '/.pub-cache/my_pkg'),
    );

    newFile('/home/test/pubspec.yaml', content: r'''
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
    addSource('/home/other/test/lib.dart', 'class Test {}');
    await resolveTestCode('''
main() {
  Test t;
  print(t);
}
''');
    await assertNoFix();
  }

  Future<void> test_relativeDirective() async {
    addSource('/home/test/lib/a.dart', '''
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
  }

  Future<void> test_relativeDirective_downOneDirectory() async {
    addSource('/home/test/lib/dir/a.dart', '''
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

  Future<void> test_relativeDirective_upOneDirectory() async {
    addSource('/home/test/lib/a.dart', '''
class Foo {}
''');
    testFile = convertPath('/home/test/lib/dir/test.dart');
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
    addSource('/home/test/lib/lib.dart', '''
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
    addSource('/home/test/lib/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
void f() {
  try {
    print(1);
  } on Test {
    print(2);
  }
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  try {
    print(1);
  } on Test {
    print(2);
  }
}
''');
  }

  Future<void> test_withClass_hasOtherLibraryWithPrefix() async {
    addSource('/home/test/lib/a.dart', '''
library a;
class One {}
''');
    addSource('/home/test/lib/b.dart', '''
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
    addSource('/home/test/lib/lib.dart', '''
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
    addSource('/home/test/lib/lib.dart', '''
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
    addSource('/home/test/lib/lib.dart', '''
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
    addSource('/home/test/lib/lib.dart', '''
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
    addSource('/home/test/lib/lib.dart', '''
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

  Future<void> test_withFunction() async {
    addSource('/home/test/lib/lib.dart', '''
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
    addSource('/home/test/lib/lib.dart', 'var myFunction = () {};');
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
    addSource('/home/test/lib/lib.dart', 'var myFunction = () {};');
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
    addSource('/home/test/lib/lib.dart', '''
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
    addSource('/home/test/lib/lib.dart', 'int zero = 0;');
    await resolveTestCode('''
main() {
  zero();
}
''');
    await assertNoFix();
  }

  Future<void> test_withFunction_unresolvedMethod() async {
    addSource('/home/test/lib/lib.dart', '''
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
    addSource('/home/test/lib/lib.dart', '''
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

  Future<void> test_withMixin() async {
    addSource('/home/test/lib/lib.dart', '''
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

  Future<void> test_withTopLevelVariable() async {
    addSource('/home/test/lib/lib.dart', '''
library lib;
int MY_VAR = 42;
''');
    await resolveTestCode('''
main() {
  print(MY_VAR);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

main() {
  print(MY_VAR);
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject2Test extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT2;

  Future<void> test_lib() async {
    newFile('/.pub-cache/my_pkg/lib/a.dart', content: "export 'b.dart';");
    newFile('/.pub-cache/my_pkg/lib/b.dart', content: 'class Test {}');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'my_pkg', rootPath: '/.pub-cache/my_pkg'),
    );

    newFile('/home/test/pubspec.yaml', content: r'''
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
    newFile('/.pub-cache/my_pkg/lib/a.dart', content: "export 'src/b.dart';");
    newFile('/.pub-cache/my_pkg/lib/src/b.dart', content: 'class Test {}');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'my_pkg', rootPath: '/.pub-cache/my_pkg'),
    );

    newFile('/home/test/pubspec.yaml', content: r'''
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
    newFile('/.pub-cache/my_pkg/lib/a.dart', content: "export 'src/b.dart';");
    newFile('/.pub-cache/my_pkg/lib/src/b.dart', content: '''
extension E on int {
  static String m() => '';
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'my_pkg', rootPath: '/.pub-cache/my_pkg'),
    );

    newFile('/home/test/pubspec.yaml', content: r'''
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

  Future<void> test_inLibSrc_differentContextRoot() async {
    newFile('/.pub-cache/bbb/lib/b1.dart', content: r'''
import 'src/b2.dart';
class A {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'bbb', rootPath: '/.pub-cache/bbb'),
    );

    newFile('/.pub-cache/bbb/lib/src/b2.dart', content: 'class Test {}');
    await resolveTestCode('''
import 'package:bbb/b1.dart';
main() {
  Test t;
  A a;
  print('\$t \$a');
}
''');
    await assertNoFix();
  }

  Future<void> test_inLibSrc_thisContextRoot() async {
    addSource('/home/test/lib/src/lib.dart', 'class Test {}');
    await resolveTestCode('''
main() {
  Test t;
  print(t);
}
''');
    await assertHasFix('''
import 'package:test/src/lib.dart';

main() {
  Test t;
  print(t);
}
''');
  }

  Future<void> test_inLibSrc_thisContextRoot_extension() async {
    addSource('/home/test/lib/src/lib.dart', '''
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
}
