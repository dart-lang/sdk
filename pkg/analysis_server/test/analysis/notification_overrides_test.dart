// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.notification.overrides;

import 'dart:async';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';
import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisNotificationOverridesTest);
}


@ReflectiveTestCase()
class AnalysisNotificationOverridesTest extends AbstractAnalysisTest {
  List<Override> overridesList;
  Override override;

  /**
   * Asserts that there is an overridden interface [OverriddenMember] at the
   * offset of [search] in [override].
   */
  void assertHasInterfaceMember(String search) {
    int offset = findOffset(search);
    for (OverriddenMember member in override.interfaceMembers) {
      if (member.element.location.offset == offset) {
        return;
      }
    }
    fail(
        'Expect to find an overridden interface members at $offset in '
            '${override.interfaceMembers.join('\n')}');
  }

  /**
   * Validates that there is an [Override] at the offset of [search].
   *
   * If [length] is not specified explicitly, then length of an identifier
   * from [search] is used.
   */
  void assertHasOverride(String search, [int length = -1]) {
    int offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    findOverride(offset, length, true);
  }

  /**
   * Asserts that there is an overridden superclass [OverriddenMember] at the
   * offset of [search] in [override].
   */
  void assertHasSuperElement(String search) {
    int offset = findOffset(search);
    OverriddenMember member = override.superclassMember;
    expect(member.element.location.offset, offset);
  }

  /**
   * Asserts that there are no overridden members from interfaces.
   */
  void assertNoInterfaceMembers() {
    expect(override.interfaceMembers, isEmpty);
  }

  /**
   * Asserts that there are no overridden member from the superclass.
   */
  void assertNoSuperMember() {
    expect(override.superclassMember, isNull);
  }

  /**
   * Finds an [Override] with the given [offset] and [length].
   *
   * If [exists] is `true`, then fails if such [Override] does not exist.
   * Otherwise remembers this it into [override].
   *
   * If [exists] is `false`, then fails if such [Override] exists.
   */
  void findOverride(int offset, int length, [bool exists]) {
    for (Override override in overridesList) {
      if (override.offset == offset && override.length == length) {
        if (exists == false) {
          fail(
              'Not expected to find (offset=$offset; length=$length) in\n'
                  '${overridesList.join('\n')}');
        }
        this.override = override;
        return;
      }
    }
    if (exists == true) {
      fail(
          'Expected to find (offset=$offset; length=$length) in\n'
              '${overridesList.join('\n')}');
    }
  }

  Future prepareOverrides() {
    addAnalysisSubscription(AnalysisService.OVERRIDES, testFile);
    return waitForTasksFinished();
  }

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_OVERRIDES) {
      var params = new AnalysisOverridesParams.fromNotification(notification);
      if (params.file == testFile) {
        overridesList = params.overrides;
      }
    }
  }

  void setUp() {
    super.setUp();
    createProject();
  }

  test_afterAnalysis() {
    addTestFile('''
class A {
  m() {} // in A
}
class B implements A {
  m() {} // in B
}
''');
    return waitForTasksFinished().then((_) {
      return prepareOverrides().then((_) {
        assertHasOverride('m() {} // in B');
        assertNoSuperMember();
        assertHasInterfaceMember('m() {} // in A');
      });
    });
  }

  test_interface_method_direct_multiple() {
    addTestFile('''
class IA {
  m() {} // in IA
}
class IB {
  m() {} // in IB
}
class A implements IA, IB {
  m() {} // in A
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('m() {} // in A');
      assertNoSuperMember();
      assertHasInterfaceMember('m() {} // in IA');
      assertHasInterfaceMember('m() {} // in IB');
    });
  }

  test_interface_method_direct_single() {
    addTestFile('''
class A {
  m() {} // in A
}
class B implements A {
  m() {} // in B
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('m() {} // in B');
      assertNoSuperMember();
      assertHasInterfaceMember('m() {} // in A');
    });
  }

  test_interface_method_indirect_single() {
    addTestFile('''
class A {
  m() {} // in A
}
class B extends A {
}
class C implements B {
  m() {} // in C
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('m() {} // in C');
      assertNoSuperMember();
      assertHasInterfaceMember('m() {} // in A');
    });
  }

  test_super_fieldByField() {
    addTestFile('''
class A {
  int fff; // in A
}
class B extends A {
  int fff; // in B
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('fff; // in B');
      assertHasSuperElement('fff; // in A');
      assertNoInterfaceMembers();
    });
  }

  test_super_fieldByGetter() {
    addTestFile('''
class A {
  int fff; // in A
}
class B extends A {
  get fff => 0; // in B
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('fff => 0; // in B');
      assertHasSuperElement('fff; // in A');
      assertNoInterfaceMembers();
    });
  }

  test_super_fieldByMethod() {
    addTestFile('''
class A {
  int fff; // in A
}
class B extends A {
  fff() {} // in B
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('fff() {} // in B');
      assertHasSuperElement('fff; // in A');
      assertNoInterfaceMembers();
    });
  }

  test_super_fieldBySetter() {
    addTestFile('''
class A {
  int fff; // in A
}
class B extends A {
  set fff(x) {} // in B
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('fff(x) {} // in B');
      assertHasSuperElement('fff; // in A');
      assertNoInterfaceMembers();
    });
  }

  test_super_getterByField() {
    addTestFile('''
class A {
  get fff => 0; // in A
  set fff(x) {} // in A
}
class B extends A {
  int fff; // in B
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('fff; // in B');
      assertHasSuperElement('fff => 0; // in A');
      assertNoInterfaceMembers();
    });
  }

  test_super_getterByGetter() {
    addTestFile('''
class A {
  get fff => 0; // in A
}
class B extends A {
  get fff => 0; // in B
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('fff => 0; // in B');
      assertHasSuperElement('fff => 0; // in A');
      assertNoInterfaceMembers();
    });
  }

  test_super_method_direct() {
    addTestFile('''
class A {
  m() {} // in A
}
class B extends A {
  m() {} // in B
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('m() {} // in B');
      assertHasSuperElement('m() {} // in A');
      assertNoInterfaceMembers();
    });
  }

  test_super_method_indirect() {
    addTestFile('''
class A {
  m() {} // in A
}
class B extends A {
}
class C extends B {
  m() {} // in C
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('m() {} // in C');
      assertHasSuperElement('m() {} // in A');
      assertNoInterfaceMembers();
    });
  }

  test_super_setterBySetter() {
    addTestFile('''
class A {
  set fff(x) {} // in A
}
class B extends A {
  set fff(x) {} // in B
}
''');
    return prepareOverrides().then((_) {
      assertHasOverride('fff(x) {} // in B');
      assertHasSuperElement('fff(x) {} // in A');
      assertNoInterfaceMembers();
    });
  }
}
