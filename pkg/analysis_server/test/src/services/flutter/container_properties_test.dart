// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'constants.dart';
import 'widget_description.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContainerPropertiesTest);
    defineReflectiveTests(ContainerPropertyAlignmentTest);
    defineReflectiveTests(ContainerPropertyPaddingTest);
  });
}

@reflectiveTest
class ContainerPropertiesTest extends WidgetDescriptionBase {
  Future<void> test_container_existing() async {
    await resolveTestCode('''
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

  Future<void> test_container_virtual() async {
    await resolveTestCode('''
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
}

@reflectiveTest
class ContainerPropertyAlignmentTest extends WidgetDescriptionBase {
  Future<void> test_read_hasAlign_notSimple() async {
    await resolveTestCode('''
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

  Future<void> test_read_hasAlign_simple() async {
    await resolveTestCode('''
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

  Future<void> test_read_hasContainer() async {
    await resolveTestCode('''
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

  Future<void> test_read_hasContainer_directional() async {
    await resolveTestCode('''
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

  Future<void> test_write_hasAlign_change() async {
    await resolveTestCode('''
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

  Future<void> test_write_hasAlign_remove() async {
    await resolveTestCode('''
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

  Future<void> test_write_hasContainer_add() async {
    await resolveTestCode('''
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

  Future<void> test_write_hasContainer_change() async {
    await resolveTestCode('''
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

  Future<void> test_write_hasContainer_remove() async {
    await resolveTestCode('''
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

  Future<void> test_write_hasPadding_add() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Padding(
    padding: EdgeInsets.only(left: 1, right: 3),
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
    padding: EdgeInsets.only(left: 1, right: 3),
    child: Text(''),
  );
}
''');
  }

  Future<void> test_write_noContainer_add() async {
    await resolveTestCode('''
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

@reflectiveTest
class ContainerPropertyPaddingTest extends WidgetDescriptionBase {
  Future<void> test_read_hasContainer_all() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.all(4),
    child: Text(''),
  );
}
''');
    var property = await getWidgetProperty('Text(', 'Container');
    var paddingProperty = getNestedProperty(property, 'padding');

    assertPropertyJsonText(paddingProperty, '''
{
  "expression": "EdgeInsets.all(4)",
  "isRequired": false,
  "isSafeToUpdate": false,
  "name": "padding",
  "children": [
    {
      "expression": "4",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "left",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 4.0
      }
    },
    {
      "expression": "4",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "top",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 4.0
      }
    },
    {
      "expression": "4",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "right",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 4.0
      }
    },
    {
      "expression": "4",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "bottom",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 4.0
      }
    }
  ]
}
''');
  }

  Future<void> test_read_hasContainer_fromLTRB() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.fromLTRB(1, 2, 3, 4),
    child: Text(''),
  );
}
''');
    var property = await getWidgetProperty('Text(', 'Container');
    var paddingProperty = getNestedProperty(property, 'padding');

    assertPropertyJsonText(paddingProperty, '''
{
  "expression": "EdgeInsets.fromLTRB(1, 2, 3, 4)",
  "isRequired": false,
  "isSafeToUpdate": false,
  "name": "padding",
  "children": [
    {
      "expression": "1",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "left",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 1.0
      }
    },
    {
      "expression": "2",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "top",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 2.0
      }
    },
    {
      "expression": "3",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "right",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 3.0
      }
    },
    {
      "expression": "4",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "bottom",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 4.0
      }
    }
  ]
}
''');
  }

  Future<void> test_read_hasContainer_only() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.only(left: 1, right: 3),
    child: Text(''),
  );
}
''');
    var property = await getWidgetProperty('Text(', 'Container');
    var paddingProperty = getNestedProperty(property, 'padding');

    assertPropertyJsonText(paddingProperty, '''
{
  "expression": "EdgeInsets.only(left: 1, right: 3)",
  "isRequired": false,
  "isSafeToUpdate": false,
  "name": "padding",
  "children": [
    {
      "expression": "1",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "left",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 1.0
      }
    },
    {
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "top",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      }
    },
    {
      "expression": "3",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "right",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 3.0
      }
    },
    {
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "bottom",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      }
    }
  ]
}
''');
  }

  Future<void> test_read_hasContainer_symmetric() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
    child: Text(''),
  );
}
''');
    var property = await getWidgetProperty('Text(', 'Container');
    var paddingProperty = getNestedProperty(property, 'padding');

    assertPropertyJsonText(paddingProperty, '''
{
  "expression": "EdgeInsets.symmetric(horizontal: 2, vertical: 4)",
  "isRequired": false,
  "isSafeToUpdate": false,
  "name": "padding",
  "children": [
    {
      "expression": "2",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "left",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 2.0
      }
    },
    {
      "expression": "4",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "top",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 4.0
      }
    },
    {
      "expression": "2",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "right",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 2.0
      }
    },
    {
      "expression": "4",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "bottom",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 4.0
      }
    }
  ]
}
''');
  }

  Future<void> test_read_hasPadding_only() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Padding(
    padding: EdgeInsets.only(left: 1, right: 3),
    child: Text(''),
  );
}
''');
    var property = await getWidgetProperty('Text(', 'Container');
    var paddingProperty = getNestedProperty(property, 'padding');

    assertPropertyJsonText(paddingProperty, '''
{
  "expression": "EdgeInsets.only(left: 1, right: 3)",
  "isRequired": false,
  "isSafeToUpdate": false,
  "name": "padding",
  "children": [
    {
      "expression": "1",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "left",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 1.0
      }
    },
    {
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "top",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      }
    },
    {
      "expression": "3",
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "right",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      },
      "value": {
        "doubleValue": 3.0
      }
    },
    {
      "isRequired": true,
      "isSafeToUpdate": true,
      "name": "bottom",
      "children": [],
      "editor": {
        "kind": "DOUBLE"
      }
    }
  ]
}
''');
  }

  Future<void> test_write_hasAlign_add_only() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Align(
    alignment: Alignment.centerRight,
    child: Text(''),
  );
}
''');
    var paddingProperty = await _paddingProperty('Text(');
    var leftProperty = getNestedProperty(paddingProperty, 'left');

    var result = await descriptions.setPropertyValue(
      leftProperty.id,
      protocol.FlutterWidgetPropertyValue(
        doubleValue: 1,
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Container(
    alignment: Alignment.centerRight,
    padding: EdgeInsets.only(left: 1),
    child: Text(''),
  );
}
''');
  }

  Future<void> test_write_hasContainer_add_only() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Container(
    child: Text(''),
  );
}
''');
    var paddingProperty = await _paddingProperty('Text(');
    var leftProperty = getNestedProperty(paddingProperty, 'left');

    var result = await descriptions.setPropertyValue(
      leftProperty.id,
      protocol.FlutterWidgetPropertyValue(
        doubleValue: 1,
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.only(left: 1),
    child: Text(''),
  );
}
''');
  }

  Future<void> test_write_hasContainer_change_all() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.only(left: 1, top: 2, right: 1, bottom: 1),
    child: Text(''),
  );
}
''');
    var paddingProperty = await _paddingProperty('Text(');
    var topProperty = getNestedProperty(paddingProperty, 'top');

    var result = await descriptions.setPropertyValue(
      topProperty.id,
      protocol.FlutterWidgetPropertyValue(
        doubleValue: 1,
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.all(1),
    child: Text(''),
  );
}
''');
  }

  Future<void> test_write_hasContainer_change_only() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.only(left: 1, right: 3),
    child: Text(''),
  );
}
''');
    var paddingProperty = await _paddingProperty('Text(');
    var leftProperty = getNestedProperty(paddingProperty, 'left');

    var result = await descriptions.setPropertyValue(
      leftProperty.id,
      protocol.FlutterWidgetPropertyValue(
        doubleValue: 11,
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.only(left: 11, right: 3),
    child: Text(''),
  );
}
''');
  }

  Future<void> test_write_hasContainer_change_remove() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.only(left: 1),
    child: Text(''),
  );
}
''');
    var paddingProperty = await _paddingProperty('Text(');
    var topProperty = getNestedProperty(paddingProperty, 'left');

    var result = await descriptions.setPropertyValue(
      topProperty.id,
      protocol.FlutterWidgetPropertyValue(
        doubleValue: 0,
      ),
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

  Future<void> test_write_hasContainer_change_symmetric_both() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.only(left: 1, top: 2, right: 1, bottom: 4),
    child: Text(''),
  );
}
''');
    var paddingProperty = await _paddingProperty('Text(');
    var topProperty = getNestedProperty(paddingProperty, 'top');

    var result = await descriptions.setPropertyValue(
      topProperty.id,
      protocol.FlutterWidgetPropertyValue(
        doubleValue: 4,
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.symmetric(horizontal: 1, vertical: 4),
    child: Text(''),
  );
}
''');
  }

  Future<void> test_write_hasContainer_change_symmetric_horizontal() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.only(left: 1, right: 3),
    child: Text(''),
  );
}
''');
    var paddingProperty = await _paddingProperty('Text(');
    var leftProperty = getNestedProperty(paddingProperty, 'left');

    var result = await descriptions.setPropertyValue(
      leftProperty.id,
      protocol.FlutterWidgetPropertyValue(
        doubleValue: 3,
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.symmetric(horizontal: 3),
    child: Text(''),
  );
}
''');
  }

  Future<void> test_write_hasContainer_change_symmetric_vertical() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.only(top: 2, bottom: 4),
    child: Text(''),
  );
}
''');
    var paddingProperty = await _paddingProperty('Text(');
    var topProperty = getNestedProperty(paddingProperty, 'top');

    var result = await descriptions.setPropertyValue(
      topProperty.id,
      protocol.FlutterWidgetPropertyValue(
        doubleValue: 4,
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Container(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Text(''),
  );
}
''');
  }

  Future<void> test_write_hasPadding_change_only() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Padding(
    padding: EdgeInsets.only(left: 1, right: 3),
    child: Text(''),
  );
}
''');
    var paddingProperty = await _paddingProperty('Text(');
    var leftProperty = getNestedProperty(paddingProperty, 'left');

    var result = await descriptions.setPropertyValue(
      leftProperty.id,
      protocol.FlutterWidgetPropertyValue(
        doubleValue: 11,
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Padding(
    padding: EdgeInsets.only(left: 11, right: 3),
    child: Text(''),
  );
}
''');
  }

  Future<void> test_write_noContainer_add_only() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void main() {
  Column(
    children: [
      Text(''),
    ],
  );
}
''');
    var paddingProperty = await _paddingProperty('Text(');
    var leftProperty = getNestedProperty(paddingProperty, 'left');

    var result = await descriptions.setPropertyValue(
      leftProperty.id,
      protocol.FlutterWidgetPropertyValue(
        doubleValue: 1,
      ),
    );

    assertExpectedChange(result, r'''
import 'package:flutter/material.dart';

void main() {
  Column(
    children: [
      Container(
        padding: EdgeInsets.only(left: 1),
        child: Text(''),
      ),
    ],
  );
}
''');
  }

  Future<protocol.FlutterWidgetProperty> _paddingProperty(
    String widgetSearch,
  ) async {
    var containerProperty = await getWidgetProperty(widgetSearch, 'Container');
    return getNestedProperty(containerProperty, 'padding');
  }
}
