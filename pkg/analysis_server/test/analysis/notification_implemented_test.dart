// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationImplementedTest);
  });
}

@reflectiveTest
class AnalysisNotificationImplementedTest extends PubPackageAnalysisServerTest {
  List<ImplementedClass>? implementedClasses;
  List<ImplementedMember>? implementedMembers;

  /// Validates that there is an [ImplementedClass] at the offset of [search].
  ///
  /// If [length] is not specified explicitly, then length of an identifier
  /// from [search] is used.
  void assertHasImplementedClass(String search, [int length = -1]) {
    var offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    if (implementedClasses == null) {
      fail('No notification of implemented classes was received');
    }
    for (var clazz in implementedClasses!) {
      if (clazz.offset == offset && clazz.length == length) {
        return;
      }
    }
    fail('Expect to find an implemented class at $offset'
        ' in $implementedClasses');
  }

  /// Validates that there is an [ImplementedClass] at the offset of [search].
  ///
  /// If [length] is not specified explicitly, then length of an identifier
  /// from [search] is used.
  void assertHasImplementedMember(String search, [int length = -1]) {
    var offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    if (implementedMembers == null) {
      fail('No notification of implemented members was received');
    }
    for (var member in implementedMembers!) {
      if (member.offset == offset && member.length == length) {
        return;
      }
    }
    fail('Expect to find an implemented member at $offset'
        ' in $implementedMembers');
  }

  /// Validates that there is no [ImplementedMember] at the offset of [search].
  ///
  /// If [length] is not specified explicitly, then length of an identifier
  /// from [search] is used.
  void assertNoImplementedMember(String search, [int length = -1]) {
    var offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    if (implementedMembers == null) {
      fail('No notification of implemented members was received');
    }
    for (var member in implementedMembers!) {
      if (member.offset == offset) {
        fail('Unexpected implemented member at $offset'
            ' in $implementedMembers');
      }
    }
  }

  /// Subscribe for `IMPLEMENTED` and wait for the notification.
  Future<void> prepareImplementedElements() async {
    await subscribeForImplemented();
    return waitForImplementedElements();
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_IMPLEMENTED) {
      var params = AnalysisImplementedParams.fromNotification(notification);
      if (params.file == testFile.path) {
        implementedClasses = params.classes;
        implementedMembers = params.members;
      }
    }
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> subscribeForImplemented() async {
    setPriorityFiles([testFile]);
    await addAnalysisSubscription(AnalysisService.IMPLEMENTED, testFile);
  }

  Future<void> test_afterAnalysis() async {
    addTestFile('''
class A {}
class B extends A {}
''');
    await waitForTasksFinished();
    await prepareImplementedElements();
    assertHasImplementedClass('A {');
  }

  Future<void> test_class_extended() async {
    addTestFile('''
class A {}
class B extends A {}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('A {');
  }

  Future<void> test_class_implementedBy_class() async {
    addTestFile('''
class A {}
class B implements A {}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('A {');
  }

  Future<void> test_class_implementedBy_enum() async {
    addTestFile('''
class A {}

enum E implements A {
  v
}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('A {');
  }

  Future<void> test_class_implementedBy_enum_getterByGetter() async {
    addTestFile('''
class A {
  int get foo => 0; // A
}

enum E implements A {
  v;
  int get foo => 0; // E
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('foo => 0; // A');
    assertNoImplementedMember('foo => 0; // E');
  }

  Future<void> test_class_implementedBy_enum_methodByMethod() async {
    addTestFile('''
class A {
  void foo() {} // A
}

enum E implements A {
  v;
  void foo() {} // E
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('foo() {} // A');
    assertNoImplementedMember('foo() {} // E');
  }

  Future<void> test_class_implementedBy_enum_setterBySetter() async {
    addTestFile('''
class A {
  set foo(int _) {} // A
}

enum E implements A {
  v;
  set foo(int _) {} // E
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('foo(int _) {} // A');
    assertNoImplementedMember('foo(int _) {} // E');
  }

  Future<void> test_class_implementedBy_extensionType() async {
    addTestFile('''
class A {}
extension type B(A it) implements A {}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('A {');
  }

  Future<void> test_class_implementedBy_mixin() async {
    addTestFile('''
class A {} // ref
class B {} // ref
class C {} // ref
class D {} // ref
mixin M on A, B implements C, D {}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('A {} // ref');
    assertHasImplementedClass('B {} // ref');
    assertHasImplementedClass('C {} // ref');
    assertHasImplementedClass('D {} // ref');
  }

  Future<void> test_class_mixedBy_class() async {
    addTestFile('''
class A {}
class B = Object with A;
''');
    await prepareImplementedElements();
    assertHasImplementedClass('A {');
  }

  Future<void> test_class_mixedBy_enum() async {
    addTestFile('''
mixin M {}
enum E with M {
  v
}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('M {}');
  }

  Future<void> test_class_mixedBy_enum_methodByMethod() async {
    addTestFile('''
class M {
  void foo() {} // M
}

enum E with M {
  v;
  void foo() {} // E
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('foo() {} // M');
    assertNoImplementedMember('foo() {} // E');
  }

  Future<void> test_extensionType_implementedBy_extensionType() async {
    addTestFile('''
extension type A(int it) {}
extension type B(int it) implements A {}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('A(int it)');
  }

  Future<void> test_mixin_implemented() async {
    addTestFile('''
mixin M { // ref
  void foo() {} // ref
  void bar() {} // ref
}

class A implements M {
  void foo() {}
}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('M { // ref');
    assertHasImplementedMember('foo() {} // ref');
    assertNoImplementedMember('bar() {} // ref');
  }

  Future<void> test_mixin_mixed() async {
    addTestFile('''
mixin M { // ref
  void foo() {} // ref
  void bar() {} // ref
}

class A extends Object with M {
  void foo() {}
}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('M { // ref');
    assertHasImplementedMember('foo() {} // ref');
    assertNoImplementedMember('bar() {} // ref');
  }

  Future<void> test_ofClass_byClass_field_withField() async {
    addTestFile('''
class A {
  int f; // A
}
class B extends A {
  int f;
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('f; // A');
  }

  Future<void> test_ofClass_byClass_field_withGetter() async {
    addTestFile('''
class A {
  int f; // A
}
class B extends A {
  get f => null;
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('f; // A');
  }

  Future<void> test_ofClass_byClass_field_withSetter() async {
    addTestFile('''
class A {
  int f; // A
}
class B extends A {
  void set f(_) {}
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('f; // A');
  }

  Future<void> test_ofClass_byClass_getter_withField() async {
    addTestFile('''
class A {
  get f => null; // A
}
class B extends A {
  int f;
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('f => null; // A');
  }

  Future<void> test_ofClass_byClass_getter_withGetter() async {
    addTestFile('''
class A {
  get f => null; // A
}
class B extends A {
  get f => null;
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('f => null; // A');
  }

  Future<void> test_ofClass_byClass_method_withMethod() async {
    addTestFile('''
class A {
  m() {} // A
}
class B extends A {
  m() {} // B
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('m() {} // A');
    assertNoImplementedMember('m() {} // B');
  }

  Future<void> test_ofClass_byClass_method_withMethod_indirectSubclass() async {
    addTestFile('''
class A {
  m() {} // A
}
class B extends A {
}
class C extends A {
  m() {}
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('m() {} // A');
  }

  Future<void>
      test_ofClass_byClass_method_withMethod_private_differentLib() async {
    newFile('$testPackageLibPath/lib.dart', r'''
import 'test.dart';
class B extends A {
  void _m() {}
}
''');
    addTestFile('''
class A {
  _m() {} // A
}
''');
    await prepareImplementedElements();
    assertNoImplementedMember('_m() {} // A');
  }

  Future<void>
      test_ofClass_byClass_method_withMethod_private_sameLibrary() async {
    addTestFile('''
class A {
  _m() {} // A
}
class B extends A {
  _m() {} // B
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('_m() {} // A');
    assertNoImplementedMember('_m() {} // B');
  }

  Future<void> test_ofClass_byClass_method_withMethod_wasAbstract() async {
    addTestFile('''
abstract class A {
  m(); // A
}
class B extends A {
  m() {}
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('m(); // A');
  }

  Future<void> test_ofClass_byClass_setter_withField() async {
    addTestFile('''
class A {
  set f(_) {} // A
}
class B extends A {
  int f;
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('f(_) {} // A');
  }

  Future<void> test_ofClass_byClass_setter_withSetter() async {
    addTestFile('''
class A {
  set f(_) {} // A
}
class B extends A {
  set f(_) {} // B
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('f(_) {} // A');
  }

  Future<void> test_ofClass_byClass_static_field_instanceStatic() async {
    addTestFile('''
class A {
  int F = 0;
}
class B extends A {
  static int F = 1;
}
''');
    await prepareImplementedElements();
    assertNoImplementedMember('F = 0');
  }

  Future<void> test_ofClass_byClass_static_field_staticInstance() async {
    addTestFile('''
class A {
  static int F = 0;
}
class B extends A {
  int F = 1;
}
''');
    await prepareImplementedElements();
    assertNoImplementedMember('F = 0');
  }

  Future<void> test_ofClass_byClass_static_field_staticStatic() async {
    addTestFile('''
class A {
  static int F = 0;
}
class B extends A {
  static int F = 1;
}
''');
    await prepareImplementedElements();
    assertNoImplementedMember('F = 0');
  }

  Future<void> test_ofClass_byClass_static_method_instanceStatic() async {
    addTestFile('''
class A {
  int m() => 0;
}
class B extends A {
  static int m() => 1;
}
''');
    await prepareImplementedElements();
    assertNoImplementedMember('m() => 0');
  }

  Future<void> test_ofClass_byClass_static_method_staticInstance() async {
    addTestFile('''
class A {
  static int m() => 0;
}
class B extends A {
  int m() => 1;
}
''');
    await prepareImplementedElements();
    assertNoImplementedMember('m() => 0');
  }

  Future<void> test_ofClass_byClass_static_method_staticStatic() async {
    addTestFile('''
class A {
  static int m() => 0;
}
class B extends A {
  static int m() => 1;
}
''');
    await prepareImplementedElements();
    assertNoImplementedMember('m() => 0');
  }

  Future<void> test_ofClass_byExtensionType_method_withMethod() async {
    addTestFile('''
class A {
  void foo() {} // A
}
extension type E(A it) implements A {
  void foo() {} // B
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('foo() {} // A');
    assertNoImplementedMember('foo() {} // B');
  }

  Future<void> test_ofExtensionType_method_withMethod() async {
    addTestFile('''
extension type A(int) {
  void foo() {} // A
}
extension type B(int) implements A {
  void foo() {} // B
}
''');
    await prepareImplementedElements();
    assertHasImplementedMember('foo() {} // A');
    assertNoImplementedMember('foo() {} // B');
  }

  Future<void> waitForImplementedElements() {
    Future<void> waitForNotification(int times) {
      if (times == 0 || implementedClasses != null) {
        return Future.value();
      }
      return Future.delayed(
          Duration(milliseconds: 1), () => waitForNotification(times - 1));
    }

    return waitForNotification(30000);
  }
}
