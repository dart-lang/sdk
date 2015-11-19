// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.set_priority_files;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer/src/generated/engine.dart'
    show InternalAnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';
import '../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(SetPriorityFilesTest);
}

@reflectiveTest
class SetPriorityFilesTest extends AbstractAnalysisTest {
  @override
  void setUp() {
    super.setUp();
    server.handlers = [new AnalysisDomainHandler(server),];
    createProject();
  }

  test_fileDoesNotExist() async {
    String file = '$projectPath/doesNotExist.dart';
    Response response = await _setPriorityFile(file);
    expect(response, isResponseSuccess('0'));
  }

  test_fileInAnalysisRoot() async {
    addTestFile('');
    // wait for analysis to ensure that the file is known to the context
    await server.onAnalysisComplete;
    // set priority files
    Response response = await _setPriorityFile(testFile);
    expect(response, isResponseSuccess('0'));
    // verify
    InternalAnalysisContext context = server.getContainingContext(testFile);
    List<Source> prioritySources = context.prioritySources;
    expect(prioritySources, hasLength(1));
    expect(prioritySources.first.fullName, testFile);
  }

  test_fileInSdk() async {
    addTestFile('');
    await server.onAnalysisComplete;
    // set priority files
    String filePath = '/lib/convert/convert.dart';
    Response response = await _setPriorityFile(filePath);
    expect(response, isResponseSuccess('0'));
    // verify
    InternalAnalysisContext sdkContext = server.defaultSdk.context;
    List<Source> prioritySources = sdkContext.prioritySources;
    expect(prioritySources, hasLength(1));
    expect(prioritySources.first.fullName, filePath);
  }

  test_fileNotInAnalysisRoot() async {
    String path = '/other/file.dart';
    addFile(path, '');
    Response response = await _setPriorityFile(path);
    expect(response.error, isNotNull);
    expect(response.error.code, RequestErrorCode.UNANALYZED_PRIORITY_FILES);
  }

  _setPriorityFile(String file) async {
    Request request =
        new AnalysisSetPriorityFilesParams(<String>[file]).toRequest('0');
    return await serverChannel.sendRequest(request);
  }
}
