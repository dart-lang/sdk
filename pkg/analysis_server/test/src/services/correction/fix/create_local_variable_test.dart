// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateLocalVariableTest);
  });
}

@reflectiveTest
class CreateLocalVariableTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_LOCAL_VARIABLE;

  @override
  void setUp() {
    super.setUp();
    // TODO(dantup): Get these tests passing with either line ending.
    useLineEndingsForPlatform = false;
  }

  Future<void> test_functionType_named() async {
    await resolveTestCode('''
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

  Future<void> test_functionType_named_generic() async {
    await resolveTestCode('''
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

  Future<void> test_functionType_synthetic() async {
    await resolveTestCode('''
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

  Future<void> test_read_typeAssignment() async {
    await resolveTestCode('''
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

  Future<void> test_read_typeCondition() async {
    await resolveTestCode('''
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

  Future<void> test_read_typeInvocationArgument() async {
    await resolveTestCode('''
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

  Future<void> test_read_typeInvocationTarget() async {
    await resolveTestCode('''
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

  Future<void> test_withImport() async {
    newFile('$workspaceRootPath/pkg/lib/a/a.dart', content: '''
class A {}
''');
    newFile('$workspaceRootPath/pkg/lib/b/b.dart', content: '''
class B {}
''');
    newFile('$workspaceRootPath/pkg/lib/c/c.dart', content: '''
import 'package:pkg/a/a.dart';
import 'package:pkg/b/b.dart';

class C {
  C(A a, B b);
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await resolveTestCode('''
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
    var groups = change.linkedEditGroups;
    expect(groups, hasLength(2));
    var typeGroup = groups[0];
    var typePositions = typeGroup.positions;
    expect(typePositions, hasLength(1));
    expect(typePositions[0].offset, 112);
    var nameGroup = groups[1];
    var groupPositions = nameGroup.positions;
    expect(groupPositions, hasLength(2));
    expect(groupPositions[0].offset, 114);
    expect(groupPositions[1].offset, 128);
  }

  Future<void> test_write_assignment() async {
    await resolveTestCode('''
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

  Future<void> test_write_assignment_compound() async {
    await resolveTestCode('''
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
