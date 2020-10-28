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
main() {
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
    addSource('/home/test/lib/lib.dart', libCode);
    await resolveTestCode('''
import 'lib.dart' as lib;

main() {
  lib.A a = null;
  lib.Test t = null;
  print('\$a \$t');
}
''');
    await assertHasFix('''
class A {}

mixin Test {
}
''', target: '/home/test/lib/lib.dart');
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
main() {
  new Test();
}
''');
    await assertNoFix();
  }

  Future<void> test_instanceCreation_withoutNew() async {
    await resolveTestCode('''
main() {
  Test();
}
''');
    await assertNoFix();
  }

  Future<void> test_itemOfList() async {
    await resolveTestCode('''
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
main() {}
''');
    await assertHasFix('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Test])
main() {}

mixin Test {
}
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.UNDEFINED_IDENTIFIER;
    });
    assertLinkedGroup(change.linkedEditGroups[0], ['Test])', 'Test {']);
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
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

mixin Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test v =', 'Test {']);
  }
}
