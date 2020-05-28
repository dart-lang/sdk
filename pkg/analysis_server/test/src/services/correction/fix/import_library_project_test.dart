// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
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
    addSource('/home/test/lib/lib.dart', '''
class A {}
class B {}
''');
    await resolveTestUnit('''
import 'lib.dart' show A;
main() {
  A a;
  B b;
  print('\$a \$b');
}
''');
    await assertNoFix();
  }

  Future<void> test_lib() async {
    addPackageFile('my_pkg', 'a.dart', 'class Test {}');
    newFile('/home/test/pubspec.yaml', content: r'''
dependencies:
  my_pkg: any
''');

    await resolveTestUnit('''
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
    addPackageFile('my_pkg', 'a.dart', '''
extension E on int {
  static String m() => '';
}
''');
    newFile('/home/test/pubspec.yaml', content: r'''
dependencies:
  my_pkg: any
''');

    await resolveTestUnit('''
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
    addPackageFile('my_pkg', 'src/a.dart', 'class Test {}');
    newFile('/home/test/pubspec.yaml', content: r'''
dependencies:
  my_pkg: any
''');
    await resolveTestUnit('''
main() {
  Test test = null;
  print(test);
}
''');
    await assertNoFix();
  }

  Future<void> test_notInLib() async {
    addSource('/home/other/test/lib.dart', 'class Test {}');
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    addPackageFile('my_pkg', 'a.dart', "export 'b.dart';");
    addPackageFile('my_pkg', 'b.dart', 'class Test {}');
    newFile('/home/test/pubspec.yaml', content: r'''
dependencies:
  my_pkg: any
''');
    await resolveTestUnit('''
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
    addPackageFile('my_pkg', 'a.dart', "export 'src/b.dart';");
    addPackageFile('my_pkg', 'src/b.dart', 'class Test {}');
    newFile('/home/test/pubspec.yaml', content: r'''
dependencies:
  my_pkg: any
''');
    await resolveTestUnit('''
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
    addPackageFile('my_pkg', 'a.dart', "export 'src/b.dart';");
    addPackageFile('my_pkg', 'src/b.dart', '''
extension E on int {
  static String m() => '';
}
''');
    newFile('/home/test/pubspec.yaml', content: r'''
dependencies:
  my_pkg: any
''');
    await resolveTestUnit('''
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
    addPackageFile('bbb', 'b1.dart', r'''
import 'src/b2.dart';
class A {}
''');
    addPackageFile('bbb', 'src/b2.dart', 'class Test {}');
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
