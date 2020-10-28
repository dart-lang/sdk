// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'widget_description.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetDescriptionTest);
    defineReflectiveTests(SetPropertyValueSelfTest);
  });
}

@reflectiveTest
class GetDescriptionTest extends WidgetDescriptionBase {
  Future<void> test_documentation_fieldFormalParameter() async {
    await resolveTestCode('''
class MyWidget {
  /// my doc
  final int f;
  MyWidget(this.f);
}

void f() {
  MyWidget(0);
}
''');
    var property = await getWidgetProperty('MyWidget(0', 'f');
    expect(property.documentation, 'my doc');
  }

  Future<void> test_documentation_fieldFormalParameter_unresolvedField() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class MyWidget {
  MyWidget(this.f);
}

void f() {
  MyWidget(0);
}
''');
    var property = await getWidgetProperty('MyWidget(0', 'f');
    expect(property.documentation, isNull);
  }

  Future<void> test_kind_named_notSet() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = await getWidgetProperty('Text(', 'softWrap');
    expect(property.documentation, startsWith('Whether the text should'));
    assertPropertyJsonText(property, r'''
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

  Future<void> test_kind_named_set() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa', softWrap: true);
}
''');
    var property = await getWidgetProperty('Text(', 'softWrap');
    expect(property.documentation, startsWith('Whether the text should'));
    assertPropertyJsonText(property, r'''
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

  Future<void> test_kind_required() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = await getWidgetProperty('Text(', 'data');
    expect(property.documentation, startsWith('The text to display.'));
    assertPropertyJsonText(property, r'''
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

  Future<void> test_nested_notSet() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('');
}
''');
    var styleProperty = await getWidgetProperty('Text(', 'style');

    var fontSizeProperty = getNestedProperty(styleProperty, 'fontSize');
    assertPropertyJsonText(fontSizeProperty, r'''
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

  Future<void> test_nested_set() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('', style: TextStyle(fontSize: 24));
}
''');
    var styleProperty = await getWidgetProperty('Text(', 'style');

    var fontSizeProperty = getNestedProperty(styleProperty, 'fontSize');
    assertPropertyJsonText(fontSizeProperty, r'''
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

    var fontStyleProperty = getNestedProperty(styleProperty, 'fontStyle');
    assertPropertyJsonText(fontStyleProperty, r'''
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

  Future<void> test_notInstanceCreation() async {
    await resolveTestCode('''
void main() {
  42;
}
''');
    var description = await getDescription('42');
    expect(description, isNull);
  }

  Future<void> test_type_double() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = await getWidgetProperty('Text(', 'textScaleFactor');
    assertPropertyJsonText(property, r'''
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

  Future<void> test_type_enum() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('', overflow: TextOverflow.fade);
}
''');
    var property = await getWidgetProperty('Text(', 'overflow');

    expect(
      property.toJson()['editor']['enumItems'][0]['documentation'],
      startsWith('Clip the overflowing'),
    );

    assertPropertyJsonText(property, r'''
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

  Future<void> test_type_int() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = await getWidgetProperty('Text(', 'maxLines');
    assertPropertyJsonText(property, r'''
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

  Future<void> test_unresolvedInstanceCreation() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void main() {
  new Foo();
}
''');
    var description = await getDescription('Foo');
    expect(description, isNull);
  }
}

@reflectiveTest
class SetPropertyValueSelfTest extends WidgetDescriptionBase {
  Future<void> test_expression() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 1);
}
''');
    var property = await getWidgetProperty('Text(', 'maxLines');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(expression: '1 + 2'),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 1 + 2);
}
''');
  }

  Future<void> test_expression_formatError() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 1);
}
''');
    var property = await getWidgetProperty('Text(', 'maxLines');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(expression: 'foo <'),
    );

    expect(
      result.errorCode,
      protocol.RequestErrorCode
          .FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION,
    );
    expect(result.change, isNull);
  }

  Future<void> test_format_dontFormatOther() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void functionbefore() {
  1 +  2; // two spaces
}

void main() {
  Text('', );
}

void functionAfter() {
  1 +  2; // two spaces
}
''');
    var property = await getWidgetProperty('Text(', 'maxLines');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void functionbefore() {
  1 +  2; // two spaces
}

void main() {
  Text(
    '',
    maxLines: 42,
  );
}

void functionAfter() {
  1 +  2; // two spaces
}
''');
  }

  Future<void> test_invalidId() async {
    await resolveTestCode('');

    var result = await descriptions.setPropertyValue(42, null);

    expect(
      result.errorCode,
      protocol.RequestErrorCode.FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID,
    );
    expect(result.change, isNull);
  }

  Future<void> test_named_addValue_beforeChild() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  MyWidget<int>(
    child: Text(''),
  );
}

class MyWidget<T> {
  MyWidget({int xxx = 0, @required Widget child});
}
''');
    var property = await getWidgetProperty('MyWidget<int>', 'xxx');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  MyWidget<int>(
    xxx: 42,
    child: Text(''),
  );
}

class MyWidget<T> {
  MyWidget({int xxx = 0, @required Widget child});
}
''');
  }

  Future<void> test_named_addValue_beforeChildren() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  MyWidget<int>(
    children: [Text('')],
  );
}

class MyWidget<T> {
  MyWidget({int xxx = 0, @required List<Widget> children});
}
''');
    var property = await getWidgetProperty('MyWidget<int>', 'xxx');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  MyWidget<int>(
    xxx: 42,
    children: [Text('')],
  );
}

class MyWidget<T> {
  MyWidget({int xxx = 0, @required List<Widget> children});
}
''');
  }

  Future<void> test_named_addValue_hasComma() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('', );
}
''');
    var property = await getWidgetProperty('Text(', 'maxLines');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text(
    '',
    maxLines: 42,
  );
}
''');
  }

  Future<void> test_named_addValue_noComma() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('');
}
''');
    var property = await getWidgetProperty('Text(', 'maxLines');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text(
    '',
    maxLines: 42,
  );
}
''');
  }

  Future<void> test_named_addValue_sortedByName_first() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  MyWidget<int>(
    bbb: 2,
  );
}

class MyWidget<T> {
  MyWidget({int aaa = 0, int bbb = 0});
}
''');
    var property = await getWidgetProperty('MyWidget<int>', 'aaa');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  MyWidget<int>(
    aaa: 42,
    bbb: 2,
  );
}

class MyWidget<T> {
  MyWidget({int aaa = 0, int bbb = 0});
}
''');
  }

  Future<void> test_named_addValue_sortedByName_last() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  MyWidget<int>(
    aaa: 1,
  );
}

class MyWidget<T> {
  MyWidget({int aaa = 0, int bbb = 0});
}
''');
    var property = await getWidgetProperty('MyWidget<int>', 'bbb');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  MyWidget<int>(
    aaa: 1,
    bbb: 42,
  );
}

class MyWidget<T> {
  MyWidget({int aaa = 0, int bbb = 0});
}
''');
  }

  Future<void> test_named_addValue_sortedByName_middle() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  MyWidget<int>(
    aaa: 1,
    ccc: 3,
  );
}

class MyWidget<T> {
  MyWidget({int aaa = 0, int bbb = 0, int ccc = 0});
}
''');
    var property = await getWidgetProperty('MyWidget<int>', 'bbb');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  MyWidget<int>(
    aaa: 1,
    bbb: 42,
    ccc: 3,
  );
}

class MyWidget<T> {
  MyWidget({int aaa = 0, int bbb = 0, int ccc = 0});
}
''');
  }

  Future<void> test_named_changeValue() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 1);
}
''');
    var property = await getWidgetProperty('Text(', 'maxLines');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(intValue: 42),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 42);
}
''');
  }

  Future<void> test_named_removeValue_last() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 1,);
}
''');
    var property = await getWidgetProperty('Text(', 'maxLines');

    var result = await descriptions.setPropertyValue(property.id, null);

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', );
}
''');
  }

  Future<void> test_named_removeValue_notLast() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 1, softWrap: true,);
}
''');
    var property = await getWidgetProperty('Text(', 'maxLines');

    var result = await descriptions.setPropertyValue(property.id, null);

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', softWrap: true,);
}
''');
  }

  Future<void> test_nested_addValue() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('', style: TextStyle(), );
}
''');
    var styleProperty = await getWidgetProperty('Text(', 'style');

    var fontSizeProperty = getNestedProperty(styleProperty, 'fontSize');

    var result = await descriptions.setPropertyValue(
      fontSizeProperty.id,
      protocol.FlutterWidgetPropertyValue(doubleValue: 42),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text(
    '',
    style: TextStyle(
      fontSize: 42,
    ),
  );
}
''');
  }

  Future<void> test_nested_addValue_materialize() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('', );
}
''');
    var styleProperty = await getWidgetProperty('Text(', 'style');

    var fontSizeProperty = getNestedProperty(styleProperty, 'fontSize');

    var result = await descriptions.setPropertyValue(
      fontSizeProperty.id,
      protocol.FlutterWidgetPropertyValue(doubleValue: 42),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text(
    '',
    style: TextStyle(
      fontSize: 42,
    ),
  );
}
''');
  }

  Future<void> test_required_changeValue() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = await getWidgetProperty('Text(', 'data');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(stringValue: 'bbbb'),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text('bbbb');
}
''');
  }

  Future<void> test_required_removeValue() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');
    var property = await getWidgetProperty('Text(', 'data');

    var result = await descriptions.setPropertyValue(property.id, null);

    expect(
      result.errorCode,
      protocol.RequestErrorCode.FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED,
    );
    expect(result.change, isNull);
  }

  Future<void> test_type_enum_addValue() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Text('');
}
''');
    var property = await getWidgetProperty('Text(', 'overflow');

    var result = await descriptions.setPropertyValue(
      property.id,
      protocol.FlutterWidgetPropertyValue(
        enumValue: protocol.FlutterWidgetPropertyValueEnumItem(
          'package:flutter/src/rendering/paragraph.dart',
          'TextOverflow',
          'ellipsis',
        ),
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Text(
    '',
    overflow: TextOverflow.ellipsis,
  );
}
''');
  }
}
