// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationImplementedTest);
  });
}

@reflectiveTest
class AnalysisNotificationImplementedTest extends AbstractAnalysisTest {
  List<ImplementedClass> implementedClasses;
  List<ImplementedMember> implementedMembers;

  /**
   * Validates that there is an [ImplementedClass] at the offset of [search].
   *
   * If [length] is not specified explicitly, then length of an identifier
   * from [search] is used.
   */
  void assertHasImplementedClass(String search, [int length = -1]) {
    int offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    if (implementedClasses == null) {
      fail('No notification of impemented classes was received');
    }
    for (ImplementedClass clazz in implementedClasses) {
      if (clazz.offset == offset && clazz.length == length) {
        return;
      }
    }
    fail('Expect to find an implemented class at $offset'
        ' in $implementedClasses');
  }

  /**
   * Validates that there is an [ImplementedClass] at the offset of [search].
   *
   * If [length] is not specified explicitly, then length of an identifier
   * from [search] is used.
   */
  void assertHasImplementedMember(String search, [int length = -1]) {
    int offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    if (implementedMembers == null) {
      fail('No notification of impemented members was received');
    }
    for (ImplementedMember member in implementedMembers) {
      if (member.offset == offset && member.length == length) {
        return;
      }
    }
    fail('Expect to find an implemented member at $offset'
        ' in $implementedMembers');
  }

  /**
   * Validates that there is no an [ImplementedClass] at the offset of [search].
   *
   * If [length] is not specified explicitly, then length of an identifier
   * from [search] is used.
   */
  void assertNoImplementedMember(String search, [int length = -1]) {
    int offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    if (implementedMembers == null) {
      fail('No notification of impemented members was received');
    }
    for (ImplementedMember member in implementedMembers) {
      if (member.offset == offset) {
        fail('Unexpected implemented member at $offset'
            ' in $implementedMembers');
      }
    }
  }

  /**
   * Subscribe for `IMPLEMENTED` and wait for the notification.
   */
  Future prepareImplementedElements() {
    subscribeForImplemented();
    return waitForImplementedElements();
  }

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_IMPLEMENTED) {
      var params = new AnalysisImplementedParams.fromNotification(notification);
      if (params.file == testFile) {
        implementedClasses = params.classes;
        implementedMembers = params.members;
      }
    }
  }

  void setUp() {
    super.setUp();
    createProject();
  }

  void subscribeForImplemented() {
    setPriorityFiles([testFile]);
    addAnalysisSubscription(AnalysisService.IMPLEMENTED, testFile);
  }

  test_afterAnalysis() async {
    addTestFile('''
class A {}
class B extends A {}
''');
    await waitForTasksFinished();
    await prepareImplementedElements();
    assertHasImplementedClass('A {');
  }

  test_afterIncrementalResolution() async {
    subscribeForImplemented();
    addTestFile('''
class A {}
class B extends A {}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('A {');
    // add a space
    implementedClasses = null;
    testCode = '''
class A  {}
class B extends A {}
''';
    server.updateContent('1', {testFile: new AddContentOverlay(testCode)});
    await waitForImplementedElements();
    assertHasImplementedClass('A  {');
  }

  test_class_extended() async {
    addTestFile('''
class A {}
class B extends A {}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('A {');
  }

  test_class_implemented() async {
    addTestFile('''
class A {}
class B implements A {}
''');
    await prepareImplementedElements();
    assertHasImplementedClass('A {');
  }

  test_class_mixed() async {
    addTestFile('''
class A {}
class B = Object with A;
''');
    await prepareImplementedElements();
    assertHasImplementedClass('A {');
  }

  test_field_withField() async {
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

  test_field_withGetter() async {
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

  test_field_withSetter() async {
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

  test_getter_withField() async {
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

  test_getter_withGetter() async {
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

  test_method_withMethod() async {
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

  test_method_withMethod_indirectSubclass() async {
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

  test_method_withMethod_private_differentLib() async {
    addFile('$testFolder/lib.dart', r'''
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

  test_method_withMethod_private_sameLibrary() async {
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

  test_method_withMethod_wasAbstract() async {
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

  test_setter_withField() async {
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

  test_setter_withSetter() async {
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

  test_static_field_instanceStatic() async {
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

  test_static_field_staticInstance() async {
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

  test_static_field_staticStatic() async {
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

  test_static_method_instanceStatic() async {
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

  test_static_method_staticInstance() async {
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

  test_static_method_staticStatic() async {
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

  Future waitForImplementedElements() {
    Future waitForNotification(int times) {
      if (times == 0 || implementedClasses != null) {
        return new Future.value();
      }
      return new Future.delayed(
          new Duration(milliseconds: 1), () => waitForNotification(times - 1));
    }

    return waitForNotification(30000);
  }
}
