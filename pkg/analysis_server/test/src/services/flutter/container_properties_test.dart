// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'constants.dart';
import 'widget_description.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContainerPropertiesTest);
  });
}

@reflectiveTest
class ContainerPropertiesTest extends WidgetDescriptionBase {
  test_alignment_read_hasAlign_notSimple() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Align(
    alignment: Alignment.centerRight,
    widthFactor: 2,
    child: Text(''),
  );
}
''');
    var property = await getWidgetProperty('Text(', 'Container');
    var alignmentProperty = getNestedProperty(property, 'alignment');
    expect(alignmentProperty.expression, isNull);
  }

  test_alignment_read_hasAlign_simple() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Align(
    alignment: Alignment.centerRight,
    child: Text(''),
  );
}
''');
    var property = await getWidgetProperty('Text(', 'Container');
    var alignmentProperty = getNestedProperty(property, 'alignment');
    assertPropertyJsonText(alignmentProperty, '''
{
  "expression": "Alignment.centerRight",
  "isRequired": false,
  "isSafeToUpdate": true,
  "name": "alignment",
  "children": [],
  $alignmentEditor,
  "value": {
    "enumValue": {
      "libraryUri": "package:flutter/src/painting/alignment.dart",
      "className": "Alignment",
      "name": "centerRight"
    }
  }
}
''');
  }

  test_alignment_read_hasContainer() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Container(
    child: Text(''),
    alignment: Alignment.centerRight,
  );
}
''');
    var property = await getWidgetProperty('Text(', 'Container');
    var alignmentProperty = getNestedProperty(property, 'alignment');
    assertPropertyJsonText(alignmentProperty, '''
{
  "expression": "Alignment.centerRight",
  "isRequired": false,
  "isSafeToUpdate": true,
  "name": "alignment",
  "children": [],
  $alignmentEditor,
  "value": {
    "enumValue": {
      "libraryUri": "package:flutter/src/painting/alignment.dart",
      "className": "Alignment",
      "name": "centerRight"
    }
  }
}
''');
  }

  test_alignment_read_hasContainer_directional() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Container(
    child: Text(''),
    alignment: AlignmentDirectional.centerStart,
  );
}
''');
    var property = await getWidgetProperty('Text(', 'Container');
    var alignmentProperty = getNestedProperty(property, 'alignment');
    assertPropertyJsonText(alignmentProperty, '''
{
  "expression": "AlignmentDirectional.centerStart",
  "isRequired": false,
  "isSafeToUpdate": true,
  "name": "alignment",
  "children": [],
  $alignmentEditor,
  "value": {
    "enumValue": {
      "libraryUri": "package:flutter/src/painting/alignment.dart",
      "className": "AlignmentDirectional",
      "name": "centerStart"
    }
  }
}
''');
  }

  test_alignment_write_hasAlign_change() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Align(
    alignment: Alignment.centerRight,
    child: Text(''),
  );
}
''');
    var alignmentProperty = await _alignmentProperty('Text(');

    var result = await descriptions.setPropertyValue(
      alignmentProperty.id,
      protocol.FlutterWidgetPropertyValue(
        enumValue: _alignmentValue('bottomLeft'),
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Align(
    alignment: Alignment.bottomLeft,
    child: Text(''),
  );
}
''');
  }

  test_alignment_write_hasAlign_remove() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Align(
    alignment: Alignment.centerRight,
    child: Text(''),
  );
}
''');
    var alignmentProperty = await _alignmentProperty('Text(');

    var result = await descriptions.setPropertyValue(
      alignmentProperty.id,
      null,
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Align(
    child: Text(''),
  );
}
''');
  }

  test_alignment_write_hasContainer_add() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Container(
    child: Text(''),
  );
}
''');
    var alignmentProperty = await _alignmentProperty('Text(');

    var result = await descriptions.setPropertyValue(
      alignmentProperty.id,
      protocol.FlutterWidgetPropertyValue(
        enumValue: _alignmentValue('bottomLeft'),
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Container(
    alignment: Alignment.bottomLeft,
    child: Text(''),
  );
}
''');
  }

  test_alignment_write_hasContainer_change() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Container(
    alignment: Alignment.centerRight,
    child: Text(''),
  );
}
''');
    var alignmentProperty = await _alignmentProperty('Text(');

    var result = await descriptions.setPropertyValue(
      alignmentProperty.id,
      protocol.FlutterWidgetPropertyValue(
        enumValue: _alignmentValue('bottomLeft'),
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Container(
    alignment: Alignment.bottomLeft,
    child: Text(''),
  );
}
''');
  }

  test_alignment_write_hasContainer_remove() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Container(
    alignment: Alignment.centerRight,
    child: Text(''),
  );
}
''');
    var alignmentProperty = await _alignmentProperty('Text(');

    var result = await descriptions.setPropertyValue(
      alignmentProperty.id,
      null,
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Container(
    child: Text(''),
  );
}
''');
  }

  test_alignment_write_noContainer_add() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Column(
    children: [
      Text(''),
    ],
  );
}
''');
    var alignmentProperty = await _alignmentProperty('Text(');

    var result = await descriptions.setPropertyValue(
      alignmentProperty.id,
      protocol.FlutterWidgetPropertyValue(
        enumValue: _alignmentValue('bottomLeft'),
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Column(
    children: [
      Container(
        alignment: Alignment.bottomLeft,
        child: Text(''),
      ),
    ],
  );
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
    var property = await getWidgetProperty('Text(', 'Container');
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

  test_container_virtual() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';

void main() {
  Column(
    children: [
      Text(''),
    ],
  );
}
''');
    var property = await getWidgetProperty('Text(', 'Container');
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

  Future<protocol.FlutterWidgetProperty> _alignmentProperty(
    String widgetSearch,
  ) async {
    var containerProperty = await getWidgetProperty(widgetSearch, 'Container');
    return getNestedProperty(containerProperty, 'alignment');
  }

  static protocol.FlutterWidgetPropertyValueEnumItem _alignmentValue(
    String name,
  ) {
    return protocol.FlutterWidgetPropertyValueEnumItem(
      'package:flutter/src/painting/alignment.dart',
      'Alignment',
      name,
    );
  }
}
