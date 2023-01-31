// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeSuperInvocationLastTest);
  });
}

@reflectiveTest
class MakeSuperInvocationLastTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.MAKE_SUPER_INVOCATION_LAST;

  Future<void> test_assert() async {
    await resolveTestCode('''
class A {
  A(int? x) : super(), assert(x != null);
}
''');
    await assertHasFix('''
class A {
  A(int? x) : assert(x != null), super();
}
''');
  }

  Future<void> test_assignment() async {
    await resolveTestCode('''
class A {
  final int x;
  final int y;
  A() : x = 1, super(), y = 1;
}
''');
    await assertHasFix('''
class A {
  final int x;
  final int y;
  A() : x = 1, y = 1, super();
}
''');
  }

  Future<void> test_comment() async {
    await resolveTestCode('''
class A {
  final int x;
  final int y;
  A() : x = 1, /* something */ super(), y = 1;
}
''');
    await assertHasFix('''
class A {
  final int x;
  final int y;
  A() : x = 1, y = 1, /* something */ super();
}
''');
  }

  Future<void> test_comment_last() async {
    await resolveTestCode('''
class A {
  final int x;
  final int y;
  A() : x = 1, /* something */ super(), /* assign */ y = 1;
}
''');
    await assertHasFix('''
class A {
  final int x;
  final int y;
  A() : x = 1, /* assign */ y = 1, /* something */ super();
}
''');
  }

  Future<void> test_comment_last_multiple() async {
    await resolveTestCode('''
class A {
  final int x;
  final int y;
  A() : x = 1, /* s1 */ /* s2 */ super(), /* a1 */ /* a2 */ y = 1;
}
''');
    await assertHasFix('''
class A {
  final int x;
  final int y;
  A() : x = 1, /* a1 */ /* a2 */ y = 1, /* s1 */ /* s2 */ super();
}
''');
  }

  Future<void> test_comment_trailing() async {
    await resolveTestCode('''
class A {
  final int x;
  final int y;
  A() :
    x = 1, /* s1 */ super() /* s2 */ /* s3 */, /* a1 */ y = 1 /* a2 */ /* a2 */;
}
''');
    await assertHasFix('''
class A {
  final int x;
  final int y;
  A() :
    x = 1, /* a1 */ y = 1 /* a2 */ /* a2 */, /* s1 */ super() /* s2 */ /* s3 */;
}
''');
  }
}
