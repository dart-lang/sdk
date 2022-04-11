// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';
import '../mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetPriorityFilesTest);
  });
}

@reflectiveTest
class SetPriorityFilesTest extends PubPackageAnalysisServerTest {
  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_fileDoesNotExist() async {
    var file = getFile('$testPackageLibPath/doesNotExist.dart');
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
    var file = newFile2('/other/file.dart', '');
    await _setPriorityFile(file);
    await setRoots(included: [file.parent.path], excluded: []);
    _verifyPriorityFiles(file);
  }

  Future<void> test_fileInSdk() async {
    addTestFile('');
    // set priority files
    var file = sdkRoot
        .getChildAssumingFolder('lib')
        .getChildAssumingFolder('convert')
        .getChildAssumingFile('convert.dart');
    var response = await _setPriorityFile(file);
    expect(response, isResponseSuccess('0'));
    // verify
    _verifyPriorityFiles(file);
  }

  Future<void> test_fileNotInAnalysisRoot() async {
    var file = newFile2('/other/file.dart', '');
    await _setPriorityFile(file);
    _verifyPriorityFiles(file);
  }

  Future<void> test_ignoredInAnalysisOptions() async {
    newAnalysisOptionsYamlFile2(testPackageRootPath, r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    var file = newFile2('$testPackageRootPath/samples/sample.dart', '');
    // attempt to set priority file
    await _setPriorityFile(file);
    _verifyPriorityFiles(file);
  }

  Future<void> test_ignoredInAnalysisOptions_inChildContext() async {
    newPackageConfigJsonFile(testPackageRootPath, '');
    newPackageConfigJsonFile('$testPackageRootPath/child', '');
    var sampleFile = newFile2(
      '$testPackageRootPath/child/samples/sample.dart',
      '',
    );
    newAnalysisOptionsYamlFile2(testPackageRootPath, r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    // attempt to set priority file
    await _setPriorityFile(sampleFile);
    _verifyPriorityFiles(sampleFile);
  }

  Future<void> test_ignoredInAnalysisOptions_inRootContext() async {
    newPackageConfigJsonFile(testPackageRootPath, '');
    newPackageConfigJsonFile('$testPackageRootPath/child', '');
    var sampleFile = newFile2(
      '$testPackageRootPath/child/samples/sample.dart',
      '',
    );
    newAnalysisOptionsYamlFile2(testPackageRootPath, r'''
analyzer:
  exclude:
    - 'child/samples/**'
''');
    // attempt to set priority file
    await _setPriorityFile(sampleFile);
    _verifyPriorityFiles(sampleFile);
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var response = await handleRequest(
      AnalysisSetPriorityFilesParams([
        'test.dart',
      ]).toRequest('0'),
    );
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var response = await handleRequest(AnalysisSetPriorityFilesParams([
      convertPath('/foo/../bar/test.dart'),
    ]).toRequest('0'));
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_sentToPlugins() async {
    addTestFile('');
    // set priority files
    var response = await _setPriorityFile(testFile);
    expect(response, isResponseSuccess('0'));
    // verify
    var params = pluginManager.analysisSetPriorityFilesParams!;
    expect(params.files, [testFile.path]);
  }

  Future<Response> _setPriorityFile(File file) async {
    return await handleSuccessfulRequest(
      AnalysisSetPriorityFilesParams(<String>[
        file.path,
      ]).toRequest('0'),
    );
  }

  void _verifyPriorityFiles(File file) {
    var driver = server.getAnalysisDriver(file.path)!;
    var prioritySources = driver.priorityFiles;
    expect(prioritySources, [file.path]);
  }
}
