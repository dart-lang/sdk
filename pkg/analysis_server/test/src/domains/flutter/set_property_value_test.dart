// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetPropertyValueTest);
  });
}

@reflectiveTest
class SetPropertyValueTest extends FlutterBase {
  Future<void> test_named_add() async {
    addTestFile(r'''
import 'package:flutter/material.dart';

void main() {
  Text('');
}
''');

    var widgetDesc = await getWidgetDescription('Text(');
    var property = getProperty(widgetDesc, 'maxLines');

    var result = await _setValue(
      property,
      FlutterWidgetPropertyValue(intValue: 42),
    );

    _assertTestFileChange(result.change, r'''
import 'package:flutter/material.dart';

void main() {
  Text(
    '',
    maxLines: 42,
  );
}
''');
  }

  Future<void> test_named_change() async {
    addTestFile(r'''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 1);
}
''');

    var widgetDesc = await getWidgetDescription('Text(');
    var property = getProperty(widgetDesc, 'maxLines');

    var result = await _setValue(
      property,
      FlutterWidgetPropertyValue(intValue: 42),
    );

    _assertTestFileChange(result.change, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 42);
}
''');
  }

  Future<void> test_named_remove() async {
    addTestFile(r'''
import 'package:flutter/material.dart';

void main() {
  Text('', maxLines: 1);
}
''');

    var widgetDesc = await getWidgetDescription('Text(');
    var property = getProperty(widgetDesc, 'maxLines');

    var result = await _setValue(property, null);

    _assertTestFileChange(result.change, r'''
import 'package:flutter/material.dart';

void main() {
  Text('', );
}
''');
  }

  Future<void> test_required_change() async {
    addTestFile(r'''
import 'package:flutter/material.dart';

void main() {
  Text('aaa');
}
''');

    var widgetDesc = await getWidgetDescription('Text(');
    var property = getProperty(widgetDesc, 'data');

    var result = await _setValue(
      property,
      FlutterWidgetPropertyValue(stringValue: 'bbb'),
    );

    _assertTestFileChange(result.change, r'''
import 'package:flutter/material.dart';

void main() {
  Text('bbb');
}
''');
  }

  void _assertTestFileChange(SourceChange change, String expected) {
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    var fileEdit = fileEdits[0];
    expect(fileEdit.file, testFile);

    var edits = fileEdit.edits;
    expect(SourceEdit.applySequence(testCode, edits), expected);
  }

  Future<FlutterSetWidgetPropertyValueResult> _setValue(
    FlutterWidgetProperty property,
    FlutterWidgetPropertyValue value,
  ) async {
    var response = await _setValueResponse(property, value);
    expect(response.error, isNull);
    return FlutterSetWidgetPropertyValueResult.fromResponse(response);
  }

  Future<Response> _setValueResponse(
    FlutterWidgetProperty property,
    FlutterWidgetPropertyValue value,
  ) async {
    var request = FlutterSetWidgetPropertyValueParams(
      property.id,
      value: value,
    ).toRequest('0');
    return await waitResponse(request);
  }
}
