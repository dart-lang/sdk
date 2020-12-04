// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixesTest);
  });
}

@reflectiveTest
class FixesTest extends AbstractAnalysisTest {
  @override
  void setUp() {
    super.setUp();
    handler = EditDomainHandler(server);
  }

  Future<void> test_fileOutsideRoot() async {
    final outsideFile = '/foo/test.dart';
    newFile(outsideFile, content: 'bad code to create error');

    // Set up the original project, as the code fix code won't run at all
    // if there are no contexts.
    createProject();
    await waitForTasksFinished();

    var request =
        EditGetFixesParams(convertPath(outsideFile), 0).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.GET_FIXES_INVALID_FILE),
    );
  }

  Future<void> test_fixUndefinedClass() async {
    createProject();
    addTestFile('''
main() {
  Completer<String> x = null;
  print(x);
}
''');
    await waitForTasksFinished();
    doAllDeclarationsTrackerWork();
    var errorFixes = await _getFixesAt('Completer<String>');
    expect(errorFixes, hasLength(1));
    var fixes = errorFixes[0].fixes;
    expect(fixes, hasLength(3));
    expect(fixes[0].message, matches('Import library'));
    expect(fixes[1].message, matches('Create class'));
    expect(fixes[2].message, matches('Create mixin'));
  }

  Future<void> test_fromPlugins() async {
    PluginInfo info = DiscoveredPluginInfo('a', 'b', 'c', null, null);
    var fixes = plugin.AnalysisErrorFixes(AnalysisError(
        AnalysisErrorSeverity.ERROR,
        AnalysisErrorType.HINT,
        Location('', 0, 0, 0, 0),
        'message',
        'code'));
    var result = plugin.EditGetFixesResult(<plugin.AnalysisErrorFixes>[fixes]);
    pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
      info: Future.value(result.toResponse('-', 1))
    };

    createProject();
    addTestFile('main() {}');
    await waitForTasksFinished();
    var errorFixes = await _getFixesAt('in(');
    expect(errorFixes, hasLength(1));
  }

  Future<void> test_hasFixes() async {
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
      var errorFixes = await _getFixesAt('print(1)');
      expect(errorFixes, hasLength(1));
      _isSyntacticErrorWithSingleFix(errorFixes[0]);
    }
    // print(10)
    {
      var errorFixes = await _getFixesAt('print(10)');
      expect(errorFixes, hasLength(2));
      _isSyntacticErrorWithSingleFix(errorFixes[0]);
      _isSyntacticErrorWithSingleFix(errorFixes[1]);
    }
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = EditGetFixesParams('test.dart', 0).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request = EditGetFixesParams(convertPath('/foo/../bar/test.dart'), 0)
        .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_overlayOnlyFile() async {
    createProject();
    testCode = '''
main() {
print(1)
}
''';
    _addOverlay(testFile, testCode);
    // ask for fixes
    await waitForTasksFinished();
    var errorFixes = await _getFixesAt('print(1)');
    expect(errorFixes, hasLength(1));
    _isSyntacticErrorWithSingleFix(errorFixes[0]);
  }

  Future<void> test_suggestImportFromDifferentAnalysisRoot() async {
    newFolder('/aaa');
    newFile('/aaa/.packages', content: '''
aaa:${toUri('/aaa/lib')}
bbb:${toUri('/bbb/lib')}
''');
    newFile('/aaa/pubspec.yaml', content: r'''
dependencies:
  bbb: any
''');

    newFolder('/bbb');
    newFile('/bbb/.packages', content: '''
bbb:${toUri('/bbb/lib')}
''');
    newFile('/bbb/lib/target.dart', content: 'class Foo() {}');
    newFile('/bbb/lib/target.generated.dart', content: 'class Foo() {}');
    newFile('/bbb/lib/target.template.dart', content: 'class Foo() {}');

    handleSuccessfulRequest(
        AnalysisSetAnalysisRootsParams(
            [convertPath('/aaa'), convertPath('/bbb')], []).toRequest('0'),
        handler: analysisHandler);

    // Configure the test file.
    testFile = convertPath('/aaa/main.dart');
    testCode = 'main() { new Foo(); }';
    _addOverlay(testFile, testCode);

    await waitForTasksFinished();
    doAllDeclarationsTrackerWork();

    var fixes = (await _getFixesAt('Foo()'))
        .single
        .fixes
        .map((f) => f.message)
        .toList();
    expect(fixes, contains("Import library 'package:bbb/target.dart'"));
    expect(
        fixes, contains("Import library 'package:bbb/target.generated.dart'"));

    // Context: http://dartbug.com/39401
    expect(fixes.contains("Import library 'package:bbb/target.template.dart'"),
        isFalse);
  }

  void _addOverlay(String name, String contents) {
    var request =
        AnalysisUpdateContentParams({name: AddContentOverlay(contents)})
            .toRequest('0');
    handleSuccessfulRequest(request, handler: analysisHandler);
  }

  Future<List<AnalysisErrorFixes>> _getFixes(int offset) async {
    var request = EditGetFixesParams(testFile, offset).toRequest('0');
    var response = await waitResponse(request);
    var result = EditGetFixesResult.fromResponse(response);
    return result.fixes;
  }

  Future<List<AnalysisErrorFixes>> _getFixesAt(String search) async {
    var offset = findOffset(search);
    return await _getFixes(offset);
  }

  void _isSyntacticErrorWithSingleFix(AnalysisErrorFixes fixes) {
    var error = fixes.error;
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
    expect(fixes.fixes, hasLength(1));
  }
}
