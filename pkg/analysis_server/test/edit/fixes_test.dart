// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';
import '../src/plugin/plugin_manager_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixesTest);
  });
}

@reflectiveTest
class FixesTest extends PubPackageAnalysisServerTest {
  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_fileOutsideRoot() async {
    final outsideFile = '/foo/test.dart';
    newFile2(outsideFile, 'bad code to create error');

    // Set up the original project, as the code fix code won't run at all
    // if there are no contexts.
    await waitForTasksFinished();

    var request =
        EditGetFixesParams(convertPath(outsideFile), 0).toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.GET_FIXES_INVALID_FILE,
    );
  }

  Future<void> test_fixUndefinedClass() async {
    addTestFile('''
main() {
  Completer<String> x = null;
  print(x);
}
''');
    await waitForTasksFinished();
    var errorFixes = await _getFixesAt(testFile, 'Completer<String>');
    expect(errorFixes, hasLength(1));
    var fixes = errorFixes[0].fixes;
    expect(fixes, hasLength(3));
    expect(fixes[0].message, matches('Import library'));
    expect(fixes[1].message, matches('Create class'));
    expect(fixes[2].message, matches('Create mixin'));
  }

  Future<void> test_fromPlugins() async {
    PluginInfo info = DiscoveredPluginInfo('a', 'b', 'c',
        TestNotificationManager(), InstrumentationService.NULL_SERVICE);
    var fixes = plugin.AnalysisErrorFixes(AnalysisError(
        AnalysisErrorSeverity.ERROR,
        AnalysisErrorType.HINT,
        Location('', 0, 0, 0, 0, endLine: 0, endColumn: 0),
        'message',
        'code'));
    var result = plugin.EditGetFixesResult(<plugin.AnalysisErrorFixes>[fixes]);
    pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
      info: Future.value(result.toResponse('-', 1))
    };

    addTestFile('main() {}');
    await waitForTasksFinished();
    var errorFixes = await _getFixesAt(testFile, 'in(');
    expect(errorFixes, hasLength(1));
  }

  Future<void> test_hasFixes() async {
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
      var errorFixes = await _getFixesAt(testFile, 'print(1)');
      expect(errorFixes, hasLength(1));
      _isSyntacticErrorWithSingleFix(errorFixes[0]);
    }
    // print(10)
    {
      var errorFixes = await _getFixesAt(testFile, 'print(10)');
      expect(errorFixes, hasLength(2));
      _isSyntacticErrorWithSingleFix(errorFixes[0]);
      _isSyntacticErrorWithSingleFix(errorFixes[1]);
    }
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = EditGetFixesParams('test.dart', 0).toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request = EditGetFixesParams(convertPath('/foo/../bar/test.dart'), 0)
        .toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_overlayOnlyFile() async {
    await _addOverlay(testFile.path, '''
main() {
print(1)
}
''');

    var file = server.resourceProvider.getFile(testFile.path);

    // ask for fixes
    await waitForTasksFinished();
    var errorFixes = await _getFixesAt(file, 'print(1)');
    expect(errorFixes, hasLength(1));
    _isSyntacticErrorWithSingleFix(errorFixes[0]);
  }

  Future<void> test_suggestImportFromDifferentAnalysisRoot() async {
    newPackageConfigJsonFile(
      '$workspaceRootPath/aaa',
      (PackageConfigFileBuilder()
            ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa')
            ..add(name: 'bbb', rootPath: '$workspaceRootPath/bbb'))
          .toContent(toUriStr: toUriStr),
    );
    newPubspecYamlFile('$workspaceRootPath/aaa', r'''
dependencies:
  bbb: any
''');

    newPackageConfigJsonFile(
      '$workspaceRootPath/bbb',
      (PackageConfigFileBuilder()
            ..add(name: 'bbb', rootPath: '$workspaceRootPath/bbb'))
          .toContent(toUriStr: toUriStr),
    );
    newFile2('$workspaceRootPath/bbb/lib/target.dart', 'class Foo() {}');
    newFile2(
        '$workspaceRootPath/bbb/lib/target.generated.dart', 'class Foo() {}');
    newFile2(
        '$workspaceRootPath/bbb/lib/target.template.dart', 'class Foo() {}');

    // Configure the test file.
    final file =
        newFile2('$workspaceRootPath/aaa/main.dart', 'main() { new Foo(); }');

    await waitForTasksFinished();

    var fixes = (await _getFixesAt(file, 'Foo()'))
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

  Future<void> _addOverlay(String name, String contents) async {
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        name: AddContentOverlay(contents),
      }).toRequest('0'),
    );
  }

  Future<List<AnalysisErrorFixes>> _getFixes(File file, int offset) async {
    var request = EditGetFixesParams(file.path, offset).toRequest('0');
    var response = await handleSuccessfulRequest(request);
    var result = EditGetFixesResult.fromResponse(response);
    return result.fixes;
  }

  Future<List<AnalysisErrorFixes>> _getFixesAt(File file, String search) async {
    var offset = offsetInFile(file, search);
    return await _getFixes(file, offset);
  }

  void _isSyntacticErrorWithSingleFix(AnalysisErrorFixes fixes) {
    var error = fixes.error;
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
    expect(fixes.fixes, hasLength(1));
  }
}
