// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationOverridesTest);
  });
}

@reflectiveTest
class AnalysisNotificationOverridesTest extends AbstractAnalysisTest {
  List<Override> overridesList;
  Override overrideObject;

  final Completer<void> _resultsAvailable = Completer();

  /// Asserts that there is an overridden interface [OverriddenMember] at the
  /// offset of [search] in [override].
  void assertHasInterfaceMember(String search) {
    var offset = findOffset(search);
    for (var member in overrideObject.interfaceMembers) {
      if (member.element.location.offset == offset) {
        return;
      }
    }
    fail('Expect to find an overridden interface members at $offset in '
        '${overrideObject.interfaceMembers.join('\n')}');
  }

  /// Validates that there is an [Override] at the offset of [search].
  ///
  /// If [length] is not specified explicitly, then length of an identifier
  /// from [search] is used.
  void assertHasOverride(String search, [int length = -1]) {
    var offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    findOverride(offset, length, true);
  }

  /// Asserts that there is an overridden superclass [OverriddenMember] at the
  /// offset of [search] in [override].
  void assertHasSuperElement(String search) {
    var offset = findOffset(search);
    var member = overrideObject.superclassMember;
    expect(member.element.location.offset, offset);
  }

  /// Asserts that there are no overridden members from interfaces.
  void assertNoInterfaceMembers() {
    expect(overrideObject.interfaceMembers, isNull);
  }

  /// Validates that there is no [Override] at the offset of [search].
  ///
  /// If [length] is not specified explicitly, then length of an identifier
  /// from [search] is used.
  void assertNoOverride(String search, [int length = -1]) {
    var offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    findOverride(offset, length, false);
  }

  /// Asserts that there are no overridden member from the superclass.
  void assertNoSuperMember() {
    expect(overrideObject.superclassMember, isNull);
  }

  /// Finds an [Override] with the given [offset] and [length].
  ///
  /// If [exists] is `true`, then fails if such [Override] does not exist.
  /// Otherwise remembers this it into [override].
  ///
  /// If [exists] is `false`, then fails if such [Override] exists.
  void findOverride(int offset, int length, [bool exists]) {
    for (var override in overridesList) {
      if (override.offset == offset && override.length == length) {
        if (exists == false) {
          fail('Not expected to find (offset=$offset; length=$length) in\n'
              '${overridesList.join('\n')}');
        }
        overrideObject = override;
        return;
      }
    }
    if (exists == true) {
      fail('Expected to find (offset=$offset; length=$length) in\n'
          '${overridesList.join('\n')}');
    }
  }

  Future prepareOverrides() {
    addAnalysisSubscription(AnalysisService.OVERRIDES, testFile);
    return _resultsAvailable.future;
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_OVERRIDES) {
      var params = AnalysisOverridesParams.fromNotification(notification);
      if (params.file == testFile) {
        overridesList = params.overrides;
        _resultsAvailable.complete();
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  Future<void> test_afterAnalysis() async {
    addTestFile('''
class A {
  m() {} // in A
}
class B implements A {
  m() {} // in B
}
''');
    await waitForTasksFinished();
    await prepareOverrides();
    assertHasOverride('m() {} // in B');
    assertNoSuperMember();
    assertHasInterfaceMember('m() {} // in A');
  }

  Future<void> test_BAD_fieldByMethod() async {
    addTestFile('''
class A {
  int fff; // in A
}
class B extends A {
  fff() {} // in B
}
''');
    await prepareOverrides();
    assertNoOverride('fff() {} // in B');
  }

  Future<void> test_BAD_getterByMethod() async {
    addTestFile('''
class A {
  get fff => null;
}
class B extends A {
  fff() {}
}
''');
    await prepareOverrides();
    assertNoOverride('fff() {}');
  }

  Future<void> test_BAD_getterBySetter() async {
    addTestFile('''
class A {
  get fff => null;
}
class B extends A {
  set fff(x) {}
}
''');
    await prepareOverrides();
    assertNoOverride('fff(x) {}');
  }

  Future<void> test_BAD_methodByField() async {
    addTestFile('''
class A {
  fff() {} // in A
}
class B extends A {
  int fff; // in B
}
''');
    await prepareOverrides();
    assertNoOverride('fff; // in B');
  }

  Future<void> test_BAD_methodByGetter() async {
    addTestFile('''
class A {
  fff() {}
}
class B extends A {
  int get fff => null;
}
''');
    await prepareOverrides();
    assertNoOverride('fff => null');
  }

  Future<void> test_BAD_methodBySetter() async {
    addTestFile('''
class A {
  fff(x) {} // A
}
class B extends A {
  set fff(x) {} // B
}
''');
    await prepareOverrides();
    assertNoOverride('fff(x) {} // B');
  }

  Future<void> test_BAD_privateByPrivate_inDifferentLib() async {
    newFile(join(testFolder, 'lib.dart'), content: r'''
class A {
  void _m() {}
}
''');
    addTestFile('''
import 'lib.dart';
class B extends A {
  void _m() {} // in B
}
''');
    await prepareOverrides();
    assertNoOverride('_m() {} // in B');
  }

  Future<void> test_BAD_setterByGetter() async {
    addTestFile('''
class A {
  set fff(x) {}
}
class B extends A {
  get fff => null;
}
''');
    await prepareOverrides();
    assertNoOverride('fff => null;');
  }

  Future<void> test_BAD_setterByMethod() async {
    addTestFile('''
class A {
  set fff(x) {} // A
}
class B extends A {
  fff(x) {} // B
}
''');
    await prepareOverrides();
    assertNoOverride('fff(x) {} // B');
  }

  Future<void> test_definedInInterface_ofInterface() async {
    addTestFile('''
class A {
  m() {} // in A
}
class B implements A {}
class C implements B {
  m() {} // in C
}
''');
    await prepareOverrides();
    assertHasOverride('m() {} // in C');
    assertNoSuperMember();
    assertHasInterfaceMember('m() {} // in A');
  }

  Future<void> test_definedInInterface_ofSuper() async {
    addTestFile('''
class A {
  m() {} // in A
}
class B implements A {}
class C extends B {
  m() {} // in C
}
''');
    await prepareOverrides();
    assertHasOverride('m() {} // in C');
    assertNoSuperMember();
    assertHasInterfaceMember('m() {} // in A');
  }

  Future<void> test_inMixin_interface_method_direct_single() async {
    addTestFile('''
class A {
  m() {} // in A
}

mixin M implements A {
  m() {} // in M
}
''');
    await prepareOverrides();
    assertHasOverride('m() {} // in M');
    assertNoSuperMember();
    assertHasInterfaceMember('m() {} // in A');
  }

  Future<void> test_inMixin_superclassConstraint_method_direct() async {
    addTestFile('''
class A {
  m() {} // in A
}

mixin M on A {
  m() {} // in M
}
''');
    await prepareOverrides();
    assertHasOverride('m() {} // in M');
    assertHasSuperElement('m() {} // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_interface_method_direct_multiple() async {
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
    await prepareOverrides();
    assertHasOverride('m() {} // in A');
    assertNoSuperMember();
    assertHasInterfaceMember('m() {} // in IA');
    assertHasInterfaceMember('m() {} // in IB');
  }

  Future<void> test_interface_method_direct_single() async {
    addTestFile('''
class A {
  m() {} // in A
}
class B implements A {
  m() {} // in B
}
''');
    await prepareOverrides();
    assertHasOverride('m() {} // in B');
    assertNoSuperMember();
    assertHasInterfaceMember('m() {} // in A');
  }

  Future<void> test_interface_method_indirect_single() async {
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
    await prepareOverrides();
    assertHasOverride('m() {} // in C');
    assertNoSuperMember();
    assertHasInterfaceMember('m() {} // in A');
  }

  Future<void> test_interface_stopWhenFound() async {
    addTestFile('''
class A {
  m() {} // in A
}
class B extends A {
  m() {} // in B
}
class C implements B {
  m() {} // in C
}
''');
    await prepareOverrides();
    assertHasOverride('m() {} // in C');
    expect(overrideObject.interfaceMembers, hasLength(2));
    assertHasInterfaceMember('m() {} // in B');
  }

  Future<void> test_mix_sameMethod() async {
    addTestFile('''
class A {
  m() {} // in A
}
abstract class B extends A {
}
class C extends A implements A {
  m() {} // in C
}
''');
    await prepareOverrides();
    assertHasOverride('m() {} // in C');
    assertHasSuperElement('m() {} // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_mix_sameMethod_Object_hashCode() async {
    addTestFile('''
class A {}
abstract class B {}
class C extends A implements A {
  int get hashCode => 42;
}
''');
    await prepareOverrides();
    assertHasOverride('hashCode => 42;');
    expect(overrideObject.superclassMember, isNotNull);
    expect(overrideObject.interfaceMembers, isNull);
  }

  Future<void> test_mixin_method_direct() async {
    addTestFile('''
class A {
  m() {} // in A
}
class B extends Object with A {
  m() {} // in B
}
''');
    await prepareOverrides();
    assertHasOverride('m() {} // in B');
    assertHasSuperElement('m() {} // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_mixin_method_indirect() async {
    addTestFile('''
class A {
  m() {} // in A
}
class B extends A {
}
class C extends Object with B {
  m() {} // in C
}
''');
    await prepareOverrides();
    assertHasOverride('m() {} // in C');
    assertHasSuperElement('m() {} // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_mixin_method_indirect2() async {
    addTestFile('''
class A {
  m() {} // in A
}
class B extends Object with A {
}
class C extends B {
  m() {} // in C
}
''');
    await prepareOverrides();
    assertHasOverride('m() {} // in C');
    assertHasSuperElement('m() {} // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_staticMembers() async {
    addTestFile('''
class A {
  static int F = 0;
  static void M() {}
  static int get G => 0;
  static void set S(int v) {}
}
class B extends A {
  static int F = 0;
  static void M() {}
  static int get G => 0;
  static void set S(int v) {}
}
''');
    await prepareOverrides();
    expect(overridesList, isEmpty);
  }

  Future<void> test_super_fieldByField() async {
    addTestFile('''
class A {
  int fff; // in A
}
class B extends A {
  int fff; // in B
}
''');
    await prepareOverrides();
    assertHasOverride('fff; // in B');
    assertHasSuperElement('fff; // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_super_fieldByGetter() async {
    addTestFile('''
class A {
  int fff; // in A
}
class B extends A {
  get fff => 0; // in B
}
''');
    await prepareOverrides();
    assertHasOverride('fff => 0; // in B');
    assertHasSuperElement('fff; // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_super_fieldBySetter() async {
    addTestFile('''
class A {
  int fff; // in A
}
class B extends A {
  set fff(x) {} // in B
}
''');
    await prepareOverrides();
    assertHasOverride('fff(x) {} // in B');
    assertHasSuperElement('fff; // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_super_getterByField() async {
    addTestFile('''
class A {
  get fff => 0; // in A
  set fff(x) {} // in A
}
class B extends A {
  int fff; // in B
}
''');
    await prepareOverrides();
    assertHasOverride('fff; // in B');
    assertHasSuperElement('fff => 0; // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_super_getterByGetter() async {
    addTestFile('''
class A {
  get fff => 0; // in A
}
class B extends A {
  get fff => 0; // in B
}
''');
    await prepareOverrides();
    assertHasOverride('fff => 0; // in B');
    assertHasSuperElement('fff => 0; // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_super_method_direct() async {
    addTestFile('''
class A {
  m() {} // in A
}
class B extends A {
  m() {} // in B
}
''');
    await prepareOverrides();
    assertHasOverride('m() {} // in B');
    assertHasSuperElement('m() {} // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_super_method_indirect() async {
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
    await prepareOverrides();
    assertHasOverride('m() {} // in C');
    assertHasSuperElement('m() {} // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_super_method_privateByPrivate() async {
    addTestFile('''
class A {
  _m() {} // in A
}
class B extends A {
  _m() {} // in B
}
''');
    await prepareOverrides();
    assertHasOverride('_m() {} // in B');
    assertHasSuperElement('_m() {} // in A');
    assertNoInterfaceMembers();
  }

  Future<void> test_super_method_superTypeCycle() async {
    addTestFile('''
class A extends B {
  m() {} // in A
}
class B extends A {
  m() {} // in B
}
''');
    await prepareOverrides();
    // must finish
  }

  Future<void> test_super_setterBySetter() async {
    addTestFile('''
class A {
  set fff(x) {} // in A
}
class B extends A {
  set fff(x) {} // in B
}
''');
    await prepareOverrides();
    assertHasOverride('fff(x) {} // in B');
    assertHasSuperElement('fff(x) {} // in A');
    assertNoInterfaceMembers();
  }
}
