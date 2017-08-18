// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetPriorityFilesTest);
  });
}

@reflectiveTest
class SetPriorityFilesTest extends AbstractAnalysisTest {
  @override
  void setUp() {
    super.setUp();
    server.handlers = [
      new AnalysisDomainHandler(server),
    ];
    createProject();
  }

  test_fileDoesNotExist() async {
    String file = '$projectPath/doesNotExist.dart';
    Response response = await _setPriorityFile(file);
    expect(response, isResponseSuccess('0'));
  }

  test_fileInAnalysisRoot() async {
    addTestFile('');
    // set priority files
    Response response = await _setPriorityFile(testFile);
    expect(response, isResponseSuccess('0'));
    // verify
    _verifyPriorityFiles(testFile);
  }

  test_fileInSdk() async {
    addTestFile('');
    // set priority files
    String filePath = '/lib/convert/convert.dart';
    Response response = await _setPriorityFile(filePath);
    expect(response, isResponseSuccess('0'));
    // verify
    _verifyPriorityFiles(filePath);
  }

  test_fileNotInAnalysisRoot() async {
    String path = '/other/file.dart';
    addFile(path, '');
    await _setPriorityFile(path);
    _verifyPriorityFiles(path);
  }

  test_ignoredInAnalysisOptions() async {
    String sampleFile = '$projectPath/samples/sample.dart';
    addFile('$projectPath/.analysis_options', r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    addFile(sampleFile, '');
    // attempt to set priority file
    await _setPriorityFile(sampleFile);
    _verifyPriorityFiles(sampleFile);
  }

  test_ignoredInAnalysisOptions_inChildContext() async {
    addFile('$projectPath/.packages', '');
    addFile('$projectPath/child/.packages', '');
    String sampleFile = '$projectPath/child/samples/sample.dart';
    addFile('$projectPath/child/.analysis_options', r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    addFile(sampleFile, '');
    // attempt to set priority file
    await _setPriorityFile(sampleFile);
    _verifyPriorityFiles(sampleFile);
  }

  test_ignoredInAnalysisOptions_inRootContext() async {
    addFile('$projectPath/.packages', '');
    addFile('$projectPath/child/.packages', '');
    String sampleFile = '$projectPath/child/samples/sample.dart';
    addFile('$projectPath/.analysis_options', r'''
analyzer:
  exclude:
    - 'child/samples/**'
''');
    addFile(sampleFile, '');
    // attempt to set priority file
    await _setPriorityFile(sampleFile);
    _verifyPriorityFiles(sampleFile);
  }

  test_sentToPlugins() async {
    addTestFile('');
    // set priority files
    Response response = await _setPriorityFile(testFile);
    expect(response, isResponseSuccess('0'));
    // verify
    plugin.AnalysisSetPriorityFilesParams params =
        pluginManager.analysisSetPriorityFilesParams;
    expect(params, isNotNull);
    expect(params.files, <String>[testFile]);
  }

  _setPriorityFile(String file) async {
    Request request =
        new AnalysisSetPriorityFilesParams(<String>[file]).toRequest('0');
    return await serverChannel.sendRequest(request);
  }

  void _verifyPriorityFiles(String path) {
    AnalysisDriver driver = server.getAnalysisDriver(path);
    List<String> prioritySources = driver.priorityFiles;
    expect(prioritySources, [path]);
  }
}
