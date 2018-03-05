// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixesTest);
  });
}

@reflectiveTest
class FixesTest extends AbstractAnalysisTest {
  @override
  void setUp() {
    super.setUp();
    handler = new EditDomainHandler(server);
  }

  test_fixUndefinedClass() async {
    createProject();
    addTestFile('''
main() {
  Future<String> x = null;
}
''');
    await waitForTasksFinished();
    List<AnalysisErrorFixes> errorFixes = await _getFixesAt('Future<String>');
    expect(errorFixes, hasLength(1));
    AnalysisError error = errorFixes[0].error;
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
    List<SourceChange> fixes = errorFixes[0].fixes;
    expect(fixes, hasLength(2));
    expect(fixes[0].message, matches('Import library'));
    expect(fixes[1].message, matches('Create class'));
  }

  test_fromPlugins() async {
    PluginInfo info = new DiscoveredPluginInfo('a', 'b', 'c', null, null);
    plugin.AnalysisErrorFixes fixes = new plugin.AnalysisErrorFixes(
        new AnalysisError(AnalysisErrorSeverity.ERROR, AnalysisErrorType.HINT,
            new Location('', 0, 0, 0, 0), 'message', 'code'));
    plugin.EditGetFixesResult result =
        new plugin.EditGetFixesResult(<plugin.AnalysisErrorFixes>[fixes]);
    pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
      info: new Future.value(result.toResponse('-', 1))
    };

    createProject();
    addTestFile('main() {}');
    await waitForTasksFinished();
    List<AnalysisErrorFixes> errorFixes = await _getFixesAt('in(');
    expect(errorFixes, hasLength(1));
  }

  test_hasFixes() async {
    createProject();
    addTestFile('''
foo() {
  print(1)
}
bar() {
  print(10) print(20)
}
''');
    await waitForTasksFinished();
    // print(1)
    {
      List<AnalysisErrorFixes> errorFixes = await _getFixesAt('print(1)');
      expect(errorFixes, hasLength(1));
      _isSyntacticErrorWithSingleFix(errorFixes[0]);
    }
    // print(10)
    {
      List<AnalysisErrorFixes> errorFixes = await _getFixesAt('print(10)');
      expect(errorFixes, hasLength(2));
      _isSyntacticErrorWithSingleFix(errorFixes[0]);
      _isSyntacticErrorWithSingleFix(errorFixes[1]);
    }
  }

  test_overlayOnlyFile() async {
    createProject();
    testCode = '''
main() {
print(1)
}
''';
    _addOverlay(testFile, testCode);
    // ask for fixes
    await waitForTasksFinished();
    List<AnalysisErrorFixes> errorFixes = await _getFixesAt('print(1)');
    expect(errorFixes, hasLength(1));
    _isSyntacticErrorWithSingleFix(errorFixes[0]);
  }

  test_suggestImportFromDifferentAnalysisRoot() async {
    String asFileUri(String input) =>
        new Uri.file(convertPath(input)).toString();
    newFolder('/aaa');
    newFile('/aaa/.packages', content: '''
aaa:${asFileUri('/aaa/lib')}
bbb:${asFileUri('/bbb/lib')}
''');
    // Ensure that the target is analyzed as an implicit source.
    newFile('/aaa/lib/foo.dart', content: 'import "package:bbb/target.dart";');

    newFolder('/bbb');
    newFile('/bbb/lib/target.dart', content: 'class Foo() {}');

    handleSuccessfulRequest(
        new AnalysisSetAnalysisRootsParams(
            [convertPath('/aaa'), convertPath('/bbb')], []).toRequest('0'),
        handler: analysisHandler);

    // Configure the test file.
    testFile = resourceProvider.convertPath('/aaa/main.dart');
    testCode = 'main() { new Foo(); }';
    _addOverlay(testFile, testCode);

    await waitForTasksFinished();

    List<String> fixes = (await _getFixesAt('Foo()'))
        .single
        .fixes
        .map((f) => f.message)
        .toList();
    expect(fixes, contains("Import library 'package:bbb/target.dart'"));
  }

  void _addOverlay(String name, String contents) {
    Request request =
        new AnalysisUpdateContentParams({name: new AddContentOverlay(contents)})
            .toRequest('0');
    handleSuccessfulRequest(request, handler: analysisHandler);
  }

  Future<List<AnalysisErrorFixes>> _getFixes(int offset) async {
    Request request = new EditGetFixesParams(testFile, offset).toRequest('0');
    Response response = await waitResponse(request);
    var result = new EditGetFixesResult.fromResponse(response);
    return result.fixes;
  }

  Future<List<AnalysisErrorFixes>> _getFixesAt(String search) async {
    int offset = findOffset(search);
    return await _getFixes(offset);
  }

  void _isSyntacticErrorWithSingleFix(AnalysisErrorFixes fixes) {
    AnalysisError error = fixes.error;
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
    expect(fixes.fixes, hasLength(1));
  }
}
