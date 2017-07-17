// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.context.directory.manager;

import 'dart:async';

import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/utilities/null_string_sink.dart';
import 'package:analyzer/context/context_root.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisResult;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/summary/summary_file_builder.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/rules/avoid_as.dart';
import 'package:path/path.dart' as path;
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart';

import 'mock_sdk.dart';
import 'mocks.dart';
import 'src/plugin/plugin_manager_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractContextManagerTest);
    defineReflectiveTests(ContextManagerWithNewOptionsTest);
    defineReflectiveTests(ContextManagerWithOldOptionsTest);
  });
}

@reflectiveTest
class AbstractContextManagerTest extends ContextManagerTest {
  void test_contextsInAnalysisRoot_nestedContext() {
    String subProjPath = path.posix.join(projPath, 'subproj');
    Folder subProjFolder = resourceProvider.newFolder(subProjPath);
    resourceProvider.newFile(
        path.posix.join(subProjPath, 'pubspec.yaml'), 'contents');
    String subProjFilePath = path.posix.join(subProjPath, 'file.dart');
    resourceProvider.newFile(subProjFilePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // Make sure that there really are contexts for both the main project and
    // the subproject.
    Folder projectFolder = resourceProvider.getFolder(projPath);
    ContextInfo projContextInfo = manager.getContextInfoFor(projectFolder);
    expect(projContextInfo, isNotNull);
    expect(projContextInfo.folder, projectFolder);
    ContextInfo subProjContextInfo = manager.getContextInfoFor(subProjFolder);
    expect(subProjContextInfo, isNotNull);
    expect(subProjContextInfo.folder, subProjFolder);
    expect(projContextInfo.analysisDriver,
        isNot(equals(subProjContextInfo.analysisDriver)));
    // Check that getDriversInAnalysisRoot() works.
    List<AnalysisDriver> drivers =
        manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, isNotNull);
    expect(drivers, hasLength(2));
    expect(drivers, contains(projContextInfo.analysisDriver));
    expect(drivers, contains(subProjContextInfo.analysisDriver));
  }

  @failingTest
  test_embedder_added() async {
    // NoSuchMethodError: The getter 'apiSignature' was called on null.
    // Receiver: null
    // Tried calling: apiSignature
    // dart:core                                                          Object.noSuchMethod
    // package:analyzer/src/dart/analysis/driver.dart 460:20              AnalysisDriver.configure
    // package:analysis_server/src/context_manager.dart 1043:16           ContextManagerImpl._checkForPackagespecUpdate
    // package:analysis_server/src/context_manager.dart 1553:5            ContextManagerImpl._handleWatchEvent
    //return super.test_embedder_added();
    fail('NoSuchMethodError');
    // Create files.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    newFile([libPath, 'nope.dart']);
    String embedderPath = newFolder([projPath, 'embedder']);
    newFile([embedderPath, 'entry.dart']);
    String embedderSrcPath = newFolder([projPath, 'embedder', 'src']);
    newFile([embedderSrcPath, 'part.dart']);

    // Setup _embedder.yaml.
    newFile([libPath, '_embedder.yaml'], r'''
embedded_libs:
  "dart:foobar": "../embedder/entry.dart"
  "dart:typed_data": "../embedder/src/part"
  ''');

    Folder projectFolder = resourceProvider.newFolder(projPath);

    // NOTE that this is Not in our package path yet.

    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    await pumpEventQueue();
    // Confirm that one driver / context was created.
    List<AnalysisDriver> drivers =
        manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, isNotNull);
    expect(drivers, hasLength(1));

    // No embedded libs yet.
    expect(sourceFactory.forUri('dart:typed_data'), isNull);

    // Add .packages file that introduces a dependency with embedded libs.
    newFile([projPath, '.packages'], r'''
test_pack:lib/''');

    await pumpEventQueue();

    // Confirm that we still have just one driver / context.
    drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, isNotNull);
    expect(drivers, hasLength(1));

    // Embedded lib should be defined now.
    expect(sourceFactory.forUri('dart:typed_data'), isNotNull);
  }

  test_embedder_packagespec() async {
    // Create files.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    newFile([libPath, 'nope.dart']);
    String sdkExtPath = newFolder([projPath, 'sdk_ext']);
    newFile([sdkExtPath, 'entry.dart']);
    String sdkExtSrcPath = newFolder([projPath, 'sdk_ext', 'src']);
    newFile([sdkExtSrcPath, 'part.dart']);
    // Setup _embedder.yaml.
    newFile([libPath, '_embedder.yaml'], r'''
embedded_libs:
  "dart:foobar": "../sdk_ext/entry.dart"
  "dart:typed_data": "../sdk_ext/src/part"
  ''');
    // Setup .packages file
    newFile([projPath, '.packages'], r'''
test_pack:lib/''');
    // Setup context.

    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    await pumpEventQueue();
    // Confirm that one context was created.
    int count = manager
        .numberOfContextsInAnalysisRoot(resourceProvider.newFolder(projPath));
    expect(count, equals(1));
    var source = sourceFactory.forUri('dart:foobar');
    expect(source, isNotNull);
    expect(source.fullName, '/my/proj/sdk_ext/entry.dart');
    // We can't find dart:core because we didn't list it in our
    // embedded_libs map.
    expect(sourceFactory.forUri('dart:core'), isNull);
    // We can find dart:typed_data because we listed it in our
    // embedded_libs map.
    expect(sourceFactory.forUri('dart:typed_data'), isNotNull);
  }

  test_ignoreFilesInPackagesFolder() {
    // create a context with a pubspec.yaml file
    String pubspecPath = path.posix.join(projPath, 'pubspec.yaml');
    resourceProvider.newFile(pubspecPath, 'pubspec');
    // create a file in the "packages" folder
    String filePath1 = path.posix.join(projPath, 'packages', 'file1.dart');
    resourceProvider.newFile(filePath1, 'contents');
    // "packages" files are ignored initially
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    expect(callbacks.currentFilePaths, isEmpty);
    // "packages" files are ignored during watch
    String filePath2 = path.posix.join(projPath, 'packages', 'file2.dart');
    resourceProvider.newFile(filePath2, 'contents');
    return pumpEventQueue().then((_) {
      expect(callbacks.currentFilePaths, isEmpty);
    });
  }

  void test_isInAnalysisRoot_excluded() {
    // prepare paths
    String project = '/project';
    String excludedFolder = '$project/excluded';
    // set roots
    resourceProvider.newFolder(project);
    resourceProvider.newFolder(excludedFolder);
    manager.setRoots(
        <String>[project], <String>[excludedFolder], <String, String>{});
    // verify
    expect(manager.isInAnalysisRoot('$excludedFolder/test.dart'), isFalse);
  }

  void test_isInAnalysisRoot_inNestedContext() {
    String subProjPath = path.posix.join(projPath, 'subproj');
    Folder subProjFolder = resourceProvider.newFolder(subProjPath);
    resourceProvider.newFile(
        path.posix.join(subProjPath, 'pubspec.yaml'), 'contents');
    String subProjFilePath = path.posix.join(subProjPath, 'file.dart');
    resourceProvider.newFile(subProjFilePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // Make sure that there really is a context for the subproject.
    ContextInfo subProjContextInfo = manager.getContextInfoFor(subProjFolder);
    expect(subProjContextInfo, isNotNull);
    expect(subProjContextInfo.folder, subProjFolder);
    // Check that isInAnalysisRoot() works.
    expect(manager.isInAnalysisRoot(subProjFilePath), isTrue);
  }

  void test_isInAnalysisRoot_inRoot() {
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    expect(manager.isInAnalysisRoot('$projPath/test.dart'), isTrue);
  }

  void test_isInAnalysisRoot_notInRoot() {
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    expect(manager.isInAnalysisRoot('/test.dart'), isFalse);
  }

  test_path_filter() async {
    // Setup context.
    Folder root = resourceProvider.newFolder(projPath);
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    expect(callbacks.currentFilePaths, isEmpty);
    // Set ignore patterns for context.
    ContextInfo rootInfo = manager.getContextInfoFor(root);
    manager.setIgnorePatternsForContext(
        rootInfo, ['sdk_ext/**', 'lib/ignoreme.dart']);
    // Start creating files.
    newFile([projPath, ContextManagerImpl.PUBSPEC_NAME]);
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    newFile([libPath, 'ignoreme.dart']);
    String sdkExtPath = newFolder([projPath, 'sdk_ext']);
    newFile([sdkExtPath, 'entry.dart']);
    String sdkExtSrcPath = newFolder([projPath, 'sdk_ext', 'src']);
    newFile([sdkExtSrcPath, 'part.dart']);
    // Pump event loop so new files are discovered and added to context.
    await pumpEventQueue();
    // Verify that ignored files were ignored.
    Iterable<String> filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains('/my/proj/lib/main.dart'));
  }

  test_refresh_folder_with_packagespec() {
    // create a context with a .packages file
    String packagespecFile = path.posix.join(projPath, '.packages');
    resourceProvider.newFile(packagespecFile, '');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
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
  test_refresh_folder_with_packagespec_subfolders() {
    // Create a folder with no .packages file, containing two subfolders with
    // .packages files.
    String subdir1Path = path.posix.join(projPath, 'subdir1');
    String subdir2Path = path.posix.join(projPath, 'subdir2');
    String packagespec1Path = path.posix.join(subdir1Path, '.packages');
    String packagespec2Path = path.posix.join(subdir2Path, '.packages');
    resourceProvider.newFile(packagespec1Path, '');
    resourceProvider.newFile(packagespec2Path, '');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
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

  test_refresh_folder_with_pubspec() {
    // create a context with a pubspec.yaml file
    String pubspecPath = path.posix.join(projPath, 'pubspec.yaml');
    resourceProvider.newFile(pubspecPath, 'pubspec');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
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

  test_refresh_folder_with_pubspec_subfolders() {
    // Create a folder with no pubspec.yaml, containing two subfolders with
    // pubspec.yaml files.
    String subdir1Path = path.posix.join(projPath, 'subdir1');
    String subdir2Path = path.posix.join(projPath, 'subdir2');
    String pubspec1Path = path.posix.join(subdir1Path, 'pubspec.yaml');
    String pubspec2Path = path.posix.join(subdir2Path, 'pubspec.yaml');
    resourceProvider.newFile(pubspec1Path, 'pubspec');
    resourceProvider.newFile(pubspec2Path, 'pubspec');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
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

  test_refresh_oneContext() {
    // create two contexts with pubspec.yaml files
    String pubspecPath = path.posix.join(projPath, 'pubspec.yaml');
    resourceProvider.newFile(pubspecPath, 'pubspec1');

    String proj2Path = '/my/proj2';
    resourceProvider.newFolder(proj2Path);
    String pubspec2Path = path.posix.join(proj2Path, 'pubspec.yaml');
    resourceProvider.newFile(pubspec2Path, 'pubspec2');

    List<String> roots = <String>[projPath, proj2Path];
    manager.setRoots(roots, <String>[], <String, String>{});
    return pumpEventQueue().then((_) {
      expect(callbacks.currentContextRoots, unorderedEquals(roots));
      int then = callbacks.now;
      callbacks.now++;
      manager.refresh([resourceProvider.getResource(proj2Path)]);
      return pumpEventQueue().then((_) {
        expect(callbacks.currentContextRoots, unorderedEquals(roots));
        expect(callbacks.currentContextTimestamps[projPath], then);
        expect(callbacks.currentContextTimestamps[proj2Path], callbacks.now);
      });
    });
  }

  test_sdk_ext_packagespec() async {
    // Create files.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    newFile([libPath, 'nope.dart']);
    String sdkExtPath = newFolder([projPath, 'sdk_ext']);
    newFile([sdkExtPath, 'entry.dart']);
    String sdkExtSrcPath = newFolder([projPath, 'sdk_ext', 'src']);
    newFile([sdkExtSrcPath, 'part.dart']);
    // Setup sdk extension mapping.
    newFile([libPath, '_sdkext'], r'''
{
  "dart:foobar": "../sdk_ext/entry.dart"
}
''');
    // Setup .packages file
    newFile([projPath, '.packages'], r'''
test_pack:lib/''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // Confirm that one context was created.
    int count = manager
        .numberOfContextsInAnalysisRoot(resourceProvider.newFolder(projPath));
    expect(count, equals(1));
    var source = sourceFactory.forUri('dart:foobar');
    expect(source.fullName, equals('/my/proj/sdk_ext/entry.dart'));
  }

  void test_setRoots_addFolderWithDartFile() {
    String filePath = path.posix.join(projPath, 'foo.dart');
    resourceProvider.newFile(filePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // verify
    Iterable<String> filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    List<AnalysisDriver> drivers =
        manager.getDriversInAnalysisRoot(resourceProvider.newFolder(projPath));
    expect(drivers, hasLength(1));
    expect(drivers[0], isNotNull);
    Source result = sourceFactory.forUri('dart:async');
    expect(result, isNotNull);
  }

  void test_setRoots_addFolderWithDartFileInSubfolder() {
    String filePath = path.posix.join(projPath, 'foo', 'bar.dart');
    resourceProvider.newFile(filePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // verify
    Iterable<String> filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
  }

  void test_setRoots_addFolderWithDummyLink() {
    String filePath = path.posix.join(projPath, 'foo.dart');
    resourceProvider.newDummyLink(filePath);
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // verify
    expect(callbacks.currentFilePaths, isEmpty);
  }

  void test_setRoots_addFolderWithNestedPackageSpec() {
    String examplePath = newFolder([projPath, ContextManagerTest.EXAMPLE_NAME]);
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);

    newFile([projPath, ContextManagerImpl.PACKAGE_SPEC_NAME]);
    newFile([libPath, 'main.dart']);
    newFile([examplePath, ContextManagerImpl.PACKAGE_SPEC_NAME]);
    newFile([examplePath, 'example.dart']);

    packageMapProvider.packageMap['proj'] = <Folder>[
      resourceProvider.getResource(libPath)
    ];

    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    expect(callbacks.currentContextRoots, hasLength(2));

    expect(callbacks.currentContextRoots, contains(projPath));
    Iterable<Source> projSources = callbacks.currentFileSources(projPath);
    expect(projSources, hasLength(1));
    expect(projSources.first.uri.toString(), 'file:///my/proj/lib/main.dart');

    expect(callbacks.currentContextRoots, contains(examplePath));
    Iterable<Source> exampleSources = callbacks.currentFileSources(examplePath);
    expect(exampleSources, hasLength(1));
    expect(exampleSources.first.uri.toString(),
        'file:///my/proj/example/example.dart');
  }

  void test_setRoots_addFolderWithNestedPubspec() {
    String examplePath = newFolder([projPath, ContextManagerTest.EXAMPLE_NAME]);
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);

    newFile([projPath, ContextManagerImpl.PUBSPEC_NAME]);
    newFile([projPath, ContextManagerImpl.PACKAGE_SPEC_NAME], 'proj:lib/');
    newFile([libPath, 'main.dart']);
    newFile([examplePath, ContextManagerImpl.PUBSPEC_NAME]);
    newFile([examplePath, 'example.dart']);

    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    expect(callbacks.currentContextRoots, hasLength(2));

    expect(callbacks.currentContextRoots, contains(projPath));
    Iterable<Source> projSources = callbacks.currentFileSources(projPath);
    expect(projSources, hasLength(1));
    expect(projSources.first.uri.toString(), 'package:proj/main.dart');

    expect(callbacks.currentContextRoots, contains(examplePath));
    Iterable<Source> exampleSources = callbacks.currentFileSources(examplePath);
    expect(exampleSources, hasLength(1));
    expect(exampleSources.first.uri.toString(),
        'file:///my/proj/example/example.dart');
  }

  void test_setRoots_addFolderWithoutPubspec() {
    packageMapProvider.packageMap = null;
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // verify
    expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_addFolderWithPackagespec() {
    String packagespecPath = path.posix.join(projPath, '.packages');
    resourceProvider.newFile(packagespecPath,
        'unittest:file:///home/somebody/.pub/cache/unittest-0.9.9/lib/');
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    File mainFile =
        resourceProvider.newFile(path.posix.join(libPath, 'main.dart'), '');
    Source source = mainFile.createSource();

    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    // verify
    expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
    expect(callbacks.currentFilePaths, hasLength(1));

    // smoketest resolution
    Source resolvedSource =
        sourceFactory.resolveUri(source, 'package:unittest/unittest.dart');
    expect(resolvedSource, isNotNull);
    expect(resolvedSource.fullName,
        equals('/home/somebody/.pub/cache/unittest-0.9.9/lib/unittest.dart'));
  }

  void test_setRoots_addFolderWithPackagespecAndPackageRoot() {
    // The package root should take priority.
    String packagespecPath = path.posix.join(projPath, '.packages');
    resourceProvider.newFile(packagespecPath,
        'unittest:file:///home/somebody/.pub/cache/unittest-0.9.9/lib/');
    String packageRootPath = '/package/root/';
    manager.setRoots(<String>[projPath], <String>[],
        <String, String>{projPath: packageRootPath});
    expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
    _checkPackageRoot(projPath, packageRootPath);
  }

  void test_setRoots_addFolderWithPubspec() {
    String pubspecPath = path.posix.join(projPath, 'pubspec.yaml');
    resourceProvider.newFile(pubspecPath, 'pubspec');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // verify
    expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_addFolderWithPubspec_andPackagespec() {
    String pubspecPath = path.posix.join(projPath, 'pubspec.yaml');
    String packagespecPath = path.posix.join(projPath, '.packages');
    resourceProvider.newFile(pubspecPath, 'pubspec');
    resourceProvider.newFile(packagespecPath, '');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // verify
    callbacks.assertContextPaths([projPath]);
  }

  void test_setRoots_addFolderWithPubspecAndLib() {
    String binPath = newFolder([projPath, ContextManagerTest.BIN_NAME]);
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    String srcPath = newFolder([libPath, ContextManagerTest.SRC_NAME]);
    String testPath = newFolder([projPath, ContextManagerTest.TEST_NAME]);

    newFile([projPath, ContextManagerImpl.PUBSPEC_NAME]);
    newFile([projPath, ContextManagerImpl.PACKAGE_SPEC_NAME], 'proj:lib/');
    String appPath = newFile([binPath, 'app.dart']);
    newFile([libPath, 'main.dart']);
    newFile([srcPath, 'internal.dart']);
    String testFilePath = newFile([testPath, 'main_test.dart']);

    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    Iterable<Source> sources = callbacks.currentFileSources(projPath);

    expect(callbacks.currentContextRoots, unorderedEquals([projPath]));
    expect(sources, hasLength(4));
    List<String> uris =
        sources.map((Source source) => source.uri.toString()).toList();
    expect(uris, contains('file://$appPath'));
    expect(uris, contains('package:proj/main.dart'));
    expect(uris, contains('package:proj/src/internal.dart'));
    expect(uris, contains('file://$testFilePath'));
  }

  void test_setRoots_addFolderWithPubspecAndPackagespecFolders() {
    // prepare paths
    String root = '/root';
    String rootFile = '$root/root.dart';
    String subProjectA = '$root/sub/aaa';
    String subProjectB = '$root/sub/sub2/bbb';
    String subProjectA_file = '$subProjectA/bin/a.dart';
    String subProjectB_file = '$subProjectB/bin/b.dart';
    // create files
    resourceProvider.newFile('$subProjectA/pubspec.yaml', 'pubspec');
    resourceProvider.newFile('$subProjectB/pubspec.yaml', 'pubspec');
    resourceProvider.newFile('$subProjectA/.packages', '');
    resourceProvider.newFile('$subProjectB/.packages', '');

    resourceProvider.newFile(rootFile, 'library root;');
    resourceProvider.newFile(subProjectA_file, 'library a;');
    resourceProvider.newFile(subProjectB_file, 'library b;');

    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root, subProjectA, subProjectB]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProjectA, [subProjectA_file]);
    callbacks.assertContextFiles(subProjectB, [subProjectB_file]);
  }

  void test_setRoots_addFolderWithPubspecFolders() {
    // prepare paths
    String root = '/root';
    String rootFile = '$root/root.dart';
    String projectA = '$root/sub/aaa';
    String projectALib = '$root/sub/aaa/lib';
    String subProjectA_file = '$projectA/bin/a.dart';
    String projectB = '$root/sub/sub2/bbb';
    String projectBLib = '$root/sub/sub2/bbb/lib';
    String subProjectB_file = '$projectB/bin/b.dart';
    // create files
    newFile([projectA, ContextManagerImpl.PUBSPEC_NAME]);
    newFile([projectA, ContextManagerImpl.PACKAGE_SPEC_NAME], 'foo:lib/');
    newFile([projectB, ContextManagerImpl.PUBSPEC_NAME]);
    newFile([projectB, ContextManagerImpl.PACKAGE_SPEC_NAME], 'bar:lib/');
    resourceProvider.newFile(rootFile, 'library root;');
    resourceProvider.newFile(subProjectA_file, 'library a;');
    resourceProvider.newFile(subProjectB_file, 'library b;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
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
          'foo': [resourceProvider.getFolder(projectALib)]
        }));
    expect(
        _packageMap(projectB),
        equals({
          'bar': [resourceProvider.getFolder(projectBLib)]
        }));
  }

  void test_setRoots_addPackageRoot() {
    String packagePathFoo = '/package1/foo';
    String packageRootPath = '/package2/foo';
    newFile([projPath, ContextManagerImpl.PACKAGE_SPEC_NAME],
        'foo:file:///package1/foo');
    Folder packageFolder = resourceProvider.newFolder(packagePathFoo);
    List<String> includedPaths = <String>[projPath];
    List<String> excludedPaths = <String>[];
    manager.setRoots(includedPaths, excludedPaths, <String, String>{});
    expect(
        _currentPackageMap,
        equals({
          'foo': [packageFolder]
        }));
    manager.setRoots(includedPaths, excludedPaths,
        <String, String>{projPath: packageRootPath});
    _checkPackageRoot(projPath, equals(packageRootPath));
  }

  void test_setRoots_changePackageRoot() {
    String packageRootPath1 = '/package1';
    String packageRootPath2 = '/package2';
    List<String> includedPaths = <String>[projPath];
    List<String> excludedPaths = <String>[];
    manager.setRoots(includedPaths, excludedPaths,
        <String, String>{projPath: packageRootPath1});
    _checkPackageRoot(projPath, equals(packageRootPath1));
    manager.setRoots(includedPaths, excludedPaths,
        <String, String>{projPath: packageRootPath2});
    _checkPackageRoot(projPath, equals(packageRootPath2));
  }

  void test_setRoots_exclude_newRoot_withExcludedFile() {
    // prepare paths
    String project = '/project';
    String file1 = '$project/file1.dart';
    String file2 = '$project/file2.dart';
    // create files
    resourceProvider.newFile(file1, '// 1');
    resourceProvider.newFile(file2, '// 2');
    // set roots
    manager.setRoots(<String>[project], <String>[file1], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file2]);
  }

  void test_setRoots_exclude_newRoot_withExcludedFolder() {
    // prepare paths
    String project = '/project';
    String folderA = '$project/aaa';
    String folderB = '$project/bbb';
    String fileA = '$folderA/a.dart';
    String fileB = '$folderB/b.dart';
    // create files
    resourceProvider.newFile(fileA, 'library a;');
    resourceProvider.newFile(fileB, 'library b;');
    // set roots
    manager.setRoots(<String>[project], <String>[folderB], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  void test_setRoots_exclude_sameRoot_addExcludedFile() {
    // prepare paths
    String project = '/project';
    String file1 = '$project/file1.dart';
    String file2 = '$project/file2.dart';
    // create files
    resourceProvider.newFile(file1, '// 1');
    resourceProvider.newFile(file2, '// 2');
    // set roots
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1, file2]);
    // exclude "2"
    manager.setRoots(<String>[project], <String>[file2], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1]);
  }

  void test_setRoots_exclude_sameRoot_addExcludedFolder() {
    // prepare paths
    String project = '/project';
    String folderA = '$project/aaa';
    String folderB = '$project/bbb';
    String fileA = '$folderA/a.dart';
    String fileB = '$folderB/b.dart';
    // create files
    resourceProvider.newFile(fileA, 'library a;');
    resourceProvider.newFile(fileB, 'library b;');
    // initially both "aaa/a" and "bbb/b" are included
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA, fileB]);
    // exclude "bbb/"
    manager.setRoots(<String>[project], <String>[folderB], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  void test_setRoots_exclude_sameRoot_removeExcludedFile() {
    // prepare paths
    String project = '/project';
    String file1 = '$project/file1.dart';
    String file2 = '$project/file2.dart';
    // create files
    resourceProvider.newFile(file1, '// 1');
    resourceProvider.newFile(file2, '// 2');
    // set roots
    manager.setRoots(<String>[project], <String>[file2], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1]);
    // stop excluding "2"
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1, file2]);
  }

  void test_setRoots_exclude_sameRoot_removeExcludedFile_inFolder() {
    // prepare paths
    String project = '/project';
    String file1 = '$project/bin/file1.dart';
    String file2 = '$project/bin/file2.dart';
    // create files
    resourceProvider.newFile(file1, '// 1');
    resourceProvider.newFile(file2, '// 2');
    // set roots
    manager.setRoots(<String>[project], <String>[file2], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1]);
    // stop excluding "2"
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1, file2]);
  }

  void test_setRoots_exclude_sameRoot_removeExcludedFolder() {
    // prepare paths
    String project = '/project';
    String folderA = '$project/aaa';
    String folderB = '$project/bbb';
    String fileA = '$folderA/a.dart';
    String fileB = '$folderB/b.dart';
    // create files
    resourceProvider.newFile(fileA, 'library a;');
    resourceProvider.newFile(fileB, 'library b;');
    // exclude "bbb/"
    manager.setRoots(<String>[project], <String>[folderB], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    // stop excluding "bbb/"
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA, fileB]);
  }

  void test_setRoots_ignoreDocFolder() {
    String project = '/project';
    String fileA = '$project/foo.dart';
    String fileB = '$project/lib/doc/bar.dart';
    String fileC = '$project/doc/bar.dart';
    resourceProvider.newFile(fileA, '');
    resourceProvider.newFile(fileB, '');
    resourceProvider.newFile(fileC, '');
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA, fileB]);
  }

  void test_setRoots_nested_includedByOuter_innerFirst() {
    String project = '/project';
    String projectPubspec = '$project/pubspec.yaml';
    String example = '$project/example';
    String examplePubspec = '$example/pubspec.yaml';
    // create files
    resourceProvider.newFile(projectPubspec, 'name: project');
    resourceProvider.newFile(examplePubspec, 'name: example');
    manager
        .setRoots(<String>[example, project], <String>[], <String, String>{});
    // verify
    {
      ContextInfo rootInfo = manager.rootInfo;
      expect(rootInfo.children, hasLength(1));
      {
        ContextInfo projectInfo = rootInfo.children[0];
        expect(projectInfo.folder.path, project);
        expect(projectInfo.children, hasLength(1));
        {
          ContextInfo exampleInfo = projectInfo.children[0];
          expect(exampleInfo.folder.path, example);
          expect(exampleInfo.children, isEmpty);
        }
      }
    }
    expect(callbacks.currentContextRoots, unorderedEquals([project, example]));
  }

  void test_setRoots_nested_includedByOuter_outerPubspec() {
    String project = '/project';
    String projectPubspec = '$project/pubspec.yaml';
    String example = '$project/example';
    // create files
    resourceProvider.newFile(projectPubspec, 'name: project');
    resourceProvider.newFolder(example);
    manager
        .setRoots(<String>[project, example], <String>[], <String, String>{});
    // verify
    {
      ContextInfo rootInfo = manager.rootInfo;
      expect(rootInfo.children, hasLength(1));
      {
        ContextInfo projectInfo = rootInfo.children[0];
        expect(projectInfo.folder.path, project);
        expect(projectInfo.children, isEmpty);
      }
    }
    expect(callbacks.currentContextRoots, unorderedEquals([project]));
  }

  void test_setRoots_nested_includedByOuter_twoPubspecs() {
    String project = '/project';
    String projectPubspec = '$project/pubspec.yaml';
    String example = '$project/example';
    String examplePubspec = '$example/pubspec.yaml';
    // create files
    resourceProvider.newFile(projectPubspec, 'name: project');
    resourceProvider.newFile(examplePubspec, 'name: example');
    manager
        .setRoots(<String>[project, example], <String>[], <String, String>{});
    // verify
    {
      ContextInfo rootInfo = manager.rootInfo;
      expect(rootInfo.children, hasLength(1));
      {
        ContextInfo projectInfo = rootInfo.children[0];
        expect(projectInfo.folder.path, project);
        expect(projectInfo.children, hasLength(1));
        {
          ContextInfo exampleInfo = projectInfo.children[0];
          expect(exampleInfo.folder.path, example);
          expect(exampleInfo.children, isEmpty);
        }
      }
    }
    expect(callbacks.currentContextRoots, unorderedEquals([project, example]));
  }

  void test_setRoots_newFolderWithPackageRoot() {
    String packageRootPath = '/package';
    manager.setRoots(<String>[projPath], <String>[],
        <String, String>{projPath: packageRootPath});
    _checkPackageRoot(projPath, equals(packageRootPath));
  }

  void test_setRoots_newlyAddedFoldersGetProperPackageMap() {
    String packagePath = '/package/foo';
    newFile([projPath, ContextManagerImpl.PACKAGE_SPEC_NAME],
        'foo:file:///package/foo');
    Folder packageFolder = resourceProvider.newFolder(packagePath);
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    expect(
        _currentPackageMap,
        equals({
          'foo': [packageFolder]
        }));
  }

  void test_setRoots_noContext_excludedFolder() {
    // prepare paths
    String project = '/project';
    String excludedFolder = '$project/excluded';
    String excludedPubspec = '$excludedFolder/pubspec.yaml';
    // create files
    resourceProvider.newFile(excludedPubspec, 'name: ignore-me');
    // set "/project", and exclude "/project/excluded"
    manager.setRoots(
        <String>[project], <String>[excludedFolder], <String, String>{});
    callbacks.assertContextPaths([project]);
  }

  void test_setRoots_noContext_inDotFolder() {
    String pubspecPath = path.posix.join(projPath, '.pub', 'pubspec.yaml');
    resourceProvider.newFile(pubspecPath, 'name: test');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // verify
    expect(callbacks.currentContextRoots, hasLength(1));
    expect(callbacks.currentContextRoots, contains(projPath));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_noContext_inPackagesFolder() {
    String pubspecPath = path.posix.join(projPath, 'packages', 'pubspec.yaml');
    resourceProvider.newFile(pubspecPath, 'name: test');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // verify
    expect(callbacks.currentContextRoots, hasLength(1));
    expect(callbacks.currentContextRoots, contains(projPath));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_packageResolver() {
    String filePath = path.posix.join(projPath, 'lib', 'foo.dart');
    newFile([projPath, ContextManagerImpl.PACKAGE_SPEC_NAME], 'foo:lib/');
    resourceProvider.newFile(filePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    var drivers =
        manager.getDriversInAnalysisRoot(resourceProvider.newFolder(projPath));
    expect(drivers, hasLength(1));
    expect(drivers[0], isNotNull);
    Source result = sourceFactory.forUri('package:foo/foo.dart');
    expect(result.fullName, filePath);
  }

  void test_setRoots_pathContainsDotFile() {
    // If the path to a file (relative to the context root) contains a folder
    // whose name begins with '.', then the file is ignored.
    String project = '/project';
    String fileA = '$project/foo.dart';
    String fileB = '$project/.pub/bar.dart';
    resourceProvider.newFile(fileA, '');
    resourceProvider.newFile(fileB, '');
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  void test_setRoots_removeFolderWithoutPubspec() {
    packageMapProvider.packageMap = null;
    // add one root - there is a context
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    expect(callbacks.currentContextRoots, hasLength(1));
    // set empty roots - no contexts
    manager.setRoots(<String>[], <String>[], <String, String>{});
    expect(callbacks.currentContextRoots, hasLength(0));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_removeFolderWithPackagespec() {
    // create a pubspec
    String pubspecPath = path.posix.join(projPath, '.packages');
    resourceProvider.newFile(pubspecPath, '');
    // add one root - there is a context
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    expect(manager.changeSubscriptions, hasLength(1));
    expect(callbacks.currentContextRoots, hasLength(1));
    // set empty roots - no contexts
    manager.setRoots(<String>[], <String>[], <String, String>{});
    expect(manager.changeSubscriptions, hasLength(0));
    expect(callbacks.currentContextRoots, hasLength(0));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_removeFolderWithPackagespecFolder() {
    // prepare paths
    String projectA = '/projectA';
    String projectB = '/projectB';
    String subProjectA = '$projectA/sub';
    String subProjectB = '$projectB/sub';
    String projectA_file = '$projectA/a.dart';
    String projectB_file = '$projectB/a.dart';
    String subProjectA_pubspec = '$subProjectA/.packages';
    String subProjectB_pubspec = '$subProjectB/.packages';
    String subProjectA_file = '$subProjectA/bin/sub_a.dart';
    String subProjectB_file = '$subProjectB/bin/sub_b.dart';
    // create files
    resourceProvider.newFile(projectA_file, '// a');
    resourceProvider.newFile(projectB_file, '// b');
    resourceProvider.newFile(subProjectA_pubspec, '');
    resourceProvider.newFile(subProjectB_pubspec, '');
    resourceProvider.newFile(subProjectA_file, '// sub-a');
    resourceProvider.newFile(subProjectB_file, '// sub-b');
    // set roots
    manager
        .setRoots(<String>[projectA, projectB], <String>[], <String, String>{});
    callbacks
        .assertContextPaths([projectA, subProjectA, projectB, subProjectB]);
    callbacks.assertContextFiles(projectA, [projectA_file]);
    callbacks.assertContextFiles(projectB, [projectB_file]);
    callbacks.assertContextFiles(subProjectA, [subProjectA_file]);
    callbacks.assertContextFiles(subProjectB, [subProjectB_file]);
    // remove "projectB"
    manager.setRoots(<String>[projectA], <String>[], <String, String>{});
    callbacks.assertContextPaths([projectA, subProjectA]);
    callbacks.assertContextFiles(projectA, [projectA_file]);
    callbacks.assertContextFiles(subProjectA, [subProjectA_file]);
  }

  void test_setRoots_removeFolderWithPubspec() {
    // create a pubspec
    String pubspecPath = path.posix.join(projPath, 'pubspec.yaml');
    resourceProvider.newFile(pubspecPath, 'pubspec');
    // add one root - there is a context
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    expect(callbacks.currentContextRoots, hasLength(1));
    // set empty roots - no contexts
    manager.setRoots(<String>[], <String>[], <String, String>{});
    expect(callbacks.currentContextRoots, hasLength(0));
    expect(callbacks.currentFilePaths, hasLength(0));
  }

  void test_setRoots_removeFolderWithPubspecFolder() {
    // prepare paths
    String projectA = '/projectA';
    String projectB = '/projectB';
    String subProjectA = '$projectA/sub';
    String subProjectB = '$projectB/sub';
    String projectA_file = '$projectA/a.dart';
    String projectB_file = '$projectB/a.dart';
    String subProjectA_pubspec = '$subProjectA/pubspec.yaml';
    String subProjectB_pubspec = '$subProjectB/pubspec.yaml';
    String subProjectA_file = '$subProjectA/bin/sub_a.dart';
    String subProjectB_file = '$subProjectB/bin/sub_b.dart';
    // create files
    resourceProvider.newFile(projectA_file, '// a');
    resourceProvider.newFile(projectB_file, '// b');
    resourceProvider.newFile(subProjectA_pubspec, 'pubspec');
    resourceProvider.newFile(subProjectB_pubspec, 'pubspec');
    resourceProvider.newFile(subProjectA_file, '// sub-a');
    resourceProvider.newFile(subProjectB_file, '// sub-b');
    // set roots
    manager
        .setRoots(<String>[projectA, projectB], <String>[], <String, String>{});
    callbacks
        .assertContextPaths([projectA, subProjectA, projectB, subProjectB]);
    callbacks.assertContextFiles(projectA, [projectA_file]);
    callbacks.assertContextFiles(projectB, [projectB_file]);
    callbacks.assertContextFiles(subProjectA, [subProjectA_file]);
    callbacks.assertContextFiles(subProjectB, [subProjectB_file]);
    // remove "projectB"
    manager.setRoots(<String>[projectA], <String>[], <String, String>{});
    callbacks.assertContextPaths([projectA, subProjectA]);
    callbacks.assertContextFiles(projectA, [projectA_file]);
    callbacks.assertContextFiles(subProjectA, [subProjectA_file]);
  }

  void test_setRoots_removePackageRoot() {
    String packagePathFoo = '/package1/foo';
    String packageRootPath = '/package2/foo';
    Folder packageFolder = resourceProvider.newFolder(packagePathFoo);
    newFile([projPath, ContextManagerImpl.PACKAGE_SPEC_NAME],
        'foo:file:///package1/foo');
    List<String> includedPaths = <String>[projPath];
    List<String> excludedPaths = <String>[];
    manager.setRoots(includedPaths, excludedPaths,
        <String, String>{projPath: packageRootPath});
    _checkPackageRoot(projPath, equals(packageRootPath));
    manager.setRoots(includedPaths, excludedPaths, <String, String>{});
    expect(
        _currentPackageMap,
        equals({
          'foo': [packageFolder]
        }));
  }

  void test_setRoots_rootPathContainsDotFile() {
    // If the path to the context root itself contains a folder whose name
    // begins with '.', then that is not sufficient to cause any files in the
    // context to be ignored.
    String project = '/.pub/project';
    String fileA = '$project/foo.dart';
    resourceProvider.newFile(fileA, '');
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  test_watch_addDummyLink() {
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // empty folder initially
    expect(callbacks.currentFilePaths, isEmpty);
    // add link
    String filePath = path.posix.join(projPath, 'foo.dart');
    resourceProvider.newDummyLink(filePath);
    // the link was ignored
    return pumpEventQueue().then((_) {
      expect(callbacks.currentFilePaths, isEmpty);
    });
  }

  test_watch_addFile() {
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // empty folder initially
    expect(callbacks.currentFilePaths, hasLength(0));
    // add file
    String filePath = path.posix.join(projPath, 'foo.dart');
    resourceProvider.newFile(filePath, 'contents');
    // the file was added
    return pumpEventQueue().then((_) {
      Iterable<String> filePaths = callbacks.currentFilePaths;
      expect(filePaths, hasLength(1));
      expect(filePaths, contains(filePath));
    });
  }

  test_watch_addFile_excluded() {
    // prepare paths
    String project = '/project';
    String folderA = '$project/aaa';
    String folderB = '$project/bbb';
    String fileA = '$folderA/a.dart';
    String fileB = '$folderB/b.dart';
    // create files
    resourceProvider.newFile(fileA, 'library a;');
    // set roots
    manager.setRoots(<String>[project], <String>[folderB], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    // add a file, ignored as excluded
    resourceProvider.newFile(fileB, 'library b;');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([project]);
      callbacks.assertContextFiles(project, [fileA]);
    });
  }

  test_watch_addFile_inDocFolder_inner() {
    // prepare paths
    String project = '/project';
    String fileA = '$project/a.dart';
    String fileB = '$project/lib/doc/b.dart';
    // create files
    resourceProvider.newFile(fileA, '');
    // set roots
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    // add a "lib/doc" file, it is not ignored
    resourceProvider.newFile(fileB, '');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([project]);
      callbacks.assertContextFiles(project, [fileA, fileB]);
    });
  }

  test_watch_addFile_inDocFolder_topLevel() {
    // prepare paths
    String project = '/project';
    String fileA = '$project/a.dart';
    String fileB = '$project/doc/b.dart';
    // create files
    resourceProvider.newFile(fileA, '');
    // set roots
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    // add a "doc" file, it is ignored
    resourceProvider.newFile(fileB, '');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([project]);
      callbacks.assertContextFiles(project, [fileA]);
    });
  }

  test_watch_addFile_pathContainsDotFile() async {
    // If a file is added and the path to it (relative to the context root)
    // contains a folder whose name begins with '.', then the file is ignored.
    String project = '/project';
    String fileA = '$project/foo.dart';
    String fileB = '$project/.pub/bar.dart';
    resourceProvider.newFile(fileA, '');
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    resourceProvider.newFile(fileB, '');
    await pumpEventQueue();
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  test_watch_addFile_rootPathContainsDotFile() async {
    // If a file is added and the path to the context contains a folder whose
    // name begins with '.', then the file is not ignored.
    String project = '/.pub/project';
    String fileA = '$project/foo.dart';
    String fileB = '$project/bar/baz.dart';
    resourceProvider.newFile(fileA, '');
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
    resourceProvider.newFile(fileB, '');
    await pumpEventQueue();
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA, fileB]);
  }

  test_watch_addFileInSubfolder() {
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // empty folder initially
    expect(callbacks.currentFilePaths, hasLength(0));
    // add file in subfolder
    String filePath = path.posix.join(projPath, 'foo', 'bar.dart');
    resourceProvider.newFile(filePath, 'contents');
    // the file was added
    return pumpEventQueue().then((_) {
      Iterable<String> filePaths = callbacks.currentFilePaths;
      expect(filePaths, hasLength(1));
      expect(filePaths, contains(filePath));
    });
  }

  test_watch_addPackagespec_toRoot() {
    // prepare paths
    String root = '/root';
    String rootFile = '$root/root.dart';
    String rootPackagespec = '$root/.packages';
    // create files
    resourceProvider.newFile(rootFile, 'library root;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    // add packagespec - still just one root
    resourceProvider.newFile(rootPackagespec, '');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile]);
      // TODO(pquitslund): verify that a new source factory is created --
      // likely this will need to happen in a corresponding ServerContextManagerTest.
    });
  }

  test_watch_addPackagespec_toSubFolder() {
    // prepare paths
    String root = '/root';
    String rootFile = '$root/root.dart';
    String subProject = '$root/sub/aaa';
    String subPubspec = '$subProject/.packages';
    String subFile = '$subProject/bin/a.dart';
    // create files
    resourceProvider.newFile(rootFile, 'library root;');
    resourceProvider.newFile(subFile, 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile, subFile]);
    // add .packages
    resourceProvider.newFile(subPubspec, '');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(root, [rootFile]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  test_watch_addPackagespec_toSubFolder_ofSubFolder() {
    // prepare paths
    String root = '/root';
    String rootFile = '$root/root.dart';
    String subProject = '$root/sub';
    String subPubspec = '$subProject/.packages';
    String subFile = '$subProject/bin/sub.dart';
    String subSubPubspec = '$subProject/subsub/.packages';
    // create files
    resourceProvider.newFile(rootFile, 'library root;');
    resourceProvider.newFile(subPubspec, '');
    resourceProvider.newFile(subFile, 'library sub;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root, subProject]);
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);
    // add pubspec - ignore, because is already in a packagespec-based context
    resourceProvider.newFile(subSubPubspec, '');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(root, [rootFile]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  test_watch_addPackagespec_toSubFolder_withPubspec() {
    // prepare paths
    String root = '/root';
    String rootFile = '$root/root.dart';
    String subProject = '$root/sub/aaa';
    String subPackagespec = '$subProject/.packages';
    String subPubspec = '$subProject/pubspec.yaml';
    String subFile = '$subProject/bin/a.dart';
    // create files
    resourceProvider.newFile(subPubspec, 'pubspec');
    resourceProvider.newFile(rootFile, 'library root;');
    resourceProvider.newFile(subFile, 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root, subProject]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);

    // add .packages
    resourceProvider.newFile(subPackagespec, '');
    return pumpEventQueue().then((_) {
      // Should NOT create another context.
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(root, [rootFile]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  test_watch_addPubspec_toRoot() {
    // prepare paths
    String root = '/root';
    String rootFile = '$root/root.dart';
    String rootPubspec = '$root/pubspec.yaml';
    // create files
    resourceProvider.newFile(rootFile, 'library root;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    // add pubspec - still just one root
    resourceProvider.newFile(rootPubspec, 'pubspec');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile]);
    });
  }

  test_watch_addPubspec_toSubFolder() {
    // prepare paths
    String root = '/root';
    String rootFile = '$root/root.dart';
    String subProject = '$root/sub/aaa';
    String subPubspec = '$subProject/pubspec.yaml';
    String subFile = '$subProject/bin/a.dart';
    // create files
    resourceProvider.newFile(rootFile, 'library root;');
    resourceProvider.newFile(subFile, 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile, subFile]);
    // add pubspec
    resourceProvider.newFile(subPubspec, 'pubspec');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(root, [rootFile]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  test_watch_addPubspec_toSubFolder_ofSubFolder() {
    // prepare paths
    String root = '/root';
    String rootFile = '$root/root.dart';
    String subProject = '$root/sub';
    String subPubspec = '$subProject/pubspec.yaml';
    String subFile = '$subProject/bin/sub.dart';
    String subSubPubspec = '$subProject/subsub/pubspec.yaml';
    // create files
    resourceProvider.newFile(rootFile, 'library root;');
    resourceProvider.newFile(subPubspec, 'pubspec');
    resourceProvider.newFile(subFile, 'library sub;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root, subProject]);
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);
    // add pubspec - ignore, because is already in a pubspec-based context
    resourceProvider.newFile(subSubPubspec, 'pubspec');
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(root, [rootFile]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  test_watch_deleteFile() {
    String filePath = path.posix.join(projPath, 'foo.dart');
    // add root with a file
    File file = resourceProvider.newFile(filePath, 'contents');
    Folder projFolder = file.parent;
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // the file was added
    Iterable<String> filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    expect(file.exists, isTrue);
    expect(projFolder.exists, isTrue);
    // delete the file
    resourceProvider.deleteFile(filePath);
    return pumpEventQueue().then((_) {
      expect(file.exists, isFalse);
      expect(projFolder.exists, isTrue);
      return expect(callbacks.currentFilePaths, hasLength(0));
    });
  }

  test_watch_deleteFolder() {
    String filePath = path.posix.join(projPath, 'foo.dart');
    // add root with a file
    File file = resourceProvider.newFile(filePath, 'contents');
    Folder projFolder = file.parent;
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // the file was added
    Iterable<String> filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    expect(file.exists, isTrue);
    expect(projFolder.exists, isTrue);
    // delete the folder
    resourceProvider.deleteFolder(projPath);
    return pumpEventQueue().then((_) {
      expect(file.exists, isFalse);
      expect(projFolder.exists, isFalse);
      return expect(callbacks.currentFilePaths, hasLength(0));
    });
  }

  test_watch_deletePackagespec_fromRoot() {
    // prepare paths
    String root = '/root';
    String rootPubspec = '$root/.packages';
    String rootFile = '$root/root.dart';
    // create files
    resourceProvider.newFile(rootPubspec, '');
    resourceProvider.newFile(rootFile, 'library root;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root]);
    callbacks.assertContextFiles(root, [rootFile]);
    // delete the pubspec
    resourceProvider.deleteFile(rootPubspec);
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile]);
    });
  }

  test_watch_deletePackagespec_fromSubFolder() {
    // prepare paths
    String root = '/root';
    String rootFile = '$root/root.dart';
    String subProject = '$root/sub/aaa';
    String subPubspec = '$subProject/.packages';
    String subFile = '$subProject/bin/a.dart';
    // create files
    resourceProvider.newFile(subPubspec, '');
    resourceProvider.newFile(rootFile, 'library root;');
    resourceProvider.newFile(subFile, 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root, subProject]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);
    // delete the pubspec
    resourceProvider.deleteFile(subPubspec);
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile, subFile]);
    });
  }

  test_watch_deletePackagespec_fromSubFolder_withPubspec() {
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
    String root = '/root';
    String rootFile = '$root/root.dart';
    String subProject = '$root/sub/aaa';
    String subPackagespec = '$subProject/.packages';
    String subPubspec = '$subProject/pubspec.yaml';
    String subFile = '$subProject/bin/a.dart';
    // create files
    resourceProvider.newFile(subPackagespec, '');
    resourceProvider.newFile(subPubspec, 'pubspec');
    resourceProvider.newFile(rootFile, 'library root;');
    resourceProvider.newFile(subFile, 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root, subProject]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);
    // delete the packagespec
    resourceProvider.deleteFile(subPackagespec);
    return pumpEventQueue().then((_) {
      // Should NOT merge
      callbacks.assertContextPaths([root, subProject]);
      callbacks.assertContextFiles(subProject, [subFile]);
    });
  }

  test_watch_deletePubspec_fromRoot() {
    // prepare paths
    String root = '/root';
    String rootPubspec = '$root/pubspec.yaml';
    String rootFile = '$root/root.dart';
    // create files
    resourceProvider.newFile(rootPubspec, 'pubspec');
    resourceProvider.newFile(rootFile, 'library root;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root]);
    callbacks.assertContextFiles(root, [rootFile]);
    // delete the pubspec
    resourceProvider.deleteFile(rootPubspec);
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile]);
    });
  }

  test_watch_deletePubspec_fromSubFolder() {
    // prepare paths
    String root = '/root';
    String rootFile = '$root/root.dart';
    String subProject = '$root/sub/aaa';
    String subPubspec = '$subProject/pubspec.yaml';
    String subFile = '$subProject/bin/a.dart';
    // create files
    resourceProvider.newFile(subPubspec, 'pubspec');
    resourceProvider.newFile(rootFile, 'library root;');
    resourceProvider.newFile(subFile, 'library a;');
    // set roots
    manager.setRoots(<String>[root], <String>[], <String, String>{});
    callbacks.assertContextPaths([root, subProject]);
    // verify files
    callbacks.assertContextFiles(root, [rootFile]);
    callbacks.assertContextFiles(subProject, [subFile]);
    // delete the pubspec
    resourceProvider.deleteFile(subPubspec);
    return pumpEventQueue().then((_) {
      callbacks.assertContextPaths([root]);
      callbacks.assertContextFiles(root, [rootFile, subFile]);
    });
  }

  test_watch_modifyFile() {
    String filePath = path.posix.join(projPath, 'foo.dart');
    // add root with a file
    resourceProvider.newFile(filePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // the file was added
    Iterable<String> filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    // TODO(brianwilkerson) Test when the file was modified
    // update the file
    callbacks.now++;
    resourceProvider.modifyFile(filePath, 'new contents');
    return pumpEventQueue().then((_) {
      // TODO(brianwilkerson) Test when the file was modified
    });
  }

  test_watch_modifyPackageMapDependency_fail() async {
    // create a dependency file
    String dependencyPath = path.posix.join(projPath, 'dep');
    resourceProvider.newFile(dependencyPath, 'contents');
    packageMapProvider.dependencies.add(dependencyPath);
    // create a Dart file
    String dartFilePath = path.posix.join(projPath, 'main.dart');
    resourceProvider.newFile(dartFilePath, 'contents');
    // the created context has the expected empty package map
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    expect(_currentPackageMap, isEmpty);
    // Change the package map dependency so that the packageMapProvider is
    // re-run, and arrange for it to return null from computePackageMap().
    packageMapProvider.packageMap = null;
    resourceProvider.modifyFile(dependencyPath, 'new contents');
    await pumpEventQueue();
    // The package map should have been changed to null.
    expect(_currentPackageMap, isEmpty);
  }

  test_watch_modifyPackagespec() {
    String packagesPath = '$projPath/.packages';
    String filePath = '$projPath/bin/main.dart';

    resourceProvider.newFile(packagesPath, '');
    resourceProvider.newFile(filePath, 'library main;');

    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    Iterable<String> filePaths = callbacks.currentFilePaths;
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    expect(_currentPackageMap, isEmpty);

    // update .packages
    callbacks.now++;
    resourceProvider.modifyFile(packagesPath, 'main:./lib/');
    return pumpEventQueue().then((_) {
      // verify new package info
      expect(_currentPackageMap.keys, unorderedEquals(['main']));
    });
  }

  /**
   * Verify that package URI's for source files in [path] will be resolved
   * using a package root matching [expectation].
   */
  void _checkPackageRoot(String path, expectation) {
    // TODO(brianwilkerson) Figure out how to test this. Possibly by comparing
    // the contents of the package map (although that approach doesn't work at
    // the moment).
//    FolderDisposition disposition = callbacks.currentContextDispositions[path];
//    expect(disposition.packageRoot, expectation);
    // TODO(paulberry): we should also verify that the package map itself is
    // correct.  See dartbug.com/23909.
  }
}

abstract class ContextManagerTest {
  /**
   * The name of the 'bin' directory.
   */
  static const String BIN_NAME = 'bin';

  /**
   * The name of the 'example' directory.
   */
  static const String EXAMPLE_NAME = 'example';

  /**
   * The name of the 'lib' directory.
   */
  static const String LIB_NAME = 'lib';

  /**
   * The name of the 'src' directory.
   */
  static const String SRC_NAME = 'src';

  /**
   * The name of the 'test' directory.
   */
  static const String TEST_NAME = 'test';

  ContextManagerImpl manager;

  TestContextManagerCallbacks callbacks;

  MemoryResourceProvider resourceProvider;

  MockPackageMapProvider packageMapProvider;

  UriResolver packageResolver = null;

  String projPath = '/my/proj';

  AnalysisError missing_required_param = new AnalysisError(
      new TestSource(), 0, 1, HintCode.MISSING_REQUIRED_PARAM, [
    ['x']
  ]);

  AnalysisError missing_return =
      new AnalysisError(new TestSource(), 0, 1, HintCode.MISSING_RETURN, [
    ['x']
  ]);

  AnalysisError invalid_assignment_error =
      new AnalysisError(new TestSource(), 0, 1, HintCode.INVALID_ASSIGNMENT, [
    ['x'],
    ['y']
  ]);

  AnalysisError unused_local_variable = new AnalysisError(
      new TestSource(), 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
    ['x']
  ]);

  List<Glob> get analysisFilesGlobs {
    List<String> patterns = <String>[
      '**/*.${AnalysisEngine.SUFFIX_DART}',
      '**/*.${AnalysisEngine.SUFFIX_HTML}',
      '**/*.${AnalysisEngine.SUFFIX_HTM}',
      '**/${AnalysisEngine.ANALYSIS_OPTIONS_FILE}',
      '**/${AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE}'
    ];
    return patterns
        .map((pattern) => new Glob(path.posix.separator, pattern))
        .toList();
  }

  AnalysisOptions get analysisOptions => callbacks.analysisOptions;

  List<ErrorProcessor> get errorProcessors => analysisOptions.errorProcessors;

  List<Linter> get lints => analysisOptions.lintRules;

  SourceFactory get sourceFactory => callbacks.sourceFactory;

  Map<String, List<Folder>> get _currentPackageMap => _packageMap(projPath);

  void deleteFile(List<String> pathComponents) {
    String filePath = path.posix.joinAll(pathComponents);
    resourceProvider.deleteFile(filePath);
  }

  /**
   * TODO(brianwilkerson) This doesn't add the strong mode processor when using
   * the new analysis driver.
   */
  ErrorProcessor getProcessor(AnalysisError error) => errorProcessors
      .firstWhere((ErrorProcessor p) => p.appliesTo(error), orElse: () => null);

  String newFile(List<String> pathComponents, [String content = '']) {
    String filePath = path.posix.joinAll(pathComponents);
    resourceProvider.newFile(filePath, content);
    return filePath;
  }

  String newFileFromBytes(List<String> pathComponents, List<int> bytes) {
    String filePath = path.posix.joinAll(pathComponents);
    resourceProvider.newFileWithBytes(filePath, bytes);
    return filePath;
  }

  String newFolder(List<String> pathComponents) {
    String folderPath = path.posix.joinAll(pathComponents);
    resourceProvider.newFolder(folderPath);
    return folderPath;
  }

  void processRequiredPlugins() {
    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);

    registerLintRules();
  }

  UriResolver providePackageResolver(Folder folder) => packageResolver;

  void setUp() {
    processRequiredPlugins();
    resourceProvider = new MemoryResourceProvider();
    resourceProvider.newFolder(projPath);
    packageMapProvider = new MockPackageMapProvider();
    // Create an SDK in the mock file system.
    new MockSdk(generateSummaryFiles: true, resourceProvider: resourceProvider);
    DartSdkManager sdkManager = new DartSdkManager('/', true);
    manager = new ContextManagerImpl(
        resourceProvider,
        sdkManager,
        providePackageResolver,
        packageMapProvider,
        analysisFilesGlobs,
        InstrumentationService.NULL_SERVICE,
        new AnalysisOptionsImpl());
    PerformanceLog logger = new PerformanceLog(new NullStringSink());
    AnalysisDriverScheduler scheduler = new AnalysisDriverScheduler(logger);
    callbacks = new TestContextManagerCallbacks(
        resourceProvider, sdkManager, logger, scheduler);
    manager.callbacks = callbacks;
  }

  /**
   * Verify that package URI's for source files in [path] will be resolved
   * using a package root matching [expectation].
   */
  void _checkPackageRoot(String path, expectation) {
    // TODO(brianwilkerson) Figure out how to test this. Possibly by comparing
    // the contents of the package map (although that approach doesn't work at
    // the moment).
//    FolderDisposition disposition = callbacks.currentContextDispositions[path];
//    expect(disposition.packageRoot, expectation);
    // TODO(paulberry): we should also verify that the package map itself is
    // correct.  See dartbug.com/23909.
  }

  Map<String, List<Folder>> _packageMap(String contextPath) {
    Folder folder = resourceProvider.getFolder(contextPath);
    ContextInfo info = manager.getContextInfoFor(folder);
    return info.analysisDriver.sourceFactory?.packageMap;
  }
}

@reflectiveTest
class ContextManagerWithNewOptionsTest extends ContextManagerWithOptionsTest {
  String get optionsFileName => AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;
}

@reflectiveTest
class ContextManagerWithOldOptionsTest extends ContextManagerWithOptionsTest {
  String get optionsFileName => AnalysisEngine.ANALYSIS_OPTIONS_FILE;
}

abstract class ContextManagerWithOptionsTest extends ContextManagerTest {
  String get optionsFileName;

  test_analysis_options_file_delete() async {
    // Setup analysis options
    newFile([projPath, optionsFileName], r'''
embedded_libs:
  "dart:foobar": "../sdk_ext/entry.dart"
analyzer:
  language:
    enableStrictCallChecks: true
  errors:
    unused_local_variable: false
linter:
  rules:
    - camel_case_types
''');

    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    await pumpEventQueue();

    // Verify options were set.
    expect(errorProcessors, hasLength(1));
    expect(lints, hasLength(1));
    expect(analysisOptions.enableStrictCallChecks, isTrue);

    // Remove options.
    deleteFile([projPath, optionsFileName]);
    await pumpEventQueue();

    // Verify defaults restored.
    expect(errorProcessors, isEmpty);
    expect(lints, isEmpty);
    expect(analysisOptions.enableStrictCallChecks, isFalse);
  }

  @failingTest
  test_analysis_options_file_delete_with_embedder() async {
    // This fails because the ContextBuilder doesn't pick up the strongMode
    // flag from the embedder.yaml file.
    // Setup _embedder.yaml.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, '_embedder.yaml'], r'''
analyzer:
  strong-mode: true
  errors:
    missing_return: false
linter:
  rules:
    - avoid_as
''');

    // Setup .packages file
    newFile([projPath, '.packages'], r'''
test_pack:lib/''');

    // Setup analysis options
    newFile([projPath, optionsFileName], r'''
analyzer:
  language:
    enableStrictCallChecks: true
  errors:
    unused_local_variable: false
linter:
  rules:
    - camel_case_types
''');

    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    await pumpEventQueue();

    // Verify options were set.
    expect(analysisOptions.enableStrictCallChecks, isTrue);
    expect(analysisOptions.strongMode, isTrue);
    expect(errorProcessors, hasLength(2));
    expect(lints, hasLength(2));

    // Remove options.
    deleteFile([projPath, optionsFileName]);
    await pumpEventQueue();

    // Verify defaults restored.
    expect(analysisOptions.enableStrictCallChecks, isFalse);
    expect(lints, hasLength(1));
    expect(lints.first, new isInstanceOf<AvoidAs>());
    expect(errorProcessors, hasLength(1));
    expect(getProcessor(missing_return).severity, isNull);
  }

  test_analysis_options_include() async {
    // Create files.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    String sdkExtPath = newFolder([projPath, 'sdk_ext']);
    newFile([sdkExtPath, 'entry.dart']);
    String sdkExtSrcPath = newFolder([projPath, 'sdk_ext', 'src']);
    newFile([sdkExtSrcPath, 'part.dart']);
    // Setup analysis options file which includes another options file.
    newFile([projPath, optionsFileName], r'''
include: other_options.yaml
''');
    newFile([projPath, 'other_options.yaml'], r'''
analyzer:
  language:
    enableStrictCallChecks: true
  errors:
    unused_local_variable: false
linter:
  rules:
    - camel_case_types
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    await pumpEventQueue();
    // Verify options were set.
    expect(analysisOptions.enableStrictCallChecks, isTrue);
    expect(errorProcessors, hasLength(1));
    expect(lints, hasLength(1));
    expect(lints[0].name, 'camel_case_types');
  }

  test_analysis_options_include_package() async {
    // Create files.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    String sdkExtPath = newFolder([projPath, 'sdk_ext']);
    newFile([sdkExtPath, 'entry.dart']);
    String sdkExtSrcPath = newFolder([projPath, 'sdk_ext', 'src']);
    newFile([sdkExtSrcPath, 'part.dart']);
    // Setup package
    String booLibPosixPath = '/my/pkg/boo/lib';
    newFile([booLibPosixPath, 'other_options.yaml'], r'''
analyzer:
  language:
    enableStrictCallChecks: true
  errors:
    unused_local_variable: false
linter:
  rules:
    - camel_case_types
''');
    // Setup analysis options file which includes another options file.
    newFile([projPath, ContextManagerImpl.PACKAGE_SPEC_NAME],
        'boo:$booLibPosixPath\n');
    newFile([projPath, optionsFileName], r'''
include: package:boo/other_options.yaml
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    await pumpEventQueue();
    // Verify options were set.
    expect(analysisOptions.enableStrictCallChecks, isTrue);
    expect(errorProcessors, hasLength(1));
    expect(lints, hasLength(1));
    expect(lints[0].name, 'camel_case_types');
  }

  test_analysis_options_parse_failure() async {
    // Create files.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    String sdkExtPath = newFolder([projPath, 'sdk_ext']);
    newFile([sdkExtPath, 'entry.dart']);
    String sdkExtSrcPath = newFolder([projPath, 'sdk_ext', 'src']);
    newFile([sdkExtSrcPath, 'part.dart']);
    // Setup analysis options file with ignore list.
    String optionsFilePath = newFile([projPath, optionsFileName], r'''
;
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    // Check that an error was produced.
    TestNotificationManager notificationManager = callbacks.notificationManager;
    var errors = notificationManager.recordedErrors;
    expect(errors, hasLength(1));
    expect(errors[errors.keys.first][optionsFilePath], hasLength(1));
  }

  test_deleteRoot_hasAnalysisOptions() async {
    newFile([projPath, optionsFileName], '');

    // Add the root.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    await pumpEventQueue();

    // Remove the root, with the analysis options file.
    // No exceptions.
    resourceProvider.deleteFolder(projPath);
    await pumpEventQueue();
  }

  @failingTest
  test_embedder_options() async {
    // This fails because the ContextBuilder doesn't pick up the strongMode
    // flag from the embedder.yaml file.
    // Create files.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    String sdkExtPath = newFolder([projPath, 'sdk_ext']);
    newFile([projPath, 'test', 'test.dart']);
    newFile([sdkExtPath, 'entry.dart']);
    List<int> bytes = new SummaryBuilder([], null, true).build();
    newFileFromBytes([projPath, 'sdk.ds'], bytes);
    // Setup _embedder.yaml.
    newFile([libPath, '_embedder.yaml'], r'''
embedded_libs:
  "dart:foobar": "../sdk_ext/entry.dart"
analyzer:
  strong-mode: true
  language:
    enableSuperMixins: true
  errors:
    missing_return: false
linter:
  rules:
    - avoid_as
''');
    // Setup .packages file
    newFile([projPath, '.packages'], r'''
test_pack:lib/''');

    // Setup analysis options
    newFile([projPath, optionsFileName], r'''
analyzer:
  exclude:
    - 'test/**'
  language:
    enableStrictCallChecks: true
  errors:
    unused_local_variable: false
linter:
  rules:
    - camel_case_types
''');

    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    await pumpEventQueue();

    // Confirm that one context was created.
    int count = manager
        .numberOfContextsInAnalysisRoot(resourceProvider.newFolder(projPath));
    expect(count, equals(1));

    // Verify options.
    // * from `_embedder.yaml`:
    expect(analysisOptions.strongMode, isTrue);
    expect(analysisOptions.enableSuperMixins, isTrue);
    // * from analysis options:
    expect(analysisOptions.enableStrictCallChecks, isTrue);

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
        unorderedEquals(
            ['avoid_as' /* embedder */, 'camel_case_types' /* options */]));

    // Sanity check embedder libs.
    var source = sourceFactory.forUri('dart:foobar');
    expect(source, isNotNull);
    expect(source.fullName, '/my/proj/sdk_ext/entry.dart');
  }

  test_error_filter_analysis_option() async {
    // Create files.
    newFile([projPath, optionsFileName], r'''
analyzer:
  errors:
    unused_local_variable: ignore
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    // Verify filter setup.
    expect(errorProcessors, hasLength(1));
    expect(getProcessor(unused_local_variable).severity, isNull);
  }

  test_error_filter_analysis_option_multiple_filters() async {
    // Create files.
    newFile([projPath, optionsFileName], r'''
analyzer:
  errors:
    invalid_assignment: ignore
    unused_local_variable: error
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    // Verify filter setup.
    expect(errorProcessors, hasLength(2));

    expect(getProcessor(invalid_assignment_error).severity, isNull);
    expect(getProcessor(unused_local_variable).severity, ErrorSeverity.ERROR);
  }

  test_error_filter_analysis_option_synonyms() async {
    // Create files.
    newFile([projPath, optionsFileName], r'''
analyzer:
  errors:
    unused_local_variable: ignore
    ambiguous_import: false
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    // Verify filter setup.
    expect(errorProcessors, isNotNull);
    expect(errorProcessors, hasLength(2));
  }

  test_error_filter_analysis_option_unpsecified() async {
    // Create files.
    newFile([projPath, optionsFileName], r'''
analyzer:
#  errors:
#    unused_local_variable: ignore
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    // Verify filter setup.
    expect(errorProcessors, isEmpty);
  }

  @failingTest
  test_optionsFile_update_strongMode() async {
    // It appears that this fails because we are not correctly updating the
    // analysis options in the driver when the file is modified.
    //return super.test_optionsFile_update_strongMode();
    // After a few other changes, the test now times out on my machine, so I'm
    // disabling it in order to prevent it from being flaky.
    fail('Test times out');
    var file = resourceProvider.newFile('$projPath/bin/test.dart', r'''
main() {
  var paths = <int>[];
  var names = <String>[];
  paths.addAll(names.map((s) => s.length));
}
''');
    resourceProvider.newFile('$projPath/$optionsFileName', r'''
analyzer:
  strong-mode: false
''');
    // Create the context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    await pumpEventQueue();

    AnalysisResult result = await callbacks.currentDriver.getResult(file.path);

    // Not strong mode - both in the context and the SDK context.
    AnalysisContext sdkContext = sourceFactory.dartSdk.context;
    expect(analysisOptions.strongMode, isFalse);
    expect(sdkContext.analysisOptions.strongMode, isFalse);
    expect(result.errors, isEmpty);

    // Update the options file - turn on 'strong-mode'.
    resourceProvider.updateFile('$projPath/$optionsFileName', r'''
analyzer:
  strong-mode: true
''');
    await pumpEventQueue();

    // Strong mode - both in the context and the SDK context.
    result = await callbacks.currentDriver.getResult(file.path);

    // Not strong mode - both in the context and the SDK context.
    sdkContext = sourceFactory.dartSdk.context;
    expect(analysisOptions.strongMode, isTrue);
    expect(sdkContext.analysisOptions.strongMode, isTrue);
    // The code is strong-mode clean.
    // Verify that TypeSystem was reset.
    expect(result.errors, isEmpty);
  }

  @failingTest
  test_path_filter_analysis_option() async {
    // This fails because we're not analyzing the analysis options file.
    // Create files.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    newFile([libPath, 'nope.dart']);
    String sdkExtPath = newFolder([projPath, 'sdk_ext']);
    newFile([sdkExtPath, 'entry.dart']);
    String sdkExtSrcPath = newFolder([projPath, 'sdk_ext', 'src']);
    newFile([sdkExtSrcPath, 'part.dart']);
    // Setup analysis options file with ignore list.
    newFile([projPath, optionsFileName], r'''
analyzer:
  exclude:
    - lib/nope.dart
    - 'sdk_ext/**'
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    // Verify that analysis options was parsed and the ignore patterns applied.
    Folder projectFolder = resourceProvider.newFolder(projPath);
    var drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, hasLength(1));
    AnalysisDriver driver = drivers[0];
    expect(
        driver.addedFiles,
        unorderedEquals(
            ['/my/proj/lib/main.dart', '/my/proj/$optionsFileName']));
  }

  test_path_filter_child_contexts_option() async {
    // Create files.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    newFile([libPath, 'pubspec.yaml'], r'''
name: foobar
''');
    String otherLibPath = newFolder([projPath, 'other_lib']);
    newFile([otherLibPath, 'entry.dart']);
    newFile([otherLibPath, 'pubspec.yaml'], r'''
name: other_lib
''');
    // Setup analysis options file with ignore list that ignores the 'other_lib'
    // directory by name.
    newFile([projPath, optionsFileName], r'''
analyzer:
  exclude:
    - 'other_lib'
''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // Verify that the context in other_lib wasn't created and that the
    // context in lib was created.
    Folder projectFolder = resourceProvider.newFolder(projPath);
    var drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, hasLength(2));
    expect(drivers[0].name, equals('/my/proj'));
    expect(drivers[1].name, equals('/my/proj/lib'));
  }

  test_path_filter_recursive_wildcard_child_contexts_option() async {
    // Create files.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    newFile([libPath, 'pubspec.yaml'], r'''
  name: foobar
  ''');
    String otherLibPath = newFolder([projPath, 'other_lib']);
    newFile([otherLibPath, 'entry.dart']);
    newFile([otherLibPath, 'pubspec.yaml'], r'''
  name: other_lib
  ''');
    // Setup analysis options file with ignore list that ignores 'other_lib'
    // and all descendants.
    newFile([projPath, optionsFileName], r'''
analyzer:
  exclude:
    - 'other_lib/**'
  ''');
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    // Verify that the context in other_lib wasn't created and that the
    // context in lib was created.
    Folder projectFolder = resourceProvider.newFolder(projPath);
    var drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, hasLength(2));
    expect(drivers[0].name, equals('/my/proj'));
    expect(drivers[1].name, equals('/my/proj/lib'));
  }

  test_path_filter_wildcard_child_contexts_option() async {
    // Create files.
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    newFile([libPath, 'pubspec.yaml'], r'''
name: foobar
''');
    String otherLibPath = newFolder([projPath, 'other_lib']);
    newFile([otherLibPath, 'entry.dart']);
    newFile([otherLibPath, 'pubspec.yaml'], r'''
name: other_lib
''');
    // Setup analysis options file with ignore list that ignores 'other_lib'
    // and all immediate children.
    newFile([projPath, optionsFileName], r'''
analyzer:
  exclude:
    - 'other_lib/*'
''');
    // Setup context / driver.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});

    Folder projectFolder = resourceProvider.newFolder(projPath);
    var drivers = manager.getDriversInAnalysisRoot(projectFolder);
    expect(drivers, hasLength(2));
    expect(drivers[0].name, equals('/my/proj'));
    expect(drivers[1].name, equals('/my/proj/lib'));
  }

  void test_setRoots_nested_excludedByOuter() {
    String project = '/project';
    String projectPubspec = '$project/pubspec.yaml';
    String example = '$project/example';
    String examplePubspec = '$example/pubspec.yaml';
    // create files
    resourceProvider.newFile(projectPubspec, 'name: project');
    resourceProvider.newFile(examplePubspec, 'name: example');
    newFile([project, optionsFileName], r'''
analyzer:
  exclude:
    - 'example'
''');
    manager
        .setRoots(<String>[project, example], <String>[], <String, String>{});
    // verify
    {
      ContextInfo rootInfo = manager.rootInfo;
      expect(rootInfo.children, hasLength(1));
      {
        ContextInfo projectInfo = rootInfo.children[0];
        expect(projectInfo.folder.path, project);
        expect(projectInfo.children, hasLength(1));
        {
          ContextInfo exampleInfo = projectInfo.children[0];
          expect(exampleInfo.folder.path, example);
          expect(exampleInfo.children, isEmpty);
        }
      }
    }
    expect(callbacks.currentContextRoots, hasLength(2));
    expect(callbacks.currentContextRoots, unorderedEquals([project, example]));
  }

  void test_setRoots_nested_excludedByOuter_deep() {
    String a = '/a';
    String c = '$a/b/c';
    String aPubspec = '$a/pubspec.yaml';
    String cPubspec = '$c/pubspec.yaml';
    // create files
    resourceProvider.newFile(aPubspec, 'name: aaa');
    resourceProvider.newFile(cPubspec, 'name: ccc');
    newFile([a, optionsFileName], r'''
analyzer:
  exclude:
    - 'b**'
''');
    manager.setRoots(<String>[a, c], <String>[], <String, String>{});
    // verify
    {
      ContextInfo rootInfo = manager.rootInfo;
      expect(rootInfo.children, hasLength(1));
      {
        ContextInfo aInfo = rootInfo.children[0];
        expect(aInfo.folder.path, a);
        expect(aInfo.children, hasLength(1));
        {
          ContextInfo cInfo = aInfo.children[0];
          expect(cInfo.folder.path, c);
          expect(cInfo.children, isEmpty);
        }
      }
    }
    expect(callbacks.currentContextRoots, hasLength(2));
    expect(callbacks.currentContextRoots, unorderedEquals([a, c]));
  }

  test_strong_mode_analysis_option() async {
    // Create files.
    newFile([projPath, optionsFileName], r'''
analyzer:
  strong-mode: true
''');
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    newFile([libPath, 'main.dart']);
    // Setup context.
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // Verify that analysis options was parsed and strong-mode set.
    expect(analysisOptions.strongMode, true);
  }

  test_watchEvents() async {
    String libPath = newFolder([projPath, ContextManagerTest.LIB_NAME]);
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    newFile([libPath, 'main.dart']);
    await new Future.delayed(new Duration(milliseconds: 1));
    expect(callbacks.watchEvents, hasLength(1));
  }
}

class TestContextManagerCallbacks extends ContextManagerCallbacks {
  /**
   * Source of timestamps stored in [currentContextFilePaths].
   */
  int now = 0;

  /**
   * The analysis driver that was created.
   */
  AnalysisDriver currentDriver;

  /**
   * A table mapping paths to the analysis driver associated with that path.
   */
  Map<String, AnalysisDriver> driverMap = <String, AnalysisDriver>{};

  /**
   * Map from context to the timestamp when the context was created.
   */
  Map<String, int> currentContextTimestamps = <String, int>{};

  /**
   * Map from context to (map from file path to timestamp of last event).
   */
  final Map<String, Map<String, int>> currentContextFilePaths =
      <String, Map<String, int>>{};

  /**
   * A map from the paths of contexts to a set of the sources that should be
   * explicitly analyzed in those contexts.
   */
  final Map<String, Set<Source>> currentContextSources =
      <String, Set<Source>>{};

  /**
   * Resource provider used for this test.
   */
  final ResourceProvider resourceProvider;

  /**
   * The manager managing the SDKs.
   */
  final DartSdkManager sdkManager;

  /**
   * The logger used by the scheduler and the driver.
   */
  final PerformanceLog logger;

  /**
   * The scheduler used by the driver.
   */
  final AnalysisDriverScheduler scheduler;

  /**
   * The list of `flushedFiles` in the last [removeContext] invocation.
   */
  List<String> lastFlushedFiles;

  /**
   * The watch events that have been broadcast.
   */
  List<WatchEvent> watchEvents = <WatchEvent>[];

  @override
  NotificationManager notificationManager = new TestNotificationManager();

  TestContextManagerCallbacks(
      this.resourceProvider, this.sdkManager, this.logger, this.scheduler);

  /**
   * Return the current set of analysis options.
   */
  AnalysisOptions get analysisOptions => currentDriver?.analysisOptions;

  /**
   * Return the paths to the context roots that currently exist.
   */
  Iterable<String> get currentContextRoots {
    return currentContextTimestamps.keys;
  }

  /**
   * Return the paths to the files being analyzed in the current context root.
   */
  Iterable<String> get currentFilePaths {
    if (currentDriver == null) {
      return <String>[];
    }
    return currentDriver.addedFiles;
  }

  /**
   * Return the current source factory.
   */
  SourceFactory get sourceFactory => currentDriver?.sourceFactory;

  @override
  AnalysisDriver addAnalysisDriver(
      Folder folder, ContextRoot contextRoot, AnalysisOptions options) {
    String path = folder.path;
    expect(currentContextRoots, isNot(contains(path)));
    expect(contextRoot, isNotNull);
    expect(contextRoot.root, path);
    currentContextTimestamps[path] = now;

    ContextBuilder builder =
        createContextBuilder(folder, options, useSummaries: true);
    AnalysisContext context = builder.buildContext(folder.path);
    SourceFactory sourceFactory = context.sourceFactory;
    AnalysisOptions analysisOptions = context.analysisOptions;
    context.dispose();

    currentDriver = new AnalysisDriver(
        scheduler,
        logger,
        resourceProvider,
        new MemoryByteStore(),
        new FileContentOverlay(),
        contextRoot,
        sourceFactory,
        analysisOptions);
    driverMap[path] = currentDriver;
    currentDriver.exceptions.listen((ExceptionResult result) {
      AnalysisEngine.instance.logger
          .logError('Analysis failed: ${result.path}', result.exception);
    });
    return currentDriver;
  }

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    AnalysisDriver driver = driverMap[contextFolder.path];
    if (driver != null) {
      changeSet.addedSources.forEach((source) {
        driver.addFile(source.fullName);
      });
      changeSet.changedSources.forEach((source) {
        driver.changeFile(source.fullName);
      });
      changeSet.removedSources.forEach((source) {
        driver.removeFile(source.fullName);
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
  void computingPackageMap(bool computing) {
    // Do nothing.
  }

  @override
  ContextBuilder createContextBuilder(Folder folder, AnalysisOptions options,
      {bool useSummaries = false}) {
    ContextBuilderOptions builderOptions = new ContextBuilderOptions();
    builderOptions.defaultOptions = options;
    ContextBuilder builder = new ContextBuilder(
        resourceProvider, sdkManager, new ContentCache(),
        options: builderOptions);
    return builder;
  }

  /**
   * Return the paths to the files being analyzed in the current context root.
   */
  Iterable<Source> currentFileSources(String contextPath) {
    if (currentDriver == null) {
      return <Source>[];
    }
    AnalysisDriver driver = driverMap[contextPath];
    SourceFactory sourceFactory = driver.sourceFactory;
    return driver.addedFiles.map((String path) {
      File file = resourceProvider.getFile(path);
      Source source = file.createSource();
      Uri uri = sourceFactory.restoreUri(source);
      return file.createSource(uri);
    });
  }

  /**
   * Return the paths to the files being analyzed in the current context root.
   */
  Iterable<String> getCurrentFilePaths(String contextPath) {
    if (currentDriver == null) {
      return <String>[];
    }
    return driverMap[contextPath].addedFiles;
  }

  @override
  void moveContext(Folder from, Folder to) {
    String path = from.path;
    String path2 = to.path;
    expect(currentContextFilePaths, contains(path));
    expect(currentContextTimestamps, contains(path));
    expect(currentContextSources, contains(path));
    expect(currentContextFilePaths, isNot(contains(path2)));
    expect(currentContextTimestamps, isNot(contains(path2)));
    expect(currentContextSources, isNot(contains(path2)));
    currentContextFilePaths[path2] = currentContextFilePaths.remove(path);
    currentContextTimestamps[path2] = currentContextTimestamps.remove(path);
    currentContextSources[path2] = currentContextSources.remove(path);
  }

  @override
  void removeContext(Folder folder, List<String> flushedFiles) {
    String path = folder.path;
    expect(currentContextRoots, contains(path));
    currentContextTimestamps.remove(path);
    currentContextFilePaths.remove(path);
    currentContextSources.remove(path);
    lastFlushedFiles = flushedFiles;
  }
}

/**
 * A [Source] that knows it's [fullName].
 */
class TestSource implements Source {
  TestSource();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestUriResolver extends UriResolver {
  Map<Uri, Source> uriMap;

  TestUriResolver(this.uriMap);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    return uriMap[uri];
  }
}
