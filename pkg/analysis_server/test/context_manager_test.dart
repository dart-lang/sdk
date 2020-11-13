// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/utilities/null_string_sink.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/rules/avoid_as.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart';

import 'src/plugin/plugin_manager_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractContextManagerTest);
    defineReflectiveTests(ContextManagerWithOptionsTest);
  });
}

/// Wrapper around the test package's `fail` function.
///
/// Unlike the test package's `fail` function, this function is not annotated
/// with @alwaysThrows, so we can call it at the top of a test method without
/// causing the rest of the method to be flagged as dead code.
void _fail(String message) {
  fail(message);
}

@reflectiveTest
class AbstractContextManagerTest extends ContextManagerTest {
  void test_contextsInAnalysisRoot_nestedContext() {
    var subProjPath = join(projPath, 'subproj');
    var subProjFolder = newFolder(subProjPath);
    newFile(join(subProjPath, 'pubspec.yaml'), content: 'contents');
    var subProjFilePath = join(subProjPath, 'file.dart');
    newFile(subProjFilePath, content: 'contents');
    manager.setRoots(<String>[projPath], <String>[]);
    // Make sure that there really are contexts for both the main project and
    // the subproject.
    var projectFolder = getFolder(projPath);
    var projContextInfo = manager.getContextInfoFor(projectFolder);
    expect(projContextInfo, isNotNull);
    expect(projContextInfo.folder, projectFolder);
    var subProjContextInfo = manager.getContextInfoFor(subProjFolder);
    expect(subProjContextInfo, isNotNull);
    expect(subProjContextInfo.folder, subProjFolder);
    expect(projContextInfo.analysisDriver,
        isNot(equals(subProjContextInfo.analysisDriver)));
    // Check that getDriversInAnalysisRoot() works.
    var drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, isNotNull);
    expect(drivers, hasLength(2));
    expect(drivers, contains(projContextInfo.analysisDriver));
    expect(drivers, contains(subProjContextInfo.analysisDriver));
  }

  @failingTest
  Future<void> test_embedder_added() async {
    // NoSuchMethodError: The getter 'apiSignature' was called on null.
    // Receiver: null
    // Tried calling: apiSignature
    // dart:core                                                          Object.noSuchMethod
    // package:analyzer/src/dart/analysis/driver.dart 460:20              AnalysisDriver.configure
    // package:analysis_server/src/context_manager.dart 1043:16           ContextManagerImpl._checkForPackagespecUpdate
    // package:analysis_server/src/context_manager.dart 1553:5            ContextManagerImpl._handleWatchEvent
    //return super.test_embedder_added();
    _fail('NoSuchMethodError');
    // Create files.
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    newFile('$libPath/main.dart');
    newFile('$libPath/nope.dart');
    var embedderPath = '$projPath/embedder';
    newFile('$embedderPath/entry.dart');
    var embedderSrcPath = '$projPath/embedder/src';
    newFile('$embedderSrcPath/part.dart');

    // Setup _embedder.yaml.
    newFile('$libPath/_embedder.yaml', content: r'''
embedded_libs:
  "dart:foobar": "../embedder/entry.dart"
  "dart:typed_data": "../embedder/src/part"
  ''');

    var projectFolder = newFolder(projPath);

    // NOTE that this is Not in our package path yet.

    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);
    await pumpEventQueue();
    // Confirm that one driver / context was created.
    var drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, isNotNull);
    expect(drivers, hasLength(1));

    // No embedded libs yet.
    expect(sourceFactory.forUri('dart:typed_data'), isNull);

    // Add .packages file that introduces a dependency with embedded libs.
    newFile('$projPath/.packages', content: r'''
test_pack:lib/''');

    await pumpEventQueue();

    // Confirm that we still have just one driver / context.
    drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, isNotNull);
    expect(drivers, hasLength(1));

    // Embedded lib should be defined now.
    expect(sourceFactory.forUri('dart:typed_data'), isNotNull);
  }

  Future<void> test_embedder_packagespec() async {
    // Create files.
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    newFile('$libPath/main.dart');
    newFile('$libPath/nope.dart');
    var sdkExtPath = '$projPath/sdk_ext';
    newFile('$sdkExtPath/entry.dart');
    var sdkExtSrcPath = '$projPath/sdk_ext/src';
    newFile('$sdkExtSrcPath/part.dart');
    // Setup _embedder.yaml.
    newFile('$libPath/_embedder.yaml', content: r'''
embedded_libs:
  "dart:foobar": "../sdk_ext/entry.dart"
  "dart:typed_data": "../sdk_ext/src/part"
  ''');
    // Setup .packages file
    newFile('$projPath/.packages', content: r'''
sky_engine:lib/''');
    // Setup context.

    manager.setRoots(<String>[projPath], <String>[]);
    await pumpEventQueue();
    // Confirm that one context was created.
    var count = manager.numberOfContextsInAnalysisRoot(newFolder(projPath));
    expect(count, equals(1));
    var source = sourceFactory.forUri('dart:foobar');
    expect(source, isNotNull);
    expect(source.fullName, convertPath('/my/proj/sdk_ext/entry.dart'));
    // We can't find dart:core because we didn't list it in our
    // embedded_libs map.
    expect(sourceFactory.forUri('dart:core'), isNull);
    // We can find dart:typed_data because we listed it in our
    // embedded_libs map.
    expect(sourceFactory.forUri('dart:typed_data'), isNotNull);
  }

  void test_isInAnalysisRoot_excluded() {
    // prepare paths
    var project = convertPath('/project');
    var excludedFolder = convertPath('$project/excluded');
    // set roots
    newFolder(project);
    newFolder(excludedFolder);
    manager.setRoots(<String>[project], <String>[excludedFolder]);
    // verify
    expect(manager.isInAnalysisRoot(convertPath('$excludedFolder/test.dart')),
        isFalse);
  }

  void test_isInAnalysisRoot_inNestedContext() {
    var subProjPath = join(projPath, 'subproj');
    var subProjFolder = newFolder(subProjPath);
    newFile(join(subProjPath, 'pubspec.yaml'), content: 'contents');
    var subProjFilePath = join(subProjPath, 'file.dart');
    newFile(subProjFilePath, content: 'contents');
    manager.setRoots(<String>[projPath], <String>[]);
    // Make sure that there really is a context for the subproject.
    var subProjContextInfo = manager.getContextInfoFor(subProjFolder);
    expect(subProjContextInfo, isNotNull);
    expect(subProjContextInfo.folder, subProjFolder);
    // Check that isInAnalysisRoot() works.
    expect(manager.isInAnalysisRoot(subProjFilePath), isTrue);
  }

  void test_isInAnalysisRoot_inRoot() {
    manager.setRoots(<String>[projPath], <String>[]);
    expect(manager.isInAnalysisRoot('$projPath/test.dart'), isTrue);
  }

  void test_isInAnalysisRoot_notInRoot() {
    manager.setRoots(<String>[projPath], <String>[]);
    expect(manager.isInAnalysisRoot('/test.dart'), isFalse);
  }

  Future<void> test_packagesFolder_areAnalyzed() {
    // create a context with a pubspec.yaml file
    var pubspecPath = join(projPath, 'pubspec.yaml');
    newFile(pubspecPath, content: 'pubspec');
    // create a file in the "packages" folder
    var filePath1 = join(projPath, 'packages', 'file1.dart');
    var file1 = newFile(filePath1, content: 'contents');
    manager.setRoots(<String>[projPath], <String>[]);
    expect(callbacks.currentFilePaths, unorderedEquals([file1.path]));
    var filePath2 = join(projPath, 'packages', 'file2.dart');
    var file2 = newFile(filePath2, content: 'contents');
    return pumpEventQueue().then((_) {
      expect(callbacks.currentFilePaths,
          unorderedEquals([file1.path, file2.path]));
    });
  }

  Future<void> test_path_filter() async {
    // Setup context.
    var root = newFolder(projPath);
    manager.setRoots(<String>[projPath], <String>[]);
    expect(callbacks.currentFilePaths, isEmpty);
    // Set ignore patterns for context.
    var rootInfo = manager.getContextInfoFor(root);
    manager.setIgnorePatternsForContext(
        rootInfo, ['sdk_ext/**', 'lib/ignoreme.dart']);
    // Start creating files.
    newFile('$projPath/${ContextManagerImpl.PUBSPEC_NAME}');
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    newFile('$libPath/main.dart');
    newFile('$libPath/ignoreme.dart');
    var sdkExtPath = '$projPath/sdk_ext';
    newFile('$sdkExtPath/entry.dart');
    var sdkExtSrcPath = '$projPath/sdk_ext/src';
    newFile('$sdkExtSrcPath/part.dart');
    // Pump event loop so new files are discovered and added to context.
    await pumpEventQueue();
    // Verify that ignored files were ignored.
    var filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(convertPath('/my/proj/lib/main.dart')));
  }

  Future<void> test_refresh_folder_with_packagespec() {
    // create a context with a .packages file
    var packagespecFile = join(projPath, '.packages');
    newFile(packagespecFile, content: '');
    manager.setRoots(<String>[projPath], <String>[]);
    return pumpEventQueue().then((_) {
      expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
      callbacks.now++;
      manager.refresh(null);
      return pumpEventQueue().then((_) {
        expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
        expect(callbacks.currentContextTimestamps[projPath], callbacks.now);
      });
    });
  }

  // TODO(paulberry): This test only tests PackagesFileDisposition.
  // Once http://dartbug.com/23909 is fixed, add a test for sdk extensions
  // and PackageMapDisposition.
  Future<void> test_refresh_folder_with_packagespec_subfolders() {
    // Create a folder with no .packages file, containing two subfolders with
    // .packages files.
    var subdir1Path = join(projPath, 'subdir1');
    var subdir2Path = join(projPath, 'subdir2');
    var packagespec1Path = join(subdir1Path, '.packages');
    var packagespec2Path = join(subdir2Path, '.packages');
    newFile(packagespec1Path, content: '');
    newFile(packagespec2Path, content: '');
    manager.setRoots(<String>[projPath], <String>[]);
    return pumpEventQueue().then((_) {
      expect(callbacks.currentContextRoots,
          unorderedEquals([subdir1Path, subdir2Path, projPath]));
      callbacks.now++;
      manager.refresh(null);
      return pumpEventQueue().then((_) {
        expect(callbacks.currentContextRoots,
            unorderedEquals([subdir1Path, subdir2Path, projPath]));
        expect(callbacks.currentContextTimestamps[projPath], callbacks.now);
        expect(callbacks.currentContextTimestamps[subdir1Path], callbacks.now);
        expect(callbacks.currentContextTimestamps[subdir2Path], callbacks.now);
      });
    });
  }

  Future<void> test_refresh_folder_with_pubspec() {
    // create a context with a pubspec.yaml file
    var pubspecPath = join(projPath, 'pubspec.yaml');
    newFile(pubspecPath, content: 'pubspec');
    manager.setRoots(<String>[projPath], <String>[]);
    return pumpEventQueue().then((_) {
      expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
      callbacks.now++;
      manager.refresh(null);
      return pumpEventQueue().then((_) {
        expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
        expect(callbacks.currentContextTimestamps[projPath], callbacks.now);
      });
    });
  }

  Future<void> test_refresh_folder_with_pubspec_subfolders() {
    // Create a folder with no pubspec.yaml, containing two subfolders with
    // pubspec.yaml files.
    var subdir1Path = join(projPath, 'subdir1');
    var subdir2Path = join(projPath, 'subdir2');
    var pubspec1Path = join(subdir1Path, 'pubspec.yaml');
    var pubspec2Path = join(subdir2Path, 'pubspec.yaml');
    newFile(pubspec1Path, content: 'pubspec');
    newFile(pubspec2Path, content: 'pubspec');
    manager.setRoots(<String>[projPath], <String>[]);
    return pumpEventQueue().then((_) {
      expect(callbacks.currentContextRoots,
          unorderedEquals([subdir1Path, subdir2Path, projPath]));
      callbacks.now++;
      manager.refresh(null);
      return pumpEventQueue().then((_) {
        expect(callbacks.currentContextRoots,
            unorderedEquals([subdir1Path, subdir2Path, projPath]));
        expect(callbacks.currentContextTimestamps[projPath], callbacks.now);
        expect(callbacks.currentContextTimestamps[subdir1Path], callbacks.now);
        expect(callbacks.currentContextTimestamps[subdir2Path], callbacks.now);
      });
    });
  }

  Future<void> test_refresh_oneContext() {
    // create two contexts with pubspec.yaml files
    var pubspecPath = join(projPath, 'pubspec.yaml');
    newFile(pubspecPath, content: 'pubspec1');

    var proj2Path = convertPath('/my/proj2');
    newFolder(proj2Path);
    var pubspec2Path = join(proj2Path, 'pubspec.yaml');
    newFile(pubspec2Path, content: 'pubspec2');

    var roots = <String>[projPath, proj2Path];
    manager.setRoots(roots, <String>[]);
    return pumpEventQueue().then((_) {
      expect(callbacks.currentContextRoots, unorderedEquals(roots));
      var then = callbacks.now;
      callbacks.now++;
      manager.refresh([getFolder(proj2Path)]);
      return pumpEventQueue().then((_) {
        expect(callbacks.currentContextRoots, unorderedEquals(roots));
        expect(callbacks.currentContextTimestamps[projPath], then);
        expect(callbacks.currentContextTimestamps[proj2Path], callbacks.now);
      });
    });
  }

  void test_setRoots_addFolderWithDartFile() {
    var filePath = join(projPath, 'foo.dart');
    newFile(filePath, content: 'contents');
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    var filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    var drivers = manager.getDriversInAnalysisRoot(newFolder(projPath));
    expect(drivers, hasLength(1));
    expect(drivers[0], isNotNull);
    var result = sourceFactory.forUri('dart:async');
    expect(result, isNotNull);
  }

  void test_setRoots_addFolderWithDartFileInSubfolder() {
    var filePath = join(projPath, 'foo', 'bar.dart');
    newFile(filePath, content: 'contents');
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    var filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
  }

  void test_setRoots_addFolderWithDummyLink() {
    var filePath = join(projPath, 'foo.dart');
    resourceProvider.newDummyLink(filePath);
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    expect(callbacks.currentFilePaths, isEmpty);
  }

  void test_setRoots_addFolderWithNestedPackageSpec() {
    var examplePath =
        convertPath('$projPath/${ContextManagerTest.EXAMPLE_NAME}');
    var libPath = convertPath('$projPath/${ContextManagerTest.LIB_NAME}');

    newFile('$projPath/${ContextManagerImpl.PACKAGE_SPEC_NAME}');
    newFile('$libPath/main.dart');
    newFile('$examplePath/${ContextManagerImpl.PACKAGE_SPEC_NAME}');
    newFile('$examplePath/example.dart');

    manager.setRoots(<String>[projPath], <String>[]);

    expect(callbacks.currentContextRoots, hasLength(2));

    expect(callbacks.currentContextRoots, contains(projPath));
    var projSources = callbacks.currentFileSources(projPath);
    expect(projSources, hasLength(1));
    expect(projSources.first.uri, toUri('$libPath/main.dart'));

    expect(callbacks.currentContextRoots, contains(examplePath));
    var exampleSources = callbacks.currentFileSources(examplePath);
    expect(exampleSources, hasLength(1));
    expect(exampleSources.first.uri, toUri('$examplePath/example.dart'));
  }

  void test_setRoots_addFolderWithNestedPubspec() {
    var examplePath =
        convertPath('$projPath/${ContextManagerTest.EXAMPLE_NAME}');
    var libPath = convertPath('$projPath/${ContextManagerTest.LIB_NAME}');

    newFile('$projPath/${ContextManagerImpl.PUBSPEC_NAME}');
    newFile('$projPath/${ContextManagerImpl.PACKAGE_SPEC_NAME}',
        content: 'proj:lib/');
    newFile('$libPath/main.dart');
    newFile('$examplePath/${ContextManagerImpl.PUBSPEC_NAME}');
    newFile('$examplePath/example.dart');

    manager.setRoots(<String>[projPath], <String>[]);

    expect(callbacks.currentContextRoots, hasLength(2));

    expect(callbacks.currentContextRoots, contains(projPath));
    var projSources = callbacks.currentFileSources(projPath);
    expect(projSources, hasLength(1));
    expect(projSources.first.uri.toString(), 'package:proj/main.dart');

    expect(callbacks.currentContextRoots, contains(examplePath));
    var exampleSources = callbacks.currentFileSources(examplePath);
    expect(exampleSources, hasLength(1));
    expect(exampleSources.first.uri, toUri('$examplePath/example.dart'));
  }

  void test_setRoots_addFolderWithoutPubspec() {
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_addFolderWithPackagespec() {
    var packagespecPath = join(projPath, '.packages');
    var testLib = convertPath('/home/somebody/.pub/cache/unittest-0.9.9/lib');
    newFile(packagespecPath, content: 'unittest:${toUriStr(testLib)}');
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    var mainFile = newFile('$libPath/main.dart');
    var source = mainFile.createSource();

    manager.setRoots(<String>[projPath], <String>[]);

    // verify
    expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
    expect(callbacks.currentFilePaths, hasLength(1));

    // smoketest resolution
    var resolvedSource =
        sourceFactory.resolveUri(source, 'package:unittest/unittest.dart');
    expect(resolvedSource, isNotNull);
    expect(resolvedSource.fullName, convertPath('$testLib/unittest.dart'));
  }

  void test_setRoots_addFolderWithPubspec() {
    var pubspecPath = join(projPath, 'pubspec.yaml');
    newFile(pubspecPath, content: 'pubspec');
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_addFolderWithPubspec_andPackagespec() {
    var pubspecPath = join(projPath, 'pubspec.yaml');
    var packagespecPath = join(projPath, '.packages');
    newFile(pubspecPath, content: 'pubspec');
    newFile(packagespecPath, content: '');
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    callbacks.assertContextPaths([projPath]);
  }

  void test_setRoots_addFolderWithPubspecAndLib() {
    var binPath = '$projPath/${ContextManagerTest.BIN_NAME}';
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    var srcPath = '$libPath/${ContextManagerTest.SRC_NAME}';
    var testPath = '$projPath/${ContextManagerTest.TEST_NAME}';

    newFile('$projPath/${ContextManagerImpl.PUBSPEC_NAME}');
    newFile('$projPath/${ContextManagerImpl.PACKAGE_SPEC_NAME}',
        content: 'proj:lib/');
    var appPath = newFile('$binPath/app.dart').path;
    newFile('$libPath/main.dart');
    newFile('$srcPath/internal.dart');
    var testFilePath = newFile('$testPath/main_test.dart').path;

    manager.setRoots(<String>[projPath], <String>[]);
    var sources = callbacks.currentFileSources(projPath);

    expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
    expect(sources, hasLength(4));
    var uris = sources.map((Source source) => source.uri.toString()).toList();
    expect(uris, contains(toUriStr(appPath)));
    expect(uris, contains('package:proj/main.dart'));
    expect(uris, contains('package:proj/src/internal.dart'));
    expect(uris, contains(toUriStr(testFilePath)));
  }

  void test_setRoots_addFolderWithPubspecAndPackagespecFolders() {
    // prepare paths
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var subProjectA = convertPath('$root/sub/aaa');
    var subProjectB = convertPath('$root/sub/sub2/bbb');
    var subProjectA_file = convertPath('$subProjectA/bin/a.dart');
    var subProjectB_file = convertPath('$subProjectB/bin/b.dart');
    // create files
    newFile('$subProjectA/pubspec.yaml', content: 'pubspec');
    newFile('$subProjectB/pubspec.yaml', content: 'pubspec');
    newFile('$subProjectA/.packages');
    newFile('$subProjectB/.packages');

    newFile(rootFile, content: 'library root;');
    newFile(subProjectA_file, content: 'library a;');
    newFile(subProjectB_file, content: 'library b;');

    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root, subProjectA, subProjectB]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProjectA, [subProjectA_file]);
    callbacks.assertContextFiles(subProjectB, [subProjectB_file]);
  }

  void test_setRoots_addFolderWithPubspecFolders() {
    // prepare paths
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var projectA = convertPath('$root/sub/aaa');
    var projectALib = convertPath('$root/sub/aaa/lib');
    var subProjectA_file = convertPath('$projectA/bin/a.dart');
    var projectB = convertPath('$root/sub/sub2/bbb');
    var projectBLib = convertPath('$root/sub/sub2/bbb/lib');
    var subProjectB_file = convertPath('$projectB/bin/b.dart');
    // create files
    newFile('$projectA/${ContextManagerImpl.PUBSPEC_NAME}');
    newFile('$projectA/${ContextManagerImpl.PACKAGE_SPEC_NAME}',
        content: 'foo:lib/');
    newFile('$projectB/${ContextManagerImpl.PUBSPEC_NAME}');
    newFile('$projectB/${ContextManagerImpl.PACKAGE_SPEC_NAME}',
        content: 'bar:lib/');
    newFile(rootFile, content: 'library root;');
    newFile(subProjectA_file, content: 'library a;');
    newFile(subProjectB_file, content: 'library b;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root, projectA, projectB]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(projectA, [subProjectA_file]);
    callbacks.assertContextFiles(projectB, [subProjectB_file]);
    // verify package maps
    expect(_packageMap(root), isEmpty);
    expect(
        _packageMap(projectA),
        equals({
          'foo': [getFolder(projectALib)]
        }));
    expect(
        _packageMap(projectB),
        equals({
          'bar': [getFolder(projectBLib)]
        }));
  }

  void test_setRoots_exclude_newRoot_withExcludedFile() {
    // prepare paths
    var project = convertPath('/project');
    var file1 = convertPath('$project/file1.dart');
    var file2 = convertPath('$project/file2.dart');
    // create files
    newFile(file1, content: '// 1');
    newFile(file2, content: '// 2');
    // set roots
    manager.setRoots(<String>[project], <String>[file1]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file2]);
  }

  void test_setRoots_exclude_newRoot_withExcludedFolder() {
    // prepare paths
    var project = convertPath('/project');
    var folderA = convertPath('$project/aaa');
    var folderB = convertPath('$project/bbb');
    var fileA = convertPath('$folderA/a.dart');
    var fileB = convertPath('$folderB/b.dart');
    // create files
    newFile(fileA, content: 'library a;');
    newFile(fileB, content: 'library b;');
    // set roots
    manager.setRoots(<String>[project], <String>[folderB]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  void test_setRoots_exclude_sameRoot_addExcludedFile() {
    // prepare paths
    var project = convertPath('/project');
    var file1 = convertPath('$project/file1.dart');
    var file2 = convertPath('$project/file2.dart');
    // create files
    newFile(file1, content: '// 1');
    newFile(file2, content: '// 2');
    // set roots
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1, file2]);
    // exclude "2"
    manager.setRoots(<String>[project], <String>[file2]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1]);
  }

  void test_setRoots_exclude_sameRoot_addExcludedFolder() {
    // prepare paths
    var project = convertPath('/project');
    var folderA = convertPath('$project/aaa');
    var folderB = convertPath('$project/bbb');
    var fileA = convertPath('$folderA/a.dart');
    var fileB = convertPath('$folderB/b.dart');
    // create files
    newFile(fileA, content: 'library a;');
    newFile(fileB, content: 'library b;');
    // initially both "aaa/a" and "bbb/b" are included
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA, fileB]);
    // exclude "bbb/"
    manager.setRoots(<String>[project], <String>[folderB]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  void test_setRoots_exclude_sameRoot_removeExcludedFile() {
    // prepare paths
    var project = convertPath('/project');
    var file1 = convertPath('$project/file1.dart');
    var file2 = convertPath('$project/file2.dart');
    // create files
    newFile(file1, content: '// 1');
    newFile(file2, content: '// 2');
    // set roots
    manager.setRoots(<String>[project], <String>[file2]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1]);
    // stop excluding "2"
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1, file2]);
  }

  void test_setRoots_exclude_sameRoot_removeExcludedFile_inFolder() {
    // prepare paths
    var project = convertPath('/project');
    var file1 = convertPath('$project/bin/file1.dart');
    var file2 = convertPath('$project/bin/file2.dart');
    // create files
    newFile(file1, content: '// 1');
    newFile(file2, content: '// 2');
    // set roots
    manager.setRoots(<String>[project], <String>[file2]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1]);
    // stop excluding "2"
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1, file2]);
  }

  void test_setRoots_exclude_sameRoot_removeExcludedFolder() {
    // prepare paths
    var project = convertPath('/project');
    var folderA = convertPath('$project/aaa');
    var folderB = convertPath('$project/bbb');
    var fileA = convertPath('$folderA/a.dart');
    var fileB = convertPath('$folderB/b.dart');
    // create files
    newFile(fileA, content: 'library a;');
    newFile(fileB, content: 'library b;');
    // exclude "bbb/"
    manager.setRoots(<String>[project], <String>[folderB]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    // stop excluding "bbb/"
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA, fileB]);
  }

  void test_setRoots_ignoreDocFolder() {
    var project = convertPath('/project');
    var fileA = convertPath('$project/foo.dart');
    var fileB = convertPath('$project/lib/doc/bar.dart');
    var fileC = convertPath('$project/doc/bar.dart');
    newFile(fileA, content: '');
    newFile(fileB, content: '');
    newFile(fileC, content: '');
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA, fileB]);
  }

  void test_setRoots_nested_includedByOuter_innerFirst() {
    var project = convertPath('/project');
    var projectPubspec = convertPath('$project/pubspec.yaml');
    var example = convertPath('$project/example');
    var examplePubspec = convertPath('$example/pubspec.yaml');
    // create files
    newFile(projectPubspec, content: 'name: project');
    newFile(examplePubspec, content: 'name: example');
    manager.setRoots(<String>[example, project], <String>[]);
    // verify
    {
      var rootInfo = manager.rootInfo;
      expect(rootInfo.children, hasLength(1));
      {
        var projectInfo = rootInfo.children[0];
        expect(projectInfo.folder.path, project);
        expect(projectInfo.children, hasLength(1));
        {
          var exampleInfo = projectInfo.children[0];
          expect(exampleInfo.folder.path, example);
          expect(exampleInfo.children, isEmpty);
        }
      }
    }
    expect(callbacks.currentContextRoots, unorderedEquals([project, example]));
  }

  void test_setRoots_nested_includedByOuter_outerPubspec() {
    var project = convertPath('/project');
    var projectPubspec = convertPath('$project/pubspec.yaml');
    var example = convertPath('$project/example');
    // create files
    newFile(projectPubspec, content: 'name: project');
    newFolder(example);
    manager.setRoots(<String>[project, example], <String>[]);
    // verify
    {
      var rootInfo = manager.rootInfo;
      expect(rootInfo.children, hasLength(1));
      {
        var projectInfo = rootInfo.children[0];
        expect(projectInfo.folder.path, project);
        expect(projectInfo.children, isEmpty);
      }
    }
    expect(callbacks.currentContextRoots, unorderedEquals([project]));
  }

  void test_setRoots_nested_includedByOuter_twoPubspecs() {
    var project = convertPath('/project');
    var projectPubspec = convertPath('$project/pubspec.yaml');
    var example = convertPath('$project/example');
    var examplePubspec = convertPath('$example/pubspec.yaml');
    // create files
    newFile(projectPubspec, content: 'name: project');
    newFile(examplePubspec, content: 'name: example');
    manager.setRoots(<String>[project, example], <String>[]);
    // verify
    {
      var rootInfo = manager.rootInfo;
      expect(rootInfo.children, hasLength(1));
      {
        var projectInfo = rootInfo.children[0];
        expect(projectInfo.folder.path, project);
        expect(projectInfo.children, hasLength(1));
        {
          var exampleInfo = projectInfo.children[0];
          expect(exampleInfo.folder.path, example);
          expect(exampleInfo.children, isEmpty);
        }
      }
    }
    expect(callbacks.currentContextRoots, unorderedEquals([project, example]));
  }

  void test_setRoots_newlyAddedFoldersGetProperPackageMap() {
    var packagePath = convertPath('/package/foo');
    newFile('$projPath/${ContextManagerImpl.PACKAGE_SPEC_NAME}',
        content: 'foo:${toUriStr('/package/foo')}');
    var packageFolder = newFolder(packagePath);
    manager.setRoots(<String>[projPath], <String>[]);
    expect(
        _currentPackageMap,
        equals({
          'foo': [packageFolder]
        }));
  }

  void test_setRoots_noContext_excludedFolder() {
    // prepare paths
    var project = convertPath('/project');
    var excludedFolder = convertPath('$project/excluded');
    var excludedPubspec = convertPath('$excludedFolder/pubspec.yaml');
    // create files
    newFile(excludedPubspec, content: 'name: ignore-me');
    // set "/project", and exclude "/project/excluded"
    manager.setRoots(<String>[project], <String>[excludedFolder]);
    callbacks.assertContextPaths([project]);
  }

  void test_setRoots_noContext_inDotFolder() {
    var pubspecPath = join(projPath, '.pub', 'pubspec.yaml');
    newFile(pubspecPath, content: 'name: test');
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    expect(callbacks.currentContextRoots, hasLength(1));
    expect(callbacks.currentContextRoots, contains(projPath));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_packageResolver() {
    var filePath = join(projPath, 'lib', 'foo.dart');
    newFile('$projPath/${ContextManagerImpl.PACKAGE_SPEC_NAME}',
        content: 'foo:lib/');
    newFile(filePath, content: 'contents');
    manager.setRoots(<String>[projPath], <String>[]);

    var drivers = manager.getDriversInAnalysisRoot(newFolder(projPath));
    expect(drivers, hasLength(1));
    expect(drivers[0], isNotNull);
    var result = sourceFactory.forUri('package:foo/foo.dart');
    expect(result.fullName, filePath);
  }

  void test_setRoots_packagesFolder_hasContext() {
    var pubspecPath = join(projPath, 'packages', 'pubspec.yaml');
    newFile(pubspecPath, content: 'name: test');
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    expect(callbacks.currentContextRoots, hasLength(2));
    expect(callbacks.currentContextRoots, contains(projPath));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_pathContainsDotFile() {
    // If the path to a file (relative to the context root) contains a folder
    // whose name begins with '.', then the file is ignored.
    var project = convertPath('/project');
    var fileA = convertPath('$project/foo.dart');
    var fileB = convertPath('$project/.pub/bar.dart');
    newFile(fileA, content: '');
    newFile(fileB, content: '');
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  void test_setRoots_removeFolderWithoutPubspec() {
    // add one root - there is a context
    manager.setRoots(<String>[projPath], <String>[]);
    expect(callbacks.currentContextRoots, hasLength(1));
    // set empty roots - no contexts
    manager.setRoots(<String>[], <String>[]);
    expect(callbacks.currentContextRoots, hasLength(0));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_removeFolderWithPackagespec() {
    // create a pubspec
    var pubspecPath = join(projPath, '.packages');
    newFile(pubspecPath, content: '');
    // add one root - there is a context
    manager.setRoots(<String>[projPath], <String>[]);
    expect(manager.changeSubscriptions, hasLength(1));
    expect(callbacks.currentContextRoots, hasLength(1));
    // set empty roots - no contexts
    manager.setRoots(<String>[], <String>[]);
    expect(manager.changeSubscriptions, hasLength(0));
    expect(callbacks.currentContextRoots, hasLength(0));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_removeFolderWithPackagespecFolder() {
    // prepare paths
    var projectA = convertPath('/projectA');
    var projectB = convertPath('/projectB');
    var subProjectA = convertPath('$projectA/sub');
    var subProjectB = convertPath('$projectB/sub');
    var projectA_file = convertPath('$projectA/a.dart');
    var projectB_file = convertPath('$projectB/a.dart');
    var subProjectA_pubspec = convertPath('$subProjectA/.packages');
    var subProjectB_pubspec = convertPath('$subProjectB/.packages');
    var subProjectA_file = convertPath('$subProjectA/bin/sub_a.dart');
    var subProjectB_file = convertPath('$subProjectB/bin/sub_b.dart');
    // create files
    newFile(projectA_file, content: '// a');
    newFile(projectB_file, content: '// b');
    newFile(subProjectA_pubspec, content: '');
    newFile(subProjectB_pubspec, content: '');
    newFile(subProjectA_file, content: '// sub-a');
    newFile(subProjectB_file, content: '// sub-b');
    // set roots
    manager.setRoots(<String>[projectA, projectB], <String>[]);
    callbacks
        .assertContextPaths([projectA, subProjectA, projectB, subProjectB]);
    callbacks.assertContextFiles(projectA, [projectA_file]);
    callbacks.assertContextFiles(projectB, [projectB_file]);
    callbacks.assertContextFiles(subProjectA, [subProjectA_file]);
    callbacks.assertContextFiles(subProjectB, [subProjectB_file]);
    // remove "projectB"
    manager.setRoots(<String>[projectA], <String>[]);
    callbacks.assertContextPaths([projectA, subProjectA]);
    callbacks.assertContextFiles(projectA, [projectA_file]);
    callbacks.assertContextFiles(subProjectA, [subProjectA_file]);
  }

  void test_setRoots_removeFolderWithPubspec() {
    // create a pubspec
    var pubspecPath = join(projPath, 'pubspec.yaml');
    newFile(pubspecPath, content: 'pubspec');
    // add one root - there is a context
    manager.setRoots(<String>[projPath], <String>[]);
    expect(callbacks.currentContextRoots, hasLength(1));
    // set empty roots - no contexts
    manager.setRoots(<String>[], <String>[]);
    expect(callbacks.currentContextRoots, hasLength(0));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_removeFolderWithPubspecFolder() {
    // prepare paths
    var projectA = convertPath('/projectA');
    var projectB = convertPath('/projectB');
    var subProjectA = convertPath('$projectA/sub');
    var subProjectB = convertPath('$projectB/sub');
    var projectA_file = convertPath('$projectA/a.dart');
    var projectB_file = convertPath('$projectB/a.dart');
    var subProjectA_pubspec = convertPath('$subProjectA/pubspec.yaml');
    var subProjectB_pubspec = convertPath('$subProjectB/pubspec.yaml');
    var subProjectA_file = convertPath('$subProjectA/bin/sub_a.dart');
    var subProjectB_file = convertPath('$subProjectB/bin/sub_b.dart');
    // create files
    newFile(projectA_file, content: '// a');
    newFile(projectB_file, content: '// b');
    newFile(subProjectA_pubspec, content: 'pubspec');
    newFile(subProjectB_pubspec, content: 'pubspec');
    newFile(subProjectA_file, content: '// sub-a');
    newFile(subProjectB_file, content: '// sub-b');
    // set roots
    manager.setRoots(<String>[projectA, projectB], <String>[]);
    callbacks
        .assertContextPaths([projectA, subProjectA, projectB, subProjectB]);
    callbacks.assertContextFiles(projectA, [projectA_file]);
    callbacks.assertContextFiles(projectB, [projectB_file]);
    callbacks.assertContextFiles(subProjectA, [subProjectA_file]);
    callbacks.assertContextFiles(subProjectB, [subProjectB_file]);
    // remove "projectB"
    manager.setRoots(<String>[projectA], <String>[]);
    callbacks.assertContextPaths([projectA, subProjectA]);
    callbacks.assertContextFiles(projectA, [projectA_file]);
    callbacks.assertContextFiles(subProjectA, [subProjectA_file]);
  }

  void test_setRoots_rootPathContainsDotFile() {
    // If the path to the context root itself contains a folder whose name
    // begins with '.', then that is not sufficient to cause any files in the
    // context to be ignored.
    var project = convertPath('/.pub/project');
    var fileA = convertPath('$project/foo.dart');
    newFile(fileA, content: '');
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  Future<void> test_watch_addDummyLink() {
    manager.setRoots(<String>[projPath], <String>[]);
    // empty folder initially
    expect(callbacks.currentFilePaths, isEmpty);
    // add link
    var filePath = join(projPath, 'foo.dart');
    resourceProvider.newDummyLink(filePath);
    // the link was ignored
    return pumpEventQueue().then((_) {
      expect(callbacks.currentFilePaths, isEmpty);
    });
  }

  Future<void> test_watch_addFile() {
    manager.setRoots(<String>[projPath], <String>[]);
    // empty folder initially
    expect(callbacks.currentFilePaths, hasLength(0));
    // add file
    var filePath = join(projPath, 'foo.dart');
    newFile(filePath, content: 'contents');
    // the file was added
    return pumpEventQueue().then((_) {
      var filePaths = callbacks.currentFilePaths;
      expect(filePaths, hasLength(1));
      expect(filePaths, contains(filePath));
    });
  }

  Future<void> test_watch_addFile_excluded() {
    // prepare paths
    var project = convertPath('/project');
    var folderA = convertPath('$project/aaa');
    var folderB = convertPath('$project/bbb');
    var fileA = convertPath('$folderA/a.dart');
    var fileB = convertPath('$folderB/b.dart');
    // create files
    newFile(fileA, content: 'library a;');
    // set roots
    manager.setRoots(<String>[project], <String>[folderB]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    // add a file, ignored as excluded
    newFile(fileB, content: 'library b;');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([project]);
      callbacks.assertContextFiles(project, [fileA]);
    });
  }

  Future<void> test_watch_addFile_inDocFolder_inner() {
    // prepare paths
    var project = convertPath('/project');
    var fileA = convertPath('$project/a.dart');
    var fileB = convertPath('$project/lib/doc/b.dart');
    // create files
    newFile(fileA, content: '');
    // set roots
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    // add a "lib/doc" file, it is not ignored
    newFile(fileB, content: '');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([project]);
      callbacks.assertContextFiles(project, [fileA, fileB]);
    });
  }

  Future<void> test_watch_addFile_inDocFolder_topLevel() {
    // prepare paths
    var project = convertPath('/project');
    var fileA = convertPath('$project/a.dart');
    var fileB = convertPath('$project/doc/b.dart');
    // create files
    newFile(fileA, content: '');
    // set roots
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    // add a "doc" file, it is ignored
    newFile(fileB, content: '');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([project]);
      callbacks.assertContextFiles(project, [fileA]);
    });
  }

  Future<void> test_watch_addFile_pathContainsDotFile() async {
    // If a file is added and the path to it (relative to the context root)
    // contains a folder whose name begins with '.', then the file is ignored.
    var project = convertPath('/project');
    var fileA = convertPath('$project/foo.dart');
    var fileB = convertPath('$project/.pub/bar.dart');
    newFile(fileA, content: '');
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    newFile(fileB, content: '');
    await pumpEventQueue();
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  Future<void> test_watch_addFile_rootPathContainsDotFile() async {
    // If a file is added and the path to the context contains a folder whose
    // name begins with '.', then the file is not ignored.
    var project = convertPath('/.pub/project');
    var fileA = convertPath('$project/foo.dart');
    var fileB = convertPath('$project/bar/baz.dart');
    newFile(fileA, content: '');
    manager.setRoots(<String>[project], <String>[]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    newFile(fileB, content: '');
    await pumpEventQueue();
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA, fileB]);
  }

  Future<void> test_watch_addFileInSubfolder() {
    manager.setRoots(<String>[projPath], <String>[]);
    // empty folder initially
    expect(callbacks.currentFilePaths, hasLength(0));
    // add file in subfolder
    var filePath = join(projPath, 'foo', 'bar.dart');
    newFile(filePath, content: 'contents');
    // the file was added
    return pumpEventQueue().then((_) {
      var filePaths = callbacks.currentFilePaths;
      expect(filePaths, hasLength(1));
      expect(filePaths, contains(filePath));
    });
  }

  Future<void> test_watch_addPackagespec_toRoot() {
    // prepare paths
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var rootPackagespec = convertPath('$root/.packages');
    // create files
    newFile(rootFile, content: 'library root;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    // add packagespec - still just one root
    newFile(rootPackagespec, content: '');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile]);
      // TODO(pquitslund): verify that a new source factory is created --
      // likely this will need to happen in a corresponding ServerContextManagerTest.
    });
  }

  Future<void> test_watch_addPackagespec_toSubFolder() {
    // prepare paths
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var subProject = convertPath('$root/sub/aaa');
    var subPubspec = convertPath('$subProject/.packages');
    var subFile = convertPath('$subProject/bin/a.dart');
    // create files
    newFile(rootFile, content: 'library root;');
    newFile(subFile, content: 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile, subFile]);
    // add .packages
    newFile(subPubspec, content: '');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(root, [rootFile]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  Future<void> test_watch_addPackagespec_toSubFolder_ofSubFolder() {
    // prepare paths
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var subProject = convertPath('$root/sub');
    var subPubspec = convertPath('$subProject/.packages');
    var subFile = convertPath('$subProject/bin/sub.dart');
    var subSubPubspec = convertPath('$subProject/subsub/.packages');
    // create files
    newFile(rootFile, content: 'library root;');
    newFile(subPubspec, content: '');
    newFile(subFile, content: 'library sub;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root, subProject]);
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);
    // add pubspec - ignore, because is already in a packagespec-based context
    newFile(subSubPubspec, content: '');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(root, [rootFile]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  Future<void> test_watch_addPackagespec_toSubFolder_withPubspec() {
    // prepare paths
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var subProject = convertPath('$root/sub/aaa');
    var subPackagespec = convertPath('$subProject/.packages');
    var subPubspec = convertPath('$subProject/pubspec.yaml');
    var subFile = convertPath('$subProject/bin/a.dart');
    // create files
    newFile(subPubspec, content: 'pubspec');
    newFile(rootFile, content: 'library root;');
    newFile(subFile, content: 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root, subProject]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);

    // add .packages
    newFile(subPackagespec, content: '');
    return pumpEventQueue().then((_) {
      // Should NOT create another context.
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(root, [rootFile]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  Future<void> test_watch_addPubspec_toRoot() {
    // prepare paths
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var rootPubspec = convertPath('$root/pubspec.yaml');
    // create files
    newFile(rootFile, content: 'library root;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    // add pubspec - still just one root
    newFile(rootPubspec, content: 'pubspec');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile]);
    });
  }

  Future<void> test_watch_addPubspec_toSubFolder() {
    // prepare paths
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var subProject = convertPath('$root/sub/aaa');
    var subPubspec = convertPath('$subProject/pubspec.yaml');
    var subFile = convertPath('$subProject/bin/a.dart');
    // create files
    newFile(rootFile, content: 'library root;');
    newFile(subFile, content: 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile, subFile]);
    // add pubspec
    newFile(subPubspec, content: 'pubspec');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(root, [rootFile]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  Future<void> test_watch_addPubspec_toSubFolder_ofSubFolder() {
    // prepare paths
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var subProject = convertPath('$root/sub');
    var subPubspec = convertPath('$subProject/pubspec.yaml');
    var subFile = convertPath('$subProject/bin/sub.dart');
    var subSubPubspec = convertPath('$subProject/subsub/pubspec.yaml');
    // create files
    newFile(rootFile, content: 'library root;');
    newFile(subPubspec, content: 'pubspec');
    newFile(subFile, content: 'library sub;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root, subProject]);
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);
    // add pubspec - ignore, because is already in a pubspec-based context
    newFile(subSubPubspec, content: 'pubspec');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(root, [rootFile]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  Future<void> test_watch_deleteFile() {
    var filePath = join(projPath, 'foo.dart');
    // add root with a file
    var file = newFile(filePath, content: 'contents');
    var projFolder = file.parent;
    manager.setRoots(<String>[projPath], <String>[]);
    // the file was added
    var filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    expect(file.exists, isTrue);
    expect(projFolder.exists, isTrue);
    // delete the file
    deleteFile(filePath);
    return pumpEventQueue().then((_) {
      expect(file.exists, isFalse);
      expect(projFolder.exists, isTrue);
      expect(callbacks.currentFilePaths, hasLength(0));
    });
  }

  Future<void> test_watch_deleteFolder() {
    var filePath = join(projPath, 'foo.dart');
    // add root with a file
    var file = newFile(filePath, content: 'contents');
    var projFolder = file.parent;
    manager.setRoots(<String>[projPath], <String>[]);
    // the file was added
    var filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    expect(file.exists, isTrue);
    expect(projFolder.exists, isTrue);
    // delete the folder
    deleteFolder(projPath);
    return pumpEventQueue().then((_) {
      expect(file.exists, isFalse);
      expect(projFolder.exists, isFalse);
      expect(callbacks.currentFilePaths, hasLength(0));
    });
  }

  Future<void> test_watch_deletePackagespec_fromRoot() {
    // prepare paths
    var root = convertPath('/root');
    var rootPubspec = convertPath('$root/.packages');
    var rootFile = convertPath('$root/root.dart');
    // create files
    newFile(rootPubspec, content: '');
    newFile(rootFile, content: 'library root;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root]);
    callbacks.assertContextFiles(root, [rootFile]);
    // delete the pubspec
    deleteFile(rootPubspec);
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile]);
    });
  }

  Future<void> test_watch_deletePackagespec_fromSubFolder() {
    // prepare paths
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var subProject = convertPath('$root/sub/aaa');
    var subPubspec = convertPath('$subProject/.packages');
    var subFile = convertPath('$subProject/bin/a.dart');
    // create files
    newFile(subPubspec, content: '');
    newFile(rootFile, content: 'library root;');
    newFile(subFile, content: 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root, subProject]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);
    // delete the pubspec
    deleteFile(subPubspec);
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile, subFile]);
    });
  }

  Future<void> test_watch_deletePackagespec_fromSubFolder_withPubspec() {
    // prepare paths:
    //
    // root
    //   root.dart
    //   sub
    //     aaa
    //       .packages
    //       pubspec.yaml
    //       bin
    //         a.dart
    //
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var subProject = convertPath('$root/sub/aaa');
    var subPackagespec = convertPath('$subProject/.packages');
    var subPubspec = convertPath('$subProject/pubspec.yaml');
    var subFile = convertPath('$subProject/bin/a.dart');
    // create files
    newFile(subPackagespec, content: '');
    newFile(subPubspec, content: 'pubspec');
    newFile(rootFile, content: 'library root;');
    newFile(subFile, content: 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root, subProject]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);
    // delete the packagespec
    deleteFile(subPackagespec);
    return pumpEventQueue().then((_) {
      // Should NOT merge
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  Future<void> test_watch_deletePubspec_fromRoot() {
    // prepare paths
    var root = convertPath('/root');
    var rootPubspec = convertPath('$root/pubspec.yaml');
    var rootFile = convertPath('$root/root.dart');
    // create files
    newFile(rootPubspec, content: 'pubspec');
    newFile(rootFile, content: 'library root;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root]);
    callbacks.assertContextFiles(root, [rootFile]);
    // delete the pubspec
    deleteFile(rootPubspec);
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile]);
    });
  }

  Future<void> test_watch_deletePubspec_fromSubFolder() {
    // prepare paths
    var root = convertPath('/root');
    var rootFile = convertPath('$root/root.dart');
    var subProject = convertPath('$root/sub/aaa');
    var subPubspec = convertPath('$subProject/pubspec.yaml');
    var subFile = convertPath('$subProject/bin/a.dart');
    // create files
    newFile(subPubspec, content: 'pubspec');
    newFile(rootFile, content: 'library root;');
    newFile(subFile, content: 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    callbacks.assertContextPaths([root, subProject]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);
    // delete the pubspec
    deleteFile(subPubspec);
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile, subFile]);
    });
  }

  Future<void> test_watch_modifyFile() {
    var filePath = join(projPath, 'foo.dart');
    // add root with a file
    newFile(filePath, content: 'contents');
    manager.setRoots(<String>[projPath], <String>[]);
    // the file was added
    var filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    // TODO(brianwilkerson) Test when the file was modified
    // update the file
    callbacks.now++;
    modifyFile(filePath, 'new contents');
    return pumpEventQueue().then((_) {
      // TODO(brianwilkerson) Test when the file was modified
    });
  }

  Future<void> test_watch_modifyPackageConfigJson() {
    var packageConfigPath = '$projPath/.dart_tool/package_config.json';
    var filePath = convertPath('$projPath/bin/main.dart');

    newFile(packageConfigPath, content: '');
    newFile(filePath, content: 'library main;');

    manager.setRoots(<String>[projPath], <String>[]);

    var filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    expect(_currentPackageMap, isEmpty);

    // update .dart_tool/package_config.json
    callbacks.now++;
    modifyFile(
      packageConfigPath,
      (PackageConfigFileBuilder()..add(name: 'my', rootPath: '../'))
          .toContent(toUriStr: toUriStr),
    );

    return pumpEventQueue().then((_) {
      // verify new package info
      expect(_currentPackageMap.keys, unorderedEquals(['my']));
    });
  }

  Future<void> test_watch_modifyPackagespec() {
    var packagesPath = convertPath('$projPath/.packages');
    var filePath = convertPath('$projPath/bin/main.dart');

    newFile(packagesPath, content: '');
    newFile(filePath, content: 'library main;');

    manager.setRoots(<String>[projPath], <String>[]);

    var filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    expect(_currentPackageMap, isEmpty);

    // update .packages
    callbacks.now++;
    modifyFile(packagesPath, 'main:./lib/');
    return pumpEventQueue().then((_) {
      // verify new package info
      expect(_currentPackageMap.keys, unorderedEquals(['main']));
    });
  }
}

abstract class ContextManagerTest with ResourceProviderMixin {
  /// The name of the 'bin' directory.
  static const String BIN_NAME = 'bin';

  /// The name of the 'example' directory.
  static const String EXAMPLE_NAME = 'example';

  /// The name of the 'lib' directory.
  static const String LIB_NAME = 'lib';

  /// The name of the 'src' directory.
  static const String SRC_NAME = 'src';

  /// The name of the 'test' directory.
  static const String TEST_NAME = 'test';

  ContextManagerImpl manager;

  TestContextManagerCallbacks callbacks;

  String projPath;

  AnalysisError missing_return =
      AnalysisError(null, 0, 1, HintCode.MISSING_RETURN, [
    ['x']
  ]);

  AnalysisError invalid_assignment_error =
      AnalysisError(null, 0, 1, CompileTimeErrorCode.INVALID_ASSIGNMENT, [
    ['x'],
    ['y']
  ]);

  AnalysisError unused_local_variable =
      AnalysisError(null, 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
    ['x']
  ]);

  List<Glob> get analysisFilesGlobs {
    var patterns = <String>[
      '**/*.${AnalysisEngine.SUFFIX_DART}',
      '**/*.${AnalysisEngine.SUFFIX_HTML}',
      '**/*.${AnalysisEngine.SUFFIX_HTM}',
      '**/${AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE}'
    ];
    return patterns
        .map((pattern) => Glob(path.posix.separator, pattern))
        .toList();
  }

  AnalysisOptions get analysisOptions => callbacks.analysisOptions;

  List<ErrorProcessor> get errorProcessors => analysisOptions.errorProcessors;

  List<Linter> get lints => analysisOptions.lintRules;

  SourceFactory get sourceFactory => callbacks.sourceFactory;

  Map<String, List<Folder>> get _currentPackageMap => _packageMap(projPath);

  /// TODO(brianwilkerson) This doesn't add the strong mode processor when using
  /// the new analysis driver.
  ErrorProcessor getProcessor(AnalysisError error) => errorProcessors
      .firstWhere((ErrorProcessor p) => p.appliesTo(error), orElse: () => null);

  void processRequiredPlugins() {
    registerLintRules();
  }

  void setUp() {
    processRequiredPlugins();
    projPath = convertPath('/my/proj');
    newFolder(projPath);
    // Create an SDK in the mock file system.
    MockSdk(resourceProvider: resourceProvider);
    var sdkManager = DartSdkManager(convertPath(sdkRoot));
    manager = ContextManagerImpl(
      resourceProvider,
      sdkManager,
      analysisFilesGlobs,
      InstrumentationService.NULL_SERVICE,
    );
    var logger = PerformanceLog(NullStringSink());
    var scheduler = AnalysisDriverScheduler(logger);
    callbacks = TestContextManagerCallbacks(
        resourceProvider, sdkManager, logger, scheduler);
    manager.callbacks = callbacks;
  }

  Map<String, List<Folder>> _packageMap(String contextPath) {
    var folder = getFolder(contextPath);
    var info = manager.getContextInfoFor(folder);
    return info.analysisDriver.sourceFactory?.packageMap;
  }
}

@reflectiveTest
class ContextManagerWithOptionsTest extends ContextManagerTest {
  String get optionsFileName => AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;

  void deleteOptionsFile() {
    deleteFile('$projPath/$optionsFileName');
  }

  Future<void> test_analysis_options_file_delete() async {
    // Setup analysis options
    newFile('$projPath/$optionsFileName', content: r'''
embedded_libs:
  "dart:foobar": "../sdk_ext/entry.dart"
analyzer:
  errors:
    unused_local_variable: false
linter:
  rules:
    - camel_case_types
''');

    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);
    await pumpEventQueue();

    // Verify options were set.
    expect(errorProcessors, hasLength(1));
    expect(lints, hasLength(1));

    // Remove options.
    deleteOptionsFile();
    await pumpEventQueue();

    // Verify defaults restored.
    expect(errorProcessors, isEmpty);
    expect(lints, isEmpty);
  }

  @failingTest
  Future<void> test_analysis_options_file_delete_with_embedder() async {
    // This fails because the ContextBuilder doesn't pick up the strongMode
    // flag from the embedder.yaml file.
    // Setup _embedder.yaml.
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    newFile('$libPath/_embedder.yaml', content: r'''
analyzer:
  language:
    enablePreviewDart2: true
  errors:
    missing_return: false
linter:
  rules:
    - avoid_as
''');

    // Setup .packages file
    newFile('$projPath/.packages', content: r'''
test_pack:lib/''');

    // Setup analysis options
    newFile('$projPath/$optionsFileName', content: r'''
analyzer:
  errors:
    unused_local_variable: false
linter:
  rules:
    - camel_case_types
''');

    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);
    await pumpEventQueue();

    // Verify options were set.
    expect(errorProcessors, hasLength(2));
    expect(lints, hasLength(2));

    // Remove options.
    deleteOptionsFile();
    await pumpEventQueue();

    // Verify defaults restored.
    expect(lints, hasLength(1));
    expect(lints.first, const TypeMatcher<AvoidAs>());
    expect(errorProcessors, hasLength(1));
    expect(getProcessor(missing_return).severity, isNull);
  }

  Future<void> test_analysis_options_include() async {
    // Create files.
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    newFile('$libPath/main.dart');
    var sdkExtPath = '$projPath/sdk_ext';
    newFile('$sdkExtPath/entry.dart');
    var sdkExtSrcPath = '$projPath/sdk_ext/src';
    newFile('$sdkExtSrcPath/part.dart');
    // Setup analysis options file which includes another options file.
    newFile('$projPath/$optionsFileName', content: r'''
include: other_options.yaml
''');
    newFile('$projPath/other_options.yaml', content: r'''
analyzer:
  errors:
    unused_local_variable: false
linter:
  rules:
    - camel_case_types
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);
    await pumpEventQueue();
    // Verify options were set.
    expect(errorProcessors, hasLength(1));
    expect(lints, hasLength(1));
    expect(lints[0].name, 'camel_case_types');
  }

  Future<void> test_analysis_options_include_package() async {
    // Create files.
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    newFile('$libPath/main.dart');
    var sdkExtPath = '$projPath/sdk_ext';
    newFile('$sdkExtPath/entry.dart');
    var sdkExtSrcPath = '$projPath/sdk_ext/src';
    newFile('$sdkExtSrcPath/part.dart');
    // Setup package
    var booLibPosixPath = '/my/pkg/boo/lib';
    newFile('$booLibPosixPath/other_options.yaml', content: r'''
analyzer:
  errors:
    unused_local_variable: false
linter:
  rules:
    - camel_case_types
''');
    // Setup analysis options file which includes another options file.
    newFile('$projPath/${ContextManagerImpl.PACKAGE_SPEC_NAME}',
        content: 'boo:${toUriStr(booLibPosixPath)}\n');
    newFile('$projPath/$optionsFileName', content: r'''
include: package:boo/other_options.yaml
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);
    await pumpEventQueue();
    // Verify options were set.
    expect(errorProcessors, hasLength(1));
    expect(lints, hasLength(1));
    expect(lints[0].name, 'camel_case_types');
  }

  @failingTest
  Future<void> test_analysis_options_parse_failure() async {
    // Create files.
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    newFile('$libPath/main.dart');
    var sdkExtPath = '$projPath/sdk_ext';
    newFile('$sdkExtPath/entry.dart');
    var sdkExtSrcPath = '$projPath/sdk_ext/src';
    newFile('$sdkExtSrcPath/part.dart');
    // Setup analysis options file with ignore list.
    var optionsFilePath = newFile('$projPath/$optionsFileName', content: r'''
;
''').path;
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);

    // Check that an error was produced.
    TestNotificationManager notificationManager = callbacks.notificationManager;
    var errors = notificationManager.recordedErrors;
    expect(errors, hasLength(1));
    expect(errors[errors.keys.first][optionsFilePath], hasLength(1));
  }

  Future<void> test_deleteRoot_hasAnalysisOptions() async {
    newFile('$projPath/$optionsFileName');

    // Add the root.
    manager.setRoots(<String>[projPath], <String>[]);
    await pumpEventQueue();

    // Remove the root, with the analysis options file.
    // No exceptions.
    deleteFolder(projPath);
    await pumpEventQueue();
  }

  @failingTest
  Future<void> test_embedder_options() async {
    // This fails because the ContextBuilder doesn't pick up the strongMode
    // flag from the embedder.yaml file.
    // Create files.
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    var sdkExtPath = '$projPath/sdk_ext';
    newFile('$projPath/test', content: 'test.dart');
    newFile('$sdkExtPath/entry.dart');
    // Setup _embedder.yaml.
    newFile('$libPath/_embedder.yaml', content: r'''
embedded_libs:
  "dart:foobar": "../sdk_ext/entry.dart"
analyzer:
  strong-mode: true
  errors:
    missing_return: false
linter:
  rules:
    - avoid_as
''');
    // Setup .packages file
    newFile('$projPath/.packages', content: r'''
test_pack:lib/''');

    // Setup analysis options
    newFile('$projPath/$optionsFileName', content: r'''
analyzer:
  exclude:
    - 'test/**'
  errors:
    unused_local_variable: false
linter:
  rules:
    - camel_case_types
''');

    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);
    await pumpEventQueue();

    // Confirm that one context was created.
    var count = manager.numberOfContextsInAnalysisRoot(newFolder(projPath));
    expect(count, equals(1));

    // Verify options.
    // * from `_embedder.yaml`:
    // TODO(brianwilkerson) Figure out what to use in place of 'strongMode'.
//    expect(analysisOptions.strongMode, isTrue);

    // * verify tests are excluded
    expect(
        callbacks.currentContextFilePaths[projPath].keys,
        unorderedEquals(
            ['/my/proj/sdk_ext/entry.dart', '/my/proj/$optionsFileName']));

    // Verify filter setup.
    expect(errorProcessors, hasLength(2));

    // * (embedder.)
    expect(getProcessor(missing_return).severity, isNull);

    // * (options.)
    expect(getProcessor(unused_local_variable).severity, isNull);

    // Verify lints.
    var lintNames = lints.map((lint) => lint.name);

    expect(
        lintNames,
        unorderedEquals([
          'avoid_as' /* embedder */,
          'camel_case_types' /* options */
        ]));

    // Sanity check embedder libs.
    var source = sourceFactory.forUri('dart:foobar');
    expect(source, isNotNull);
    expect(source.fullName, '/my/proj/sdk_ext/entry.dart');
  }

  Future<void> test_error_filter_analysis_option() async {
    // Create files.
    newFile('$projPath/$optionsFileName', content: r'''
analyzer:
  errors:
    unused_local_variable: ignore
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);

    // Verify filter setup.
    expect(errorProcessors, hasLength(1));
    expect(getProcessor(unused_local_variable).severity, isNull);
  }

  Future<void> test_error_filter_analysis_option_multiple_filters() async {
    // Create files.
    newFile('$projPath/$optionsFileName', content: r'''
analyzer:
  errors:
    invalid_assignment: ignore
    unused_local_variable: error
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);

    // Verify filter setup.
    expect(errorProcessors, hasLength(2));

    expect(getProcessor(invalid_assignment_error).severity, isNull);
    expect(getProcessor(unused_local_variable).severity, ErrorSeverity.ERROR);
  }

  Future<void> test_error_filter_analysis_option_synonyms() async {
    // Create files.
    newFile('$projPath/$optionsFileName', content: r'''
analyzer:
  errors:
    unused_local_variable: ignore
    ambiguous_import: false
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);

    // Verify filter setup.
    expect(errorProcessors, isNotNull);
    expect(errorProcessors, hasLength(2));
  }

  Future<void> test_error_filter_analysis_option_unpsecified() async {
    // Create files.
    newFile('$projPath/$optionsFileName', content: r'''
analyzer:
#  errors:
#    unused_local_variable: ignore
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);

    // Verify filter setup.
    expect(errorProcessors, isEmpty);
  }

  Future<void> test_non_analyzable_files_not_considered() async {
    // Set up project and get a reference to the driver.
    manager.setRoots(<String>[projPath], <String>[]);
    var projectFolder = newFolder(projPath);
    var drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, hasLength(1));

    // Add the driver to the manager so that it will receive the events.
    manager.driverMap[projectFolder] = drivers[0];

    // Ensure adding a file that shouldn't be analyzed is not picked up.
    newFile('$projPath/test.txt');
    await pumpEventQueue();
    expect(drivers[0].hasFilesToAnalyze, false);

    // Ensure modifying a file that shouldn't be analyzed is not picked up.
    modifyFile('$projPath/test.txt', 'new content');
    await pumpEventQueue();
    expect(drivers[0].hasFilesToAnalyze, false);
  }

  @failingTest
  Future<void> test_optionsFile_update_strongMode() async {
    // It appears that this fails because we are not correctly updating the
    // analysis options in the driver when the file is modified.
    //return super.test_optionsFile_update_strongMode();
    // After a few other changes, the test now times out on my machine, so I'm
    // disabling it in order to prevent it from being flaky.
    _fail('Test times out');
    var file = newFile('$projPath/bin/test.dart', content: r'''
main() {
  var paths = <int>[];
  var names = <String>[];
  paths.addAll(names.map((s) => s.length));
}
''');
    newFile('$projPath/$optionsFileName', content: r'''
analyzer:
  strong-mode: false
''');
    // Create the context.
    manager.setRoots(<String>[projPath], <String>[]);
    await pumpEventQueue();

    var result = await callbacks.currentDriver.getResult(file.path);

    // Not strong mode - both in the context and the SDK context.
//    AnalysisContext sdkContext = sourceFactory.dartSdk.context;
    // TODO(brianwilkerson) Figure out whether there is an option other than
    // 'strongMode' that will apply to the SDK context.
//    expect(analysisOptions.strongMode, isFalse);
//    expect(sdkContext.analysisOptions.strongMode, isFalse);
    expect(result.errors, isEmpty);

    // Update the options file - turn on 'strong-mode'.
    modifyFile('$projPath/$optionsFileName', r'''
analyzer:
  strong-mode: true
''');
    await pumpEventQueue();

    // Strong mode - both in the context and the SDK context.
    result = await callbacks.currentDriver.getResult(file.path);

    // Not strong mode - both in the context and the SDK context.
//    sdkContext = sourceFactory.dartSdk.context;
    // TODO(brianwilkerson) Figure out whether there is an option other than
    // 'strongMode' that will apply to the SDK context.
//    expect(analysisOptions.strongMode, isTrue);
//    expect(sdkContext.analysisOptions.strongMode, isTrue);
    // The code is strong-mode clean.
    // Verify that TypeSystem was reset.
    expect(result.errors, isEmpty);
  }

  @failingTest
  Future<void> test_path_filter_analysis_option() async {
    // This fails because we're not analyzing the analysis options file.
    // Create files.
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    newFile('$libPath/main.dart');
    newFile('$libPath/nope.dart');
    var sdkExtPath = '$projPath/sdk_ext';
    newFile('$sdkExtPath/entry.dart');
    var sdkExtSrcPath = '$projPath/sdk_ext/src';
    newFile('$sdkExtSrcPath/part.dart');
    // Setup analysis options file with ignore list.
    newFile('$projPath/$optionsFileName', content: r'''
analyzer:
  exclude:
    - lib/nope.dart
    - 'sdk_ext/**'
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);

    // Verify that analysis options was parsed and the ignore patterns applied.
    var projectFolder = newFolder(projPath);
    var drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, hasLength(1));
    var driver = drivers[0];
    expect(
        driver.addedFiles,
        unorderedEquals(
            ['/my/proj/lib/main.dart', '/my/proj/$optionsFileName']));
  }

  Future<void> test_path_filter_child_contexts_option() async {
    // Create files.
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    newFile('$libPath/main.dart');
    newFile('$libPath/pubspec.yaml', content: r'''
name: foobar
''');
    var otherLibPath = '$projPath/other_lib';
    newFile('$otherLibPath/entry.dart');
    newFile('$otherLibPath/pubspec.yaml', content: r'''
name: other_lib
''');
    // Setup analysis options file with ignore list that ignores the 'other_lib'
    // directory by name.
    newFile('$projPath/$optionsFileName', content: r'''
analyzer:
  exclude:
    - 'other_lib'
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);
    // Verify that the context in other_lib wasn't created and that the
    // context in lib was created.
    var projectFolder = newFolder(projPath);
    var drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, hasLength(2));
    expect(drivers[0].name, equals(convertPath('/my/proj')));
    expect(drivers[1].name, equals(convertPath('/my/proj/lib')));
  }

  Future<void>
      test_path_filter_recursive_wildcard_child_contexts_option() async {
    // Create files.
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    newFile('$libPath/main.dart');
    newFile('$libPath/pubspec.yaml', content: r'''
  name: foobar
  ''');
    var otherLibPath = '$projPath/other_lib';
    newFile('$otherLibPath/entry.dart');
    newFile('$otherLibPath/pubspec.yaml', content: r'''
  name: other_lib
  ''');
    // Setup analysis options file with ignore list that ignores 'other_lib'
    // and all descendants.
    newFile('$projPath/$optionsFileName', content: r'''
analyzer:
  exclude:
    - 'other_lib/**'
  ''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[]);

    // Verify that the context in other_lib wasn't created and that the
    // context in lib was created.
    var projectFolder = newFolder(projPath);
    var drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, hasLength(2));
    expect(drivers[0].name, equals(convertPath('/my/proj')));
    expect(drivers[1].name, equals(convertPath('/my/proj/lib')));
  }

  Future<void> test_path_filter_wildcard_child_contexts_option() async {
    // Create files.
    var libPath = '$projPath/${ContextManagerTest.LIB_NAME}';
    newFile('$libPath/main.dart');
    newFile('$libPath/pubspec.yaml', content: r'''
name: foobar
''');
    var otherLibPath = '$projPath/other_lib';
    newFile('$otherLibPath/entry.dart');
    newFile('$otherLibPath/pubspec.yaml', content: r'''
name: other_lib
''');
    // Setup analysis options file with ignore list that ignores 'other_lib'
    // and all immediate children.
    newFile('$projPath/$optionsFileName', content: r'''
analyzer:
  exclude:
    - 'other_lib/*'
''');
    // Setup context / driver.
    manager.setRoots(<String>[projPath], <String>[]);

    var projectFolder = newFolder(projPath);
    var drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, hasLength(2));
    expect(drivers[0].name, equals(convertPath('/my/proj')));
    expect(drivers[1].name, equals(convertPath('/my/proj/lib')));
  }

  void test_setRoots_nested_excludedByOuter() {
    var project = convertPath('/project');
    var projectPubspec = convertPath('$project/pubspec.yaml');
    var example = convertPath('$project/example');
    var examplePubspec = convertPath('$example/pubspec.yaml');
    // create files
    newFile(projectPubspec, content: 'name: project');
    newFile(examplePubspec, content: 'name: example');
    newFile('$project/$optionsFileName', content: r'''
analyzer:
  exclude:
    - 'example'
''');
    manager.setRoots(<String>[project, example], <String>[]);
    // verify
    {
      var rootInfo = manager.rootInfo;
      expect(rootInfo.children, hasLength(1));
      {
        var projectInfo = rootInfo.children[0];
        expect(projectInfo.folder.path, project);
        expect(projectInfo.children, hasLength(1));
        {
          var exampleInfo = projectInfo.children[0];
          expect(exampleInfo.folder.path, example);
          expect(exampleInfo.children, isEmpty);
        }
      }
    }
    expect(callbacks.currentContextRoots, hasLength(2));
    expect(callbacks.currentContextRoots, unorderedEquals([project, example]));
  }

  void test_setRoots_nested_excludedByOuter_deep() {
    var a = convertPath('/a');
    var c = convertPath('$a/b/c');
    var aPubspec = convertPath('$a/pubspec.yaml');
    var cPubspec = convertPath('$c/pubspec.yaml');
    // create files
    newFile(aPubspec, content: 'name: aaa');
    newFile(cPubspec, content: 'name: ccc');
    newFile('$a/$optionsFileName', content: r'''
analyzer:
  exclude:
    - 'b**'
''');
    manager.setRoots(<String>[a, c], <String>[]);
    // verify
    {
      var rootInfo = manager.rootInfo;
      expect(rootInfo.children, hasLength(1));
      {
        var aInfo = rootInfo.children[0];
        expect(aInfo.folder.path, a);
        expect(aInfo.children, hasLength(1));
        {
          var cInfo = aInfo.children[0];
          expect(cInfo.folder.path, c);
          expect(cInfo.children, isEmpty);
        }
      }
    }
    expect(callbacks.currentContextRoots, hasLength(2));
    expect(callbacks.currentContextRoots, unorderedEquals([a, c]));
  }

  Future<void> test_watchEvents() async {
    var libPath = newFolder('$projPath/${ContextManagerTest.LIB_NAME}').path;
    manager.setRoots(<String>[projPath], <String>[]);
    newFile('$libPath/main.dart');
    await Future.delayed(Duration(milliseconds: 1));
    expect(callbacks.watchEvents, hasLength(1));
  }
}

class TestContextManagerCallbacks extends ContextManagerCallbacks {
  /// Source of timestamps stored in [currentContextFilePaths].
  int now = 0;

  /// The analysis driver that was created.
  AnalysisDriver currentDriver;

  /// A table mapping paths to the analysis driver associated with that path.
  Map<String, AnalysisDriver> driverMap = <String, AnalysisDriver>{};

  /// Map from context to the timestamp when the context was created.
  Map<String, int> currentContextTimestamps = <String, int>{};

  /// Map from context to (map from file path to timestamp of last event).
  final Map<String, Map<String, int>> currentContextFilePaths =
      <String, Map<String, int>>{};

  /// A map from the paths of contexts to a set of the sources that should be
  /// explicitly analyzed in those contexts.
  final Map<String, Set<Source>> currentContextSources =
      <String, Set<Source>>{};

  /// Resource provider used for this test.
  final ResourceProvider resourceProvider;

  /// The manager managing the SDKs.
  final DartSdkManager sdkManager;

  /// The logger used by the scheduler and the driver.
  final PerformanceLog logger;

  /// The scheduler used by the driver.
  final AnalysisDriverScheduler scheduler;

  /// The list of `flushedFiles` in the last [removeContext] invocation.
  List<String> lastFlushedFiles;

  /// The watch events that have been broadcast.
  List<WatchEvent> watchEvents = <WatchEvent>[];

  @override
  AbstractNotificationManager notificationManager = TestNotificationManager();

  TestContextManagerCallbacks(
      this.resourceProvider, this.sdkManager, this.logger, this.scheduler);

  /// Return the current set of analysis options.
  AnalysisOptions get analysisOptions => currentDriver?.analysisOptions;

  /// Return the paths to the context roots that currently exist.
  Iterable<String> get currentContextRoots {
    return currentContextTimestamps.keys;
  }

  /// Return the paths to the files being analyzed in the current context root.
  Iterable<String> get currentFilePaths {
    if (currentDriver == null) {
      return <String>[];
    }
    return currentDriver.addedFiles;
  }

  /// Return the current source factory.
  SourceFactory get sourceFactory => currentDriver?.sourceFactory;

  @override
  AnalysisDriver addAnalysisDriver(Folder folder, ContextRoot contextRoot) {
    var path = folder.path;
    expect(currentContextRoots, isNot(contains(path)));
    expect(contextRoot, isNotNull);
    expect(contextRoot.root, path);
    currentContextTimestamps[path] = now;

    var builder = createContextBuilder(folder);
    builder.analysisDriverScheduler = scheduler;
    builder.byteStore = MemoryByteStore();
    builder.performanceLog = logger;
    builder.fileContentOverlay = FileContentOverlay();
    currentDriver = builder.buildDriver(contextRoot);

    driverMap[path] = currentDriver;
    currentDriver.exceptions.listen((ExceptionResult result) {
      AnalysisEngine.instance.instrumentationService.logException(
          CaughtException.withMessage('Analysis failed: ${result.filePath}',
              result.exception.exception, result.exception.stackTrace));
    });
    return currentDriver;
  }

  @override
  void afterWatchEvent(WatchEvent event) {}

  @override
  void analysisOptionsUpdated(AnalysisDriver driver) {}

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    var driver = driverMap[contextFolder.path];
    if (driver != null) {
      changeSet.addedFiles.forEach((source) {
        driver.addFile(source);
      });
      changeSet.changedFiles.forEach((source) {
        driver.changeFile(source);
      });
      changeSet.removedFiles.forEach((source) {
        driver.removeFile(source);
      });
    }
  }

  @override
  void applyFileRemoved(AnalysisDriver driver, String file) {
    driver.removeFile(file);
  }

  void assertContextFiles(String contextPath, List<String> expectedFiles) {
    expect(getCurrentFilePaths(contextPath), unorderedEquals(expectedFiles));
  }

  void assertContextPaths(List<String> expected) {
    expect(currentContextRoots, unorderedEquals(expected));
  }

  @override
  void broadcastWatchEvent(WatchEvent event) {
    watchEvents.add(event);
  }

  @override
  ContextBuilder createContextBuilder(Folder folder) {
    var builderOptions = ContextBuilderOptions();
    var builder = ContextBuilder(resourceProvider, sdkManager, null,
        options: builderOptions);
    return builder;
  }

  /// Return the paths to the files being analyzed in the current context root.
  Iterable<Source> currentFileSources(String contextPath) {
    if (currentDriver == null) {
      return <Source>[];
    }
    var driver = driverMap[contextPath];
    var sourceFactory = driver.sourceFactory;
    return driver.addedFiles.map((String path) {
      var file = resourceProvider.getFile(path);
      var source = file.createSource();
      var uri = sourceFactory.restoreUri(source);
      return file.createSource(uri);
    });
  }

  /// Return the paths to the files being analyzed in the current context root.
  Iterable<String> getCurrentFilePaths(String contextPath) {
    if (currentDriver == null) {
      return <String>[];
    }
    return driverMap[contextPath].addedFiles;
  }

  @override
  void removeContext(Folder folder, List<String> flushedFiles) {
    var path = folder.path;
    expect(currentContextRoots, contains(path));
    currentContextTimestamps.remove(path);
    currentContextFilePaths.remove(path);
    currentContextSources.remove(path);
    lastFlushedFiles = flushedFiles;
  }
}
