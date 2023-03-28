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
    defineReflectiveTests(ReplacedByTest);
    defineReflectiveTests(ReplacedByUriSemanticsTest);
  });
}

@reflectiveTest
class ReplacedByTest extends DataDrivenFixProcessorTest {
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

  Future<void> _assertReplacement(_Element oldElement, _Element newElement,
      {bool isAssignment = false,
      bool isInvocation = false,
      bool isPrefixed = false,
      bool isOldRemoved = false}) async {
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
    //TODO(asashour) inserting imports should remove initial blank lines
    var oldImport = isOldRemoved
        ? ''
        : '''
$import
''';
    var newImport = '''
$import${isOldRemoved ? '\n' : ''}
''';

    await resolveTestCode('''
${oldImport}var x = $prefixReference${oldElement.reference}$invocation;
''');
    await assertHasFix('''
${newImport}var x = $prefixReference${newElement.reference}$invocation;
''');
  }

  Transform _replacedBy(ElementKind oldKind, List<String> oldComponents,
      ElementKind newKind, List<String> newComponents,
      {bool isStatic = false, Uri? oldUri}) {
    var oldElement = ElementDescriptor(
        libraryUris: [oldUri ?? Uri.parse(importUri)],
        kind: oldKind,
        isStatic: isStatic,
        components: oldComponents);
    var newElement = ElementDescriptor(
        libraryUris: [Uri.parse(importUri)],
        kind: newKind,
        isStatic: isStatic,
        components: newComponents);
    return Transform(
        title: 'title',
        date: DateTime.now(),
        element: oldElement,
        bulkApply: true,
        changesSelector: UnconditionalChangesSelector([
          ReplacedBy(newElement: newElement),
        ]));
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
''', errorFilter: ignoreUnusedImport);
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
''', errorFilter: ignoreUnusedImport);
  }
}

class _Element {
  final ElementKind kind;
  final List<String> components;
  final String declaration;

  _Element(this.kind, this.components, this.declaration);

  // ignore: unused_element
  factory _Element.class_({bool isDeprecated = false, bool isOld = false}) {
    var name = isOld ? 'C_old' : 'C_new';
    var annotation = _annotation(isDeprecated: isDeprecated, isTopLevel: true);
    return _Element(
      ElementKind.classKind,
      [name],
      '''
${annotation}class $name {}''',
    );
  }

  factory _Element.constant({bool isDeprecated = false, bool isOld = false}) {
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

  factory _Element.defaultConstructor(
      {bool isDeprecated = false, bool isOld = false}) {
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

  // ignore: unused_element
  factory _Element.enum_({bool isDeprecated = false, bool isOld = false}) {
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

  factory _Element.field(
      {bool isDeprecated = false, bool isOld = false, bool isStatic = false}) {
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

  factory _Element.getter(
      {bool isDeprecated = false, bool isOld = false, bool isStatic = false}) {
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

  factory _Element.method(
      {bool isDeprecated = false, bool isOld = false, bool isStatic = false}) {
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

  factory _Element.namedConstructor(
      {bool isDeprecated = false, bool isOld = false}) {
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

  factory _Element.setter(
      {bool isDeprecated = false, bool isOld = false, bool isStatic = false}) {
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

  factory _Element.topLevelFunction(
      {bool isDeprecated = false, bool isOld = false}) {
    var name = isOld ? 'f_old' : 'f_new';
    var annotation = _annotation(isDeprecated: isDeprecated, isTopLevel: true);
    return _Element(
      ElementKind.functionKind,
      [name],
      '''
${annotation}int $name() => 0;''',
    );
  }

  factory _Element.topLevelGetter(
      {bool isDeprecated = false, bool isOld = false}) {
    var getterName = isOld ? 'g_old' : 'g_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    return _Element(
      ElementKind.getterKind,
      [getterName],
      '''
${annotation}int get $getterName => 0;''',
    );
  }

  factory _Element.topLevelSetter(
      {bool isDeprecated = false, bool isOld = false}) {
    var setterName = isOld ? 's_old' : 's_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    return _Element(
      ElementKind.setterKind,
      [setterName],
      '''
${annotation}set $setterName(int v) {}''',
    );
  }

  factory _Element.topLevelVariable(
      {bool isDeprecated = false, bool isOld = false}) {
    var name = isOld ? 'v_old' : 'v_new';
    var annotation = _annotation(isDeprecated: isDeprecated, isTopLevel: true);
    return _Element(
      ElementKind.variableKind,
      [name],
      '''
${annotation}int $name = 0;''',
    );
  }

  // ignore: unused_element
  factory _Element.typedef({bool isDeprecated = false, bool isOld = false}) {
    var name = isOld ? 'T_old' : 'T_new';
    var annotation = _annotation(isDeprecated: isDeprecated);
    return _Element(
      ElementKind.typedefKind,
      [name],
      '''
${annotation}typedef $name = int Function();''',
    );
  }

  String get reference {
    if (components[0].isEmpty) {
      return components[1];
    }
    return components.reversed.join('.');
  }

  static String _annotation(
      {required bool isDeprecated, bool isTopLevel = false}) {
    var indent = isTopLevel ? '' : '  ';
    return isDeprecated ? '@deprecated\n$indent' : '';
  }
}
