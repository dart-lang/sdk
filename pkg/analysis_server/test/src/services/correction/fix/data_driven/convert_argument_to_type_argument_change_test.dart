// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/convert_argument_to_type_argument_change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename_change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
        ConvertArgumentToTypeArgumentChange_DeprecatedMemberUseTest);
  });
}

@reflectiveTest
class ConvertArgumentToTypeArgumentChange_DeprecatedMemberUseTest
    extends DataDrivenFixProcessorTest {
  @override
  FixKind get kind => DartFixKind.DATA_DRIVEN;

  Future<void> test_method_named_first_only() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int m1({Type t, int x}) {}
  int m2<T>({int x}) {}
}
''');
    setPackageData(_convertNamed(['C', 'm1'], 'm2', 't', 0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m1(t: int, x: 0);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2<int>(x: 0);
}
''');
  }

  Future<void> test_method_named_last_only() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int m1({int x, int y, Type t}) {}
  int m2<T>({int x, int y}) {}
}
''');
    setPackageData(_convertNamed(['C', 'm1'], 'm2', 't', 0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m1(x: 0, y: 1, t: int);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2<int>(x: 0, y: 1);
}
''');
  }

  Future<void> test_method_named_middle_only() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int m1({int x, Type t, int y}) {}
  int m2<T>({int x, int y}) {}
}
''');
    setPackageData(_convertNamed(['C', 'm1'], 'm2', 't', 0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m1(x: 0, t: int, y: 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2<int>(x: 0, y: 1);
}
''');
  }

  Future<void> test_method_named_mixed_only() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int m1(int x, {Type t, int y}) {}
  int m2<T>(int x, {int y}) {}
}
''');
    setPackageData(_convertNamed(['C', 'm1'], 'm2', 't', 0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m1(0, t: int, y: 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2<int>(0, y: 1);
}
''');
  }

  Future<void> test_method_positional_first_only() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int m1(Type t, int x) {}
  int m2<T>(int x) {}
}
''');
    setPackageData(_convertPositional(['C', 'm1'], 'm2', 0, 0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m1(int, 0);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2<int>(0);
}
''');
  }

  Future<void> test_method_positional_last_only() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int m1(int x, int y, Type t) {}
  int m2<T>(int x, int y) {}
}
''');
    setPackageData(_convertPositional(['C', 'm1'], 'm2', 2, 0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m1(0, 1, int);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2<int>(0, 1);
}
''');
  }

  Future<void> test_method_positional_middle_only() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int m1(int x, Type t, int y) {}
  int m2<T>(int x, int y) {}
}
''');
    setPackageData(_convertPositional(['C', 'm1'], 'm2', 1, 0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m1(0, int, 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2<int>(0, 1);
}
''');
  }

  Future<void> test_method_positional_only_first() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int m1<T>(Type t) {}
  int m2<S, T>() {}
}
''');
    setPackageData(_convertPositional(['C', 'm1'], 'm2', 0, 0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m1<int>(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2<String, int>();
}
''');
  }

  Future<void> test_method_positional_only_last() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int m1<S, T>(Type t) {}
  int m2<S, T, U>() {}
}
''');
    setPackageData(_convertPositional(['C', 'm1'], 'm2', 0, 2));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m1<int, double>(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2<int, double, String>();
}
''');
  }

  Future<void> test_method_positional_only_middle() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int m1<S, U>(Type t) {}
  int m2<S, T, U>() {}
}
''');
    setPackageData(_convertPositional(['C', 'm1'], 'm2', 0, 1));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m1<int, double>(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2<int, String, double>();
}
''');
  }

  Future<void> test_method_positional_only_only() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int m1(Type t) {}
  int m2<T>() {}
}
''');
    setPackageData(_convertPositional(['C', 'm1'], 'm2', 0, 0));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.m1(int);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2<int>();
}
''');
  }

  Transform _convertNamed(List<String> components, String newName,
          String parameterName, int typeArgumentIndex) =>
      Transform(
          title: 'title',
          element: ElementDescriptor(
              libraryUris: [importUri], components: components),
          changes: [
            RenameChange(newName: newName),
            ConvertArgumentToTypeArgumentChange(
                parameterReference: NamedParameterReference(parameterName),
                typeArgumentIndex: typeArgumentIndex),
          ]);

  Transform _convertPositional(List<String> components, String newName,
          int argumentIndex, int typeArgumentIndex) =>
      Transform(
          title: 'title',
          element: ElementDescriptor(
              libraryUris: [importUri], components: components),
          changes: [
            RenameChange(newName: newName),
            ConvertArgumentToTypeArgumentChange(
                parameterReference: PositionalParameterReference(argumentIndex),
                typeArgumentIndex: typeArgumentIndex),
          ]);
}
