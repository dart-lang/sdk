// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateClassTest);
  });
}

@reflectiveTest
class CreateClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CLASS;

  Future<void> test_annotation() async {
    await resolveTestUnit('''
@Test('a')
void f() {}
''');
    await assertHasFix('''
@Test('a')
void f() {}

class Test {
  const Test(String s);
}
''');
    assertLinkedGroup(
        change.linkedEditGroups[0], ["Test('", 'Test {', 'Test(S']);
  }

  Future<void> test_extends() async {
    await resolveTestUnit('''
class MyClass extends BaseClass {}
''');
    await assertHasFix('''
class MyClass extends BaseClass {}

class BaseClass {
}
''');
  }

  Future<void> test_hasUnresolvedPrefix() async {
    await resolveTestUnit('''
main() {
  prefix.Test v = null;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_implements() async {
    await resolveTestUnit('''
class MyClass implements BaseClass {}
''');
    await assertHasFix('''
class MyClass implements BaseClass {}

class BaseClass {
}
''');
  }

  Future<void> test_inLibraryOfPrefix() async {
    addSource('/home/test/lib/lib.dart', r'''
class A {}
''');

    await resolveTestUnit('''
import 'lib.dart' as lib;

main() {
  lib.A a = null;
  lib.Test t = null;
  print('\$a \$t');
}
''');

    await assertHasFix('''
class A {}

class Test {
}
''', target: '/home/test/lib/lib.dart');
    expect(change.linkedEditGroups, hasLength(1));
  }

  Future<void> test_innerLocalFunction() async {
    await resolveTestUnit('''
f() {
  g() {
    Test v = null;
    print(v);
  }
  g();
}
''');
    await assertHasFix('''
f() {
  g() {
    Test v = null;
    print(v);
  }
  g();
}

class Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test v =', 'Test {']);
  }

  Future<void> test_instanceCreation_withoutNew_fromFunction() async {
    await resolveTestUnit('''
main() {
  Test ();
}
''');
    await assertHasFix('''
main() {
  Test ();
}

class Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test ()', 'Test {']);
  }

  Future<void> test_instanceCreation_withoutNew_fromMethod() async {
    await resolveTestUnit('''
class A {
  main() {
    Test ();
  }
}
''');
    await assertHasFix('''
class A {
  main() {
    Test ();
  }
}

class Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test ()', 'Test {']);
  }

  Future<void> test_itemOfList() async {
    await resolveTestUnit('''
main() {
  var a = [Test];
  print(a);
}
''');
    await assertHasFix('''
main() {
  var a = [Test];
  print(a);
}

class Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test];', 'Test {']);
  }

  Future<void> test_itemOfList_inAnnotation() async {
    await resolveTestUnit('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Test])
main() {}
''');
    await assertHasFix('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Test])
main() {}

class Test {
}
''', errorFilter: (error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER;
    });
    assertLinkedGroup(change.linkedEditGroups[0], ['Test])', 'Test {']);
  }

  Future<void> test_simple() async {
    await resolveTestUnit('''
main() {
  Test v = null;
  print(v);
}
''');
    await assertHasFix('''
main() {
  Test v = null;
  print(v);
}

class Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test v =', 'Test {']);
  }

  Future<void> test_with() async {
    await resolveTestUnit('''
class MyClass with BaseClass {}
''');
    await assertHasFix('''
class MyClass with BaseClass {}

class BaseClass {
}
''');
  }
}
