// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analysis_server/src/utilities/progress.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart'
    show HasToJson;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';
import 'mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDomainBazelTest);
    defineReflectiveTests(AnalysisDomainPubTest);
    defineReflectiveTests(AnalysisDomainHandlerTest);
    defineReflectiveTests(SetSubscriptionsTest);
  });
}

@reflectiveTest
class AnalysisDomainBazelTest extends _AnalysisDomainTest {
  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$workspaceRootPath/dart/my';

  String get myPackageTestFilePath => '$myPackageLibPath/test.dart';

  String get workspaceRootPath => '/workspace';

  @override
  void setUp() {
    super.setUp();
    newFile('$workspaceRootPath/WORKSPACE');
  }

  Future<void> test_fileSystem_changeFile_buildFile() async {
    // This BUILD file does not enable null safety.
    newBazelBuildFile(myPackageRootPath, '');

    newFile(myPackageTestFilePath, content: '''
void f(int? a) {}
''');

    await setRoots(included: [myPackageRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Cannot use `int?` without enabling null safety.
    assertHasErrors(myPackageTestFilePath);

    // Enable null safety.
    newBazelBuildFile(myPackageRootPath, '''
dart_package(null_safety = True)
''');

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We have null safety enabled, so no errors.
    assertNoErrors(myPackageTestFilePath);
  }
}

@reflectiveTest
class AnalysisDomainHandlerTest extends AbstractAnalysisTest {
  Future<void> outOfRangeTest(SourceEdit edit) async {
    var helper = AnalysisTestHelper();
    await helper.createSingleFileProject('library A;');
    await helper.onAnalysisComplete;
    helper.sendContentChange(AddContentOverlay('library B;'));
    await helper.onAnalysisComplete;
    var contentChange = ChangeContentOverlay([edit]);
    var request = AnalysisUpdateContentParams({helper.testFile: contentChange})
        .toRequest('0');
    var response = helper.handler.handleRequest(request, NotCancelableToken());
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_OVERLAY_CHANGE));
  }

  Future<void> test_setAnalysisRoots_excludedFolder() async {
    newFile('/project/aaa/a.dart', content: '// a');
    newFile('/project/bbb/b.dart', content: '// b');
    var excludedPath = join(projectPath, 'bbb');
    var response = await testSetAnalysisRoots([projectPath], [excludedPath]);
    expect(response, isResponseSuccess('0'));
  }

  Future<void> test_setAnalysisRoots_included_newFolder() async {
    newPubspecYamlFile('/project', 'name: project');
    var file = newFile('/project/bin/test.dart', content: 'main() {}').path;
    var response = await testSetAnalysisRoots([projectPath], []);
    var serverRef = server;
    expect(response, isResponseSuccess('0'));
    // verify that unit is resolved eventually
    await server.onAnalysisComplete;
    var resolvedUnit = await serverRef.getResolvedUnit(file);
    expect(resolvedUnit, isNotNull);
  }

  Future<void> test_setAnalysisRoots_included_nonexistentFolder() async {
    var projectA = convertPath('/project_a');
    var projectB = convertPath('/project_b');
    var fileB = newFile('/project_b/b.dart', content: '// b').path;
    var response = await testSetAnalysisRoots([projectA, projectB], []);
    var serverRef = server;
    expect(response, isResponseSuccess('0'));
    // Non-existence of /project_a should not prevent files in /project_b
    // from being analyzed.
    await server.onAnalysisComplete;
    var resolvedUnit = await serverRef.getResolvedUnit(fileB);
    expect(resolvedUnit, isNotNull);
  }

  Future<void> test_setAnalysisRoots_included_notAbsolute() async {
    var response = await testSetAnalysisRoots(['foo/bar'], []);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  Future<void> test_setAnalysisRoots_included_notNormalized() async {
    var response = await testSetAnalysisRoots(['/foo/../bar'], []);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  Future<void> test_setAnalysisRoots_notAbsolute() async {
    var response = await testSetAnalysisRoots([], ['foo/bar']);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  Future<void> test_setAnalysisRoots_notNormalized() async {
    var response = await testSetAnalysisRoots([], ['/foo/../bar']);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  void test_setPriorityFiles_invalid() {
    var request = AnalysisSetPriorityFilesParams(
      [convertPath('/project/lib.dart')],
    ).toRequest('0');
    var response = handler.handleRequest(request, NotCancelableToken());
    expect(response, isResponseSuccess('0'));
  }

  Future<void> test_setPriorityFiles_valid() async {
    var p1 = convertPath('/p1');
    var p2 = convertPath('/p2');
    var aPath = convertPath('/p1/a.dart');
    var bPath = convertPath('/p2/b.dart');
    var cPath = convertPath('/p2/c.dart');
    newFile(aPath, content: 'library a;');
    newFile(bPath, content: 'library b;');
    newFile(cPath, content: 'library c;');

    await setRoots(included: [p1, p2], excluded: []);

    void setPriorityFiles(List<String> fileList) {
      var request = AnalysisSetPriorityFilesParams(fileList).toRequest('0');
      var response = handler.handleRequest(request, NotCancelableToken());
      expect(response, isResponseSuccess('0'));
      // TODO(brianwilkerson) Enable the line below after getPriorityFiles
      // has been implemented.
      // expect(server.getPriorityFiles(), unorderedEquals(fileList));
    }

    setPriorityFiles([aPath, bPath]);
    setPriorityFiles([bPath, cPath]);
    setPriorityFiles([]);
  }

  Future<void> test_updateContent_badType() async {
    var helper = AnalysisTestHelper();
    await helper.createSingleFileProject('// empty');
    await helper.onAnalysisComplete;
    var request = Request('0', ANALYSIS_REQUEST_UPDATE_CONTENT, {
      ANALYSIS_REQUEST_UPDATE_CONTENT_FILES: {
        helper.testFile: {
          'type': 'foo',
        }
      }
    });
    var response = helper.handler.handleRequest(request, NotCancelableToken());
    expect(response, isResponseFailure('0'));
  }

  Future<void> test_updateContent_changeOnDisk_duringOverride() async {
    var helper = AnalysisTestHelper();
    await helper.createSingleFileProject('library A;');
    await helper.onAnalysisComplete;
    // update code
    helper.sendContentChange(AddContentOverlay('library B;'));
    // There should be no errors
    await helper.onAnalysisComplete;
    expect(helper.getTestErrors(), hasLength(0));
    // Change file on disk, adding a syntax error.
    helper.resourceProvider.modifyFile(helper.testFile, 'library lib');
    // There should still be no errors (file should not have been reread).
    await helper.onAnalysisComplete;
    expect(helper.getTestErrors(), hasLength(0));
    // Send a content change with a null content param--file should be
    // reread from disk.
    helper.sendContentChange(RemoveContentOverlay());
    // There should be errors now.
    await helper.onAnalysisComplete;
    expect(helper.getTestErrors(), hasLength(1));
  }

  Future<void> test_updateContent_changeOnDisk_normal() async {
    var helper = AnalysisTestHelper();
    await helper.createSingleFileProject('library A;');
    await helper.onAnalysisComplete;
    // There should be no errors
    expect(helper.getTestErrors(), hasLength(0));
    // Change file on disk, adding a syntax error.
    helper.resourceProvider.modifyFile(helper.testFile, 'library lib');
    // There should be errors now.
    await pumpEventQueue();
    await helper.onAnalysisComplete;
    expect(helper.getTestErrors(), hasLength(1));
  }

  Future<void> test_updateContent_fullContent() async {
    var helper = AnalysisTestHelper();
    await helper.createSingleFileProject('// empty');
    await helper.onAnalysisComplete;
    // no errors initially
    var errors = helper.getTestErrors();
    expect(errors, isEmpty);
    // update code
    helper.sendContentChange(AddContentOverlay('library lib'));
    // wait, there is an error
    await helper.onAnalysisComplete;
    errors = helper.getTestErrors();
    expect(errors, hasLength(1));
  }

  Future<void> test_updateContent_incremental() async {
    var helper = AnalysisTestHelper();
    var initialContent = 'library A;';
    await helper.createSingleFileProject(initialContent);
    await helper.onAnalysisComplete;
    // no errors initially
    var errors = helper.getTestErrors();
    expect(errors, isEmpty);
    // Add the file to the cache
    helper.sendContentChange(AddContentOverlay(initialContent));
    // update code
    helper.sendContentChange(ChangeContentOverlay(
        [SourceEdit('library '.length, 'A;'.length, 'lib')]));
    // wait, there is an error
    await helper.onAnalysisComplete;
    errors = helper.getTestErrors();
    expect(errors, hasLength(1));
  }

  Future<void> test_updateContent_outOfRange_beyondEnd() {
    return outOfRangeTest(SourceEdit(6, 6, 'foo'));
  }

  Future<void> test_updateContent_outOfRange_negativeLength() {
    return outOfRangeTest(SourceEdit(3, -1, 'foo'));
  }

  Future<void> test_updateContent_outOfRange_negativeOffset() {
    return outOfRangeTest(SourceEdit(-1, 3, 'foo'));
  }

  void test_updateOptions_invalid() {
    var request = Request('0', ANALYSIS_REQUEST_UPDATE_OPTIONS, {
      ANALYSIS_REQUEST_UPDATE_OPTIONS_OPTIONS: {'not-an-option': true}
    });
    var response = handler.handleRequest(request, NotCancelableToken());
    // Invalid options should be silently ignored.
    expect(response, isResponseSuccess('0'));
  }

  void test_updateOptions_null() {
    // null is allowed as a synonym for {}.
    var request = Request('0', ANALYSIS_REQUEST_UPDATE_OPTIONS,
        {ANALYSIS_REQUEST_UPDATE_OPTIONS_OPTIONS: null});
    var response = handler.handleRequest(request, NotCancelableToken());
    expect(response, isResponseSuccess('0'));
  }

  Future<Response> testSetAnalysisRoots(
      List<String> included, List<String> excluded) {
    return setRoots(
        included: included, excluded: excluded, validateSuccessResponse: false);
  }

  Future<void> xtest_getReachableSources_invalidSource() async {
    // TODO(brianwilkerson) Re-enable this test if we re-enable the
    // analysis.getReachableSources request.
    newFile('/project/a.dart', content: 'import "b.dart";');
    await server.setAnalysisRoots('0', ['/project/'], []);

    await server.onAnalysisComplete;

    var request = AnalysisGetReachableSourcesParams('/does/not/exist.dart')
        .toRequest('0');
    var response = handler.handleRequest(request, NotCancelableToken())!;
    var error = response.error!;
    expect(error.code, RequestErrorCode.GET_REACHABLE_SOURCES_INVALID_FILE);
  }

  Future<void> xtest_getReachableSources_validSources() async {
    // TODO(brianwilkerson) Re-enable this test if we re-enable the
    // analysis.getReachableSources request.
    var fileA = newFile('/project/a.dart', content: 'import "b.dart";').path;
    newFile('/project/b.dart');

    await server.setAnalysisRoots('0', ['/project/'], []);

    await server.onAnalysisComplete;

    var request = AnalysisGetReachableSourcesParams(fileA).toRequest('0');
    var response = handler.handleRequest(request, NotCancelableToken())!;

    var json = response.toJson()[Response.RESULT] as Map<String, dynamic>;

    // Sanity checks.
    expect(json['sources'], hasLength(6));
    expect(json['sources']['file:///project/a.dart'],
        unorderedEquals(['dart:core', 'file:///project/b.dart']));
    expect(json['sources']['file:///project/b.dart'], ['dart:core']);
  }
}

@reflectiveTest
class AnalysisDomainPubTest extends _AnalysisDomainTest {
  String get testFilePath => '$testPackageLibPath/test.dart';

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get workspaceRootPath => '/home';

  Future<void> test_fileSystem_addFile_analysisOptions() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([a_path, b_path]);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Both a.dart and b.dart are analyzed.
    _assertAnalyzedFiles(
      hasErrors: [a_path, b_path],
      notAnalyzed: [],
    );

    // Write the options file that excludes b.dart
    newAnalysisOptionsYamlFile(testPackageRootPath, content: r'''
analyzer:
  exclude:
    - lib/b.dart
''');

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Errors for all files were flushed, and only a.dart is reported again.
    _assertFlushedResults([a_path, b_path]);
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [b_path],
    );
  }

  Future<void> test_fileSystem_addFile_analysisOptions_analysis() async {
    var a_path = '$testPackageLibPath/a.dart';
    var options_path = '$testPackageRootPath/analysis_options.yaml';

    newFile(a_path, content: 'error');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [options_path],
    );

    // Add 'analysis_options.yaml' that has an error.
    newFile(options_path, content: '''
analyzer:
  error:
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Both files were analyzed.
    _assertAnalyzedFiles(
      hasErrors: [a_path, options_path],
      notAnalyzed: [],
    );
  }

  Future<void> test_fileSystem_addFile_androidManifestXml() async {
    var path = '$testPackageRootPath/AndroidManifest.xml';

    newFile('$testPackageLibPath/a.dart', content: '');

    newAnalysisOptionsYamlFile(testPackageRootPath, content: '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    await setRoots(included: [workspaceRootPath], excluded: []);

    newFile(path, content: '<manifest/>');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // No touch-screen.
    assertHasErrors(path);
  }

  Future<void> test_fileSystem_addFile_dart() async {
    var a_path = '$testPackageLibPath/a.dart';

    // We have to create the folder, otherwise there is nothing to watch.
    newFolder(testPackageLibPath);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We don't have a.dart yet.
    assertNoErrorsNotification(a_path);

    _createFilesWithErrors([a_path]);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We created a.dart, so it should be analyzed.
    assertHasErrors(a_path);
  }

  Future<void> test_fileSystem_addFile_dart_dotFolder() async {
    var a_path = '$projectPath/lib/.foo/a.dart';
    var b_path = '$projectPath/lib/b.dart';

    newFile(b_path, content: r'''
import '.foo/a.dart';
void f(A a) {}
''');

    await createProject();
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We don't have a.dart, so the import cannot be resolved.
    assertHasErrors(b_path);

    newFile(a_path, content: r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // 'a.dart' is in a dot-folder, so excluded from analysis.
    assertNoErrorsNotification(a_path);

    // We added a.dart with `A`, so no errors.
    assertNoErrors(b_path);
  }

  Future<void> test_fileSystem_addFile_dart_excluded() async {
    var a_path = '$projectPath/lib/a.dart';
    var b_path = '$projectPath/lib/b.dart';

    newAnalysisOptionsYamlFile(projectPath, content: r'''
analyzer:
  exclude:
    - "**/a.dart"
''');

    newFile(b_path, content: r'''
import 'a.dart';
void f(A a) {}
''');

    await createProject();
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We don't have a.dart, so the import cannot be resolved.
    assertHasErrors(b_path);

    newFile(a_path, content: r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We excluded 'a.dart' from analysis, no errors notification for it.
    assertNoErrorsNotification(a_path);

    // We added a.dart with `A`, so no errors.
    assertNoErrors(b_path);
  }

  Future<void> test_fileSystem_addFile_dotPackagesFile() async {
    var aaaLibPath = '/packages/aaa/lib';
    var a_path = '$aaaLibPath/a.dart';

    newFile(a_path, content: '''
class A {}
''');

    newFile(testFilePath, content: '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We cannot resolve `package:aaa/a.dart`
    assertHasErrors(testFilePath);

    // Write `.packages`, recreate analysis contexts.
    newDotPackagesFile(testPackageRootPath, content: '''
aaa:${toUriStr(aaaLibPath)}
''');

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_fileSystem_addFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    newFile('$testPackageLibPath/a.dart', content: '');

    // Make sure that it is a package.
    writePackageConfig(
      '$testPackageRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder(),
    );

    await setRoots(included: [workspaceRootPath], excluded: []);

    // No `fix_data.yaml` to analyze yet.
    assertNoErrorsNotification(path);

    // Create it, will be analyzed.
    newFile(path, content: '0: 1');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // And it has errors.
    assertHasErrors(path);

    // We don't recreate analysis contexts.
    _assertFlushedResults([]);
  }

  Future<void> test_fileSystem_addFile_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var a_path = '$aaaRootPath/lib/a.dart';

    newFile(a_path, content: '''
class A {}
''');

    newFile(testFilePath, content: '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We cannot resolve `package:aaa/a.dart`
    assertHasErrors(testFilePath);

    // Write `package_config.json`, recreate analysis contexts.
    writePackageConfig(
      '$testPackageRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder()..add(name: 'aaa', rootPath: aaaRootPath),
    );

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_fileSystem_addFile_pubspec_analysis() async {
    var a_path = '$testPackageLibPath/a.dart';
    var pubspec_path = '$testPackageRootPath/pubspec.yaml';

    newFile(a_path, content: 'error');

    // Write an empty file to force a new analysis context.
    // We look for `pubspec.yaml` files only in analysis context roots.
    newAnalysisOptionsYamlFile(testPackageRootPath, content: '');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [pubspec_path],
    );

    // Add a non-Dart file that we know how to analyze.
    newFile(pubspec_path, content: '''
name: sample
dependencies: true
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Both files were analyzed.
    _assertAnalyzedFiles(
      hasErrors: [a_path, pubspec_path],
      notAnalyzed: [],
    );
  }

  Future<void> test_fileSystem_addFile_unrelated() async {
    var a_path = '$testPackageLibPath/a.dart';
    var unrelated_path = '$testPackageRootPath/unrelated.txt';

    newFile(a_path, content: 'error');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [unrelated_path],
    );

    // Add an unrelated file, no analysis.
    newFile(unrelated_path, content: 'anything');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // No analysis.
    _assertFlushedResults([]);
    _assertAnalyzedFiles(hasErrors: [], notAnalyzed: [a_path]);
  }

  Future<void> test_fileSystem_changeFile_analysisOptions() async {
    var options_path = '$testPackageRootPath/analysis_options.yaml';
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';
    var c_path = '$testPackageLibPath/c.dart';

    _createFilesWithErrors([a_path, b_path, c_path]);

    // Exclude b.dart from analysis.
    newFile(options_path, content: r'''
analyzer:
  exclude:
    - lib/b.dart
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Only a.dart is analyzed, because b.dart is excluded.
    _assertAnalyzedFiles(
      hasErrors: [a_path, c_path],
      notAnalyzed: [b_path],
    );

    // Exclude c.dart from analysis.
    newFile(options_path, content: r'''
analyzer:
  exclude:
    - lib/c.dart
''');

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Errors for all files were flushed, a.dart and b.dart analyzed.
    _assertFlushedResults([options_path, a_path, c_path]);
    _assertAnalyzedFiles(
      hasErrors: [a_path, b_path],
      noErrors: [options_path],
      notAnalyzed: [c_path],
    );
  }

  Future<void> test_fileSystem_changeFile_androidManifestXml() async {
    var path = '$testPackageRootPath/AndroidManifest.xml';

    newFile('$testPackageLibPath/a.dart', content: '');

    // Has an error - no touch screen.
    newFile(path, content: '<manifest/>');

    newAnalysisOptionsYamlFile(testPackageRootPath, content: '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // Forget and check that we did.
    forgetReceivedErrors();
    assertNoErrorsNotification(path);

    // Update the file, so analyze it.
    newFile(path, content: '<manifest/>');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // An error was reported.
    assertHasErrors(path);
  }

  Future<void> test_fileSystem_changeFile_dart() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newFile(a_path, content: r'''
class A2 {}
''');

    newFile(b_path, content: r'''
import 'a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    assertNoErrors(a_path);
    assertHasErrors(b_path);
    forgetReceivedErrors();

    // Update a.dart so that b.dart has no error.
    newFile(a_path, content: 'class A {}');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // The update of a.dart fixed the error in b.dart
    assertNoErrors(a_path);
    assertNoErrors(b_path);
  }

  Future<void> test_fileSystem_changeFile_dart_dotFolder() async {
    var a_path = '$testPackageLibPath/.foo/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newFile(a_path, content: r'''
class B {}
''');

    newFile(b_path, content: r'''
import '.foo/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // 'a.dart' is in a dot-folder, so excluded from analysis.
    assertNoErrorsNotification(a_path);

    // We have `B`, not `A`, in a.dart, so has errors.
    assertHasErrors(b_path);

    newFile(a_path, content: r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // 'a.dart' is in a dot-folder, so excluded from analysis.
    assertNoErrorsNotification(a_path);

    // We changed a.dart, to have `A`, so no errors.
    assertNoErrors(b_path);
  }

  Future<void> test_fileSystem_changeFile_dart_excluded() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newAnalysisOptionsYamlFile(testPackageRootPath, content: r'''
analyzer:
  exclude:
    - "**/a.dart"
''');

    newFile(a_path, content: r'''
class B {}
''');

    newFile(b_path, content: r'''
import 'a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We excluded 'a.dart' from analysis, no errors notification for it.
    assertNoErrorsNotification(a_path);

    // We have `B`, not `A`, in a.dart, so has errors.
    assertHasErrors(b_path);

    newFile(a_path, content: r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We changed a.dart, to have `A`, so no errors.
    assertNoErrors(b_path);
  }

  Future<void> test_fileSystem_changeFile_dotPackagesFile() async {
    var aaaLibPath = '/packages/aaa/lib';
    var a_path = '$aaaLibPath/a.dart';

    newFile(a_path, content: '''
class A {}
''');

    // Write `.packages` empty, without `package:aaa`.
    newDotPackagesFile(testPackageRootPath, content: '');

    newFile(testFilePath, content: '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We cannot resolve `package:aaa/a.dart`
    assertHasErrors(testFilePath);

    // Write `.packages`, recreate analysis contexts.
    newDotPackagesFile(testPackageRootPath, content: '''
aaa:${toUriStr(aaaLibPath)}
''');

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_fileSystem_changeFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    newFile('$testPackageLibPath/a.dart', content: '');

    // Make sure that it is a package.
    writePackageConfig(
      '$testPackageRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder(),
    );

    // This file has an error.
    newFile(path, content: '0: 1');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The file was analyzed.
    assertHasErrors(path);

    // Replace with the context that does not have errors.
    newFile(path, content: r'''
version: 1
transforms: []
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // And it has errors.
    assertNoErrors(path);

    // We don't recreate analysis contexts.
    _assertFlushedResults([]);
  }

  Future<void> test_fileSystem_changeFile_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var a_path = '$aaaRootPath/lib/a.dart';

    newFile(a_path, content: '''
class A {}
''');

    // Write the empty file, without `package:aaa`.
    writePackageConfig(
      '$testPackageRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder(),
    );

    newFile(testFilePath, content: '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We cannot resolve `package:aaa/a.dart`
    assertHasErrors(testFilePath);

    // Write `package_config.json`, recreate analysis contexts.
    writePackageConfig(
      '$testPackageRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder()..add(name: 'aaa', rootPath: aaaRootPath),
    );

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_fileSystem_deleteFile_analysisOptions() async {
    var options_path = '$testPackageRootPath/analysis_options.yaml';
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([a_path, b_path]);

    // Exclude b.dart from analysis.
    newFile(options_path, content: r'''
analyzer:
  exclude:
    - lib/b.dart
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Only a.dart is analyzed, because b.dart is excluded.
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [b_path],
    );

    // Delete the options file.
    deleteFile(options_path);

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Errors for a.dart were flushed, a.dart and b.dart analyzed.
    _assertFlushedResults([options_path, a_path]);
    _assertAnalyzedFiles(
      hasErrors: [a_path, b_path],
      notAnalyzed: [options_path],
    );
  }

  Future<void> test_fileSystem_deleteFile_androidManifestXml() async {
    var path = '$testPackageRootPath/AndroidManifest.xml';

    newFile('$testPackageLibPath/a.dart', content: '');

    // Has an error - no touch screen.
    newFile(path, content: '<manifest/>');

    newAnalysisOptionsYamlFile(testPackageRootPath, content: '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // An error was reported.
    _assertAnalyzedFiles(hasErrors: [path], notAnalyzed: []);

    // Delete the file.
    deleteFile(path);
    await pumpEventQueue();

    // We received a flush notification.
    _assertAnalyzedFiles(hasErrors: [], notAnalyzed: [path]);
  }

  Future<void> test_fileSystem_deleteFile_dart() async {
    var a_path = '$testPackageLibPath/a.dart';

    _createFilesWithErrors([a_path]);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    assertHasErrors(a_path);

    deleteFile(a_path);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We deleted a.dart, its errors should be flushed.
    _assertFlushedResults([a_path]);
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_fileSystem_deleteFile_dart_excluded() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newAnalysisOptionsYamlFile(testPackageRootPath, content: r'''
analyzer:
  exclude:
    - "**/a.dart"
''');

    newFile(a_path, content: r'''
class A {}
''');

    newFile(b_path, content: r'''
import 'a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We excluded 'a.dart' from analysis, no errors notification for it.
    assertNoErrorsNotification(a_path);

    // We have `A` in a.dart, so no errors.
    assertNoErrors(b_path);

    deleteFile(a_path);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We deleted a.dart, so `A` cannot be resolved.
    assertHasErrors(b_path);
  }

  Future<void> test_fileSystem_deleteFile_dotPackagesFile() async {
    var aaaLibPath = '/packages/aaa/lib';
    var a_path = '$aaaLibPath/a.dart';

    newFile(a_path, content: '''
class A {}
''');

    newDotPackagesFile(testPackageRootPath, content: '''
aaa:${toUriStr(aaaLibPath)}
''');

    newFile(testFilePath, content: '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // Write `.packages`, recreate analysis contexts.
    deleteFile('$testPackageRootPath/.packages');

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We cannot resolve `package:aaa/a.dart`
    assertHasErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_fileSystem_deleteFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    newFile('$testPackageLibPath/a.dart', content: '');

    // Make sure that it is a package.
    writePackageConfig(
      '$testPackageRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder(),
    );

    // This file has an error.
    newFile(path, content: '0: 1');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The file was analyzed.
    _assertAnalyzedFiles(hasErrors: [path], notAnalyzed: []);

    // Delete the file.
    deleteFile(path);
    await pumpEventQueue();

    // We received a flush notification.
    _assertAnalyzedFiles(hasErrors: [], notAnalyzed: [path]);
  }

  Future<void> test_fileSystem_deleteFile_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var a_path = '$aaaRootPath/lib/a.dart';

    newFile(a_path, content: '''
class A {}
''');

    // Write the empty file, without `package:aaa`.
    writePackageConfig(
      '$testPackageRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder()..add(name: 'aaa', rootPath: aaaRootPath),
    );

    newFile(testFilePath, content: '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // Delete `package_config.json`, recreate analysis contexts.
    deleteFile(
      '$testPackageRootPath/.dart_tool/package_config.json',
    );

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We cannot resolve 'package:aaa/a.dart', so errors.
    assertHasErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_setRoots_dotPackagesFile() async {
    var aaaLibPath = '/packages/aaa/lib';
    var a_path = '$aaaLibPath/a.dart';

    newFile(a_path, content: '''
class A {}
''');

    newDotPackagesFile(testPackageRootPath, content: '''
aaa:${toUriStr(aaaLibPath)}
''');

    newFile(testFilePath, content: '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    // create project and wait for analysis
    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_setRoots_includedFile() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([a_path, b_path]);

    await setRoots(included: [a_path], excluded: []);

    // Only a.dart is included, so b.dart is not analyzed.
    await server.onAnalysisComplete;
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [b_path],
    );
  }

  Future<void> test_setRoots_includedFile_setRoots() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([a_path, b_path]);

    // Include only single file.
    await setRoots(included: [a_path], excluded: []);
    await server.onAnalysisComplete;

    // So, only a.dart is analyzed, and b.dart is not.
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [b_path],
    );

    // Include the folder that contains both a.dart and b.dart
    await setRoots(included: [testPackageRootPath], excluded: []);
    await server.onAnalysisComplete;

    // So, both a.dart and b.dart are analyzed.
    _assertAnalyzedFiles(
      hasErrors: [a_path, b_path],
      notAnalyzed: [],
    );
  }

  Future<void> test_setRoots_includedFileFolder() async {
    var includedFile = '$testPackageLibPath/a.dart';
    var includedFolder = '$testPackageLibPath/foo';
    var includedFolderFile1 = '$includedFolder/1.dart';
    var includedFolderFile2 = '$includedFolder/2.dart';
    var notIncludedFile = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([
      includedFile,
      includedFolderFile1,
      includedFolderFile2,
      notIncludedFile,
    ]);

    await setRoots(included: [includedFile, includedFolder], excluded: []);
    await server.onAnalysisComplete;

    // We can combine a file, and a folder as included paths.
    // And the file that is not in there is not analyzed.
    _assertAnalyzedFiles(hasErrors: [
      includedFile,
      includedFolderFile1,
      includedFolderFile2,
    ], notAnalyzed: [
      notIncludedFile,
    ]);
  }

  Future<void> test_setRoots_includedFolder_analysisOptions_exclude() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newAnalysisOptionsYamlFile(testPackageRootPath, content: '''
analyzer:
  exclude:
    - "**/b.dart"
''');

    _createFilesWithErrors([a_path, b_path]);

    await setRoots(included: [workspaceRootPath], excluded: []);

    // b.dart is excluded using the options file.
    await server.onAnalysisComplete;
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [b_path],
    );
  }

  @FailingTest(reason: 'Not implemented in ContextLocator')
  Future<void> test_setRoots_includedFolder_excludedFile() async {
    var a_path = '$testPackageLibPath/a.dart';
    var excluded_path = '$testPackageRootPath/excluded/b.dart';

    _createFilesWithErrors([a_path, excluded_path]);

    await setRoots(
      included: [workspaceRootPath],
      excluded: [excluded_path],
    );
    await server.onAnalysisComplete;

    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [excluded_path],
    );
  }

  Future<void> test_setRoots_includedFolder_excludedFolder() async {
    var a_path = '$testPackageLibPath/a.dart';
    var excluded_path = '$testPackageRootPath/excluded/b.dart';

    _createFilesWithErrors([a_path, excluded_path]);

    await setRoots(
      included: [workspaceRootPath],
      excluded: ['$testPackageRootPath/excluded'],
    );
    await server.onAnalysisComplete;

    // a.dart is analyzed, but b.dart is in the excluded folder.
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [excluded_path],
    );
  }

  Future<void> test_setRoots_notDartFile_androidManifestXml() async {
    var path = '$testPackageRootPath/AndroidManifest.xml';

    newFile('$testPackageLibPath/a.dart', content: '');

    newAnalysisOptionsYamlFile(testPackageRootPath, content: '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    newFile(path, content: '<manifest/>');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // No touch-screen.
    assertHasErrors(path);
  }

  Future<void> test_setRoots_notDartFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    // Make sure that it is a package.
    writePackageConfig(
      '$testPackageRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder(),
    );

    // So, `lib/fix_data.yaml` will be analyzed.
    newFile(path, content: '0: 1');

    await setRoots(included: [workspaceRootPath], excluded: []);

    assertHasErrors(path);
  }

  Future<void> test_setRoots_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var a_path = '$aaaRootPath/lib/a.dart';

    newFile(a_path, content: '''
class A {}
''');

    writePackageConfig(
      '$testPackageRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder()..add(name: 'aaa', rootPath: aaaRootPath),
    );

    newFile(testFilePath, content: '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    // create project and wait for analysis
    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }
}

/// A helper to test 'analysis.*' requests.
class AnalysisTestHelper with ResourceProviderMixin {
  late MockServerChannel serverChannel;
  late AnalysisServer server;
  late AnalysisDomainHandler handler;

  Map<AnalysisService, List<String>> analysisSubscriptions = {};

  Map<String, List<AnalysisError>> filesErrors = {};
  Map<String, List<HighlightRegion>> filesHighlights = {};
  Map<String, List<NavigationRegion>> filesNavigation = {};

  late String projectPath;
  late String testFile;
  late String testCode;

  AnalysisTestHelper() {
    projectPath = convertPath('/project');
    testFile = convertPath('/project/bin/test.dart');
    serverChannel = MockServerChannel();

    // Create an SDK in the mock file system.
    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    server = AnalysisServer(
        serverChannel,
        resourceProvider,
        AnalysisServerOptions(),
        DartSdkManager(sdkRoot.path),
        CrashReportingAttachmentsBuilder.empty,
        InstrumentationService.NULL_SERVICE);
    handler = AnalysisDomainHandler(server);
    // listen for notifications
    var notificationStream = serverChannel.notificationController.stream;
    notificationStream.listen((Notification notification) {
      if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
        var decoded = AnalysisErrorsParams.fromNotification(notification);
        filesErrors[decoded.file] = decoded.errors;
      }
      if (notification.event == ANALYSIS_NOTIFICATION_HIGHLIGHTS) {
        var params = AnalysisHighlightsParams.fromNotification(notification);
        filesHighlights[params.file] = params.regions;
      }
      if (notification.event == ANALYSIS_NOTIFICATION_NAVIGATION) {
        var params = AnalysisNavigationParams.fromNotification(notification);
        filesNavigation[params.file] = params.regions;
      }
    });
  }

  /// Returns a [Future] that completes when the server's analysis is complete.
  Future get onAnalysisComplete {
    return server.onAnalysisComplete;
  }

  void addAnalysisSubscription(AnalysisService service, String file) {
    // add file to subscription
    var files = analysisSubscriptions[service];
    if (files == null) {
      files = <String>[];
      analysisSubscriptions[service] = files;
    }
    files.add(file);
    // set subscriptions
    var request =
        AnalysisSetSubscriptionsParams(analysisSubscriptions).toRequest('0');
    handleSuccessfulRequest(request);
  }

  void addAnalysisSubscriptionHighlights(String file) {
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
  }

  void addAnalysisSubscriptionNavigation(String file) {
    addAnalysisSubscription(AnalysisService.NAVIGATION, file);
  }

  /// Creates an empty project `/project`.
  void createEmptyProject() {
    newFolder(projectPath);
    var request =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
  }

  /// Creates a project with a single Dart file `/project/bin/test.dart` with
  /// the given [code].
  Future<void> createSingleFileProject(code) async {
    testCode = _getCodeString(code);
    newFolder(projectPath);
    newFile(testFile, content: testCode);
    await setRoots(included: [projectPath], excluded: []);
  }

  /// Returns the offset of [search] in [testCode].
  /// Fails if not found.
  int findOffset(String search) {
    var offset = testCode.indexOf(search);
    expect(offset, isNot(-1));
    return offset;
  }

  /// Returns [AnalysisError]s recorded for the given [file].
  /// May be empty, but not `null`.
  List<AnalysisError> getErrors(String file) {
    var errors = filesErrors[file];
    if (errors != null) {
      return errors;
    }
    return <AnalysisError>[];
  }

  /// Returns highlights recorded for the given [file].
  /// May be empty, but not `null`.
  List<HighlightRegion> getHighlights(String file) {
    var highlights = filesHighlights[file];
    if (highlights != null) {
      return highlights;
    }
    return [];
  }

  /// Returns navigation regions recorded for the given [file].
  /// May be empty, but not `null`.
  List<NavigationRegion> getNavigation(String file) {
    var navigation = filesNavigation[file];
    if (navigation != null) {
      return navigation;
    }
    return [];
  }

  /// Returns [AnalysisError]s recorded for the [testFile].
  /// May be empty, but not `null`.
  List<AnalysisError> getTestErrors() {
    return getErrors(testFile);
  }

  /// Returns highlights recorded for the given [testFile].
  /// May be empty, but not `null`.
  List<HighlightRegion> getTestHighlights() {
    return getHighlights(testFile);
  }

  /// Returns navigation information recorded for the given [testFile].
  /// May be empty, but not `null`.
  List<NavigationRegion> getTestNavigation() {
    return getNavigation(testFile);
  }

  /// Validates that the given [request] is handled successfully.
  void handleSuccessfulRequest(Request request) {
    var response = handler.handleRequest(request, NotCancelableToken());
    expect(response, isResponseSuccess('0'));
  }

  /// Send an `updateContent` request for [testFile].
  void sendContentChange(HasToJson contentChange) {
    var request =
        AnalysisUpdateContentParams({testFile: contentChange}).toRequest('0');
    handleSuccessfulRequest(request);
  }

  Future<void> setRoots(
      {required List<String> included, required List<String> excluded}) async {
    var request =
        AnalysisSetAnalysisRootsParams(included, excluded).toRequest('0');
    var response = await waitResponse(request);
    expect(response, isResponseSuccess(request.id));
  }

  /// Stops the associated server.
  void stopServer() {
    server.done();
  }

  /// Completes with a successful [Response] for the given [request].
  /// Otherwise fails.
  Future<Response> waitResponse(Request request) async {
    return serverChannel.sendRequest(request);
  }

  static String _getCodeString(code) {
    if (code is List<String>) {
      code = code.join('\n');
    }
    return code as String;
  }
}

@reflectiveTest
class SetSubscriptionsTest extends AbstractAnalysisTest {
  Map<String, List<HighlightRegion>> filesHighlights = {};

  final Completer<void> _resultsAvailable = Completer();

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_HIGHLIGHTS) {
      var params = AnalysisHighlightsParams.fromNotification(notification);
      filesHighlights[params.file] = params.regions;
      _resultsAvailable.complete();
    }
  }

  Future<void> test_afterAnalysis() async {
    addTestFile('int V = 42;');
    await createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[testFile], isNotEmpty);
  }

  Future<void> test_afterAnalysis_noSuchFile() async {
    var file = convertPath('/no-such-file.dart');
    addTestFile('// no matter');
    await createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[file], isEmpty);
  }

  Future<void> test_afterAnalysis_packageFile_external() async {
    var pkgFile = newFile('/packages/pkgA/lib/libA.dart', content: '''
library lib_a;
class A {}
''').path;
    newDotPackagesFile('/project', content: 'pkgA:file:///packages/pkgA/lib');
    //
    addTestFile('''
import 'package:pkgA/libA.dart';
main() {
  new A();
}
''');
    await createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFile], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFile], isNotEmpty);
  }

  Future<void> test_afterAnalysis_packageFile_inRoot() async {
    var pkgA = convertPath('/pkgA');
    var pkgB = convertPath('/pkgA');
    var pkgFileA = newFile('$pkgA/lib/libA.dart', content: '''
library lib_a;
class A {}
''').path;
    newFile('$pkgA/lib/libB.dart', content: '''
import 'package:pkgA/libA.dart';
main() {
  new A();
}
''');
    // add 'pkgA' and 'pkgB' as projects
    newFolder(projectPath);
    await setRoots(included: [pkgA, pkgB], excluded: []);
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFileA], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFileA);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFileA], isNotEmpty);
  }

  Future<void> test_afterAnalysis_packageFile_notUsed() async {
    var pkgFile = newFile('/packages/pkgA/lib/libA.dart', content: '''
library lib_a;
class A {}
''').path;
    newDotPackagesFile('/project', content: 'pkgA:/packages/pkgA/lib');
    //
    addTestFile('// no "pkgA" reference');
    await createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFile], isNull);
    // make it a priority file, so make analyzable
    server.setPriorityFiles('0', [pkgFile]);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFile], isNotEmpty);
  }

  Future<void> test_afterAnalysis_sdkFile() async {
    var file = convertPath('/sdk/lib/core/core.dart');
    addTestFile('// no matter');
    await createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[file], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[file], isNotEmpty);
  }

  Future<void> test_beforeAnalysis() async {
    addTestFile('int V = 42;');
    await createProject();
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    // wait for analysis
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNotEmpty);
  }

  Future<void> test_sentToPlugins() async {
    addTestFile('int V = 42;');
    await createProject();
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    // wait for analysis
    await waitForTasksFinished();
    var params = pluginManager.analysisSetSubscriptionsParams!;
    var subscriptions = params.subscriptions;
    expect(subscriptions, hasLength(1));
    var files = subscriptions[plugin.AnalysisService.HIGHLIGHTS];
    expect(files, [testFile]);
  }
}

class _AnalysisDomainTest extends AbstractAnalysisTest {
  final Map<String, List<AnalysisError>> filesErrors = {};

  /// The files for which `analysis.flushResults` was received.
  final List<String> flushResults = [];

  void assertHasErrors(String path) {
    path = convertPath(path);
    expect(filesErrors[path], isNotEmpty, reason: path);
  }

  void assertNoErrors(String path) {
    path = convertPath(path);
    expect(filesErrors[path], isEmpty, reason: path);
  }

  void assertNoErrorsNotification(String path) {
    path = convertPath(path);
    expect(filesErrors[path], isNull, reason: path);
  }

  void forgetReceivedErrors() {
    filesErrors.clear();
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_FLUSH_RESULTS) {
      var decoded = AnalysisFlushResultsParams.fromNotification(notification);
      flushResults.addAll(decoded.files);
      decoded.files.forEach(filesErrors.remove);
    }
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    }
  }

  void writePackageConfig(String path, PackageConfigFileBuilder config) {
    newFile(path, content: config.toContent(toUriStr: toUriStr));
  }

  void _assertAnalyzedFiles({
    required List<String> hasErrors,
    List<String> noErrors = const [],
    required List<String> notAnalyzed,
  }) {
    for (var path in hasErrors) {
      assertHasErrors(path);
    }

    for (var path in noErrors) {
      assertNoErrors(path);
    }

    for (var path in notAnalyzed) {
      assertNoErrorsNotification(path);
    }

    filesErrors.clear();
  }

  void _assertFlushedResults(List<String> paths) {
    var convertedPaths = paths.map(convertPath).toList();
    expect(flushResults, unorderedEquals(convertedPaths));
    flushResults.clear();
  }

  /// Create files with a content that has a compile time error.
  /// So, when analyzed, these files will satisfy [assertHasErrors].
  void _createFilesWithErrors(List<String> paths) {
    for (var path in paths) {
      newFile(path, content: 'error');
    }
  }
}
