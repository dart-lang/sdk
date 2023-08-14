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
    defineReflectiveTests(CreateMixinTest);
  });
}

@reflectiveTest
class CreateMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_MIXIN;

  Future<void> test_hasUnresolvedPrefix() async {
    await resolveTestCode('''
void f() {
  prefix.Test v = null;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_inLibraryOfPrefix() async {
    var libCode = r'''
class A {}
''';
    newFile('$testPackageLibPath/lib.dart', libCode);
    await resolveTestCode('''
import 'lib.dart' as lib;

void f() {
  lib.A? a = null;
  lib.Test? t = null;
  print('\$a \$t');
}
''');
    await assertHasFix('''
class A {}

mixin Test {
}
''', target: '$testPackageLibPath/lib.dart');
    expect(change.linkedEditGroups, hasLength(1));
  }

  Future<void> test_innerLocalFunction() async {
    await resolveTestCode('''
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

mixin Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test v =', 'Test {']);
  }

  Future<void> test_instanceCreation_withNew() async {
    await resolveTestCode('''
void f() {
  new Test();
}
''');
    await assertNoFix();
  }

  Future<void> test_instanceCreation_withoutNew() async {
    await resolveTestCode('''
void f() {
  Test();
}
''');
    await assertNoFix();
  }

  Future<void> test_itemOfList() async {
    await resolveTestCode('''
void f() {
  var a = [Test];
  print(a);
}
''');
    await assertHasFix('''
void f() {
  var a = [Test];
  print(a);
}

mixin Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test];', 'Test {']);
  }

  Future<void> test_itemOfList_inAnnotation() async {
    await resolveTestCode('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Test])
void f() {}
''');
    await assertHasFix('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Test])
void f() {}

mixin Test {
}
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.UNDEFINED_IDENTIFIER;
    });
    assertLinkedGroup(change.linkedEditGroups[0], ['Test])', 'Test {']);
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
void f() {
  Test v = null;
  print(v);
}
''');
    await assertHasFix('''
void f() {
  Test v = null;
  print(v);
}

mixin Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test v =', 'Test {']);
  }
}
