// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

void main() {
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
      AnalysisDomainHandler(server),
    ];
    createProject();
  }

  Future<void> test_fileDoesNotExist() async {
    var file = convertPath('$projectPath/doesNotExist.dart');
    var response = await _setPriorityFile(file);
    expect(response, isResponseSuccess('0'));
  }

  Future<void> test_fileInAnalysisRoot() async {
    addTestFile('');
    // set priority files
    var response = await _setPriorityFile(testFile);
    expect(response, isResponseSuccess('0'));
    // verify
    _verifyPriorityFiles(testFile);
  }

  Future<void> test_fileInAnalysisRootAddedLater() async {
    var path = convertPath('/other/file.dart');
    newFile(path);
    await _setPriorityFile(path);
    await _setAnalysisRoots('/other');
    _verifyPriorityFiles(path);
  }

  Future<void> test_fileInSdk() async {
    addTestFile('');
    // set priority files
    var filePath = convertPath('/lib/convert/convert.dart');
    var response = await _setPriorityFile(filePath);
    expect(response, isResponseSuccess('0'));
    // verify
    _verifyPriorityFiles(filePath);
  }

  Future<void> test_fileNotInAnalysisRoot() async {
    var path = convertPath('/other/file.dart');
    newFile(path);
    await _setPriorityFile(path);
    _verifyPriorityFiles(path);
  }

  Future<void> test_ignoredInAnalysisOptions() async {
    var sampleFile = convertPath('$projectPath/samples/sample.dart');
    newFile('$projectPath/.analysis_options', content: r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    newFile(sampleFile);
    // attempt to set priority file
    await _setPriorityFile(sampleFile);
    _verifyPriorityFiles(sampleFile);
  }

  Future<void> test_ignoredInAnalysisOptions_inChildContext() async {
    newFile('$projectPath/.packages');
    newFile('$projectPath/child/.packages');
    var sampleFile = convertPath('$projectPath/child/samples/sample.dart');
    newFile('$projectPath/child/.analysis_options', content: r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    newFile(sampleFile);
    // attempt to set priority file
    await _setPriorityFile(sampleFile);
    _verifyPriorityFiles(sampleFile);
  }

  Future<void> test_ignoredInAnalysisOptions_inRootContext() async {
    newFile('$projectPath/.packages');
    newFile('$projectPath/child/.packages');
    var sampleFile = convertPath('$projectPath/child/samples/sample.dart');
    newFile('$projectPath/.analysis_options', content: r'''
analyzer:
  exclude:
    - 'child/samples/**'
''');
    newFile(sampleFile);
    // attempt to set priority file
    await _setPriorityFile(sampleFile);
    _verifyPriorityFiles(sampleFile);
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = AnalysisSetPriorityFilesParams(['test.dart']).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request =
        AnalysisSetPriorityFilesParams([convertPath('/foo/../bar/test.dart')])
            .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_sentToPlugins() async {
    addTestFile('');
    // set priority files
    var response = await _setPriorityFile(testFile);
    expect(response, isResponseSuccess('0'));
    // verify
    var params = pluginManager.analysisSetPriorityFilesParams;
    expect(params, isNotNull);
    expect(params.files, <String>[testFile]);
  }

  Future<Response> _setAnalysisRoots(String folder) async {
    var request = AnalysisSetAnalysisRootsParams([folder], []).toRequest('1');
    return await serverChannel.sendRequest(request);
  }

  Future<Response> _setPriorityFile(String file) async {
    var request = AnalysisSetPriorityFilesParams(<String>[file]).toRequest('0');
    return await serverChannel.sendRequest(request);
  }

  void _verifyPriorityFiles(String path) {
    var driver = server.getAnalysisDriver(path);
    var prioritySources = driver.priorityFiles;
    expect(prioritySources, [path]);
  }
}
