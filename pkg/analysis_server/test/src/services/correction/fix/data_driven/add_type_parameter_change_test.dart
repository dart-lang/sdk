// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/add_type_parameter_change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/value_extractor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddTypeParameterChange_DeprecatedMemberUseTest);
    defineReflectiveTests(AddTypeParameterChange_InvalidOverrideTest);
    defineReflectiveTests(
        AddTypeParameterChange_WrongNumberOfTypeArgumentsTest);
  });
}

@reflectiveTest
class AddTypeParameterChange_DeprecatedMemberUseTest
    extends _AddTypeParameterChange {
  Future<void> test_method_first() async {
    setPackageContent('''
class C {
  @deprecated
  void m<T>() {}
}
''');
    setPackageData(_add(0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m<int>();
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m<String, int>();
}
''');
  }

  Future<void> test_method_last() async {
    setPackageContent('''
class C {
  @deprecated
  void m<S, T>() {}
}
''');
    setPackageData(_add(2));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m<int, double>();
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m<int, double, String>();
}
''');
  }

  Future<void> test_method_middle() async {
    setPackageContent('''
class C {
  @deprecated
  void m<S, U>() {}
}
''');
    setPackageData(_add(1));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m<int, double>();
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m<int, String, double>();
}
''');
  }

  Future<void> test_method_only() async {
    setPackageContent('''
class C {
  @deprecated
  void m() {}
}
''');
    setPackageData(_add(0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m();
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m<String>();
}
''');
  }
}

@reflectiveTest
class AddTypeParameterChange_InvalidOverrideTest
    extends _AddTypeParameterChange {
  Future<void> test_method_bound() async {
    setPackageContent('''
class C {
  void m<T extends num>() {}
}
''');
    setPackageData(_add(0, extendedType: 'num'));
    await resolveTestUnit('''
import '$importUri';

class D extends C {
  @override
  void m() {}
}
''');
    await assertHasFix('''
import '$importUri';

class D extends C {
  @override
  void m<T extends num>() {}
}
''');
  }

  Future<void> test_method_noBound() async {
    setPackageContent('''
class C {
  void m<T>() {}
}
''');
    setPackageData(_add(0));
    await resolveTestUnit('''
import '$importUri';

class D extends C {
  @override
  void m() {}
}
''');
    await assertHasFix('''
import '$importUri';

class D extends C {
  @override
  void m<T>() {}
}
''');
  }
}

@reflectiveTest
class AddTypeParameterChange_WrongNumberOfTypeArgumentsTest
    extends _AddTypeParameterChange {
  Future<void> test_class() async {
    setPackageContent('''
class C<S, T> {}
''');
    setPackageData(_add(0, components: ['C']));
    await resolveTestUnit('''
import '$importUri';

void f(C<int> c) {}
''');
    await assertHasFix('''
import '$importUri';

void f(C<String, int> c) {}
''');
  }

  Future<void> test_constructor() async {
    setPackageContent('''
class C<S, T> {
  void C() {}
}
''');
    setPackageData(_add(0, components: ['C', 'C']));
    await resolveTestUnit('''
import '$importUri';

C f() {
  return C<int>();
}
''');
    await assertHasFix('''
import '$importUri';

C f() {
  return C<String, int>();
}
''');
  }

  Future<void> test_extension() async {
    setPackageContent('''
class C {}
extension E<S, T> on C {
  void m() {}
}
''');
    setPackageData(_add(0, components: ['E']));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  E<int>(c).m();
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  E<String, int>(c).m();
}
''');
  }

  Future<void> test_method() async {
    setPackageContent('''
class C {
  void m<S, T>() {}
}
''');
    setPackageData(_add(0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m<int>();
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m<String, int>();
}
''');
  }
}

abstract class _AddTypeParameterChange extends DataDrivenFixProcessorTest {
  Transform _add(int index, {List<String> components, String extendedType}) =>
      Transform(
          title: 'title',
          element: ElementDescriptor(
              libraryUris: [importUri], components: components ?? ['C', 'm']),
          changes: [
            AddTypeParameterChange(
                extendedType: extendedType,
                index: index,
                name: 'T',
                value: LiteralExtractor('String')),
          ]);
}
