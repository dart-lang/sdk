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
    defineReflectiveTests(AssistsTest);
  });
}

@reflectiveTest
class AssistsTest extends AbstractAnalysisTest {
  List<SourceChange> changes;

  Future<void> prepareAssists(String search, [int length = 0]) async {
    var offset = findOffset(search);
    await prepareAssistsAt(offset, length);
  }

  Future<void> prepareAssistsAt(int offset, int length) async {
    var request = EditGetAssistsParams(testFile, offset, length).toRequest('0');
    var response = await waitResponse(request);
    var result = EditGetAssistsResult.fromResponse(response);
    changes = result.assists;
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = EditDomainHandler(server);
  }

  Future<void> test_fromPlugins() async {
    PluginInfo info = DiscoveredPluginInfo('a', 'b', 'c', null, null);
    var message = 'From a plugin';
    var change = plugin.PrioritizedSourceChange(
        5,
        SourceChange(message, edits: <SourceFileEdit>[
          SourceFileEdit('', 0, edits: <SourceEdit>[SourceEdit(0, 0, 'x')])
        ]));
    var result =
        plugin.EditGetAssistsResult(<plugin.PrioritizedSourceChange>[change]);
    pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
      info: Future.value(result.toResponse('-', 1))
    };

    addTestFile('main() {}');
    await waitForTasksFinished();
    await prepareAssists('in(');
    _assertHasChange(message, 'xmain() {}');
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = EditGetAssistsParams('test.dart', 0, 0).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request =
        EditGetAssistsParams(convertPath('/foo/../bar/test.dart'), 0, 0)
            .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_removeTypeAnnotation() async {
    addTestFile('''
main() {
  int v = 1;
}
''');
    await waitForTasksFinished();
    await prepareAssists('v =');
    _assertHasChange('Remove type annotation', '''
main() {
  var v = 1;
}
''');
  }

  Future<void> test_splitVariableDeclaration() async {
    addTestFile('''
main() {
  int v = 1;
}
''');
    await waitForTasksFinished();
    await prepareAssists('v =');
    _assertHasChange('Split variable declaration', '''
main() {
  int v;
  v = 1;
}
''');
  }

  Future<void> test_surroundWithIf() async {
    addTestFile('''
main() {
  print(1);
  print(2);
}
''');
    await waitForTasksFinished();
    var offset = findOffset('  print(1)');
    var length = findOffset('}') - offset;
    await prepareAssistsAt(offset, length);
    _assertHasChange("Surround with 'if'", '''
main() {
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
        var resultCode =
            SourceEdit.applySequence(testCode, change.edits[0].edits);
        expect(resultCode, expectedCode);
        return;
      }
    }
    fail('Expected to find |$message| in\n' + changes.join('\n'));
  }
}
