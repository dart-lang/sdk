// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.html_test;

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/html.dart';
import 'package:analyzer/task/model.dart';
import 'package:html/dom.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context/abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartScriptsTaskTest);
    defineReflectiveTests(HtmlErrorsTaskTest);
    defineReflectiveTests(ParseHtmlTaskTest);
  });
}

isInstanceOf isDartScriptsTask = new isInstanceOf<DartScriptsTask>();
isInstanceOf isHtmlErrorsTask = new isInstanceOf<HtmlErrorsTask>();
isInstanceOf isParseHtmlTask = new isInstanceOf<ParseHtmlTask>();

@reflectiveTest
class DartScriptsTaskTest extends AbstractContextTest {
  test_buildInputs() {
    Source source = newSource('/test.html');
    Map<String, TaskInput> inputs = DartScriptsTask.buildInputs(source);
    expect(inputs, isNotNull);
    expect(inputs.keys, unorderedEquals([DartScriptsTask.DOCUMENT_INPUT]));
  }

  test_constructor() {
    Source source = newSource('/test.html');
    DartScriptsTask task = new DartScriptsTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_createTask() {
    Source source = newSource('/test.html');
    DartScriptsTask task = DartScriptsTask.createTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_description() {
    Source source = newSource('/test.html');
    DartScriptsTask task = new DartScriptsTask(null, source);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = DartScriptsTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  void test_perform_embedded_source() {
    String content = r'''
    void buttonPressed() {}
  ''';
    AnalysisTarget target = newSource(
        '/test.html',
        '''
<!DOCTYPE html>
<html>
<head>
  <script type='application/dart'>$content</script>
</head>
<body>
</body>
</html>''');
    computeResult(target, REFERENCED_LIBRARIES, matcher: isDartScriptsTask);
    expect(outputs[REFERENCED_LIBRARIES], hasLength(0));
    expect(outputs[DART_SCRIPTS], hasLength(1));
    DartScript script = outputs[DART_SCRIPTS][0];
    expect(script.fragments, hasLength(1));
    ScriptFragment fragment = script.fragments[0];
    expect(fragment.content, content);
  }

  void test_perform_empty_source_reference() {
    AnalysisTarget target = newSource(
        '/test.html',
        r'''
<!DOCTYPE html>
<html>
<head>
  <script type='application/dart' src=''/>
</head>
<body>
</body>
</html>''');
    computeResult(target, REFERENCED_LIBRARIES, matcher: isDartScriptsTask);
    expect(outputs[REFERENCED_LIBRARIES], hasLength(0));
    expect(outputs[DART_SCRIPTS], hasLength(0));
  }

  void test_perform_invalid_source_reference() {
    AnalysisTarget target = newSource(
        '/test.html',
        r'''
<!DOCTYPE html>
<html>
<head>
  <script type='application/dart' src='an;invalid:[]uri'/>
</head>
<body>
</body>
</html>''');
    computeResult(target, REFERENCED_LIBRARIES, matcher: isDartScriptsTask);
    expect(outputs[REFERENCED_LIBRARIES], hasLength(0));
    expect(outputs[DART_SCRIPTS], hasLength(0));
  }

  void test_perform_non_existing_source_reference() {
    AnalysisTarget target = newSource(
        '/test.html',
        r'''
<!DOCTYPE html>
<html>
<head>
  <script type='application/dart' src='does/not/exist.dart'/>
</head>
<body>
</body>
</html>''');
    computeResult(target, REFERENCED_LIBRARIES, matcher: isDartScriptsTask);
    expect(outputs[REFERENCED_LIBRARIES], hasLength(1));
    expect(outputs[DART_SCRIPTS], hasLength(0));
  }

  test_perform_none() {
    AnalysisTarget target = newSource(
        '/test.html',
        r'''
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
    computeResult(target, REFERENCED_LIBRARIES, matcher: isDartScriptsTask);
    expect(outputs[REFERENCED_LIBRARIES], hasLength(0));
    expect(outputs[DART_SCRIPTS], hasLength(0));
  }

  void test_perform_referenced_source() {
    AnalysisTarget target = newSource(
        '/test.html',
        r'''
<!DOCTYPE html>
<html>
<head>
  <script type='application/dart' src='test.dart'/>
</head>
<body>
</body>
</html>''');
    computeResult(target, REFERENCED_LIBRARIES, matcher: isDartScriptsTask);
    expect(outputs[REFERENCED_LIBRARIES], hasLength(1));
    expect(outputs[DART_SCRIPTS], hasLength(0));
  }
}

@reflectiveTest
class HtmlErrorsTaskTest extends AbstractContextTest {
  fail_perform_htmlErrors() {
    AnalysisTarget target = newSource(
        '/test.html',
        r'''
<html>
  <head>
    <title>test page</not-title>
  </head>
  <body>
    Test
  </body>
</html>
''');
    computeResult(target, HTML_ERRORS, matcher: isHtmlErrorsTask);
    expect(outputs[HTML_ERRORS], hasLength(1));
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

  test_perform_dartErrors() {
    AnalysisTarget target = newSource(
        '/test.html',
        r'''
<!DOCTYPE html>
<html>
  <head>
    <title>test page</title>
    <script type='application/dart'>
      void buttonPressed() {
    </script>
  </head>
  <body>Test</body>
</html>
''');
    computeResult(target, HTML_ERRORS, matcher: isHtmlErrorsTask);
    expect(outputs[HTML_ERRORS], hasLength(1));
  }

  test_perform_noErrors() {
    AnalysisTarget target = newSource(
        '/test.html',
        r'''
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
    computeResult(target, HTML_ERRORS, matcher: isHtmlErrorsTask);
    expect(outputs[HTML_ERRORS], isEmpty);
  }
}

@reflectiveTest
class ParseHtmlTaskTest extends AbstractContextTest {
  test_buildInputs() {
    Source source = newSource('/test.html');
    Map<String, TaskInput> inputs = ParseHtmlTask.buildInputs(source);
    expect(inputs, isNotNull);
    expect(
        inputs.keys,
        unorderedEquals([
          ParseHtmlTask.CONTENT_INPUT_NAME,
          ParseHtmlTask.MODIFICATION_TIME_INPUT
        ]));
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
    String code = r'''
<!DOCTYPE html>
<html>
  <head>
    <title>test page</title>
  </head>
  <body>
    <h1 myAttr='my value'>Test</h1>
  </body>
</html>
''';
    AnalysisTarget target = newSource('/test.html', code);
    computeResult(target, HTML_DOCUMENT);
    expect(task, isParseHtmlTask);
    expect(outputs[HTML_DOCUMENT_ERRORS], isEmpty);
    // HTML_DOCUMENT
    {
      Document document = outputs[HTML_DOCUMENT];
      expect(document, isNotNull);
      // verify that attributes are not lower-cased
      Element element = document.body.getElementsByTagName('h1').single;
      expect(element.attributes['myAttr'], 'my value');
    }
    // LINE_INFO
    {
      LineInfo lineInfo = outputs[LINE_INFO];
      expect(lineInfo, isNotNull);
      {
        int offset = code.indexOf('<!DOCTYPE');
        LineInfo_Location location = lineInfo.getLocation(offset);
        expect(location.lineNumber, 1);
        expect(location.columnNumber, 1);
      }
      {
        int offset = code.indexOf('<html>');
        LineInfo_Location location = lineInfo.getLocation(offset);
        expect(location.lineNumber, 2);
        expect(location.columnNumber, 1);
      }
      {
        int offset = code.indexOf('<title>');
        LineInfo_Location location = lineInfo.getLocation(offset);
        expect(location.lineNumber, 4);
        expect(location.columnNumber, 5);
      }
    }
  }

  test_perform_noDocType() {
    String code = r'''
<div>AAA</div>
<span>BBB</span>
''';
    AnalysisTarget target = newSource('/test.html', code);
    computeResult(target, HTML_DOCUMENT);
    expect(task, isParseHtmlTask);
    // validate Document
    {
      Document document = outputs[HTML_DOCUMENT];
      expect(document, isNotNull);
      // artificial <html>
      expect(document.nodes, hasLength(1));
      Element htmlElement = document.nodes[0];
      expect(htmlElement.localName, 'html');
      // artificial <body>
      expect(htmlElement.nodes, hasLength(2));
      Element bodyElement = htmlElement.nodes[1];
      expect(bodyElement.localName, 'body');
      // actual nodes
      expect(bodyElement.nodes, hasLength(4));
      expect((bodyElement.nodes[0] as Element).localName, 'div');
      expect((bodyElement.nodes[2] as Element).localName, 'span');
    }
    // it's OK to don't have DOCTYPE
    expect(outputs[HTML_DOCUMENT_ERRORS], isEmpty);
  }
}
