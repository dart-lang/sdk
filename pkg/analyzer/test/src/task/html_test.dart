// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.html_test;

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../context/abstract_context.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ParseHtmlTaskTest);
}

@reflectiveTest
class ParseHtmlTaskTest extends AbstractContextTest {
  fail_perform() {
    fail('Could not parse the HTML');
//    AnalysisTarget target = newSource('/test.html', r'''
//<html>
//  <head>
//    <title 'test page'/>
//  </head>
//  <body>
//    Test
//  </body>
//</html>
//''');
//    computeResult(target, DOCUMENT);
//    expect(task, new isInstanceOf<ParseHtmlTask>());
//    expect(outputs[DOCUMENT], isNotNull);
//    expect(outputs[DOCUMENT_ERRORS], isNotEmpty);
  }

  test_buildInputs() {
    Source source = newSource('/test.html');
    Map<String, TaskInput> inputs = ParseHtmlTask.buildInputs(source);
    expect(inputs, isNotNull);
    expect(inputs.keys, unorderedEquals([ParseHtmlTask.CONTENT_INPUT_NAME]));
  }

  test_constructor() {
    Source source = newSource('/test.html');
    ParseHtmlTask task = new ParseHtmlTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_createTask() {
    Source source = newSource('/test.html');
    ParseHtmlTask task = ParseHtmlTask.createTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_description() {
    Source source = newSource('/test.html');
    ParseHtmlTask task = new ParseHtmlTask(null, source);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = ParseHtmlTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }
}
