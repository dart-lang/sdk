// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/add_type_parameter.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/changes_selector.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddTypeParameterToClassTest);
    defineReflectiveTests(AddTypeParameterToExtensionTest);
    defineReflectiveTests(AddTypeParameterToMethodTest);
    defineReflectiveTests(AddTypeParameterToMixinTest);
    defineReflectiveTests(AddTypeParameterToTopLevelFunctionTest);
    defineReflectiveTests(AddTypeParameterToTypedefTest);
  });
}

@reflectiveTest
class AddTypeParameterToClassTest extends _AddTypeParameterChange {
  @override
  String get _kind => 'class';

  Future<void> test_constructorInvocation_removed() async {
    setPackageContent('''
class C<S, T> {
  void C() {}
}
''');
    setPackageData(_add(0, components: ['C', 'C']));
    await resolveTestCode('''
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

  Future<void> test_inExtends_removed() async {
    setPackageContent('''
class A<S, T> {}
''');
    setPackageData(_add(0, components: ['A']));
    await resolveTestCode('''
import '$importUri';

class B extends A<int> {}
''');
    await assertHasFix('''
import '$importUri';

class B extends A<String, int> {}
''');
  }

  Future<void> test_inImplements_removed() async {
    setPackageContent('''
class A<S, T> {}
''');
    setPackageData(_add(0, components: ['A']));
    await resolveTestCode('''
import '$importUri';

class B implements A<int> {}
''');
    await assertHasFix('''
import '$importUri';

class B implements A<String, int> {}
''');
  }

  Future<void> test_inOn_removed() async {
    setPackageContent('''
class A<S, T> {}
''');
    setPackageData(_add(0, components: ['A']));
    await resolveTestCode('''
import '$importUri';

extension E on A<int> {}
''');
    await assertHasFix('''
import '$importUri';

extension E on A<String, int> {}
''');
  }

  Future<void> test_inTypeAnnotation_removed() async {
    setPackageContent('''
class C<S, T> {}
''');
    setPackageData(_add(0, components: ['C']));
    await resolveTestCode('''
import '$importUri';

void f(C<int> c) {}
''');
    await assertHasFix('''
import '$importUri';

void f(C<String, int> c) {}
''');
  }

  Future<void> test_inWith_removed() async {
    setPackageContent('''
class A<S, T> {}
''');
    setPackageData(_add(0, components: ['A']));
    await resolveTestCode('''
import '$importUri';

class B with A<int> {}
''');
    await assertHasFix('''
import '$importUri';

class B with A<String, int> {}
''');
  }
}

@reflectiveTest
class AddTypeParameterToExtensionTest extends _AddTypeParameterChange {
  @override
  String get _kind => 'extension';

  Future<void> test_override_removed() async {
    setPackageContent('''
class C {}
extension E<S, T> on C {
  void m() {}
}
''');
    setPackageData(_add(0, components: ['E']));
    await resolveTestCode('''
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
}

@reflectiveTest
class AddTypeParameterToMethodTest extends _AddTypeParameterChange {
  @override
  String get _kind => 'method';

  Future<void> test_first_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m<T>() {}
}
''');
    setPackageData(_add(0));
    await resolveTestCode('''
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

  Future<void> test_first_removed() async {
    setPackageContent('''
class C {
  void m<S, T>() {}
}
''');
    setPackageData(_add(0));
    await resolveTestCode('''
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

  Future<void> test_last_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m<S, T>() {}
}
''');
    setPackageData(_add(2));
    await resolveTestCode('''
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

  Future<void> test_middle_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m<S, U>() {}
}
''');
    setPackageData(_add(1));
    await resolveTestCode('''
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

  Future<void> test_only_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m() {}
}
''');
    setPackageData(_add(0));
    await resolveTestCode('''
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

  Future<void> test_override_withBound_removed() async {
    setPackageContent('''
class C {
  void m<T extends num>() {}
}
''');
    setPackageData(_add(0, extendedType: 'num'));
    await resolveTestCode('''
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

  Future<void> test_override_withoutBound_removed() async {
    setPackageContent('''
class C {
  void m<T>() {}
}
''');
    setPackageData(_add(0));
    await resolveTestCode('''
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
class AddTypeParameterToMixinTest extends _AddTypeParameterChange {
  @override
  String get _kind => 'mixin';

  Future<void> test_inWith_removed() async {
    setPackageContent('''
mixin M<S, T> {}
''');
    setPackageData(_add(0, components: ['M']));
    await resolveTestCode('''
import '$importUri';

class B with M<int> {}
''');
    await assertHasFix('''
import '$importUri';

class B with M<String, int> {}
''');
  }
}

@reflectiveTest
class AddTypeParameterToTopLevelFunctionTest extends _AddTypeParameterChange {
  @override
  String get _kind => 'function';

  Future<void> test_only_deprecated() async {
    setPackageContent('''
@deprecated
void f() {}
''');
    setPackageData(_add(0, components: ['f']));
    await resolveTestCode('''
import '$importUri';

void g() {
  f();
}
''');
    await assertHasFix('''
import '$importUri';

void g() {
  f<String>();
}
''');
  }
}

@reflectiveTest
class AddTypeParameterToTypedefTest extends _AddTypeParameterChange {
  @override
  String get _kind => 'typedef';

  @failingTest
  Future<void> test_functionType_removed() async {
    // The test fails because the change is to the typedef `F`, not to the
    // parameter `f`, so we don't see that the change might apply.
    //
    // Note, however, that there isn't currently any way to specify that the
    // type parameter belongs to the function type being declared rather than to
    // the typedef, so even if we fixed the problem above we would apply the
    // change in the wrong places.
    setPackageContent('''
typedef F = T Function<S, T>();
''');
    setPackageData(_add(0, components: ['F']));
    await resolveTestCode('''
import '$importUri';

void g(F f) {
  f<int>();
}
''');
    await assertHasFix('''
import '$importUri';

void g(F f) {
  f<String, int>();
}
''');
  }

  Future<void> test_typedef_first_removed() async {
    setPackageContent('''
typedef F<S, T> = T Function();
''');
    setPackageData(_add(0, components: ['F']));
    await resolveTestCode('''
import '$importUri';

void g(F<int> f) {
  f();
}
''');
    await assertHasFix('''
import '$importUri';

void g(F<String, int> f) {
  f();
}
''');
  }

  @failingTest
  Future<void> test_typedef_only_removed() async {
    // The test fails because there is no diagnostic generated when there were
    // no type arguments before the change; the type arguments are silently
    // inferred to be `dynamic`.
    setPackageContent('''
typedef F<T> = T Function();
''');
    setPackageData(_add(0, components: ['F']));
    await resolveTestCode('''
import '$importUri';

void g(F f) {
  f();
}
''');
    await assertHasFix('''
import '$importUri';

void g(F<String> f) {
  f();
}
''');
  }
}

abstract class _AddTypeParameterChange extends DataDrivenFixProcessorTest {
  /// Return the kind of element whose parameters are being modified.
  String get _kind;

  Transform _add(int index, {List<String> components, String extendedType}) =>
      Transform(
          title: 'title',
          element: ElementDescriptor(
              libraryUris: [Uri.parse(importUri)],
              kind: ElementKindUtilities.fromName(_kind),
              components: components ?? ['C', 'm']),
          bulkApply: false,
          changesSelector: UnconditionalChangesSelector([
            AddTypeParameter(
                index: index,
                name: 'T',
                extendedType:
                    extendedType == null ? null : codeTemplate(extendedType),
                argumentValue: codeTemplate('String')),
          ]));
}
