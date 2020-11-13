// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/accessor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/add_type_parameter.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_template.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_matcher.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/modify_parameters.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/value_generator.dart';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TransformSetParserTest);
  });
}

@reflectiveTest
class TransformSetParserTest extends AbstractTransformSetParserTest {
  List<Uri> get uris => [Uri.parse('package:myPackage/test.dart')];

  void test_addParameter_optionalNamed() {
    parse('''
version: 1
transforms:
- title: 'Add'
  date: 2020-09-09
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'p'
      style: optional_named
      argumentValue:
        expression: '{% p %}'
        variables:
          p:
            kind: 'fragment'
            value: 'arguments[1]'
''');
    var transforms = _transforms('f');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Add');
    expect(transform.changes, hasLength(1));
    var change = transform.changes[0] as ModifyParameters;
    var modifications = change.modifications;
    expect(modifications, hasLength(1));
    var modification = modifications[0] as AddParameter;
    expect(modification.index, 0);
    expect(modification.name, 'p');
    expect(modification.isRequired, false);
    expect(modification.isPositional, false);
    var components = modification.argumentValue.components;
    expect(components, hasLength(1));
    var value = _accessor(components[0]) as ArgumentAccessor;
    var parameter = value.parameter as PositionalParameterReference;
    expect(parameter.index, 1);
  }

  void test_addParameter_optionalPositional() {
    parse('''
version: 1
transforms:
- title: 'Add'
  date: 2020-09-09
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'p'
      style: optional_positional
''');
    var transforms = _transforms('f');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Add');
    expect(transform.changes, hasLength(1));
    var change = transform.changes[0] as ModifyParameters;
    var modifications = change.modifications;
    expect(modifications, hasLength(1));
    var modification = modifications[0] as AddParameter;
    expect(modification.index, 0);
    expect(modification.name, 'p');
    expect(modification.isRequired, false);
    expect(modification.isPositional, true);
  }

  void test_addParameter_requiredNamed() {
    parse('''
version: 1
transforms:
- title: 'Add'
  date: 2020-09-09
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'p'
      style: required_named
      argumentValue:
        expression: '{% p %}'
        variables:
          p:
            kind: 'fragment'
            value: 'arguments[1]'
''');
    var transforms = _transforms('f');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Add');
    expect(transform.changes, hasLength(1));
    var change = transform.changes[0] as ModifyParameters;
    var modifications = change.modifications;
    expect(modifications, hasLength(1));
    var modification = modifications[0] as AddParameter;
    expect(modification.index, 0);
    expect(modification.name, 'p');
    expect(modification.isRequired, true);
    expect(modification.isPositional, false);
    var components = modification.argumentValue.components;
    expect(components, hasLength(1));
    var value = _accessor(components[0]) as ArgumentAccessor;
    var parameter = value.parameter as PositionalParameterReference;
    expect(parameter.index, 1);
  }

  void test_addParameter_requiredPositional() {
    parse('''
version: 1
transforms:
- title: 'Add'
  date: 2020-09-09
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'p'
      style: required_positional
      argumentValue:
        expression: '{% p %}'
        variables:
          p:
            kind: 'fragment'
            value: 'arguments[1]'
''');
    var transforms = _transforms('f');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Add');
    expect(transform.changes, hasLength(1));
    var change = transform.changes[0] as ModifyParameters;
    var modifications = change.modifications;
    expect(modifications, hasLength(1));
    var modification = modifications[0] as AddParameter;
    expect(modification.index, 0);
    expect(modification.name, 'p');
    expect(modification.isRequired, true);
    expect(modification.isPositional, true);
    var components = modification.argumentValue.components;
    expect(components, hasLength(1));
    var value = _accessor(components[0]) as ArgumentAccessor;
    var parameter = value.parameter as PositionalParameterReference;
    expect(parameter.index, 1);
  }

  void test_addParameter_requiredPositional_complexTemplate() {
    parse('''
version: 1
transforms:
- title: 'Add'
  date: 2020-09-09
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'p'
      style: required_positional
      argumentValue:
        expression: '{% a %}({% b %})'
        variables:
          a:
            kind: 'fragment'
            value: 'arguments[1]'
          b:
            kind: 'fragment'
            value: 'arguments[2]'
''');
    var transforms = _transforms('f');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Add');
    expect(transform.changes, hasLength(1));
    var change = transform.changes[0] as ModifyParameters;
    var modifications = change.modifications;
    expect(modifications, hasLength(1));
    var modification = modifications[0] as AddParameter;
    expect(modification.index, 0);
    expect(modification.name, 'p');
    expect(modification.isRequired, true);
    expect(modification.isPositional, true);
    var components = modification.argumentValue.components;
    expect(components, hasLength(4));
    var extractorA = _accessor(components[0]) as ArgumentAccessor;
    var parameterA = extractorA.parameter as PositionalParameterReference;
    expect(parameterA.index, 1);
    expect((components[1] as TemplateText).text, '(');
    var extractorB = _accessor(components[2]) as ArgumentAccessor;
    var parameterB = extractorB.parameter as PositionalParameterReference;
    expect(parameterB.index, 2);
    expect((components[3] as TemplateText).text, ')');
  }

  void test_addTypeParameter_fromImportedName() {
    parse('''
version: 1
transforms:
- date: 2020-09-03
  element:
    uris:
      - 'test.dart'
    class: 'A'
  title: 'Add'
  changes:
    - kind: 'addTypeParameter'
      index: 0
      name: 'T'
      argumentValue:
        expression: '{% t %}'
        variables:
          t:
            kind: 'import'
            uris: ['dart:core']
            name: 'String'
''');
    var transforms = _transforms('A');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Add');
    expect(transform.changes, hasLength(1));
    var change = transform.changes[0] as AddTypeParameter;
    expect(change.index, 0);
    expect(change.name, 'T');
    var components = change.argumentValue.components;
    expect(components, hasLength(1));
    var value = (components[0] as TemplateVariable).generator as ImportedName;
    expect(value.uris, [Uri.parse('dart:core')]);
    expect(value.name, 'String');
  }

  void test_addTypeParameter_fromNamedArgument() {
    parse('''
version: 1
transforms:
- title: 'Add'
  date: 2020-09-03
  element:
    uris:
      - 'test.dart'
    class: 'A'
  changes:
    - kind: 'addTypeParameter'
      index: 0
      name: 'T'
      argumentValue:
        expression: '{% t %}'
        variables:
          t:
            kind: 'fragment'
            value: 'arguments[p]'
''');
    var transforms = _transforms('A');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Add');
    expect(transform.changes, hasLength(1));
    var change = transform.changes[0] as AddTypeParameter;
    expect(change.index, 0);
    expect(change.name, 'T');
    expect(change.extendedType, null);

    var components = change.argumentValue.components;
    expect(components, hasLength(1));
    var value = _accessor(components[0]) as ArgumentAccessor;
    var parameter = value.parameter as NamedParameterReference;
    expect(parameter.name, 'p');
  }

  void test_addTypeParameter_fromPositionalArgument() {
    parse('''
version: 1
transforms:
- title: 'Add'
  date: 2020-09-03
  element:
    uris:
      - 'test.dart'
    class: 'A'
  changes:
    - kind: 'addTypeParameter'
      index: 0
      name: 'T'
      extends:
        expression: 'Object'
      argumentValue:
        expression: '{% t %}'
        variables:
          t:
            kind: 'fragment'
            value: 'arguments[2]'
''');
    var transforms = _transforms('A');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Add');
    expect(transform.changes, hasLength(1));
    var change = transform.changes[0] as AddTypeParameter;
    expect(change.index, 0);
    expect(change.name, 'T');

    var extendsComponents = change.extendedType.components;
    expect(extendsComponents, hasLength(1));
    expect((extendsComponents[0] as TemplateText).text, 'Object');

    var argumentComponents = change.argumentValue.components;
    expect(argumentComponents, hasLength(1));
    var value = _accessor(argumentComponents[0]) as ArgumentAccessor;
    var parameter = value.parameter as PositionalParameterReference;
    expect(parameter.index, 2);
  }

  void test_bulkApply() {
    parse('''
version: 1
transforms:
- title: 'Rename g'
  date: 2020-09-10
  bulkApply: false
  element:
    uris: ['test.dart']
    getter: 'g'
  changes: []
''');
    var transforms = _transforms('g');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Rename g');
    expect(transform.bulkApply, false);
    expect(transform.changes, isEmpty);
  }

  void test_correctOffsetForPlainStrings() {
    assertErrors('''
version: 1
transforms:
- title: 'Add'
  date: 2020-09-03
  element:
    uris:
      - 'test.dart'
    class: 'A'
  changes:
    - kind: 'addTypeParameter'
      index: 0
      name: 'T'
      extends:
        expression: 'Object'
      argumentValue:
        expression: '{% t %}'
        variables:
          t:
            kind: 'fragment'
            value: args
''', [
      error(TransformSetErrorCode.unknownAccessor, 361, 4),
    ]);
  }

  void test_date() {
    parse('''
version: 1
transforms:
- title: 'Rename g'
  date: 2020-09-10
  element:
    uris: ['test.dart']
    getter: 'g'
  changes: []
''');
    var transforms = _transforms('g');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Rename g');
    expect(transform.changes, isEmpty);
  }

  void test_element_getter_inMixin() {
    parse('''
version: 1
transforms:
- title: 'Rename g'
  date: 2020-09-02
  element:
    uris: ['test.dart']
    getter: 'g'
    inMixin: 'A'
  changes: []
''');
    var transforms = _transforms('g');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Rename g');
    expect(transform.changes, isEmpty);
  }

  void test_element_getter_topLevel() {
    parse('''
version: 1
transforms:
- title: 'Rename g'
  date: 2020-09-02
  element:
    uris: ['test.dart']
    getter: 'g'
  changes: []
''');
    var transforms = _transforms('g');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Rename g');
    expect(transform.changes, isEmpty);
  }

  void test_element_method_inClass() {
    parse('''
version: 1
transforms:
- title: 'Rename m'
  date: 2020-09-02
  element:
    uris: ['test.dart']
    method: 'm'
    inClass: 'A'
  changes: []
''');
    var transforms = _transforms('m');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Rename m');
    expect(transform.changes, isEmpty);
  }

  void test_element_variable() {
    parse('''
version: 1
transforms:
- title: 'Rename v'
  date: 2020-10-01
  element:
    uris: ['test.dart']
    variable: 'v'
  changes: []
''');
    var transforms = _transforms('v');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Rename v');
    expect(transform.changes, isEmpty);
  }

  void test_incomplete() {
    parse('''
version: 1
transforms:
''');
    expect(result, null);
    errorListener.assertErrors([
      error(TransformSetErrorCode.invalidValue, 21, 0),
    ]);
  }

  void test_invalidYaml() {
    parse('''
[
''');
    expect(result, null);
    errorListener.assertErrors([
      error(TransformSetErrorCode.yamlSyntaxError, 2, 0),
    ]);
  }

  void test_removeParameter_named() {
    parse('''
version: 1
transforms:
- title: 'Remove'
  date: 2020-09-09
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'removeParameter'
      name: 'p'
''');
    var transforms = _transforms('f');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Remove');
    expect(transform.changes, hasLength(1));
    var change = transform.changes[0] as ModifyParameters;
    var modifications = change.modifications;
    expect(modifications, hasLength(1));
    var modification = modifications[0] as RemoveParameter;
    var parameter = modification.parameter as NamedParameterReference;
    expect(parameter.name, 'p');
  }

  void test_removeParameter_positional() {
    parse('''
version: 1
transforms:
- title: 'Remove'
  date: 2020-09-09
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'removeParameter'
      index: 0
''');
    var transforms = _transforms('f');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Remove');
    expect(transform.changes, hasLength(1));
    var change = transform.changes[0] as ModifyParameters;
    var modifications = change.modifications;
    expect(modifications, hasLength(1));
    var modification = modifications[0] as RemoveParameter;
    var parameter = modification.parameter as PositionalParameterReference;
    expect(parameter.index, 0);
  }

  void test_rename() {
    parse('''
version: 1
transforms:
- title: 'Rename A'
  date: 2020-08-21
  element:
    uris:
      - 'test.dart'
    class: 'A'
  changes:
    - kind: 'rename'
      newName: 'B'
''');
    var transforms = _transforms('A');
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Rename A');
    expect(transform.changes, hasLength(1));
    var rename = transform.changes[0] as Rename;
    expect(rename.newName, 'B');
  }

  /// Return the first accessor from the given [component].
  Accessor _accessor(TemplateComponent component) =>
      ((component as TemplateVariable).generator as CodeFragment).accessors[0];

  ElementMatcher _matcher(String name) =>
      ElementMatcher(importedUris: uris, name: name);

  List<Transform> _transforms(String name) =>
      result.transformsFor(_matcher(name), applyingBulkFixes: false);
}
