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
    defineReflectiveTests(GetDescriptionTest);
    defineReflectiveTests(SetPropertyValueSelfTest);
  });
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
    var property = _getProperty('Text(', 'softWrap');
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
    var property = _getProperty('Text(', 'softWrap');
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
    var property = _getProperty('Text(', 'data');
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
    var property = _getProperty('Text(', 'textScaleFactor');
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

  test_type_int() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = _getProperty('Text(', 'maxLines');
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

    var result = descriptions.setPropertyValue(42, null);

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
    var property = _getProperty('Text(', 'maxLines');

    var result = descriptions.setPropertyValue(
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
    var property = _getProperty('Text(', 'maxLines');

    var result = descriptions.setPropertyValue(
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
    var property = _getProperty('Text(', 'maxLines');

    var result = descriptions.setPropertyValue(
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
    var property = _getProperty('Text(', 'maxLines');

    var result = descriptions.setPropertyValue(property.id, null);

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
    var property = _getProperty('Text(', 'maxLines');

    var result = descriptions.setPropertyValue(property.id, null);

    _assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', softWrap: true,);
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
    var property = _getProperty('Text(', 'data');

    var result = descriptions.setPropertyValue(
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
    var property = _getProperty('Text(', 'data');

    var result = descriptions.setPropertyValue(property.id, null);

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
    String widgetSearch,
    String propertyName,
  ) {
    var widgetDescription = _getDescription(widgetSearch);
    expect(widgetDescription, isNotNull);

    return widgetDescription.properties.singleWhere(
      (property) => property.name == propertyName,
    );
  }

  void _removeNotInterestingElements(Map<String, dynamic> json) {
    json.remove('documentation');

    var id = json.remove('id') as int;
    expect(id, isNotNull);

    var children = json['children'];
    if (children is List<Map<String, dynamic>>) {
      children.forEach(_removeNotInterestingElements);
    }
  }
}
