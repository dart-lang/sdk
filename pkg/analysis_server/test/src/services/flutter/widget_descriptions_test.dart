// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/flutter/widget_descriptions.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContainerPropertiesTest);
    defineReflectiveTests(GetDescriptionTest);
    defineReflectiveTests(SetPropertyValueSelfTest);
  });
}

@reflectiveTest
class ContainerPropertiesTest extends _BaseTest {
  test_alignment_hasContainer() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Container(
    child: Text(''),
    alignment: Alignment.centerRight,
  );
}
''');
    var property = _getProperty('Container', widgetSearch: 'Text(');
    var alignmentProperty = _getProperty('alignment', parentProperty: property);
    // TODO(scheglov) Value, editor.
    _assertPropertyJsonText(alignmentProperty, r'''
{
  "expression": "Alignment.centerRight",
  "isRequired": false,
  "isSafeToUpdate": false,
  "name": "alignment",
  "children": []
}
''');
  }

  test_container_existing() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Container(
    child: Text(''),
    alignment: Alignment.centerRight,
  );
}
''');
    var property = _getProperty('Container', widgetSearch: 'Text(');
    var childrenNames = property.children.map((p) => p.name).toList();

    expect(
      childrenNames,
      containsAll([
        'alignment',
        'color',
        'decoration',
        'height',
        'margin',
        'width',
      ]),
    );

    expect(childrenNames, isNot(contains('child')));
  }
}

@reflectiveTest
class GetDescriptionTest extends _BaseTest {
  test_kind_named_notSet() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = _getProperty('softWrap', widgetSearch: 'Text(');
    expect(property.documentation, startsWith('Whether the text should'));
    _assertPropertyJsonText(property, r'''
{
  "isRequired": false,
  "isSafeToUpdate": true,
  "name": "softWrap",
  "children": [],
  "editor": {
    "kind": "BOOL"
  }
}
''');
  }

  test_kind_named_set() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa', softWrap: true);
}
''');
    var property = _getProperty('softWrap', widgetSearch: 'Text(');
    expect(property.documentation, startsWith('Whether the text should'));
    _assertPropertyJsonText(property, r'''
{
  "expression": "true",
  "isRequired": false,
  "isSafeToUpdate": true,
  "name": "softWrap",
  "children": [],
  "editor": {
    "kind": "BOOL"
  },
  "value": {
    "boolValue": true
  }
}
''');
  }

  test_kind_required() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = _getProperty('data', widgetSearch: 'Text(');
    expect(property.documentation, startsWith('The text to display.'));
    _assertPropertyJsonText(property, r'''
{
  "expression": "'aaa'",
  "isRequired": true,
  "isSafeToUpdate": true,
  "name": "data",
  "children": [],
  "editor": {
    "kind": "STRING"
  },
  "value": {
    "stringValue": "aaa"
  }
}
''');
  }

  test_nested_notSet() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('');
}
''');
    var styleProperty = _getProperty('style', widgetSearch: 'Text(');

    var fontSizeProperty = _getProperty(
      'fontSize',
      parentProperty: styleProperty,
    );
    _assertPropertyJsonText(fontSizeProperty, r'''
{
  "isRequired": false,
  "isSafeToUpdate": true,
  "name": "fontSize",
  "children": [],
  "editor": {
    "kind": "DOUBLE"
  }
}
''');
  }

  test_nested_set() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('', style: TextStyle(fontSize: 24));
}
''');
    var styleProperty = _getProperty('style', widgetSearch: 'Text(');

    var fontSizeProperty = _getProperty(
      'fontSize',
      parentProperty: styleProperty,
    );
    _assertPropertyJsonText(fontSizeProperty, r'''
{
  "expression": "24",
  "isRequired": false,
  "isSafeToUpdate": true,
  "name": "fontSize",
  "children": [],
  "editor": {
    "kind": "DOUBLE"
  },
  "value": {
    "intValue": 24
  }
}
''');

    var fontStyleProperty = _getProperty(
      'fontStyle',
      parentProperty: styleProperty,
    );
    _assertPropertyJsonText(fontStyleProperty, r'''
{
  "isRequired": false,
  "isSafeToUpdate": true,
  "name": "fontStyle",
  "children": [],
  "editor": {
    "kind": "ENUM",
    "enumItems": [
      {
        "libraryUri": "package:ui/ui.dart",
        "className": "FontStyle",
        "name": "normal"
      },
      {
        "libraryUri": "package:ui/ui.dart",
        "className": "FontStyle",
        "name": "italic"
      }
    ]
  }
}
''');
  }

  test_notInstanceCreation() async {
    await resolveTestUnit('''
void main() {
  42;
}
''');
    var description = _getDescription('42');
    expect(description, isNull);
  }

  test_type_double() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = _getProperty('textScaleFactor', widgetSearch: 'Text(');
    _assertPropertyJsonText(property, r'''
{
  "isRequired": false,
  "isSafeToUpdate": true,
  "name": "textScaleFactor",
  "children": [],
  "editor": {
    "kind": "DOUBLE"
  }
}
''');
  }

  test_type_enum() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('', overflow: TextOverflow.fade);
}
''');
    var property = _getProperty('overflow', widgetSearch: 'Text(');

    expect(
      property.toJson()['editor']['enumItems'][0]['documentation'],
      startsWith('Clip the overflowing'),
    );

    _assertPropertyJsonText(property, r'''
{
  "expression": "TextOverflow.fade",
  "isRequired": false,
  "isSafeToUpdate": true,
  "name": "overflow",
  "children": [],
  "editor": {
    "kind": "ENUM",
    "enumItems": [
      {
        "libraryUri": "package:flutter/src/rendering/paragraph.dart",
        "className": "TextOverflow",
        "name": "clip"
      },
      {
        "libraryUri": "package:flutter/src/rendering/paragraph.dart",
        "className": "TextOverflow",
        "name": "fade"
      },
      {
        "libraryUri": "package:flutter/src/rendering/paragraph.dart",
        "className": "TextOverflow",
        "name": "ellipsis"
      },
      {
        "libraryUri": "package:flutter/src/rendering/paragraph.dart",
        "className": "TextOverflow",
        "name": "visible"
      }
    ]
  },
  "value": {
    "enumValue": {
      "libraryUri": "package:flutter/src/rendering/paragraph.dart",
      "className": "TextOverflow",
      "name": "fade"
    }
  }
}
''');
  }

  test_type_int() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = _getProperty('maxLines', widgetSearch: 'Text(');
    _assertPropertyJsonText(property, r'''
{
  "isRequired": false,
  "isSafeToUpdate": true,
  "name": "maxLines",
  "children": [],
  "editor": {
    "kind": "INT"
  }
}
''');
  }

  test_unresolvedInstanceCreation() async {
    verifyNoTestUnitErrors = false;
    await resolveTestUnit('''
void main() {
  new Foo();
}
''');
    var description = _getDescription('Foo');
    expect(description, isNull);
  }
}

@reflectiveTest
class SetPropertyValueSelfTest extends _BaseTest {
  test_invalidId() async {
    await resolveTestUnit('');

    var result = await descriptions.setPropertyValue(42, null);

    expect(
      result.errorCode,
      protocol.RequestErrorCode.FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID,
    );
    expect(result.change, isNull);
  }

  test_named_addValue_hasComma() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('', );
}
''');
    var property = _getProperty('maxLines', widgetSearch: 'Text(');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    _assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 42, );
}
''');
  }

  test_named_addValue_noComma() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('');
}
''');
    var property = _getProperty('maxLines', widgetSearch: 'Text(');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    _assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 42, );
}
''');
  }

  test_named_changeValue() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 1);
}
''');
    var property = _getProperty('maxLines', widgetSearch: 'Text(');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    _assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 42);
}
''');
  }

  test_named_removeValue_last() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 1,);
}
''');
    var property = _getProperty('maxLines', widgetSearch: 'Text(');

    var result = await descriptions.setPropertyValue(property.id, null);

    _assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', );
}
''');
  }

  test_named_removeValue_notLast() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 1, softWrap: true,);
}
''');
    var property = _getProperty('maxLines', widgetSearch: 'Text(');

    var result = await descriptions.setPropertyValue(property.id, null);

    _assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', softWrap: true,);
}
''');
  }

  test_nested_addValue() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('', style: TextStyle(), );
}
''');
    var styleProperty = _getProperty('style', widgetSearch: 'Text(');

    var fontSizeProperty = _getProperty(
      'fontSize',
      parentProperty: styleProperty,
    );

    var result = await descriptions.setPropertyValue(
      fontSizeProperty.id,
      protocol.FlutterWidgetPropertyValue(doubleValue: 42),
    );

    _assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', style: TextStyle(fontSize: 42.0, ), );
}
''');
  }

  test_nested_addValue_materialize() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('', );
}
''');
    var styleProperty = _getProperty('style', widgetSearch: 'Text(');

    var fontSizeProperty = _getProperty(
      'fontSize',
      parentProperty: styleProperty,
    );

    var result = await descriptions.setPropertyValue(
      fontSizeProperty.id,
      protocol.FlutterWidgetPropertyValue(doubleValue: 42),
    );

    _assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', style: TextStyle(fontSize: 42.0, ), );
}
''');
  }

  test_required_changeValue() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = _getProperty('data', widgetSearch: 'Text(');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(stringValue: 'bbbb'),
    );

    _assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('bbbb');
}
''');
  }

  test_required_removeValue() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = _getProperty('data', widgetSearch: 'Text(');

    var result = await descriptions.setPropertyValue(property.id, null);

    expect(
      result.errorCode,
      protocol.RequestErrorCode.FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED,
    );
    expect(result.change, isNull);
  }
}

@reflectiveTest
class _BaseTest extends AbstractSingleUnitTest {
  final flutter = Flutter.mobile;
  final descriptions = WidgetDescriptions();

  @override
  void setUp() {
    super.setUp();
    addFlutterPackage();
  }

  void _assertExpectedChange(SetPropertyValueResult result, String expected) {
    expect(result.errorCode, isNull);

    var change = result.change;

    expect(change.edits, hasLength(1));
    var fileEdit = change.edits[0];
    expect(fileEdit.file, testAnalysisResult.path);

    var actual = SourceEdit.applySequence(
      testAnalysisResult.content,
      fileEdit.edits,
    );
    expect(actual, expected);
  }

  void _assertPropertyJsonText(
    protocol.FlutterWidgetProperty property,
    String expected,
  ) {
    var json = property.toJson();
    _removeNotInterestingElements(json);

    var actual = JsonEncoder.withIndent('  ').convert(json);

    expected = expected.trimRight();
    if (actual != expected) {
      print('-----');
      print(actual);
      print('-----');
    }
    expect(actual, expected);
  }

  protocol.FlutterGetWidgetDescriptionResult _getDescription(String search) {
    var content = testAnalysisResult.content;

    var offset = content.indexOf(search);
    if (offset == -1) {
      fail('Not found: $search');
    }

    if (content.indexOf(search, offset + search.length) != -1) {
      fail('More than one: $search');
    }

    return descriptions.getDescription(testAnalysisResult, offset);
  }

  protocol.FlutterWidgetProperty _getProperty(
    String name, {
    String widgetSearch,
    protocol.FlutterWidgetProperty parentProperty,
  }) {
    if (widgetSearch == null && parentProperty == null ||
        widgetSearch != null && parentProperty != null) {
      fail("Either 'widgetSearch' or 'parentProperty' must be specified");
    }

    List<protocol.FlutterWidgetProperty> properties;
    if (widgetSearch != null) {
      var widgetDescription = _getDescription(widgetSearch);
      expect(widgetDescription, isNotNull);

      properties = widgetDescription.properties;
    } else if (parentProperty != null) {
      properties = parentProperty.children;
    }

    return properties.singleWhere(
      (property) => property.name == name,
    );
  }

  void _removeNotInterestingElements(Map<String, dynamic> json) {
    json.remove('documentation');

    var id = json.remove('id') as int;
    expect(id, isNotNull);

    Object editor = json['editor'];
    if (editor is Map<String, dynamic> && editor['kind'] == 'ENUM') {
      Object items = editor['enumItems'];
      if (items is List<Map<String, dynamic>>) {
        for (var item in items) {
          item.remove('documentation');
        }
      }
    }

    Object value = json['value'];
    if (value is Map<String, dynamic>) {
      Object enumItem = value['enumValue'];
      if (enumItem is Map<String, dynamic>) {
        enumItem.remove('documentation');
      }
    }

    var children = json['children'];
    if (children is List<Map<String, dynamic>>) {
      children.forEach(_removeNotInterestingElements);
    }
  }
}
