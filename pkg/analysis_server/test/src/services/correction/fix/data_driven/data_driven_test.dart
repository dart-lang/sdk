// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_manager.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsNonClassTest);
    defineReflectiveTests(ExtraPositionalArgumentsCouldBeNamedTest);
    defineReflectiveTests(ExtraPositionalArgumentsTest);
    defineReflectiveTests(ImplementsNonClassTest);
    defineReflectiveTests(InvalidOverrideTest);
    defineReflectiveTests(MissingRequiredArgumentTest);
    defineReflectiveTests(MixinOfNonClassTest);
    defineReflectiveTests(NewWithUndefinedConstructorDefaultTest);
    defineReflectiveTests(NonBulkFixTest);
    defineReflectiveTests(NotEnoughArgumentsTest);
    defineReflectiveTests(OverrideOnNonOverridingMethodTest);
    defineReflectiveTests(UndefinedClassTest);
    defineReflectiveTests(UndefinedFunctionTest);
    defineReflectiveTests(UndefinedGetterTest);
    defineReflectiveTests(UndefinedIdentifierTest);
    defineReflectiveTests(UndefinedMethodTest);
    defineReflectiveTests(UndefinedNamedParameterTest);
    defineReflectiveTests(UndefinedSetterTest);
    defineReflectiveTests(UriTest);
    defineReflectiveTests(WrongNumberOfTypeArgumentsConstructorTest);
    defineReflectiveTests(WrongNumberOfTypeArgumentsExtensionTest);
    defineReflectiveTests(WrongNumberOfTypeArgumentsMethodTest);
    defineReflectiveTests(WrongNumberOfTypeArgumentsTest);
    defineReflectiveTests(NoProducerOverlapsTest);
  });
}

@reflectiveTest
class ExtendsNonClassTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';
class A extends Old {}
class B extends Old {}
''');
    await assertHasFix('''
import '$importUri';
class A extends New {}
class B extends New {}
''');
  }

  Future<void> test_rename_removed() async {
    setPackageContent('''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';
class A extends Old {}
class B extends Old {}
''');
    await assertHasFix('''
import '$importUri';
class A extends New {}
class B extends New {}
''');
  }
}

@reflectiveTest
class ExtraPositionalArgumentsCouldBeNamedTest extends _DataDrivenTest {
  @failingTest
  Future<void> test_replaceParameter() async {
    // This fails for two reasons. First, we grab the argument from the outer
    // invocation before we modify it, which causes the unmodified version of
    // the argument to be used for the added named parameter. Second, we produce
    // overlapping edits.
    setPackageContent('''
int f(int x, {int y = 0}) => x;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Replace parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 1
      name: 'y'
      style: required_named
      argumentValue:
        expression: '{% old %}'
        variables:
          old:
            kind: 'argument'
            index: 1
    - kind: 'removeParameter'
      index: 1
''');
    await resolveTestCode('''
import '$importUri';
void g() {
  f(0, f(1, 2));
}
''');
    await assertHasFix('''
import '$importUri';
void g() {
  f(0, y: f(1, y: 2));
}
''');
  }
}

@reflectiveTest
class ExtraPositionalArgumentsTest extends _DataDrivenTest {
  @failingTest
  Future<void> test_removeParameter() async {
    // This fails because we delete the extra argument from the inner invocation
    // (`, 2`) before deleting the argument from the outer invocation, which
    // results in three characters too many being deleted.
    setPackageContent('''
int f(int x) => x;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Remove parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    function: 'f'
  changes:
    - kind: 'removeParameter'
      index: 1
''');
    await resolveTestCode('''
import '$importUri';
void g() {
  f(0, f(1, 2));
}
''');
    await assertHasFix('''
import '$importUri';
void g() {
  f(0);
}
''');
  }
}

@reflectiveTest
class ImplementsNonClassTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';
class A implements Old {}
class B implements Old {}
''');
    await assertHasFix('''
import '$importUri';
class A implements New {}
class B implements New {}
''');
  }

  Future<void> test_rename_removed() async {
    setPackageContent('''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';
class A implements Old {}
class B implements Old {}
''');
    await assertHasFix('''
import '$importUri';
class A implements New {}
class B implements New {}
''');
  }
}

@reflectiveTest
class InvalidOverrideTest extends _DataDrivenTest {
  @failingTest
  Future<void> test_addParameter() async {
    // This functionality hasn't been implemented yet.
    setPackageContent('''
class C {
  void m(int x, int y) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addParameter'
      index: 1
      name: 'y'
      style: required_positional
      argumentValue:
        expression: '0'
''');
    await resolveTestCode('''
import '$importUri';
class A extends C {
  @override
  void m(int x) {}
}
class B extends C {
  @override
  void m(int x) {}
}
''');
    await assertHasFix('''
import '$importUri';
class A extends C {
  @override
  void m(int x, int y) {}
}
class B extends C {
  @override
  void m(int x, int y) {}
}
''');
  }

  Future<void> test_addTypeParameter() async {
    setPackageContent('''
class C {
  void m<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 0
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
class A extends C {
  @override
  void m() {}
}
class B extends C {
  @override
  void m() {}
}
''');
    await assertHasFix('''
import '$importUri';
class A extends C {
  @override
  void m<T>() {}
}
class B extends C {
  @override
  void m<T>() {}
}
''');
  }
}

@reflectiveTest
class MissingRequiredArgumentTest extends _DataDrivenTest {
  Future<void> test_changeParameterType_dotShorthand_constructor() async {
    setPackageContent('''
class A {
  A({required String x});
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Change parameter type to empty string'
  date: 2025-08-20
  element:
    uris: ['$importUri']
    constructor: 'new'
    inClass: 'A'
  changes:
    - kind: 'changeParameterType'
      name: 'x'
      nullability: non_null
      argumentValue:
        expression: "''"
''');
    await resolveTestCode('''
import '$importUri';
A f() {
  return .new(x: null);
}
''');
    await assertHasFix('''
import '$importUri';
A f() {
  return .new(x: '');
}
''');
  }

  Future<void> test_changeParameterType_dotShorthand_method() async {
    setPackageContent('''
class A {
  static A method({required int x}) => A();
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Change parameter type to empty string'
  date: 2025-08-20
  element:
    uris: ['$importUri']
    method: 'method'
    inClass: 'A'
  changes:
    - kind: 'changeParameterType'
      name: 'x'
      nullability: non_null
      argumentValue:
        expression: "''"
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  A a = .method(x: null);
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  A a = .method(x: '');
}
''');
  }
}

@reflectiveTest
class MixinOfNonClassTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';
class A with Old {}
class B with Old {}
''');
    await assertHasFix('''
import '$importUri';
class A with New {}
class B with New {}
''');
  }

  Future<void> test_rename_removed() async {
    setPackageContent('''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';
class A with Old {}
class B with Old {}
''');
    await assertHasFix('''
import '$importUri';
class A with New {}
class B with New {}
''');
  }
}

@reflectiveTest
class NewWithUndefinedConstructorDefaultTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  C([C c]);
  C.new([C c]);
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    constructor: ''
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
C c() => C(C());
''');
    await assertHasFix('''
import '$importUri';
C c() => C.new(C.new());
''');
  }

  Future<void> test_rename_deprecated_dotShorthand() async {
    setPackageContent('''
class C {
  @deprecated
  C.deprecated([C c]);
  C.new([C c]);
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    constructor: 'deprecated'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
C c() => .deprecated(.deprecated());
''');
    await assertHasFix('''
import '$importUri';
C c() => .new(.new());
''');
  }

  Future<void> test_rename_removed() async {
    setPackageContent('''
class C {
  C.updated([C c]);
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    constructor: ''
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'updated'
''');
    await resolveTestCode('''
import '$importUri';
C c() => C(C());
''');
    await assertHasFix('''
import '$importUri';
C c() => C.updated(C.updated());
''');
  }

  Future<void> test_rename_removed_dotShorthand() async {
    setPackageContent('''
class C {
  C.updated(C? c);
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to updated'
  date: 2025-08-14
  element:
    uris: ['$importUri']
    constructor: 'new'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'updated'
''');
    await resolveTestCode('''
import '$importUri';
C c() => .new(.new());
''');
    // TODO(kallentu): We're only able to fix the `.new` with a context type of
    // `C` in the first pass. When we don't know the arguments of the undefined
    // constructor, we aren't able to replace the arguments.
    // Potentially fix this in the future.
    await assertHasFix('''
import '$importUri';
C c() => .updated(.new());
''');
  }
}

@reflectiveTest
class NonBulkFixTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  bulkApply: false
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';
class A extends Old {}
class B extends Old {}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class NoProducerOverlapsTest {
  void test_noProducerOverlaps() {
    // Ensure that no error code is used by both data-driven fixes and
    // non-data-driven fixes, as this could result in an LSP "Apply-all" code
    // action accidentally executing data-driven fixes.

    var dataDrivenCodes = <String>{};
    var bulkFixForLintCodes = registeredFixGenerators.lintProducers.entries
        .where(
          (e) => e.value.any(
            (generator) => generator(
              context: StubCorrectionProducerContext.instance,
            ).canBeAppliedAcrossFiles,
          ),
        )
        .map((e) => e.key);
    var bulkFixForNonLintCodes = registeredFixGenerators
        .nonLintProducers
        .entries
        .where(
          (e) => e.value.any(
            (generator) => generator(
              context: StubCorrectionProducerContext.instance,
            ).canBeAppliedAcrossFiles,
          ),
        )
        .map((e) => e.key.uniqueName);
    var nonDataDrivenCodes = {
      ...bulkFixForLintCodes,
      ...bulkFixForNonLintCodes,
    };

    for (var MapEntry(key: code, value: generators)
        in BulkFixProcessor.nonLintMultiProducerMap.entries) {
      for (var generator in generators) {
        var producer = generator(
          context: StubCorrectionProducerContext.instance,
        );
        if (producer is DataDriven) {
          dataDrivenCodes.add(code.uniqueName);
        } else {
          nonDataDrivenCodes.add(code.uniqueName);
        }
      }
    }

    var intersection = dataDrivenCodes.intersection(nonDataDrivenCodes);
    if (intersection.isNotEmpty) {
      fail(
        'Error codes $intersection have both data-driven and non-data-driven '
        'fixes',
      );
    }
  }
}

@reflectiveTest
class NotEnoughArgumentsTest extends _DataDrivenTest {
  Future<void> test_addParameter() async {
    setPackageContent('''
int f(int x, int y) => x + y;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 1
      name: 'y'
      style: required_positional
      argumentValue:
        expression: '0'
''');
    await resolveTestCode('''
import '$importUri';
void g() {
  f(f(0));
}
''');
    await assertHasFix('''
import '$importUri';
void g() {
  f(f(0, 0), 0);
}
''');
  }

  Future<void> test_addParameter_named() async {
    setPackageContent('''
class C {
  void m({required String x}) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add parameter'
  date: 2022-09-22
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'x'
      style: required_named
      argumentValue:
        expression: 'value'
''');
    await resolveTestCode('''
import '$importUri';
void f(String value) {
  var c = C();
  c.m();
}
''');
    await assertHasFix('''
import '$importUri';
void f(String value) {
  var c = C();
  c.m(x: value);
}
''');
  }

  Future<void> test_addParameter_named_dotShorthand() async {
    setPackageContent('''
class C {
  static C m({required String x}) => C();
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add parameter'
  date: 2022-09-22
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'x'
      style: required_named
      argumentValue:
        expression: 'value'
''');
    await resolveTestCode('''
import '$importUri';
void f(String value) {
  C c = .m();
}
''');
    await assertHasFix('''
import '$importUri';
void f(String value) {
  C c = .m(x: value);
}
''');
  }

  Future<void> test_addParameter_named_dotShorthand_onlyFixOne() async {
    setPackageContent('''
class C {
  static C m({required String x}) => C();
}
class B {
  static B m({required String x}) => B();
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add parameter'
  date: 2022-09-22
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'x'
      style: required_named
      argumentValue:
        expression: 'value'
''');
    await resolveTestCode('''
import '$importUri';
void f(String value) {
  C c = .m();
  B b = .m();
}
''');
    await assertHasFix('''
import '$importUri';
void f(String value) {
  C c = .m(x: value);
  B b = .m();
}
''');
  }

  Future<void> test_addParameter_withImport() async {
    newFile('$workspaceRootPath/p/lib/d.dart', '''
class D {}
''');
    setPackageContent('''
import 'd.dart';

class C {
  void m(D x) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add parameter'
  date: 2021-08-03
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'x'
      style: required_positional
      argumentValue:
        expression: '{% d %}()'
        variables:
          d:
            kind: 'import'
            uris: ['d.dart']
            name: 'D'
''');
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m();
  c.m();
}
''');
    await assertHasFix('''
import 'package:p/d.dart';
import '$importUri';

void f(C c) {
  c.m(D());
  c.m(D());
}
''');
  }
}

@reflectiveTest
class OverrideOnNonOverridingMethodTest extends _DataDrivenTest {
  Future<void> test_rename() async {
    setPackageContent('''
class C {
  int new(int x) => x + 1;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
class D extends C {
  @override
  int old(int x) => x + 2;
}
class E extends C {
  @override
  int old(int x) => x + 3;
}
''');
    await assertHasFix('''
import '$importUri';
class D extends C {
  @override
  int new(int x) => x + 2;
}
class E extends C {
  @override
  int new(int x) => x + 3;
}
''');
  }
}

@reflectiveTest
class UndefinedClassTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';
void f(Old a, Old b) {}
''');
    await assertHasFix('''
import '$importUri';
void f(New a, New b) {}
''');
  }

  Future<void> test_rename_removed() async {
    setPackageContent('''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';
void f(Old a, Old b) {}
''');
    await assertHasFix('''
import '$importUri';
void f(New a, New b) {}
''');
  }
}

@reflectiveTest
class UndefinedFunctionTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
int old(int x) => x + 1;
int new(int x) => x + 1;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    function: 'old'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  old(old(0));
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  new(new(0));
}
''');
  }

  Future<void> test_rename_removed() async {
    setPackageContent('''
int new(int x) => x + 1;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    function: 'old'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  old(old(0));
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  new(new(0));
}
''');
  }
}

@reflectiveTest
class UndefinedGetterTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  int get old => 0;
  int get new => 0;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    getter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
void f(C a, C b) {
  a.old + b.old;
}
''');
    await assertHasFix('''
import '$importUri';
void f(C a, C b) {
  a.new + b.new;
}
''');
  }

  Future<void> test_rename_deprecated_dotShorthand_field() async {
    setPackageContent('''
class C {
  @deprecated
  static C? old = null;
  static C? field = null;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to field'
  date: 2025-08-20
  element:
    uris: ['$importUri']
    getter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'field'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  C? c = .old;
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  C? c = .field;
}
''');
  }

  Future<void> test_rename_deprecated_dotShorthand_getter() async {
    setPackageContent('''
class C {
  @deprecated
  static C get old => C();
  static C get getter => C();
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to getter'
  date: 2025-08-11
  element:
    uris: ['$importUri']
    getter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'getter'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  C c = .old;
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  C c = .getter;
}
''');
  }

  Future<void> test_rename_removed() async {
    setPackageContent('''
class C {
  int get new => 0;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    getter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
void f(C a, C b) {
  a.old + b.old;
}
''');
    await assertHasFix('''
import '$importUri';
void f(C a, C b) {
  a.new + b.new;
}
''');
  }

  Future<void> test_rename_removed_dotShorthand_field() async {
    setPackageContent('''
class C {
  static C? field = null;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to field'
  date: 2025-08-11
  element:
    uris: ['$importUri']
    getter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'field'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  C? c = .old;
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  C? c = .field;
}
''');
  }

  Future<void> test_rename_removed_dotShorthand_field_onlyFixOne() async {
    setPackageContent('''
class B {
  static B? field = null;
}
class C {
  static C? field = null;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to field'
  date: 2025-08-11
  element:
    uris: ['$importUri']
    getter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'field'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  C? c = .old;
  B? b = .old;
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  C? c = .field;
  B? b = .old;
}
''');
  }

  Future<void> test_rename_removed_dotShorthand_getter() async {
    setPackageContent('''
class C {
  static C get getter => C();
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to getter'
  date: 2025-08-11
  element:
    uris: ['$importUri']
    getter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'getter'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  C c = .old;
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  C c = .getter;
}
''');
  }

  Future<void> test_rename_removed_dotShorthand_getter_onlyFixOne() async {
    setPackageContent('''
class B {
  static B get getter => B();
}
class C {
  static C get getter => C();
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to getter'
  date: 2025-08-11
  element:
    uris: ['$importUri']
    getter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'getter'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  C c = .old;
  B b = .old;
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  C c = .getter;
  B b = .old;
}
''');
  }
}

@reflectiveTest
class UndefinedIdentifierTest extends _DataDrivenTest {
  Future<void> test_rename_topLevelVariable_deprecated() async {
    setPackageContent('''
@deprecated
int old = 0;
int new = 0;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    variable: 'old'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  old + old;
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  new + new;
}
''');
  }

  Future<void> test_rename_topLevelVariable_removed() async {
    setPackageContent('''
int new = 0;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    variable: 'old'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  old + old;
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  new + new;
}
''');
  }
}

@reflectiveTest
class UndefinedMethodTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  int old(int x) => x + 1;
  int new(int x) => x + 1;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
void f(C a, C b) {
  a.old(b.old(0));
}
''');
    await assertHasFix('''
import '$importUri';
void f(C a, C b) {
  a.new(b.new(0));
}
''');
  }

  Future<void> test_rename_deprecated_dotShorthand_constructor() async {
    setPackageContent('''
  class A {
    @deprecated
    A.old();
    A.n();
  }
  ''');
    addPackageDataFile('''
  version: 1
  transforms:
  - title: 'Rename to n'
    date: 2025-08-08
    element:
      uris: ['$importUri']
      constructor: 'old'
      inClass: 'A'
    changes:
      - kind: 'rename'
        newName: 'n'
  ''');
    await resolveTestCode('''
  import '$importUri';
  void f() {
    A a = .old();
  }
  ''');
    await assertHasFix('''
  import '$importUri';
  void f() {
    A a = .n();
  }
  ''');
  }

  Future<void> test_rename_deprecated_dotShorthand_method() async {
    setPackageContent('''
  class A {
    @deprecated
    static A old() => A();
    static A n() => A();
  }
  ''');
    addPackageDataFile('''
  version: 1
  transforms:
  - title: 'Rename to n'
    date: 2025-08-08
    element:
      uris: ['$importUri']
      method: 'old'
      inClass: 'A'
    changes:
      - kind: 'rename'
        newName: 'n'
  ''');
    await resolveTestCode('''
  import '$importUri';
  void f() {
    A a = .old();
  }
  ''');
    await assertHasFix('''
  import '$importUri';
  void f() {
    A a = .n();
  }
  ''');
  }

  Future<void> test_rename_removed() async {
    setPackageContent('''
class C {
  int new(int x) => x + 1;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
void f(C a, C b) {
  a.old(b.old(0));
}
''');
    await assertHasFix('''
import '$importUri';
void f(C a, C b) {
  a.new(b.new(0));
}
''');
  }

  Future<void> test_rename_removed_dotShorthand_constructor() async {
    setPackageContent('''
  class A {
    A.n();
  }
  ''');
    addPackageDataFile('''
  version: 1
  transforms:
  - title: 'Rename to n'
    date: 2025-08-08
    element:
      uris: ['$importUri']
      constructor: 'o'
      inClass: 'A'
    changes:
      - kind: 'rename'
        newName: 'n'
  ''');
    await resolveTestCode('''
  import '$importUri';
  void f() {
    A a = .o();
  }
  ''');
    await assertHasFix('''
  import '$importUri';
  void f() {
    A a = .n();
  }
  ''');
  }

  Future<void> test_rename_removed_dotShorthand_constructor_onlyFixOne() async {
    setPackageContent('''
  class A {
    A.n();
  }
  class B {
    B.n();
  }
  ''');
    addPackageDataFile('''
  version: 1
  transforms:
  - title: 'Rename to n'
    date: 2025-08-08
    element:
      uris: ['$importUri']
      constructor: 'o'
      inClass: 'A'
    changes:
      - kind: 'rename'
        newName: 'n'
  ''');
    await resolveTestCode('''
  import '$importUri';
  void f() {
    A a = .o();
    B b = .o();
  }
  ''');
    await assertHasFix('''
  import '$importUri';
  void f() {
    A a = .n();
    B b = .o();
  }
  ''');
  }

  Future<void> test_rename_removed_dotShorthand_method() async {
    setPackageContent('''
  class A {
    static A n() => A();
  }
  ''');
    addPackageDataFile('''
  version: 1
  transforms:
  - title: 'Rename to n'
    date: 2025-08-08
    element:
      uris: ['$importUri']
      method: 'o'
      inClass: 'A'
    changes:
      - kind: 'rename'
        newName: 'n'
  ''');
    await resolveTestCode('''
  import '$importUri';
  void f() {
    A a = .o();
  }
  ''');
    await assertHasFix('''
  import '$importUri';
  void f() {
    A a = .n();
  }
  ''');
  }

  Future<void> test_rename_removed_dotShorthand_method_onlyFixOne() async {
    setPackageContent('''
  class A {
    static A n() => A();
  }
  class B {
    static B n() => B();
  }
  ''');
    addPackageDataFile('''
  version: 1
  transforms:
  - title: 'Rename to n'
    date: 2025-08-08
    element:
      uris: ['$importUri']
      method: 'o'
      inClass: 'A'
    changes:
      - kind: 'rename'
        newName: 'n'
  ''');
    await resolveTestCode('''
  import '$importUri';
  void f() {
    A a = .o();
    B b = .o();
  }
  ''');
    await assertHasFix('''
  import '$importUri';
  void f() {
    A a = .n();
    B b = .o();
  }
  ''');
  }

  Future<void> test_rename_removed_onlyFixOne() async {
    setPackageContent('''
class A {
  void n(int x) {}
}
class B {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'o'
    inClass: 'A'
  changes:
    - kind: 'rename'
      newName: 'n'
''');
    await resolveTestCode('''
import '$importUri';

void f(A a, B b) {
  a.o(0);
  b.o(1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(A a, B b) {
  a.n(0);
  b.o(1);
}
''');
  }

  Future<void> test_replacedBy_deprecated_dotShorthand_constructor() async {
    setPackageContent('''
  class A {
    @deprecated
    A.old();
    A.n();
  }
  ''');
    addPackageDataFile('''
  version: 1
  transforms:
  - title: 'Rename to n'
    date: 2025-08-08
    element:
      uris: ['$importUri']
      constructor: 'old'
      inClass: 'A'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['$importUri']
          constructor: 'n'
          inClass: 'A'
  ''');
    await resolveTestCode('''
  import '$importUri';
  void f() {
    A a = .old();
  }
  ''');
    await assertHasFix('''
  import '$importUri';
  void f() {
    A a = A.n();
  }
  ''');
  }

  Future<void> test_replacedBy_deprecated_dotShorthand_method() async {
    setPackageContent('''
  class A {
    @deprecated
    static A old() => A();
    static A n() => A();
  }
  ''');
    addPackageDataFile('''
  version: 1
  transforms:
  - title: 'Replaced by n'
    date: 2025-08-08
    element:
      uris: ['$importUri']
      method: 'old'
      inClass: 'A'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['$importUri']
          method: 'n'
          inClass: 'A'
  ''');
    await resolveTestCode('''
  import '$importUri';
  void f() {
    A a = .old();
  }
  ''');
    await assertHasFix('''
  import '$importUri';
  void f() {
    A a = A.n();
  }
  ''');
  }

  Future<void> test_replacedBy_removed_dotShorthand_constructor() async {
    setPackageContent('''
  class A {
    A.n();
  }
  ''');
    addPackageDataFile('''
  version: 1
  transforms:
  - title: 'Replaced by n'
    date: 2025-08-08
    element:
      uris: ['$importUri']
      constructor: 'old'
      inClass: 'A'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['$importUri']
          constructor: 'n'
          inClass: 'A'
  ''');
    await resolveTestCode('''
  import '$importUri';
  void f() {
    A a = .old();
  }
  ''');
    // TODO(kallentu): ReplacedBy should replace with a dot shorthand in this
    // case instead of the full typed identifier.
    await assertHasFix('''
  import '$importUri';
  void f() {
    A a = A.n();
  }
  ''');
  }

  Future<void> test_replacedBy_removed_dotShorthand_method() async {
    setPackageContent('''
  class A {
    static A n() => A();
  }
  ''');
    addPackageDataFile('''
  version: 1
  transforms:
  - title: 'Replaced by n'
    date: 2025-08-08
    element:
      uris: ['$importUri']
      method: 'old'
      inClass: 'A'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['$importUri']
          method: 'n'
          inClass: 'A'
  ''');
    await resolveTestCode('''
  import '$importUri';
  void f() {
    A a = .old();
  }
  ''');
    await assertHasFix('''
  import '$importUri';
  void f() {
    A a = A.n();
  }
  ''');
  }
}

@reflectiveTest
class UndefinedNamedParameterTest extends _DataDrivenTest {
  Future<void> test_renameParameter_dotShorthand_constructor() async {
    setPackageContent('''
class A {
  A({int x = 0});
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename parameter'
  date: 2025-08-20
  element:
    uris: ['$importUri']
    constructor: 'new'
    inClass: 'A'
  changes:
    - kind: 'renameParameter'
      oldName: 'y'
      newName: 'x'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  A a = .new(y: 1);
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  A a = .new(x: 1);
}
''');
  }

  Future<void> test_renameParameter_dotShorthand_method() async {
    setPackageContent('''
class A {
  static A method({int x = 0}) => A();
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename parameter'
  date: 2025-08-20
  element:
    uris: ['$importUri']
    method: 'method'
    inClass: 'A'
  changes:
    - kind: 'renameParameter'
      oldName: 'y'
      newName: 'x'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  A a = .method(y: 1);
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  A a = .method(x: 1);
}
''');
  }
}

@reflectiveTest
class UndefinedSetterTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  set new(int x) {}
  set new(int x) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    setter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
void f(C a, C b) {
  a.old = b.old = 1;
}
''');
    await assertHasFix('''
import '$importUri';
void f(C a, C b) {
  a.new = b.new = 1;
}
''');
  }

  Future<void> test_rename_removed() async {
    setPackageContent('''
class C {
  set new(int x) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    setter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
void f(C a, C b) {
  a.old = b.old = 1;
}
''');
    await assertHasFix('''
import '$importUri';
void f(C a, C b) {
  a.new = b.new = 1;
}
''');
  }
}

@reflectiveTest
class UriTest extends _DataDrivenTest {
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/52233')
  Future<void> test_relative_uri_for_exported() async {
    newFile('$workspaceRootPath/p/lib/src/ex.dart', '''
@deprecated
class Old {}
class New {}
''');
    newFile('$workspaceRootPath/p/lib/lib.dart', '''
export 'src/ex.dart';
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['lib.dart']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';
class A extends Old {}
class B extends Old {}
''');
    await assertHasFix('''
import '$importUri';
class A extends New {}
class B extends New {}
''');
  }
}

@reflectiveTest
class WrongNumberOfTypeArgumentsConstructorTest extends _DataDrivenTest {
  Future<void> test_addTypeParameter() async {
    setPackageContent('''
class C<S, T> {
  C.c([C c]);
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
C f() => C<String>.c(C<String>.c());
''');
    await assertHasFix('''
import '$importUri';
C f() => C<String, int>.c(C<String, int>.c());
''');
  }
}

@reflectiveTest
class WrongNumberOfTypeArgumentsExtensionTest extends _DataDrivenTest {
  Future<void> test_addTypeParameter() async {
    setPackageContent('''
extension E<S, T> on String {
  int m(int x) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    extension: 'E'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
void f(String s) {
  E<String>(s).m(E<String>(s).m(0));
}
''');
    await assertHasFix('''
import '$importUri';
void f(String s) {
  E<String, int>(s).m(E<String, int>(s).m(0));
}
''');
  }
}

@reflectiveTest
class WrongNumberOfTypeArgumentsMethodTest extends _DataDrivenTest {
  Future<void> test_addTypeParameter() async {
    setPackageContent('''
class C {
  int m<S, T>(int x) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
void f(C c) {
  c.m<String>(c.m<String>(0));
}
''');
    await assertHasFix('''
import '$importUri';
void f(C c) {
  c.m<String, int>(c.m<String, int>(0));
}
''');
  }

  Future<void> test_addTypeParameter_dotShorthand() async {
    setPackageContent('''
class C {
  static C m<S, T>(C x) => x;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
void f(C c) {
  C c = .m<String>(.m<String>(C()));
}
''');
    await assertHasFix('''
import '$importUri';
void f(C c) {
  C c = .m<String, int>(.m<String, int>(C()));
}
''');
  }

  Future<void> test_addTypeParameter_dotShorthand_onlyFixOneClass() async {
    setPackageContent('''
class C {
  static C m<S, T>(C x) => x;
}
class B {
  static B m<S, T>(B x) => x;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
void f() {
  C c = .m<String>(.m<String>(C()));
  B b = .m<String>(.m<String>(B()));
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  C c = .m<String, int>(.m<String, int>(C()));
  B b = .m<String>(.m<String>(B()));
}
''');
  }
}

@reflectiveTest
class WrongNumberOfTypeArgumentsTest extends _DataDrivenTest {
  Future<void> test_addTypeParameter() async {
    setPackageContent('''
class C<S, T> {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
void f(C<String> c) {}
''');
    await assertHasFix('''
import '$importUri';
void f(C<String, int> c) {}
''');
  }

  Future<void> test_addTypeParameter_unnamedConstructor() async {
    setPackageContent('''
class C<S, T> {
  C([C c]);
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
C f() => C<String>(C<String>());
''');
    await assertHasFix('''
import '$importUri';
C f() => C<String, int>(C<String, int>());
''');
  }
}

class _DataDrivenTest extends BulkFixProcessorTest {
  /// Return the URI used to import the library created by [setPackageContent].
  String get importUri => 'package:p/lib.dart';

  /// Add the file containing the data used by the data-driven fix with the
  /// given [content].
  void addPackageDataFile(String content) {
    newFile(
      '$workspaceRootPath/p/lib/${TransformSetManager.dataFileName}',
      content,
    );
  }

  /// Set the content of the library that defines the element referenced by the
  /// data on which this test is based.
  void setPackageContent(String content) {
    newFile('$workspaceRootPath/p/lib/lib.dart', content);
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'p', rootPath: '$workspaceRootPath/p'),
    );
  }

  @override
  Future<void> tearDown() async {
    TransformSetManager.instance.clearCache();
    await super.tearDown();
  }
}
