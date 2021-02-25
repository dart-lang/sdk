// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/flutter/widget_descriptions.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';

@reflectiveTest
class WidgetDescriptionBase extends AbstractSingleUnitTest {
  final descriptions = WidgetDescriptions();

  void assertExpectedChange(SetPropertyValueResult result, String expected) {
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

  void assertPropertyJsonText(
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

  Future<protocol.FlutterGetWidgetDescriptionResult> getDescription(
      String search) async {
    var content = testAnalysisResult.content;

    var offset = content.indexOf(search);
    if (offset == -1) {
      fail('Not found: $search');
    }

    if (content.contains(search, offset + search.length)) {
      fail('More than one: $search');
    }

    return descriptions.getDescription(testAnalysisResult, offset);
  }

  protocol.FlutterWidgetProperty getNestedProperty(
      protocol.FlutterWidgetProperty parentProperty, String name) {
    var nestedProperties = parentProperty.children;
    return nestedProperties.singleWhere(
      (property) => property.name == name,
    );
  }

  Future<protocol.FlutterWidgetProperty> getWidgetProperty(
      String widgetSearch, String name) async {
    var widgetDescription = await getDescription(widgetSearch);
    expect(widgetDescription, isNotNull);

    var properties = widgetDescription.properties;
    return properties.singleWhere(
      (property) => property.name == name,
    );
  }

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  void _removeNotInterestingElements(Map<String, dynamic> json) {
    json.remove('documentation');

    var id = json.remove('id') as int;
    expect(id, isNotNull);

    Object editor = json['editor'];
    if (editor is Map<String, dynamic>) {
      if (editor['kind'] == 'ENUM' || editor['kind'] == 'ENUM_LIKE') {
        Object items = editor['enumItems'];
        if (items is List<Map<String, dynamic>>) {
          for (var item in items) {
            item.remove('documentation');
          }
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

    Object children = json['children'];
    if (children is List<Map<String, dynamic>>) {
      children.forEach(_removeNotInterestingElements);
    }
  }
}
