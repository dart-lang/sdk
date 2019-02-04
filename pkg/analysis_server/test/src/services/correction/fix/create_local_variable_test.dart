// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateLocalVariableTest);
  });
}

@reflectiveTest
class CreateLocalVariableTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_LOCAL_VARIABLE;

  test_functionType_named() async {
    await resolveTestUnit('''
typedef MY_FUNCTION(int p);
foo(MY_FUNCTION f) {}
main() {
  foo(bar);
}
''');
    await assertHasFix('''
typedef MY_FUNCTION(int p);
foo(MY_FUNCTION f) {}
main() {
  MY_FUNCTION bar;
  foo(bar);
}
''');
  }

  test_functionType_named_generic() async {
    await resolveTestUnit('''
typedef MY_FUNCTION<T>(T p);
foo(MY_FUNCTION<int> f) {}
main() {
  foo(bar);
}
''');
    await assertHasFix('''
typedef MY_FUNCTION<T>(T p);
foo(MY_FUNCTION<int> f) {}
main() {
  MY_FUNCTION<int> bar;
  foo(bar);
}
''');
  }

  test_functionType_synthetic() async {
    await resolveTestUnit('''
foo(f(int p)) {}
main() {
  foo(bar);
}
''');
    await assertHasFix('''
foo(f(int p)) {}
main() {
  Function(int p) bar;
  foo(bar);
}
''');
  }

  test_read_typeAssignment() async {
    await resolveTestUnit('''
main() {
  int a = test;
  print(a);
}
''');
    await assertHasFix('''
main() {
  int test;
  int a = test;
  print(a);
}
''');
  }

  test_read_typeCondition() async {
    await resolveTestUnit('''
main() {
  if (!test) {
    print(42);
  }
}
''');
    await assertHasFix('''
main() {
  bool test;
  if (!test) {
    print(42);
  }
}
''');
  }

  test_read_typeInvocationArgument() async {
    await resolveTestUnit('''
main() {
  f(test);
}
f(String p) {}
''');
    await assertHasFix('''
main() {
  String test;
  f(test);
}
f(String p) {}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['String test;']);
    assertLinkedGroup(change.linkedEditGroups[1], ['test;', 'test);']);
  }

  test_read_typeInvocationTarget() async {
    await resolveTestUnit('''
main() {
  test.add('hello');
}
''');
    await assertHasFix('''
main() {
  var test;
  test.add('hello');
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['test;', 'test.add(']);
  }

  test_withImport() async {
    addPackageFile('pkg', 'a/a.dart', '''
class A {}
''');
    addPackageFile('pkg', 'b/b.dart', '''
class B {}
''');
    addPackageFile('pkg', 'c/c.dart', '''
import 'package:pkg/a/a.dart';
import 'package:pkg/b/b.dart';

class C {
  C(A a, B b);
}
''');

    await resolveTestUnit('''
import 'package:pkg/a/a.dart';
import 'package:pkg/c/c.dart';

main() {
  A a;
  new C(a, b);
}
''');
    await assertHasFix('''
import 'package:pkg/a/a.dart';
import 'package:pkg/b/b.dart';
import 'package:pkg/c/c.dart';

main() {
  A a;
  B b;
  new C(a, b);
}
''');
    List<LinkedEditGroup> groups = change.linkedEditGroups;
    expect(groups, hasLength(2));
    LinkedEditGroup typeGroup = groups[0];
    List<Position> typePositions = typeGroup.positions;
    expect(typePositions, hasLength(1));
    expect(typePositions[0].offset, 112);
    LinkedEditGroup nameGroup = groups[1];
    List<Position> groupPositions = nameGroup.positions;
    expect(groupPositions, hasLength(2));
    expect(groupPositions[0].offset, 114);
    expect(groupPositions[1].offset, 128);
  }

  test_write_assignment() async {
    await resolveTestUnit('''
main() {
  test = 42;
}
''');
    await assertHasFix('''
main() {
  var test = 42;
}
''');
  }

  test_write_assignment_compound() async {
    await resolveTestUnit('''
main() {
  test += 42;
}
''');
    await assertHasFix('''
main() {
  int test;
  test += 42;
}
''');
  }
}
