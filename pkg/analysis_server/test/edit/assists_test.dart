// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';
import '../src/plugin/plugin_manager_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssistsTest);
  });
}

@reflectiveTest
class AssistsTest extends PubPackageAnalysisServerTest {
  late List<SourceChange> changes;

  Future<void> prepareAssists(String search, [int length = 0]) async {
    var offset = findOffset(search);
    await prepareAssistsAt(offset, length);
  }

  Future<void> prepareAssistsAt(int offset, int length) async {
    var request = EditGetAssistsParams(
      testFile.path,
      offset,
      length,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleSuccessfulRequest(request);
    var result = EditGetAssistsResult.fromResponse(
      response,
      clientUriConverter: server.uriConverter,
    );
    changes = result.assists;
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    registerBuiltInAssistGenerators();
    await setRoots(included: [workspaceRootPath], excluded: []);
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
    var message = 'From a plugin';
    var change = plugin.PrioritizedSourceChange(
      5,
      SourceChange(
        message,
        edits: <SourceFileEdit>[
          SourceFileEdit('', 5, edits: <SourceEdit>[SourceEdit(5, 0, 'x')]),
        ],
      ),
    );
    var result = plugin.EditGetAssistsResult(<plugin.PrioritizedSourceChange>[
      change,
    ]);
    pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
      info: Future.value(result.toResponse('-', 1)),
    };

    addTestFile('void f() {}');
    await waitForTasksFinished();
    await prepareAssists('f(');
    _assertHasChange(message, 'void xf() {}');
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = EditGetAssistsParams(
      'test.dart',
      0,
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
    var request = EditGetAssistsParams(
      convertPath('/foo/../bar/test.dart'),
      0,
      0,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_removeTypeAnnotation() async {
    addTestFile('''
void f() {
  int v = 1;
}
''');
    await waitForTasksFinished();
    await prepareAssists('v =');
    _assertHasChange('Remove type annotation', '''
void f() {
  var v = 1;
}
''');
  }

  Future<void> test_splitVariableDeclaration() async {
    addTestFile('''
void f() {
  int v = 1;
}
''');
    await waitForTasksFinished();
    await prepareAssists('v =');
    _assertHasChange('Split variable declaration', '''
void f() {
  int v;
  v = 1;
}
''');
  }

  Future<void> test_surroundWithIf() async {
    addTestFile('''
void f() {
  print(1);
  print(2);
}
''');
    await waitForTasksFinished();
    var offset = findOffset('  print(1)');
    var length = findOffset('}') - offset;
    await prepareAssistsAt(offset, length);
    _assertHasChange("Surround with 'if'", '''
void f() {
  if (condition) {
    print(1);
    print(2);
  }
}
''');
  }

  void _assertHasChange(String message, String expectedCode) {
    for (var change in changes) {
      if (change.message == message) {
        var resultCode = SourceEdit.applySequence(
          testFileContent,
          change.edits[0].edits,
        );
        expect(resultCode, expectedCode);
        return;
      }
    }
    fail('Expected to find |$message| in\n${changes.join('\n')}');
  }
}
