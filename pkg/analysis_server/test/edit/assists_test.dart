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
    defineReflectiveTests(AssistsTest);
  });
}

@reflectiveTest
class AssistsTest extends AbstractAnalysisTest {
  List<SourceChange> changes;

  prepareAssists(String search, [int length = 0]) async {
    int offset = findOffset(search);
    await prepareAssistsAt(offset, length);
  }

  prepareAssistsAt(int offset, int length) async {
    Request request =
        new EditGetAssistsParams(testFile, offset, length).toRequest('0');
    Response response = await waitResponse(request);
    var result = new EditGetAssistsResult.fromResponse(response);
    changes = result.assists;
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new EditDomainHandler(server);
  }

  test_fromPlugins() async {
    PluginInfo info = new DiscoveredPluginInfo('a', 'b', 'c', null, null);
    String message = 'From a plugin';
    plugin.PrioritizedSourceChange change = new plugin.PrioritizedSourceChange(
        5,
        new SourceChange(message, edits: <SourceFileEdit>[
          new SourceFileEdit('', 0,
              edits: <SourceEdit>[new SourceEdit(0, 0, 'x')])
        ]));
    plugin.EditGetAssistsResult result = new plugin.EditGetAssistsResult(
        <plugin.PrioritizedSourceChange>[change]);
    pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
      info: new Future.value(result.toResponse('-', 1))
    };

    addTestFile('main() {}');
    await waitForTasksFinished();
    await prepareAssists('in(');
    _assertHasChange(message, 'xmain() {}');
  }

  test_removeTypeAnnotation() async {
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

  test_splitVariableDeclaration() async {
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

  test_surroundWithIf() async {
    addTestFile('''
main() {
  print(1);
  print(2);
}
''');
    await waitForTasksFinished();
    int offset = findOffset('  print(1)');
    int length = findOffset('}') - offset;
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
    for (SourceChange change in changes) {
      if (change.message == message) {
        String resultCode =
            SourceEdit.applySequence(testCode, change.edits[0].edits);
        expect(resultCode, expectedCode);
        return;
      }
    }
    fail("Expected to find |$message| in\n" + changes.join('\n'));
  }
}
