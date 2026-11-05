// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/changes_selector.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/replaced_by.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplacedByPrefixBulkTest);
    defineReflectiveTests(ReplacedByTest);
    defineReflectiveTests(ReplacedByUriSemanticsTest);
  });
}

@reflectiveTest
class ReplacedByPrefixBulkTest extends DataDrivenBulkFixProcessorTest {
  Future<void> test_deferredPrefix_notReused() async {
    setPackageContent('''
class C {
  @deprecated
  int get oldGetter => 0;
}

@deprecated
class MovedType {}
''');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
import 'lib.dart';

extension NewExt on C {
  int newMethod() => 0;
}

class MovedType {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Move oldGetter'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      getter: 'oldGetter'
      inClass: 'C'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          method: 'newMethod'
          inExtension: 'NewExt'
  - title: 'Move MovedType'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'MovedType'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'MovedType'
''');
    await resolveTestCode('''
import '$importUri' deferred as web;

Future<void> f(Object x) async {
  await web.loadLibrary();
  if (x is web.C) {
    x.oldGetter;
  }
  web.MovedType();
}
''');
    await assertHasFix('''
import '$importUri' deferred as web;
import 'package:p/lib2.dart';

Future<void> f(Object x) async {
  await web.loadLibrary();
  if (x is web.C) {
    x.newMethod();
  }
  MovedType();
}
''');
  }

  Future<void>
  test_extensionMove_mixedSourceImports_unprefixedAndPrefixed() async {
    setPackageContent('''
class C {
  @deprecated
  int get oldGetter => 0;
}
''');
    newFile('$workspaceRootPath/p/lib/ext.dart', '''
import 'lib.dart';

extension NewExt on C {
  int newMethod() => 0;
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Move oldGetter'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      getter: 'oldGetter'
      inClass: 'C'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/ext.dart']
          method: 'newMethod'
          inExtension: 'NewExt'
''');
    await resolveTestCode('''
import '$importUri';
import '$importUri' as web;

void f(C a, web.C b) {
  a.oldGetter;
  b.oldGetter;
}
''');
    await assertHasFix('''
import 'package:p/ext.dart';
import '$importUri';
import '$importUri' as web;

void f(C a, web.C b) {
  a.newMethod();
  b.newMethod();
}
''');
  }

  Future<void> test_extensionMove_preservesSourceImportPrefix() async {
    setPackageContent('''
class C {
  @deprecated
  int get oldGetter => 0;
}

class Notification {}

@deprecated
class MovedType {}
''');
    newFile('$workspaceRootPath/p/lib/ext.dart', '''
import 'lib.dart';

class Notification {}

class MovedType {}

extension NewExt on C {
  int newMethod() => 0;
}
''');
    newFile('$workspaceRootPath/p/lib/widgets.dart', '''
class Notification {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Move oldGetter'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      getter: 'oldGetter'
      inClass: 'C'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/ext.dart']
          method: 'newMethod'
          inExtension: 'NewExt'
  - title: 'Move MovedType'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'MovedType'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/ext.dart']
          class: 'MovedType'
''');
    await resolveTestCode('''
import '$importUri' as web;
import 'package:p/widgets.dart';

void f(web.C c) {
  c.oldGetter;
  final n = Notification();
  final m = web.MovedType();
  print((n, m));
}
''');
    await assertHasFix('''
import 'package:p/ext.dart' as web;
import '$importUri' as web;
import 'package:p/widgets.dart';

void f(web.C c) {
  c.newMethod();
  final n = Notification();
  final m = web.MovedType();
  print((n, m));
}
''');
  }

  Future<void>
  test_multiplePrefixedSites_differentSourcePrefixes_sameTargetLibrary() async {
    setPackageContent('''
@deprecated
void firstFn() {}
@deprecated
void secondFn() {}
''');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
void firstFn() {}
void secondFn() {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Move firstFn'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      function: 'firstFn'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          function: 'firstFn'
  - title: 'Move secondFn'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      function: 'secondFn'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          function: 'secondFn'
''');
    await resolveTestCode('''
import '$importUri' as p1;
import '$importUri' as p2;

void f() {
  p1.firstFn();
  p2.secondFn();
}
''');
    await assertHasFix('''
import '$importUri' as p1;
import '$importUri' as p2;
import 'package:p/lib2.dart' as p1;

void f() {
  p1.firstFn();
  p1.secondFn();
}
''');
  }

  Future<void> test_multiplePrefixedSites_sameTargetLibrary() async {
    setPackageContent('''
class MovedAnnotation {
  @deprecated
  const MovedAnnotation.named();
}

class MovedClass {
  @deprecated
  static int staticField = 0;

  @deprecated
  static void staticMethod() {}

  const MovedClass();

  @deprecated
  const MovedClass.named();
}

@deprecated
class MovedType {
  const MovedType();
}

@deprecated
int get topGetter => 0;

@deprecated
set topSetter(int value) {}

@deprecated
void topFn() {}
''');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class MovedAnnotation {
  const MovedAnnotation.named();
}

class MovedClass {
  static int staticField = 0;
  static void staticMethod() {}
  const MovedClass();
  const MovedClass.named();
}

class MovedType {
  const MovedType();
}

int get topGetter => 0;
set topSetter(int value) {}
void topFn() {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Move MovedAnnotation.named'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      constructor: 'named'
      inClass: 'MovedAnnotation'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          constructor: 'named'
          inClass: 'MovedAnnotation'
  - title: 'Move MovedClass.named'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      constructor: 'named'
      inClass: 'MovedClass'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          constructor: 'named'
          inClass: 'MovedClass'
  - title: 'Move MovedClass.staticField'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      field: 'staticField'
      inClass: 'MovedClass'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          field: 'staticField'
          inClass: 'MovedClass'
  - title: 'Move MovedClass.staticMethod'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      method: 'staticMethod'
      inClass: 'MovedClass'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          method: 'staticMethod'
          inClass: 'MovedClass'
  - title: 'Move MovedType'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'MovedType'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'MovedType'
  - title: 'Move topGetter'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      getter: 'topGetter'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          getter: 'topGetter'
  - title: 'Move topSetter'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      setter: 'topSetter'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          setter: 'topSetter'
  - title: 'Move topFn'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      function: 'topFn'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          function: 'topFn'
''');
    await resolveTestCode('''
import '$importUri' as web;

class MovedType {}

@web.MovedAnnotation.named()
void f(web.MovedType? arg) {
  final a = web.MovedType();
  final b = web.MovedClass.named();
  final c = web.MovedClass.staticField;
  web.MovedClass.staticMethod();
  final d = web.topGetter;
  web.topSetter = c + d;
  web.topFn();
  print((arg, a, b));
}
''');
    await assertHasFix('''
import '$importUri' as web;
import 'package:p/lib2.dart' as web;

class MovedType {}

@web.MovedAnnotation.named()
void f(web.MovedType? arg) {
  final a = web.MovedType();
  final b = web.MovedClass.named();
  final c = web.MovedClass.staticField;
  web.MovedClass.staticMethod();
  final d = web.topGetter;
  web.topSetter = c + d;
  web.topFn();
  print((arg, a, b));
}
''');
  }
}

@reflectiveTest
class ReplacedByTest extends DataDrivenFixProcessorTest {
  Future<void> test_class_class() async {
    await _assertReplacement(
      _Element.class_(isDeprecated: true, isOld: true),
      _Element.class_(),
    );
  }

  Future<void> test_class_enum() async {
    await _assertReplacement(
      _Element.class_(isDeprecated: true, isOld: true),
      _Element.enum_(),
    );
  }

  Future<void> test_class_extensionType() async {
    await _assertReplacement(
      _Element.class_(isDeprecated: true, isOld: true),
      _Element.extensionType(),
    );
  }

  Future<void> test_class_mixin() async {
    await _assertReplacement(
      _Element.class_(isDeprecated: true, isOld: true),
      _Element.mixin(),
    );
  }

  Future<void> test_class_typedef() async {
    await _assertReplacement(
      _Element.class_(isDeprecated: true, isOld: true),
      _Element.typedef(aliasedType: 'int'),
    );
  }

  Future<void> test_defaultConstructor_defaultConstructor() async {
    await _assertReplacement(
      _Element.defaultConstructor(isDeprecated: true, isOld: true),
      _Element.defaultConstructor(),
      isInvocation: true,
    );
  }

  Future<void> test_defaultConstructor_defaultConstructor_prefixed() async {
    await _assertReplacement(
      _Element.defaultConstructor(isDeprecated: true, isOld: true),
      _Element.defaultConstructor(),
      isInvocation: true,
      isPrefixed: true,
    );
  }

  Future<void> test_defaultConstructor_defaultConstructor_removed() async {
    await _assertReplacement(
      _Element.defaultConstructor(isDeprecated: true, isOld: true),
      _Element.defaultConstructor(),
      isInvocation: true,
      isOldRemoved: true,
    );
  }

  Future<void> test_defaultConstructor_namedConstructor() async {
    await _assertReplacement(
      _Element.defaultConstructor(isDeprecated: true, isOld: true),
      _Element.namedConstructor(),
      isInvocation: true,
    );
  }

  Future<void> test_defaultConstructor_namedConstructor_prefixed() async {
    await _assertReplacement(
      _Element.defaultConstructor(isDeprecated: true, isOld: true),
      _Element.namedConstructor(),
      isInvocation: true,
      isPrefixed: true,
    );
  }

  Future<void> test_enum_class() async {
    await _assertReplacement(
      _Element.enum_(isDeprecated: true, isOld: true),
      _Element.class_(),
    );
  }

  Future<void> test_enum_enum() async {
    await _assertReplacement(
      _Element.enum_(isDeprecated: true, isOld: true),
      _Element.enum_(),
    );
  }

  Future<void> test_enum_extensionType() async {
    await _assertReplacement(
      _Element.enum_(isDeprecated: true, isOld: true),
      _Element.extensionType(),
    );
  }

  Future<void> test_enum_mixin() async {
    await _assertReplacement(
      _Element.enum_(isDeprecated: true, isOld: true),
      _Element.mixin(),
    );
  }

  Future<void> test_enum_typedef() async {
    await _assertReplacement(
      _Element.enum_(isDeprecated: true, isOld: true),
      _Element.typedef(aliasedType: 'int'),
    );
  }

  Future<void> test_enumConstant_enumConstant() async {
    await _assertReplacement(
      _Element.constant(isDeprecated: true, isOld: true),
      _Element.constant(),
    );
  }

  Future<void> test_enumConstant_enumConstant_prefixed() async {
    await _assertReplacement(
      _Element.constant(isDeprecated: true, isOld: true),
      _Element.constant(),
      isPrefixed: true,
    );
  }

  Future<void> test_enumConstant_staticField() async {
    await _assertReplacement(
      _Element.constant(isDeprecated: true, isOld: true),
      _Element.field(isStatic: true),
    );
  }

  Future<void> test_enumConstant_staticField_prefixed() async {
    await _assertReplacement(
      _Element.constant(isDeprecated: true, isOld: true),
      _Element.field(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_enumConstant_staticGetter() async {
    await _assertReplacement(
      _Element.constant(isDeprecated: true, isOld: true),
      _Element.getter(isStatic: true),
    );
  }

  Future<void> test_enumConstant_staticGetter_prefixed() async {
    await _assertReplacement(
      _Element.constant(isDeprecated: true, isOld: true),
      _Element.getter(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_enumConstant_topLevelGetter() async {
    await _assertReplacement(
      _Element.constant(isDeprecated: true, isOld: true),
      _Element.topLevelGetter(),
    );
  }

  Future<void> test_enumConstant_topLevelGetter_prefixed() async {
    await _assertReplacement(
      _Element.constant(isDeprecated: true, isOld: true),
      _Element.topLevelGetter(),
      isPrefixed: true,
    );
  }

  Future<void> test_enumConstant_topLevelVariable() async {
    await _assertReplacement(
      _Element.constant(isDeprecated: true, isOld: true),
      _Element.topLevelVariable(),
    );
  }

  Future<void> test_enumConstant_topLevelVariable_prefixed() async {
    await _assertReplacement(
      _Element.constant(isDeprecated: true, isOld: true),
      _Element.topLevelVariable(),
      isPrefixed: true,
    );
  }

  Future<void> test_extensionType_class() async {
    await _assertReplacement(
      _Element.extensionType(isDeprecated: true, isOld: true),
      _Element.class_(),
    );
  }

  Future<void> test_extensionType_enum() async {
    await _assertReplacement(
      _Element.extensionType(isDeprecated: true, isOld: true),
      _Element.enum_(),
    );
  }

  Future<void> test_extensionType_extensionType() async {
    await _assertReplacement(
      _Element.extensionType(isDeprecated: true, isOld: true),
      _Element.extensionType(),
    );
  }

  Future<void> test_extensionType_mixin() async {
    await _assertReplacement(
      _Element.extensionType(isDeprecated: true, isOld: true),
      _Element.mixin(),
    );
  }

  Future<void> test_extensionType_typedef() async {
    await _assertReplacement(
      _Element.extensionType(isDeprecated: true, isOld: true),
      _Element.typedef(aliasedType: 'int'),
    );
  }

  Future<void> test_function_function_invocation() async {
    await _assertReplacement(
      _Element.topLevelFunction(isDeprecated: true, isOld: true),
      _Element.topLevelFunction(),
      isInvocation: true,
    );
  }

  Future<void> test_function_function_invocation_prefixed() async {
    await _assertReplacement(
      _Element.topLevelFunction(isDeprecated: true, isOld: true),
      _Element.topLevelFunction(),
      isInvocation: true,
      isPrefixed: true,
    );
  }

  Future<void> test_function_function_tearoff() async {
    await _assertReplacement(
      _Element.topLevelFunction(isDeprecated: true, isOld: true),
      _Element.topLevelFunction(),
    );
  }

  Future<void> test_function_function_tearoff_prefixed() async {
    await _assertReplacement(
      _Element.topLevelFunction(isDeprecated: true, isOld: true),
      _Element.topLevelFunction(),
      isPrefixed: true,
    );
  }

  Future<void> test_function_staticMethod_invocation() async {
    await _assertReplacement(
      _Element.topLevelFunction(isDeprecated: true, isOld: true),
      _Element.method(isStatic: true),
      isInvocation: true,
    );
  }

  Future<void> test_function_staticMethod_invocation_prefixed() async {
    await _assertReplacement(
      _Element.topLevelFunction(isDeprecated: true, isOld: true),
      _Element.method(isStatic: true),
      isInvocation: true,
      isPrefixed: true,
    );
  }

  Future<void> test_function_staticMethod_tearoff() async {
    await _assertReplacement(
      _Element.topLevelFunction(isDeprecated: true, isOld: true),
      _Element.method(isStatic: true),
    );
  }

  Future<void> test_function_staticMethod_tearoff_prefixed() async {
    await _assertReplacement(
      _Element.topLevelFunction(isDeprecated: true, isOld: true),
      _Element.method(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_getter_method() async {
    setPackageContent('''
class C {
  @deprecated
  int get oldGetter => 0;

  int newMethod() => 0;
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace an instance getter with a method'
    date: 2022-12-16
    element:
      uris: ['$importUri']
      getter: 'oldGetter'
      inClass: 'C'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['$importUri']
          method: 'newMethod'
          inClass: 'C'
''');
    await resolveTestCode('''
import '$importUri';

var x = C().oldGetter;
''');
    await assertHasFix('''
import '$importUri';

var x = C().newMethod();
''');
  }

  Future<void> test_method_getter() async {
    setPackageContent('''
class C {
  @deprecated
  int oldMethod() => 0;

  int get newGetter => 0;
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace an instance method with a getter'
    date: 2022-12-16
    element:
      uris: ['$importUri']
      method: 'oldMethod'
      inClass: 'C'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['$importUri']
          getter: 'newGetter'
          inClass: 'C'
''');
    await resolveTestCode('''
import '$importUri';

var x = C().oldMethod();
''');
    await assertHasFix('''
import '$importUri';

var x = C().newGetter;
''');
  }

  Future<void> test_method_getter_multipleParameters() async {
    setPackageContent('''
class C {
  @deprecated
  int oldMethod(int i) => 0;

  int get newGetter => 0;
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace an instance method with multiple parameters, with a getter'
    date: 2022-12-16
    element:
      uris: ['$importUri']
      method: 'oldMethod'
      inClass: 'C'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['$importUri']
          getter: 'newGetter'
          inClass: 'C'
''');
    await resolveTestCode('''
import '$importUri';

var x = C().oldMethod(1);
''');
    await assertNoFix();
  }

  Future<void> test_mixin_class() async {
    await _assertReplacement(
      _Element.mixin(isDeprecated: true, isOld: true),
      _Element.class_(),
    );
  }

  Future<void> test_mixin_enum() async {
    await _assertReplacement(
      _Element.mixin(isDeprecated: true, isOld: true),
      _Element.enum_(),
    );
  }

  Future<void> test_mixin_extensionType() async {
    await _assertReplacement(
      _Element.mixin(isDeprecated: true, isOld: true),
      _Element.extensionType(),
    );
  }

  Future<void> test_mixin_mixin() async {
    await _assertReplacement(
      _Element.mixin(isDeprecated: true, isOld: true),
      _Element.mixin(),
    );
  }

  Future<void> test_mixin_typedef() async {
    await _assertReplacement(
      _Element.mixin(isDeprecated: true, isOld: true),
      _Element.typedef(aliasedType: 'int'),
    );
  }

  Future<void> test_namedConstructor_defaultConstructor() async {
    await _assertReplacement(
      _Element.namedConstructor(isDeprecated: true, isOld: true),
      _Element.defaultConstructor(),
      isInvocation: true,
    );
  }

  Future<void> test_namedConstructor_defaultConstructor_prefixed() async {
    await _assertReplacement(
      _Element.namedConstructor(isDeprecated: true, isOld: true),
      _Element.defaultConstructor(),
      isInvocation: true,
      isPrefixed: true,
    );
  }

  Future<void> test_namedConstructor_namedConstructor() async {
    await _assertReplacement(
      _Element.namedConstructor(isDeprecated: true, isOld: true),
      _Element.namedConstructor(),
      isInvocation: true,
    );
  }

  Future<void> test_namedConstructor_namedConstructor_prefixed() async {
    await _assertReplacement(
      _Element.namedConstructor(isDeprecated: true, isOld: true),
      _Element.namedConstructor(),
      isInvocation: true,
      isPrefixed: true,
    );
  }

  Future<void> test_staticField_enumConstant() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.constant(),
    );
  }

  Future<void> test_staticField_enumConstant_prefixed() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.constant(),
      isPrefixed: true,
    );
  }

  Future<void> test_staticField_staticField() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.field(isStatic: true),
    );
  }

  Future<void> test_staticField_staticField_prefixed() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.field(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_staticField_staticGetter() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.getter(isStatic: true),
    );
  }

  Future<void> test_staticField_staticGetter_prefixed() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.getter(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_staticField_staticSetter() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.setter(isStatic: true),
      isAssignment: true,
    );
  }

  Future<void> test_staticField_staticSetter_prefixed() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.setter(isStatic: true),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_staticField_topLevelGetter() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelGetter(),
    );
  }

  Future<void> test_staticField_topLevelGetter_prefixed() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelGetter(),
      isPrefixed: true,
    );
  }

  Future<void> test_staticField_topLevelSetter() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelSetter(),
      isAssignment: true,
    );
  }

  Future<void> test_staticField_topLevelSetter_prefixed() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelSetter(),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_staticField_topLevelVariable() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelVariable(),
    );
  }

  Future<void> test_staticField_topLevelVariable_prefixed() async {
    await _assertReplacement(
      _Element.field(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelVariable(),
      isPrefixed: true,
    );
  }

  Future<void> test_staticGetter_enumConstant() async {
    await _assertReplacement(
      _Element.getter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.constant(),
    );
  }

  Future<void> test_staticGetter_enumConstant_prefixed() async {
    await _assertReplacement(
      _Element.getter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.constant(),
      isPrefixed: true,
    );
  }

  Future<void> test_staticGetter_staticField() async {
    await _assertReplacement(
      _Element.getter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.field(isStatic: true),
    );
  }

  Future<void> test_staticGetter_staticField_prefixed() async {
    await _assertReplacement(
      _Element.getter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.field(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_staticGetter_staticGetter() async {
    await _assertReplacement(
      _Element.getter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.getter(isStatic: true),
    );
  }

  Future<void> test_staticGetter_staticGetter_prefixed() async {
    await _assertReplacement(
      _Element.getter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.getter(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_staticGetter_topLevelGetter() async {
    await _assertReplacement(
      _Element.getter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelGetter(),
    );
  }

  Future<void> test_staticGetter_topLevelGetter_prefixed() async {
    await _assertReplacement(
      _Element.getter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelGetter(),
      isPrefixed: true,
    );
  }

  Future<void> test_staticGetter_topLevelVariable() async {
    await _assertReplacement(
      _Element.getter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelVariable(),
    );
  }

  Future<void> test_staticGetter_topLevelVariable_prefixed() async {
    await _assertReplacement(
      _Element.getter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelVariable(),
      isPrefixed: true,
    );
  }

  Future<void> test_staticMethod_function_invocation() async {
    await _assertReplacement(
      _Element.method(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelFunction(),
      isInvocation: true,
    );
  }

  Future<void> test_staticMethod_function_invocation_prefixed() async {
    await _assertReplacement(
      _Element.method(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelFunction(),
      isInvocation: true,
      isPrefixed: true,
    );
  }

  Future<void> test_staticMethod_function_tearoff() async {
    await _assertReplacement(
      _Element.method(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelFunction(),
    );
  }

  Future<void> test_staticMethod_function_tearoff_prefixed() async {
    await _assertReplacement(
      _Element.method(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelFunction(),
      isPrefixed: true,
    );
  }

  Future<void> test_staticMethod_staticMethod_invocation() async {
    await _assertReplacement(
      _Element.method(isDeprecated: true, isOld: true, isStatic: true),
      _Element.method(isStatic: true),
      isInvocation: true,
    );
  }

  Future<void> test_staticMethod_staticMethod_invocation_prefixed() async {
    await _assertReplacement(
      _Element.method(isDeprecated: true, isOld: true, isStatic: true),
      _Element.method(isStatic: true),
      isInvocation: true,
      isPrefixed: true,
    );
  }

  Future<void> test_staticMethod_staticMethod_tearoff() async {
    await _assertReplacement(
      _Element.method(isDeprecated: true, isOld: true, isStatic: true),
      _Element.method(isStatic: true),
    );
  }

  Future<void> test_staticMethod_staticMethod_tearoff_prefixed() async {
    await _assertReplacement(
      _Element.method(isDeprecated: true, isOld: true, isStatic: true),
      _Element.method(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_staticSetter_staticField() async {
    await _assertReplacement(
      _Element.setter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.field(isStatic: true),
      isAssignment: true,
    );
  }

  Future<void> test_staticSetter_staticField_prefixed() async {
    await _assertReplacement(
      _Element.setter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.field(isStatic: true),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_staticSetter_staticSetter() async {
    await _assertReplacement(
      _Element.setter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.setter(isStatic: true),
      isAssignment: true,
    );
  }

  Future<void> test_staticSetter_staticSetter_prefixed() async {
    await _assertReplacement(
      _Element.setter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.setter(isStatic: true),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_staticSetter_topLevelSetter() async {
    await _assertReplacement(
      _Element.setter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelSetter(),
      isAssignment: true,
    );
  }

  Future<void> test_staticSetter_topLevelSetter_prefixed() async {
    await _assertReplacement(
      _Element.setter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelSetter(),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_staticSetter_topLevelVariable() async {
    await _assertReplacement(
      _Element.setter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelVariable(),
      isAssignment: true,
    );
  }

  Future<void> test_staticSetter_topLevelVariable_prefixed() async {
    await _assertReplacement(
      _Element.setter(isDeprecated: true, isOld: true, isStatic: true),
      _Element.topLevelVariable(),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelGetter_enumConstant() async {
    await _assertReplacement(
      _Element.topLevelGetter(isDeprecated: true, isOld: true),
      _Element.constant(),
    );
  }

  Future<void> test_topLevelGetter_enumConstant_prefixed() async {
    await _assertReplacement(
      _Element.topLevelGetter(isDeprecated: true, isOld: true),
      _Element.constant(),
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelGetter_staticField() async {
    await _assertReplacement(
      _Element.topLevelGetter(isDeprecated: true, isOld: true),
      _Element.field(isStatic: true),
    );
  }

  Future<void> test_topLevelGetter_staticField_prefixed() async {
    await _assertReplacement(
      _Element.topLevelGetter(isDeprecated: true, isOld: true),
      _Element.field(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelGetter_staticGetter() async {
    await _assertReplacement(
      _Element.topLevelGetter(isDeprecated: true, isOld: true),
      _Element.getter(isStatic: true),
    );
  }

  Future<void> test_topLevelGetter_staticGetter_prefixed() async {
    await _assertReplacement(
      _Element.topLevelGetter(isDeprecated: true, isOld: true),
      _Element.getter(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelGetter_topLevelGetter() async {
    await _assertReplacement(
      _Element.topLevelGetter(isDeprecated: true, isOld: true),
      _Element.topLevelGetter(),
    );
  }

  Future<void> test_topLevelGetter_topLevelGetter_prefixed() async {
    await _assertReplacement(
      _Element.topLevelGetter(isDeprecated: true, isOld: true),
      _Element.topLevelGetter(),
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelGetter_topLevelVariable() async {
    await _assertReplacement(
      _Element.topLevelGetter(isDeprecated: true, isOld: true),
      _Element.topLevelVariable(),
    );
  }

  Future<void> test_topLevelGetter_topLevelVariable_prefixed() async {
    await _assertReplacement(
      _Element.topLevelGetter(isDeprecated: true, isOld: true),
      _Element.topLevelVariable(),
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelSetter_staticField() async {
    await _assertReplacement(
      _Element.topLevelSetter(isDeprecated: true, isOld: true),
      _Element.field(isStatic: true),
      isAssignment: true,
    );
  }

  Future<void> test_topLevelSetter_staticField_prefixed() async {
    await _assertReplacement(
      _Element.topLevelSetter(isDeprecated: true, isOld: true),
      _Element.field(isStatic: true),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelSetter_staticSetter() async {
    await _assertReplacement(
      _Element.topLevelSetter(isDeprecated: true, isOld: true),
      _Element.setter(isStatic: true),
      isAssignment: true,
    );
  }

  Future<void> test_topLevelSetter_staticSetter_prefixed() async {
    await _assertReplacement(
      _Element.topLevelSetter(isDeprecated: true, isOld: true),
      _Element.setter(isStatic: true),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelSetter_topLevelSetter() async {
    await _assertReplacement(
      _Element.topLevelSetter(isDeprecated: true, isOld: true),
      _Element.topLevelSetter(),
      isAssignment: true,
    );
  }

  Future<void> test_topLevelSetter_topLevelSetter_prefixed() async {
    await _assertReplacement(
      _Element.topLevelSetter(isDeprecated: true, isOld: true),
      _Element.topLevelSetter(),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelSetter_topLevelVariable() async {
    await _assertReplacement(
      _Element.topLevelSetter(isDeprecated: true, isOld: true),
      _Element.topLevelVariable(),
      isAssignment: true,
    );
  }

  Future<void> test_topLevelSetter_topLevelVariable_prefixed() async {
    await _assertReplacement(
      _Element.topLevelSetter(isDeprecated: true, isOld: true),
      _Element.topLevelVariable(),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelVariable_enumConstant() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.constant(),
    );
  }

  Future<void> test_topLevelVariable_enumConstant_prefixed() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.constant(),
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelVariable_staticField() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.field(isStatic: true),
    );
  }

  Future<void> test_topLevelVariable_staticField_prefixed() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.field(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelVariable_staticGetter() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.getter(isStatic: true),
    );
  }

  Future<void> test_topLevelVariable_staticGetter_prefixed() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.getter(isStatic: true),
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelVariable_staticSetter() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.setter(isStatic: true),
      isAssignment: true,
    );
  }

  Future<void> test_topLevelVariable_staticSetter_prefixed() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.setter(isStatic: true),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelVariable_topLevelGetter() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.topLevelGetter(),
    );
  }

  Future<void> test_topLevelVariable_topLevelGetter_prefixed() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.topLevelGetter(),
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelVariable_topLevelSetter() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.topLevelSetter(),
      isAssignment: true,
    );
  }

  Future<void> test_topLevelVariable_topLevelSetter_prefixed() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.topLevelSetter(),
      isAssignment: true,
      isPrefixed: true,
    );
  }

  Future<void> test_topLevelVariable_topLevelVariable() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.topLevelVariable(),
    );
  }

  Future<void> test_topLevelVariable_topLevelVariable_prefixed() async {
    await _assertReplacement(
      _Element.topLevelVariable(isDeprecated: true, isOld: true),
      _Element.topLevelVariable(),
      isPrefixed: true,
    );
  }

  Future<void> test_typedef_class() async {
    await _assertReplacement(
      _Element.typedef(isDeprecated: true, isOld: true, aliasedType: 'int'),
      _Element.class_(),
    );
  }

  Future<void> test_typedef_enum() async {
    await _assertReplacement(
      _Element.typedef(isDeprecated: true, isOld: true, aliasedType: 'int'),
      _Element.enum_(),
    );
  }

  Future<void> test_typedef_extensionType() async {
    await _assertReplacement(
      _Element.typedef(isDeprecated: true, isOld: true, aliasedType: 'int'),
      _Element.extensionType(),
    );
  }

  Future<void> test_typedef_mixin() async {
    await _assertReplacement(
      _Element.typedef(isDeprecated: true, isOld: true, aliasedType: 'int'),
      _Element.mixin(),
    );
  }

  Future<void> test_typedef_typedef() async {
    await _assertReplacement(
      _Element.typedef(isDeprecated: true, isOld: true, aliasedType: 'int'),
      _Element.typedef(aliasedType: 'int'),
    );
  }

  Future<void> _assertReplacement(
    _Element oldElement,
    _Element newElement, {
    bool isAssignment = false,
    bool isInvocation = false,
    bool isPrefixed = false,
    bool isOldRemoved = false,
  }) async {
    assert(!(isAssignment && isInvocation));
    setPackageContent('''
${isOldRemoved ? '' : oldElement.declaration}
${newElement.declaration}
''');

    setPackageData(
      _replacedBy(
        oldElement.kind,
        oldElement.components,
        newElement.kind,
        newElement.components,
        oldUri: isOldRemoved ? Uri.parse('dart:core') : null,
      ),
    );

    var prefixDeclaration = isPrefixed ? ' as p' : '';
    var prefixReference = isPrefixed ? 'p.' : '';
    var invocation = isInvocation ? '()' : '';
    if (isAssignment) {
      await resolveTestCode('''
import '$importUri'$prefixDeclaration;

void g() {
  $prefixReference${oldElement.reference} = 0;
}
''');
      await assertHasFix('''
import '$importUri'$prefixDeclaration;

void g() {
  $prefixReference${newElement.reference} = 0;
}
''');
      return;
    }

    var import = "import '$importUri'$prefixDeclaration;";
    // TODO(asashour): inserting imports should remove initial blank lines
    var oldImport = isOldRemoved
        ? ''
        : '''
$import
''';
    var newImport =
        '''
$import${isOldRemoved ? '\n' : ''}
''';

    await resolveTestCode('''
${oldImport}var x = $prefixReference${oldElement.reference}$invocation;
''');
    await assertHasFix('''
${newImport}var x = $prefixReference${newElement.reference}$invocation;
''');
  }

  Transform _replacedBy(
    ElementKind oldKind,
    List<String> oldComponents,
    ElementKind newKind,
    List<String> newComponents, {
    bool isStatic = false,
    Uri? oldUri,
  }) {
    var oldElement = ElementDescriptor(
      libraryUris: [oldUri ?? Uri.parse(importUri)],
      kind: oldKind,
      isStatic: isStatic,
      components: oldComponents,
    );
    var newElement = ElementDescriptor(
      libraryUris: [Uri.parse(importUri)],
      kind: newKind,
      isStatic: isStatic,
      components: newComponents,
    );
    return Transform(
      title: 'title',
      date: DateTime.now(),
      element: oldElement,
      bulkApply: true,
      changesSelector: UnconditionalChangesSelector([
        ReplacedBy(newElement: newElement, replaceTarget: false),
      ]),
    );
  }
}

@reflectiveTest
class ReplacedByUriSemanticsTest extends DataDrivenFixProcessorTest {
  Future<void> test_different_uris() async {
    setPackageContent('''
@deprecated
double oldSin(num n) => 1;
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace with different uri'
    date: 2022-09-28
    element:
      uris: ['$importUri']
      function: 'oldSin'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['dart:math']
          function: 'sin'
''');
    await resolveTestCode('''
import '$importUri';

var x = oldSin(1);
''');
    await assertHasFix('''
import 'dart:math';

import '$importUri';

var x = sin(1);
''');
  }

  Future<void> test_docImport_replacedBy_multipleBrokenInComment() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/new.dart', '''
class A {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace by new.dart'
    date: 2026-01-01
    library: 'package:p/old.dart'
    changes:
      - kind: 'replacedBy'
        newLibrary: 'package:p/new.dart'
''');
    await resolveTestCode('''
/// @docImport 'package:p/old.dart';
/// @docImport 'package:p/missing.dart';
library;
''');
    await assertNoFix(
      filter: (d) => d.offset == testCode.indexOf("'package:p/missing.dart'"),
    );
    await assertHasFix('''
/// @docImport 'package:p/new.dart';
/// @docImport 'package:p/missing.dart';
library;
''', filter: (d) => d.offset == testCode.indexOf("'package:p/old.dart'"));
  }

  Future<void> test_docImport_replacedBy_multipleInComment() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/other.dart', '''
class B {}
''');
    newFile('$workspaceRootPath/p/lib/new.dart', '''
class A {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace by new.dart'
    date: 2026-01-01
    library: 'package:p/old.dart'
    changes:
      - kind: 'replacedBy'
        newLibrary: 'package:p/new.dart'
''');
    await resolveTestCode('''
/// @docImport 'package:p/other.dart';
/// @docImport 'package:p/old.dart';
library;
''');
    await assertHasFix('''
/// @docImport 'package:p/other.dart';
/// @docImport 'package:p/new.dart';
library;
''');
  }

  Future<void> test_docImport_replacedBy_removed() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/new.dart', '''
class A {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace by new.dart'
    date: 2026-01-01
    library: 'package:p/old.dart'
    changes:
      - kind: 'replacedBy'
        newLibrary: 'package:p/new.dart'
''');
    await resolveTestCode('''
/// @docImport 'package:p/old.dart';
library;
''');
    await assertHasFix('''
/// @docImport 'package:p/new.dart';
library;
''');
  }

  Future<void> test_new_class_uris_single() async {
    setPackageContent('');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace A'
    date: 2022-05-12
    element:
      uris: ['$importUri']
      class: 'A'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:matcher/expect.dart']
          class: 'A'
''');
    await resolveTestCode('''
import '$importUri';

void f(A a) {
  print(a);
}
''');
    await assertHasFix('''
import 'package:matcher/expect.dart';
import '$importUri';

void f(A a) {
  print(a);
}
''');
  }

  Future<void> test_new_element_uris_multiple() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/expect.dart', '''
void expect(actual, expected) {}
''');
    newFile('$workspaceRootPath/p/lib/export.dart', '''
export 'expect.dart';
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace expect'
    date: 2022-05-12
    bulkApply: false
    element:
      uris: ['$importUri']
      function: 'expect'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/expect.dart', 'package:p/export.dart']
          function: 'expect'
''');
    await resolveTestCode('''
import '$importUri';

f() {
  expect(true, true);
}
''');
    await assertHasFix('''
import 'package:p/expect.dart';
import '$importUri';

f() {
  expect(true, true);
}
''');
  }

  Future<void> test_new_element_uris_prefixed() async {
    setPackageContent('''
@deprecated
void expect(Object? v1, Object? v2) {}
''');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
void expect(Object? v1, Object? v2) {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace expect'
    date: 2022-05-12
    bulkApply: false
    element:
      uris: ['$importUri']
      function: 'expect'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          function: 'expect'
''');

    /// Preserves the call-site prefix on the newly added import.
    await resolveTestCode('''
import '$importUri' as prefix;

main() {
  prefix.expect(true, true);
}
''');
    await assertHasFix('''
import '$importUri' as prefix;
import 'package:p/lib2.dart' as prefix;

main() {
  prefix.expect(true, true);
}
''');
  }

  Future<void> test_new_element_uris_prefixed_avoidsAmbiguousImport() async {
    setPackageContent('''
@deprecated
class AudioContext {
  AudioContext();
}
''');
    newFile('$workspaceRootPath/p/lib/other_audio.dart', '''
class AudioContext {}
''');
    newFile('$workspaceRootPath/p/lib/webaudio.dart', '''
class AudioContext {
  AudioContext();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Move AudioContext'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'AudioContext'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/webaudio.dart']
          class: 'AudioContext'
''');
    await resolveTestCode('''
import '$importUri' as web;
import 'package:p/other_audio.dart';

AudioContext? other;
final ctx = web.AudioContext();
''');
    await assertHasFix('''
import '$importUri' as web;
import 'package:p/other_audio.dart';
import 'package:p/webaudio.dart' as web;

AudioContext? other;
final ctx = web.AudioContext();
''');
  }

  Future<void> test_new_element_uris_prefixed_removedClass() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/webaudio.dart', '''
class AudioContext {
  AudioContext();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Move AudioContext'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'AudioContext'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/webaudio.dart']
          class: 'AudioContext'
''');
    await resolveTestCode('''
import '$importUri' as web;

void f() {
  web.AudioContext();
}
''');
    await assertHasFix('''
import '$importUri' as web;
import 'package:p/webaudio.dart' as web;

void f() {
  web.AudioContext();
}
''');
  }

  Future<void> test_new_element_uris_prefixed_removedTopLevelFunction() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
void topFn() {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Move topFn'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      function: 'topFn'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          function: 'topFn'
''');
    await resolveTestCode('''
import '$importUri' as web;

void f() {
  web.topFn();
}
''');
    await assertHasFix('''
import '$importUri' as web;
import 'package:p/lib2.dart' as web;

void f() {
  web.topFn();
}
''');
  }

  Future<void> test_new_element_uris_prefixed_to_other_prefix() async {
    setPackageContent('''
@deprecated
void expect(Object? v1, Object? v2) {}
''');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
void expect(Object? v1, Object? v2) {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace expect'
    date: 2022-05-12
    bulkApply: false
    element:
      uris: ['$importUri']
      function: 'expect'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          function: 'expect'
''');
    await resolveTestCode('''
import '$importUri' as prefix;
import 'package:p/lib2.dart' as other; // ignore: unused_import

main() {
  prefix.expect(true, true);
}
''');
    await assertHasFix('''
import '$importUri' as prefix;
import 'package:p/lib2.dart' as other; // ignore: unused_import

main() {
  other.expect(true, true);
}
''');
  }

  Future<void> test_new_element_uris_prefixed_to_same_prefix() async {
    setPackageContent('''
@deprecated
void oldExpect(Object? v1, Object? v2) {}
''');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
void expect(Object? v1, Object? v2) {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace oldExpect'
    date: 2022-05-12
    bulkApply: false
    element:
      uris: ['$importUri']
      function: 'oldExpect'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          function: 'expect'
''');
    await resolveTestCode('''
import '$importUri' as prefix;
import 'package:p/lib2.dart' as prefix; // ignore: unused_import

main() {
  prefix.oldExpect(true, true);
}
''');
    await assertHasFix('''
import '$importUri' as prefix;
import 'package:p/lib2.dart' as prefix; // ignore: unused_import

main() {
  prefix.expect(true, true);
}
''');
  }

  Future<void> test_new_element_uris_prefixed_to_unprefixed() async {
    setPackageContent('''
@deprecated
void expect(Object? v1, Object? v2) {}
''');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
void expect(Object? v1, Object? v2) {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace expect'
    date: 2022-05-12
    bulkApply: false
    element:
      uris: ['$importUri']
      function: 'expect'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          function: 'expect'
''');
    await resolveTestCode('''
import '$importUri' as prefix;
import 'package:p/lib2.dart'; // ignore: unused_import

main() {
  prefix.expect(true, true);
}
''');
    await assertHasFix('''
import '$importUri' as prefix;
import 'package:p/lib2.dart'; // ignore: unused_import

main() {
  expect(true, true);
}
''');
  }

  Future<void> test_new_element_uris_single() async {
    setPackageContent('');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace expect'
    date: 2022-05-12
    bulkApply: false
    element:
      uris: ['$importUri']
      function: 'expect'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:matcher/expect.dart']
          function: 'expect'
''');
    await resolveTestCode('''
import '$importUri';

main() {
  expect(true, true);
}
''');
    await assertHasFix('''
import 'package:matcher/expect.dart';
import '$importUri';

main() {
  expect(true, true);
}
''');
  }

  Future<void> test_new_element_uris_to_prefixed() async {
    setPackageContent('''
@deprecated
void expect(Object? v1, Object? v2) {}
''');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
void expect(Object? v1, Object? v2) {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace expect'
    date: 2022-05-12
    bulkApply: false
    element:
      uris: ['$importUri']
      function: 'expect'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          function: 'expect'
''');
    // Use the prefix of the existing prefixed import.
    await resolveTestCode('''
import '$importUri';
import 'package:p/lib2.dart' as prefix; // ignore: unused_import

main() {
  expect(true, true);
}
''');
    await assertHasFix('''
import '$importUri';
import 'package:p/lib2.dart' as prefix; // ignore: unused_import

main() {
  prefix.expect(true, true);
}
''');
  }

  Future<void> test_removed_annotation_constructor_uris_prefixed() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class New {
  const New.named();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace Old with New'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'Old'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'New'
''');
    await resolveTestCode('''
import '$importUri' as prefix;

@prefix.Old.named()
void f() {}
''');
    await assertHasFix('''
import '$importUri' as prefix;
import 'package:p/lib2.dart' as prefix;

@prefix.New.named()
void f() {}
''');
  }

  Future<void> test_removed_annotation_constructor_uris_single() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class New {
  const New();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace Old with New'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'Old'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'New'
''');
    await resolveTestCode('''
import '$importUri';

@Old()
void f() {}
''');
    await assertHasFix('''
import '$importUri';
import 'package:p/lib2.dart';

@New()
void f() {}
''');
  }

  Future<void> test_removed_catchClause_uris_prefixed() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class NewError implements Exception {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace OldError with NewError'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'OldError'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'NewError'
''');
    await resolveTestCode('''
import '$importUri' as prefix;

void f() {
  try {} on prefix.OldError catch (e) {
    print(e);
  }
}
''');
    await assertHasFix('''
import '$importUri' as prefix;
import 'package:p/lib2.dart' as prefix;

void f() {
  try {} on prefix.NewError catch (e) {
    print(e);
  }
}
''', filter: ignoreUnusedImport);
  }

  Future<void> test_removed_catchClause_uris_single() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class NewError implements Exception {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace OldError with NewError'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'OldError'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'NewError'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  try {} on OldError catch (e) {
    print(e);
  }
}
''');
    await assertHasFix('''
import '$importUri';
import 'package:p/lib2.dart';

void f() {
  try {} on NewError catch (e) {
    print(e);
  }
}
''', filter: ignoreUnusedImport);
  }

  Future<void> test_removed_classTypeAlias_uris_single() async {
    setPackageContent('''
mixin M {}
''');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace Old with New'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'Old'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'New'
''');
    await resolveTestCode('''
import '$importUri';

class C = Old with M;
''');
    await assertHasFix('''
import '$importUri';
import 'package:p/lib2.dart';

class C = New with M;
''');
  }

  Future<void> test_removed_constCreation_uris_prefixed() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class New {
  const New.named();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace Old with New'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'Old'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'New'
''');
    await resolveTestCode('''
import '$importUri' as prefix;

var x = const prefix.Old.named();
''');
    await assertHasFix('''
import '$importUri' as prefix;
import 'package:p/lib2.dart' as prefix;

var x = const prefix.New.named();
''');
  }

  Future<void> test_removed_constCreation_uris_single() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class New<T> {
  const New();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace Old with New'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'Old'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'New'
''');
    await resolveTestCode('''
import '$importUri';

var x = const Old<int>();
''');
    await assertHasFix('''
import '$importUri';
import 'package:p/lib2.dart';

var x = const New<int>();
''');
  }

  Future<void> test_removed_extendsWithMixin_uris_prefixed() async {
    setPackageContent('''
mixin M {}
''');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace Old with New'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'Old'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'New'
''');
    await resolveTestCode('''
import '$importUri';
import '$importUri' as prefix;

class C extends prefix.Old with M {}
''');
    await assertHasFix('''
import '$importUri';
import '$importUri' as prefix;
import 'package:p/lib2.dart' as prefix;

class C extends prefix.New with M {}
''', filter: ignoreUnusedImport);
  }

  Future<void> test_removed_newCreation_uris_prefixed() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class New {
  New.named();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace Old with New'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'Old'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'New'
''');
    await resolveTestCode('''
import '$importUri' as prefix;

var x = new prefix.Old.named();
''');
    await assertHasFix('''
import '$importUri' as prefix;
import 'package:p/lib2.dart' as prefix;

var x = new prefix.New.named();
''');
  }

  Future<void> test_removed_newCreation_uris_single() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class New<T> {
  New();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace Old with New'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'Old'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'New'
''');
    await resolveTestCode('''
import '$importUri';

var x = new Old<int>();
''');
    await assertHasFix('''
import '$importUri';
import 'package:p/lib2.dart';

var x = new New<int>();
''');
  }

  Future<void> test_removed_typeTest_uris_prefixed() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class New<T> {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace Old with New'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'Old'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'New'
''');
    await resolveTestCode('''
import '$importUri' as prefix;

bool f(Object x) => x is! prefix.Old<int>;
''');
    await assertHasFix('''
import '$importUri' as prefix;
import 'package:p/lib2.dart' as prefix;

bool f(Object x) => x is! prefix.New<int>;
''', filter: ignoreUnusedImport);
  }

  Future<void> test_removed_typeTest_uris_single() async {
    setPackageContent('');
    newFile('$workspaceRootPath/p/lib/lib2.dart', '''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace Old with New'
    date: 2026-01-01
    element:
      uris: ['$importUri']
      class: 'Old'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:p/lib2.dart']
          class: 'New'
''');
    await resolveTestCode('''
import '$importUri';

bool f(Object x) => x is Old;
''');
    await assertHasFix('''
import '$importUri';
import 'package:p/lib2.dart';

bool f(Object x) => x is New;
''', filter: ignoreUnusedImport);
  }
}

class _Element {
  final ElementKind kind;
  final List<String> components;
  final String declaration;

  new(this.kind, this.components, this.declaration);

  factory class_({bool isDeprecated = false, bool isOld = false}) {
    var name = isOld ? 'C_old' : 'C_new';
    var annotation = _annotation(isDeprecated: isDeprecated, isTopLevel: true);
    return _Element(
      ElementKind.classKind,
      [name],
      '''
${annotation}class $name {}''',
    );
  }

  factory constant({bool isDeprecated = false, bool isOld = false}) {
    var enumName = isOld ? 'E_old' : 'E_new';
    var constantName = isOld ? 'c_old' : 'c_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    return _Element(
      ElementKind.constantKind,
      [constantName, enumName],
      '''
enum $enumName {
  $annotation$constantName
}''',
    );
  }

  factory defaultConstructor({bool isDeprecated = false, bool isOld = false}) {
    var className = isOld ? 'C_old' : 'C_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    return _Element(
      ElementKind.constructorKind,
      ['', className],
      '''
class $className {
  $annotation$className();
}''',
    );
  }

  factory enum_({bool isDeprecated = false, bool isOld = false}) {
    var enumName = isOld ? 'E_old' : 'E_new';
    var constantName = isOld ? 'c_old' : 'c_new';
    var annotation = _annotation(isDeprecated: isDeprecated, isTopLevel: true);
    return _Element(
      ElementKind.enumKind,
      [enumName],
      '''
${annotation}enum $enumName { $constantName }''',
    );
  }

  factory extensionType({
    bool isDeprecated = false,
    bool isOld = false,
    String representationType = 'int',
    String representationVariable = '_',
    String? constructorName,
    bool isConst = false,
  }) {
    var name = isOld ? 'X_old' : 'X_new';
    var annotation = _annotation(isDeprecated: isDeprecated, isTopLevel: true);
    var constructorPart =
        '${constructorName == null ? '' : '.$constructorName'}'
        '($representationType $representationVariable)';
    var constPrefix = isConst ? 'const ' : '';
    return _Element(
      ElementKind.extensionTypeKind,
      [name],
      '''
${annotation}extension type $constPrefix$name$constructorPart {}''',
    );
  }

  factory field({
    bool isDeprecated = false,
    bool isOld = false,
    bool isStatic = false,
  }) {
    var fieldName = isOld ? 'sf_old' : 'sf_new';
    var className = isOld ? 'C_old' : 'C_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    var keyword = isStatic ? 'static ' : '';
    return _Element(
      ElementKind.fieldKind,
      [fieldName, className],
      '''
class $className {
  $annotation${keyword}int $fieldName = 0;
}''',
    );
  }

  factory getter({
    bool isDeprecated = false,
    bool isOld = false,
    bool isStatic = false,
  }) {
    var getterName = isOld ? 'g_old' : 'g_new';
    var className = isOld ? 'C_old' : 'C_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    var keyword = isStatic ? 'static ' : '';
    return _Element(
      ElementKind.getterKind,
      [getterName, className],
      '''
class $className {
  $annotation${keyword}int get $getterName => 0;
}''',
    );
  }

  factory method({
    bool isDeprecated = false,
    bool isOld = false,
    bool isStatic = false,
  }) {
    var methodName = isOld ? 'm_old' : 'm_new';
    var className = isOld ? 'C_old' : 'C_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    var keyword = isStatic ? 'static ' : '';
    return _Element(
      ElementKind.methodKind,
      [methodName, className],
      '''
class $className {
  $annotation${keyword}int $methodName() => 0;
}''',
    );
  }

  factory mixin({bool isDeprecated = false, bool isOld = false}) {
    var name = isOld ? 'M_old' : 'M_new';
    var annotation = _annotation(isDeprecated: isDeprecated, isTopLevel: true);
    return _Element(
      ElementKind.mixinKind,
      [name],
      '''
${annotation}mixin $name {}''',
    );
  }

  factory namedConstructor({bool isDeprecated = false, bool isOld = false}) {
    var constructorName = isOld ? 'c_old' : 'c_new';
    var className = isOld ? 'C_old' : 'C_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    return _Element(
      ElementKind.constructorKind,
      [constructorName, className],
      '''
class $className {
  $annotation$className.$constructorName();
}''',
    );
  }

  factory setter({
    bool isDeprecated = false,
    bool isOld = false,
    bool isStatic = false,
  }) {
    var setterName = isOld ? 's_old' : 's_new';
    var className = isOld ? 'C_old' : 'C_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    var keyword = isStatic ? 'static ' : '';
    return _Element(
      ElementKind.setterKind,
      [setterName, className],
      '''
class $className {
  $annotation${keyword}set $setterName(int v) {}
}''',
    );
  }

  factory topLevelFunction({bool isDeprecated = false, bool isOld = false}) {
    var name = isOld ? 'f_old' : 'f_new';
    var annotation = _annotation(isDeprecated: isDeprecated, isTopLevel: true);
    return _Element(
      ElementKind.functionKind,
      [name],
      '''
${annotation}int $name() => 0;''',
    );
  }

  factory topLevelGetter({bool isDeprecated = false, bool isOld = false}) {
    var getterName = isOld ? 'g_old' : 'g_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    return _Element(
      ElementKind.getterKind,
      [getterName],
      '''
${annotation}int get $getterName => 0;''',
    );
  }

  factory topLevelSetter({bool isDeprecated = false, bool isOld = false}) {
    var setterName = isOld ? 's_old' : 's_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    return _Element(
      ElementKind.setterKind,
      [setterName],
      '''
${annotation}set $setterName(int v) {}''',
    );
  }

  factory topLevelVariable({bool isDeprecated = false, bool isOld = false}) {
    var name = isOld ? 'v_old' : 'v_new';
    var annotation = _annotation(isDeprecated: isDeprecated, isTopLevel: true);
    return _Element(
      ElementKind.variableKind,
      [name],
      '''
${annotation}int $name = 0;''',
    );
  }

  factory typedef({
    bool isDeprecated = false,
    bool isOld = false,
    String aliasedType = 'int Function()',
  }) {
    var name = isOld ? 'T_old' : 'T_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    return _Element(
      ElementKind.typedefKind,
      [name],
      '''
${annotation}typedef $name = $aliasedType;''',
    );
  }

  String get reference {
    if (components[0].isEmpty) {
      return components[1];
    }
    return components.reversed.join('.');
  }

  static String _annotation({
    required bool isDeprecated,
    bool isTopLevel = false,
  }) {
    var indent = isTopLevel ? '' : '  ';
    return isDeprecated ? '@deprecated\n$indent' : '';
  }
}
