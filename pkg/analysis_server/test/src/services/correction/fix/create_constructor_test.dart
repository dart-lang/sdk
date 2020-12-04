// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateConstructorTest);
    defineReflectiveTests(CreateConstructorMixinTest);
  });
}

@reflectiveTest
class CreateConstructorMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CONSTRUCTOR;

  Future<void> test_named() async {
    await resolveTestCode('''
mixin M {}

main() {
  new M.named();
}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class CreateConstructorTest extends FixProcessorTest {
  static final _text200 = 'x' * 200;

  @override
  FixKind get kind => DartFixKind.CREATE_CONSTRUCTOR;

  Future<void> test_inLibrary_insteadOfSyntheticDefault() async {
    var a = newFile('/home/test/lib/a.dart', content: '''
/// $_text200
class A {}
''').path;
    await resolveTestCode('''
import 'a.dart';

main() {
  new A.named(1, 2.0);
}
''');
    await assertHasFix('''
/// $_text200
class A {
  A.named(int i, double d);
}
''', target: a);
  }

  Future<void> test_inLibrary_named() async {
    var a = newFile('/home/test/lib/a.dart', content: '''
/// $_text200
class A {}
''').path;
    await resolveTestCode('''
import 'a.dart';

main() {
  new A(1, 2.0);
}
''');
    await assertHasFix('''
/// $_text200
class A {
  A(int i, double d);
}
''', target: a);
  }

  Future<void> test_insteadOfSyntheticDefault() async {
    await resolveTestCode('''
class A {
  int field;

  method() {}
}
main() {
  new A(1, 2.0);
}
''');
    await assertHasFix('''
class A {
  int field;

  A(int i, double d);

  method() {}
}
main() {
  new A(1, 2.0);
}
''');
  }

  Future<void> test_mixin() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
mixin M {}
void f() {
  new M(3);
}
''');
    await assertNoFix(
        errorFilter: (error) =>
            error.errorCode != CompileTimeErrorCode.MIXIN_INSTANTIATE);
  }

  Future<void> test_named() async {
    await resolveTestCode('''
class A {
  method() {}
}
main() {
  new A.named(1, 2.0);
}
''');
    await assertHasFix('''
class A {
  A.named(int i, double d);

  method() {}
}
main() {
  new A.named(1, 2.0);
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['named(int ', 'named(1']);
  }

  Future<void> test_named_emptyClassBody() async {
    await resolveTestCode('''
class A {}
main() {
  new A.named(1);
}
''');
    await assertHasFix('''
class A {
  A.named(int i);
}
main() {
  new A.named(1);
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['named(int ', 'named(1']);
  }
}
