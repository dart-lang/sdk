// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.html_test;

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/task/html.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../context/abstract_context.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(HtmlErrorsTaskTest);
  runReflectiveTests(ParseHtmlTaskTest);
  runReflectiveTests(ReferencedLibrariesTaskTest);
}

@reflectiveTest
class HtmlErrorsTaskTest extends AbstractContextTest {
  test_buildInputs() {
    Source source = newSource('/test.html');
    Map<String, TaskInput> inputs = HtmlErrorsTask.buildInputs(source);
    expect(inputs, isNotNull);
    expect(
        inputs.keys, unorderedEquals([HtmlErrorsTask.DOCUMENT_ERRORS_INPUT]));
  }

  test_constructor() {
    Source source = newSource('/test.html');
    HtmlErrorsTask task = new HtmlErrorsTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_createTask() {
    Source source = newSource('/test.html');
    HtmlErrorsTask task = HtmlErrorsTask.createTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_description() {
    Source source = newSource('/test.html');
    HtmlErrorsTask task = new HtmlErrorsTask(null, source);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = HtmlErrorsTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform() {
    AnalysisTarget target = newSource('/test.html', r'''
<!DOCTYPE html>
<html>
  <head>
    <title>test page</title>
  </head>
  <body>
    Test
  </body>
</html>
''');
    computeResult(target, HTML_ERRORS);
    expect(task, new isInstanceOf<HtmlErrorsTask>());
    expect(outputs[HTML_ERRORS], isEmpty);
  }
}

@reflectiveTest
class ParseHtmlTaskTest extends AbstractContextTest {
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

  test_perform() {
    AnalysisTarget target = newSource('/test.html', r'''
<!DOCTYPE html>
<html>
  <head>
    <title>test page</title>
  </head>
  <body>
    <h1 Test>
  </body>
</html>
''');
    computeResult(target, HTML_DOCUMENT);
    expect(task, new isInstanceOf<ParseHtmlTask>());
    expect(outputs[HTML_DOCUMENT], isNotNull);
    expect(outputs[HTML_DOCUMENT_ERRORS], isNotEmpty);
  }
}

@reflectiveTest
class ReferencedLibrariesTaskTest extends AbstractContextTest {
  test_buildInputs() {
    Source source = newSource('/test.html');
    Map<String, TaskInput> inputs = ReferencedLibrariesTask.buildInputs(source);
    expect(inputs, isNotNull);
    expect(
        inputs.keys, unorderedEquals([ReferencedLibrariesTask.DOCUMENT_INPUT]));
  }

  test_constructor() {
    Source source = newSource('/test.html');
    ReferencedLibrariesTask task = new ReferencedLibrariesTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_createTask() {
    Source source = newSource('/test.html');
    ReferencedLibrariesTask task =
        ReferencedLibrariesTask.createTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_description() {
    Source source = newSource('/test.html');
    ReferencedLibrariesTask task = new ReferencedLibrariesTask(null, source);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = ReferencedLibrariesTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  void test_perform_embedded_source() {
    AnalysisTarget target = newSource('/test.html', r'''
<!DOCTYPE html>
<html>
<head>
  <script type='application/dart'>
    void buttonPressed() {}
  </script>
</head>
<body>
</body>
</html>''');
    computeResult(target, REFERENCED_LIBRARIES);
    expect(task, new isInstanceOf<ReferencedLibrariesTask>());
    expect(outputs[REFERENCED_LIBRARIES], hasLength(0));
  }

  void test_perform_empty_source_reference() {
    AnalysisTarget target = newSource('/test.html', r'''
<!DOCTYPE html>
<html>
<head>
  <script type='application/dart' src=''/>
</head>
<body>
</body>
</html>''');
    computeResult(target, REFERENCED_LIBRARIES);
    expect(task, new isInstanceOf<ReferencedLibrariesTask>());
    expect(outputs[REFERENCED_LIBRARIES], hasLength(0));
  }

  void test_perform_invalid_source_reference() {
    AnalysisTarget target = newSource('/test.html', r'''
<!DOCTYPE html>
<html>
<head>
  <script type='application/dart' src='an;invalid:[]uri'/>
</head>
<body>
</body>
</html>''');
    computeResult(target, REFERENCED_LIBRARIES);
    expect(task, new isInstanceOf<ReferencedLibrariesTask>());
    expect(outputs[REFERENCED_LIBRARIES], hasLength(0));
  }

  void test_perform_non_existing_source_reference() {
    AnalysisTarget target = newSource('/test.html', r'''
<!DOCTYPE html>
<html>
<head>
  <script type='application/dart' src='does/not/exist.dart'/>
</head>
<body>
</body>
</html>''');
    computeResult(target, REFERENCED_LIBRARIES);
    expect(task, new isInstanceOf<ReferencedLibrariesTask>());
    expect(outputs[REFERENCED_LIBRARIES], hasLength(1));
  }

  test_perform_none() {
    AnalysisTarget target = newSource('/test.html', r'''
<!DOCTYPE html>
<html>
  <head>
    <title>test page</title>
  </head>
  <body>
    Test
  </body>
</html>
''');
    computeResult(target, REFERENCED_LIBRARIES);
    expect(task, new isInstanceOf<ReferencedLibrariesTask>());
    expect(outputs[REFERENCED_LIBRARIES], isEmpty);
  }

  void test_perform_referenced_source() {
    AnalysisTarget target = newSource('/test.html', r'''
<!DOCTYPE html>
<html>
<head>
  <script type='application/dart' src='test.dart'/>
</head>
<body>
</body>
</html>''');
    computeResult(target, REFERENCED_LIBRARIES);
    expect(task, new isInstanceOf<ReferencedLibrariesTask>());
    expect(outputs[REFERENCED_LIBRARIES], hasLength(1));
  }
}
