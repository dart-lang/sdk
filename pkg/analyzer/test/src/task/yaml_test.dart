// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.yaml_test;

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/yaml.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/yaml.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../context/abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParseYamlTaskTest);
  });
}

isInstanceOf isParseYamlTask = new isInstanceOf<ParseYamlTask>();

@reflectiveTest
class ParseYamlTaskTest extends AbstractContextTest {
  Source source;

  test_perform() {
    _performParseTask(r'''
rules:
  style_guide:
    camel_case_types: false
''');
    expect(outputs, hasLength(3));
    YamlDocument document = outputs[YAML_DOCUMENT];
    expect(document, isNotNull);
    var value = document.contents.value;
    expect(value, new isInstanceOf<Map>());
    expect(value['rules']['style_guide']['camel_case_types'], isFalse);
    expect(outputs[YAML_ERRORS], hasLength(0));
    LineInfo lineInfo = outputs[LINE_INFO];
    expect(lineInfo, isNotNull);
    expect(lineInfo.getOffsetOfLine(0), 0);
    expect(lineInfo.getOffsetOfLine(1), 7);
    expect(lineInfo.getOffsetOfLine(2), 22);
    expect(lineInfo.getOffsetOfLine(3), 50);
  }

  test_perform_doesNotExist() {
    _performParseTask(null);
    expect(outputs, hasLength(3));
    YamlDocument document = outputs[YAML_DOCUMENT];
    expect(document, isNotNull);
    expect(document.contents.value, isNull);
    expect(outputs[YAML_ERRORS], hasLength(1));
    LineInfo lineInfo = outputs[LINE_INFO];
    expect(lineInfo, isNotNull);
    expect(lineInfo.getOffsetOfLine(0), 0);
  }

  void _performParseTask(String content) {
    if (content == null) {
      source = resourceProvider.getFile('/test.yaml').createSource();
    } else {
      source = newSource('/test.yaml', content);
    }
    computeResult(source, YAML_DOCUMENT, matcher: isParseYamlTask);
  }
}
