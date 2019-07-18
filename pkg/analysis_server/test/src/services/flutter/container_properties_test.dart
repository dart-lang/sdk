// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'widget_description.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContainerPropertiesTest);
  });
}

@reflectiveTest
class ContainerPropertiesTest extends WidgetDescriptionBase {
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
    var property = await getWidgetProperty('Text(', 'Container');
    var alignmentProperty = getNestedProperty(property, 'alignment');
    // TODO(scheglov) Value, editor.
    assertPropertyJsonText(alignmentProperty, r'''
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
