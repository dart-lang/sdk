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
      bool isPrefixed = false}) async {
    assert(!(isAssignment && isInvocation));
    setPackageContent('''
${oldElement.declaration}
${newElement.declaration}
''');
    setPackageData(_replacedBy(oldElement.kind, oldElement.components,
        newElement.kind, newElement.components));
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
    await resolveTestCode('''
import '$importUri'$prefixDeclaration;

var x = $prefixReference${oldElement.reference}$invocation;
''');
    await assertHasFix('''
import '$importUri'$prefixDeclaration;

var x = $prefixReference${newElement.reference}$invocation;
''');
  }

  Transform _replacedBy(ElementKind oldKind, List<String> oldComponents,
      ElementKind newKind, List<String> newComponents,
      {bool isStatic = false}) {
    var uris = [Uri.parse(importUri)];
    var oldElement = ElementDescriptor(
        libraryUris: uris,
        kind: oldKind,
        isStatic: isStatic,
        components: oldComponents);
    var newElement2 = ElementDescriptor(
        libraryUris: uris,
        kind: newKind,
        isStatic: isStatic,
        components: newComponents);
    return Transform(
        title: 'title',
        date: DateTime.now(),
        element: oldElement,
        bulkApply: true,
        changesSelector: UnconditionalChangesSelector([
          ReplacedBy(newElement: newElement2),
        ]));
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
