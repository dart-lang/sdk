// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer/src/generated/engine.dart'
    show InternalAnalysisContext;
import 'package:analyzer/src/generated/source.dart';
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
  bool get enableNewAnalysisDriver => false;

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
    InternalAnalysisContext sdkContext = server.findSdk().context;
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

  test_ignoredInAnalysisOptions() async {
    String sampleFile = '$projectPath/samples/sample.dart';
    addFile(
        '$projectPath/.analysis_options',
        r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    addFile(sampleFile, '');
    // attempt to set priority file
    Response response = await _setPriorityFile(sampleFile);
    expect(response.error, isNotNull);
    expect(response.error.code, RequestErrorCode.UNANALYZED_PRIORITY_FILES);
  }

  test_ignoredInAnalysisOptions_inChildContext() async {
    addFile('$projectPath/.packages', '');
    addFile('$projectPath/child/.packages', '');
    String sampleFile = '$projectPath/child/samples/sample.dart';
    addFile(
        '$projectPath/child/.analysis_options',
        r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    addFile(sampleFile, '');
    // attempt to set priority file
    Response response = await _setPriorityFile(sampleFile);
    expect(response.error, isNotNull);
    expect(response.error.code, RequestErrorCode.UNANALYZED_PRIORITY_FILES);
  }

  test_ignoredInAnalysisOptions_inRootContext() async {
    addFile('$projectPath/.packages', '');
    addFile('$projectPath/child/.packages', '');
    String sampleFile = '$projectPath/child/samples/sample.dart';
    addFile(
        '$projectPath/.analysis_options',
        r'''
analyzer:
  exclude:
    - 'child/samples/**'
''');
    addFile(sampleFile, '');
    // attempt to set priority file
    Response response = await _setPriorityFile(sampleFile);
    expect(response.error, isNotNull);
    expect(response.error.code, RequestErrorCode.UNANALYZED_PRIORITY_FILES);
  }

  test_sentToPlugins() async {
    addTestFile('');
    // wait for analysis to ensure that the file is known to the context
    await server.onAnalysisComplete;
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
}
