// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
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
    registerBuiltInFixGenerators();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_concurrentModifications() async {
    var file = server.resourceProvider.getFile(testFile.path);
    var futures = <Future<void>>[];

    // Send many requests to modify files and get fixes.
    for (var i = 1; i < 100; i++) {
      futures.add(_addOverlay(testFile.path, 'var i = $i;'));
      await pumpEventQueue();
      futures.add(
        handleSuccessfulRequest(
          EditGetFixesParams(
            file.path,
            0,
          ).toRequest('$i', clientUriConverter: server.uriConverter),
        ),
      );
      await pumpEventQueue();
    }

    // Except all to complete.
    await Future.wait(futures);
  }

  Future<void> test_fileOutsideRoot() async {
    var outsideFile = '/foo/test.dart';
    newFile(outsideFile, 'bad code to create error');

    // Set up the original project, as the code fix code won't run at all
    // if there are no contexts.
    await waitForTasksFinished();

    var request = EditGetFixesParams(
      convertPath(outsideFile),
      0,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.GET_FIXES_INVALID_FILE,
    );
  }

  Future<void> test_fixUndefinedClass() async {
    addTestFile('''
void f() {
  Completer<String> x = null;
  print(x);
}
''');
    await waitForTasksFinished();
    var errors = await _getFixesAt(testFile, 'Completer<String>');
    expect(errors, hasLength(1));
    var fixes = errors.first.fixes;
    expect(fixes, hasLength(4));
    expect(fixes[0].message, matches('Import library'));
    expect(fixes[1].message, matches("Import library .+ with 'show'"));
    expect(fixes[2].message, matches('Create class'));
    expect(fixes[3].message, matches('Create mixin'));
  }

  Future<void> test_fromPlugins() async {
    if (!AnalysisServer.supportsPlugins) return;
    PluginInfo info = PluginInfo(
      'a',
      'b',
      'c',
      TestNotificationManager(),
      InstrumentationService.NULL_SERVICE,
    );
    var fixes = plugin.AnalysisErrorFixes(
      AnalysisError(
        AnalysisErrorSeverity.ERROR,
        AnalysisErrorType.HINT,
        Location('', 0, 0, 0, 0, endLine: 0, endColumn: 0),
        'message',
        'code',
      ),
    );
    var result = plugin.EditGetFixesResult(<plugin.AnalysisErrorFixes>[fixes]);
    pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
      info: Future.value(result.toResponse('-', 1)),
    };

    addTestFile('void f() {}');
    await waitForTasksFinished();
    var errorFixes = await _getFixesAt(testFile, 'f(');
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
      _isSyntacticErrorWithMultiFix(errorFixes[0]);
    }
    // print(10)
    {
      var errorFixes = await _getFixesAt(testFile, 'print(10)');
      expect(errorFixes, hasLength(2));
      _isSyntacticErrorWithMultiFix(errorFixes[0]);
      _isSyntacticErrorWithMultiFix(errorFixes[0]);
    }
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = EditGetFixesParams(
      'test.dart',
      0,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request = EditGetFixesParams(
      convertPath('/foo/../bar/test.dart'),
      0,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_overlayOnlyFile() async {
    await _addOverlay(testFile.path, '''
void f() {
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
    writePackageConfig(
      convertPath('$workspaceRootPath/aaa'),
      config:
          (PackageConfigFileBuilder()
            ..add(name: 'bbb', rootPath: '$workspaceRootPath/bbb')),
    );
    newPubspecYamlFile('$workspaceRootPath/aaa', r'''
dependencies:
  bbb: any
''');

    writePackageConfig(convertPath('$workspaceRootPath/bbb'));
    newFile('$workspaceRootPath/bbb/lib/target.dart', 'class Foo() {}');
    newFile(
      '$workspaceRootPath/bbb/lib/target.generated.dart',
      'class Foo() {}',
    );
    newFile(
      '$workspaceRootPath/bbb/lib/target.template.dart',
      'class Foo() {}',
    );

    // Configure the test file.
    var file = newFile(
      '$workspaceRootPath/aaa/main.dart',
      'void f() { Foo(); }',
    );

    await waitForTasksFinished();

    var fixes =
        (await _getFixesAt(
          file,
          'Foo()',
        )).single.fixes.map((f) => f.message).toList();
    expect(fixes, contains("Import library 'package:bbb/target.dart'"));
    expect(
      fixes,
      contains("Import library 'package:bbb/target.generated.dart'"),
    );

    // Context: http://dartbug.com/39401
    expect(
      fixes.contains("Import library 'package:bbb/target.template.dart'"),
      isFalse,
    );
  }

  Future<void> _addOverlay(String name, String contents) async {
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        name: AddContentOverlay(contents),
      }).toRequest('0', clientUriConverter: server.uriConverter),
    );
  }

  Future<List<AnalysisErrorFixes>> _getFixes(File file, int offset) async {
    var request = EditGetFixesParams(
      file.path,
      offset,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleSuccessfulRequest(request);
    var result = EditGetFixesResult.fromResponse(
      response,
      clientUriConverter: server.uriConverter,
    );
    return result.fixes;
  }

  Future<List<AnalysisErrorFixes>> _getFixesAt(File file, String search) async {
    var offset = offsetInFile(file, search);
    return await _getFixes(file, offset);
  }

  void _isSyntacticError(AnalysisErrorFixes fixes) {
    var error = fixes.error;
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
  }

  void _isSyntacticErrorWithMultiFix(AnalysisErrorFixes fixes) {
    _isSyntacticError(fixes);
    expect(fixes.fixes.length, greaterThan(1));
  }

  void _isSyntacticErrorWithSingleFix(AnalysisErrorFixes fixes) {
    _isSyntacticError(fixes);
    expect(fixes.fixes, hasLength(1));
  }
}
