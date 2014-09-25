// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.context.directory.manager;

import 'package:analysis_server/src/context_manager.dart';
import 'reflective_tests.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(ContextManagerTest);
}


@ReflectiveTestCase()
class ContextManagerTest {
  TestContextManager manager;
  MemoryResourceProvider resourceProvider;
  MockPackageMapProvider packageMapProvider;

  String projPath = '/my/proj';

  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    packageMapProvider = new MockPackageMapProvider();
    manager = new TestContextManager(resourceProvider, packageMapProvider);
    resourceProvider.newFolder(projPath);
  }

  test_ignoreFilesInPackagesFolder() {
    // create a context with a pubspec.yaml file
    String pubspecPath = posix.join(projPath, 'pubspec.yaml');
    resourceProvider.newFile(pubspecPath, 'pubspec');
    // create a file in the "packages" folder
    String filePath1 = posix.join(projPath, 'packages', 'file1.dart');
    resourceProvider.newFile(filePath1, 'contents');
    // "packages" files are ignored initially
    manager.setRoots(<String>[projPath], <String>[]);
    expect(manager.currentContextFilePaths[projPath], isEmpty);
    // "packages" files are ignored during watch
    String filePath2 = posix.join(projPath, 'packages', 'file2.dart');
    resourceProvider.newFile(filePath2, 'contents');
    return pumpEventQueue().then((_) {
      expect(manager.currentContextFilePaths[projPath], isEmpty);
    });
  }

  void test_isInAnalysisRoot_excluded() {
    // prepare paths
    String project = '/project';
    String excludedFolder = '$project/excluded';
    // set roots
    resourceProvider.newFolder(project);
    resourceProvider.newFolder(excludedFolder);
    manager.setRoots(<String>[project], <String>[excludedFolder]);
    // verify
    expect(manager.isInAnalysisRoot('$excludedFolder/test.dart'), isFalse);
  }

  void test_isInAnalysisRoot_inRoot() {
    manager.setRoots(<String>[projPath], <String>[]);
    expect(manager.isInAnalysisRoot('$projPath/test.dart'), isTrue);
  }

  void test_isInAnalysisRoot_notInRoot() {
    manager.setRoots(<String>[projPath], <String>[]);
    expect(manager.isInAnalysisRoot('/test.dart'), isFalse);
  }

  test_refresh_folder_with_pubspec() {
    // create a context with a pubspec.yaml file
    String pubspecPath = posix.join(projPath, 'pubspec.yaml');
    resourceProvider.newFile(pubspecPath, 'pubspec');
    manager.setRoots(<String>[projPath], <String>[]);
    return pumpEventQueue().then((_) {
      expect(manager.currentContextPaths.toList(), [projPath]);
      manager.now++;
      manager.refresh();
      return pumpEventQueue().then((_) {
        expect(manager.currentContextPaths.toList(), [projPath]);
        expect(manager.currentContextTimestamps[projPath], manager.now);
      });
    });
  }

  test_refresh_folder_with_pubspec_subfolders() {
    // Create a folder with no pubspec.yaml, containing two subfolders with
    // pubspec.yaml files.
    String subdir1Path = posix.join(projPath, 'subdir1');
    String subdir2Path = posix.join(projPath, 'subdir2');
    String pubspec1Path = posix.join(subdir1Path, 'pubspec.yaml');
    String pubspec2Path = posix.join(subdir2Path, 'pubspec.yaml');
    resourceProvider.newFile(pubspec1Path, 'pubspec');
    resourceProvider.newFile(pubspec2Path, 'pubspec');
    manager.setRoots(<String>[projPath], <String>[]);
    return pumpEventQueue().then((_) {
      expect(manager.currentContextPaths.toSet(),
          [subdir1Path, subdir2Path, projPath].toSet());
      manager.now++;
      manager.refresh();
      return pumpEventQueue().then((_) {
        expect(manager.currentContextPaths.toSet(),
          [subdir1Path, subdir2Path, projPath].toSet());
        expect(manager.currentContextTimestamps[projPath], manager.now);
        expect(manager.currentContextTimestamps[subdir1Path], manager.now);
        expect(manager.currentContextTimestamps[subdir2Path], manager.now);
      });
    });
  }

  void test_setRoots_addFolderWithDartFile() {
    String filePath = posix.join(projPath, 'foo.dart');
    resourceProvider.newFile(filePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    var filePaths = manager.currentContextFilePaths[projPath];
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
  }

  void test_setRoots_addFolderWithDartFileInSubfolder() {
    String filePath = posix.join(projPath, 'foo', 'bar.dart');
    resourceProvider.newFile(filePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    var filePaths = manager.currentContextFilePaths[projPath];
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
  }

  void test_setRoots_addFolderWithDummyLink() {
    String filePath = posix.join(projPath, 'foo.dart');
    resourceProvider.newDummyLink(filePath);
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    var filePaths = manager.currentContextFilePaths[projPath];
    expect(filePaths, isEmpty);
  }

  void test_setRoots_addFolderWithPubspec() {
    String pubspecPath = posix.join(projPath, 'pubspec.yaml');
    resourceProvider.newFile(pubspecPath, 'pubspec');
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    expect(manager.currentContextPaths, hasLength(1));
    expect(manager.currentContextPaths, contains(projPath));
    expect(manager.currentContextFilePaths[projPath], hasLength(0));
  }

  void test_setRoots_addFolderWithPubspecFolders() {
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
    resourceProvider.newFile(rootFile, 'library root;');
    resourceProvider.newFile(subProjectA_file, 'library a;');
    resourceProvider.newFile(subProjectB_file, 'library b;');
    // configure package maps
    packageMapProvider.packageMaps = {
      subProjectA: {
        'foo': [resourceProvider.newFolder('/package/foo')]
      },
      subProjectA: {
        'bar': [resourceProvider.newFolder('/package/bar')]
      },
    };
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    manager.assertContextPaths([root, subProjectA, subProjectB]);
    // verify files
    manager.assertContextFiles(root, [rootFile]);
    manager.assertContextFiles(subProjectA, [subProjectA_file]);
    manager.assertContextFiles(subProjectB, [subProjectB_file]);
    // verify package maps
    expect(
        manager.currentContextPackageMaps[root],
        equals(packageMapProvider.packageMaps[root]));
    expect(
        manager.currentContextPackageMaps[subProjectA],
        equals(packageMapProvider.packageMaps[subProjectA]));
    expect(
        manager.currentContextPackageMaps[subProjectB],
        equals(packageMapProvider.packageMaps[subProjectB]));
  }

  void test_setRoots_addFolderWithoutPubspec() {
    packageMapProvider.packageMap = null;
    manager.setRoots(<String>[projPath], <String>[]);
    // verify
    expect(manager.currentContextPaths, hasLength(1));
    expect(manager.currentContextPaths, contains(projPath));
    expect(manager.currentContextFilePaths[projPath], hasLength(0));
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
    manager.setRoots(<String>[project], <String>[file1]);
    manager.assertContextPaths([project]);
    manager.assertContextFiles(project, [file2]);
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
    manager.setRoots(<String>[project], <String>[folderB]);
    manager.assertContextPaths([project]);
    manager.assertContextFiles(project, [fileA]);
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
    manager.setRoots(<String>[project], <String>[]);
    manager.assertContextPaths([project]);
    manager.assertContextFiles(project, [file1, file2]);
    // exclude "2"
    manager.setRoots(<String>[project], <String>[file2]);
    manager.assertContextPaths([project]);
    manager.assertContextFiles(project, [file1]);
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
    manager.setRoots(<String>[project], <String>[]);
    manager.assertContextPaths([project]);
    manager.assertContextFiles(project, [fileA, fileB]);
    // exclude "bbb/"
    manager.setRoots(<String>[project], <String>[folderB]);
    manager.assertContextPaths([project]);
    manager.assertContextFiles(project, [fileA]);
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
    manager.setRoots(<String>[project], <String>[file2]);
    manager.assertContextPaths([project]);
    manager.assertContextFiles(project, [file1]);
    // stop excluding "2"
    manager.setRoots(<String>[project], <String>[]);
    manager.assertContextPaths([project]);
    manager.assertContextFiles(project, [file1, file2]);
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
    manager.setRoots(<String>[project], <String>[folderB]);
    manager.assertContextPaths([project]);
    manager.assertContextFiles(project, [fileA]);
    // stop excluding "bbb/"
    manager.setRoots(<String>[project], <String>[]);
    manager.assertContextPaths([project]);
    manager.assertContextFiles(project, [fileA, fileB]);
  }

  void test_setRoots_ignoreSubContext_ofSubContext() {
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
    resourceProvider.newFile(subSubPubspec, 'pubspec');
    // set roots
    manager.setRoots(<String>[root], <String>[]);
    manager.assertContextPaths([root, subProject]);
    manager.assertContextFiles(root, [rootFile]);
    manager.assertContextFiles(subProject, [subFile]);
  }

  void test_setRoots_newlyAddedFoldersGetProperPackageMap() {
    String packagePath = '/package/foo';
    Folder packageFolder = resourceProvider.newFolder(packagePath);
    packageMapProvider.packageMap = {
      'foo': [packageFolder]
    };
    manager.setRoots(<String>[projPath], <String>[]);
    expect(
        manager.currentContextPackageMaps[projPath],
        equals(packageMapProvider.packageMap));
  }

  void test_setRoots_removeFolderWithPubspec() {
    // create a pubspec
    String pubspecPath = posix.join(projPath, 'pubspec.yaml');
    resourceProvider.newFile(pubspecPath, 'pubspec');
    // add one root - there is a context
    manager.setRoots(<String>[projPath], <String>[]);
    expect(manager.currentContextPaths, hasLength(1));
    // set empty roots - no contexts
    manager.setRoots(<String>[], <String>[]);
    expect(manager.currentContextPaths, hasLength(0));
    expect(manager.currentContextFilePaths, hasLength(0));
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
    manager.setRoots(<String>[projectA, projectB], <String>[]);
    manager.assertContextPaths([projectA, subProjectA, projectB, subProjectB]);
    manager.assertContextFiles(projectA, [projectA_file]);
    manager.assertContextFiles(projectB, [projectB_file]);
    manager.assertContextFiles(subProjectA, [subProjectA_file]);
    manager.assertContextFiles(subProjectB, [subProjectB_file]);
    // remove "projectB"
    manager.setRoots(<String>[projectA], <String>[]);
    manager.assertContextPaths([projectA, subProjectA]);
    manager.assertContextFiles(projectA, [projectA_file]);
    manager.assertContextFiles(subProjectA, [subProjectA_file]);
  }

  void test_setRoots_removeFolderWithoutPubspec() {
    packageMapProvider.packageMap = null;
    // add one root - there is a context
    manager.setRoots(<String>[projPath], <String>[]);
    expect(manager.currentContextPaths, hasLength(1));
    // set empty roots - no contexts
    manager.setRoots(<String>[], <String>[]);
    expect(manager.currentContextPaths, hasLength(0));
    expect(manager.currentContextFilePaths, hasLength(0));
  }

  test_watch_addDummyLink() {
    manager.setRoots(<String>[projPath], <String>[]);
    // empty folder initially
    Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
    expect(filePaths, isEmpty);
    // add link
    String filePath = posix.join(projPath, 'foo.dart');
    resourceProvider.newDummyLink(filePath);
    // the link was ignored
    return pumpEventQueue().then((_) {
      expect(filePaths, isEmpty);
    });
  }

  test_watch_addFile() {
    manager.setRoots(<String>[projPath], <String>[]);
    // empty folder initially
    Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
    expect(filePaths, hasLength(0));
    // add file
    String filePath = posix.join(projPath, 'foo.dart');
    resourceProvider.newFile(filePath, 'contents');
    // the file was added
    return pumpEventQueue().then((_) {
      expect(filePaths, hasLength(1));
      expect(filePaths, contains(filePath));
    });
  }

  test_watch_addFileInSubfolder() {
    manager.setRoots(<String>[projPath], <String>[]);
    // empty folder initially
    Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
    expect(filePaths, hasLength(0));
    // add file in subfolder
    String filePath = posix.join(projPath, 'foo', 'bar.dart');
    resourceProvider.newFile(filePath, 'contents');
    // the file was added
    return pumpEventQueue().then((_) {
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
    manager.setRoots(<String>[project], <String>[folderB]);
    manager.assertContextPaths([project]);
    manager.assertContextFiles(project, [fileA]);
    // add a file, ignored as excluded
    resourceProvider.newFile(fileB, 'library b;');
    return pumpEventQueue().then((_) {
      manager.assertContextPaths([project]);
      manager.assertContextFiles(project, [fileA]);
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
    manager.setRoots(<String>[root], <String>[]);
    manager.assertContextPaths([root]);
    // verify files
    manager.assertContextFiles(root, [rootFile]);
    // add pubspec - still just one root
    resourceProvider.newFile(rootPubspec, 'pubspec');
    return pumpEventQueue().then((_) {
      manager.assertContextPaths([root]);
      manager.assertContextFiles(root, [rootFile]);
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
    manager.setRoots(<String>[root], <String>[]);
    manager.assertContextPaths([root]);
    // verify files
    manager.assertContextFiles(root, [rootFile, subFile]);
    // add pubspec
    resourceProvider.newFile(subPubspec, 'pubspec');
    return pumpEventQueue().then((_) {
      manager.assertContextPaths([root, subProject]);
      manager.assertContextFiles(root, [rootFile]);
      manager.assertContextFiles(subProject, [subFile]);
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
    manager.setRoots(<String>[root], <String>[]);
    manager.assertContextPaths([root, subProject]);
    manager.assertContextFiles(root, [rootFile]);
    manager.assertContextFiles(subProject, [subFile]);
    // add pubspec - ignore, because is already in a pubspec-based context
    resourceProvider.newFile(subSubPubspec, 'pubspec');
    return pumpEventQueue().then((_) {
      manager.assertContextPaths([root, subProject]);
      manager.assertContextFiles(root, [rootFile]);
      manager.assertContextFiles(subProject, [subFile]);
    });
  }

  test_watch_deleteFile() {
    String filePath = posix.join(projPath, 'foo.dart');
    // add root with a file
    resourceProvider.newFile(filePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[]);
    // the file was added
    Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    // delete the file
    resourceProvider.deleteFile(filePath);
    return pumpEventQueue().then((_) {
      return expect(filePaths, hasLength(0));
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
    manager.setRoots(<String>[root], <String>[]);
    manager.assertContextPaths([root]);
    manager.assertContextFiles(root, [rootFile]);
    // delete the pubspec
    resourceProvider.deleteFile(rootPubspec);
    return pumpEventQueue().then((_) {
      manager.assertContextPaths([root]);
      manager.assertContextFiles(root, [rootFile]);
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
    manager.setRoots(<String>[root], <String>[]);
    manager.assertContextPaths([root, subProject]);
    // verify files
    manager.assertContextFiles(root, [rootFile]);
    manager.assertContextFiles(subProject, [subFile]);
    // delete the pubspec
    resourceProvider.deleteFile(subPubspec);
    return pumpEventQueue().then((_) {
      manager.assertContextPaths([root]);
      manager.assertContextFiles(root, [rootFile, subFile]);
    });
  }

  test_watch_modifyFile() {
    String filePath = posix.join(projPath, 'foo.dart');
    // add root with a file
    resourceProvider.newFile(filePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[]);
    // the file was added
    Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    expect(filePaths[filePath], equals(manager.now));
    // update the file
    manager.now++;
    resourceProvider.modifyFile(filePath, 'new contents');
    return pumpEventQueue().then((_) {
      return expect(filePaths[filePath], equals(manager.now));
    });
  }

  test_watch_modifyPackageMapDependency() {
    // create a dependency file
    String dependencyPath = posix.join(projPath, 'dep');
    resourceProvider.newFile(dependencyPath, 'contents');
    packageMapProvider.dependencies.add(dependencyPath);
    // create a Dart file
    String dartFilePath = posix.join(projPath, 'main.dart');
    resourceProvider.newFile(dartFilePath, 'contents');
    // the created context has the expected empty package map
    manager.setRoots(<String>[projPath], <String>[]);
    expect(manager.currentContextPackageMaps[projPath], isEmpty);
    // configure package map
    String packagePath = '/package/foo';
    resourceProvider.newFolder(packagePath);
    packageMapProvider.packageMap = {
      'foo': projPath
    };
    // Changing a .dart file in the project shouldn't cause a new
    // package map to be picked up.
    resourceProvider.modifyFile(dartFilePath, 'new contents');
    return pumpEventQueue().then((_) {
      expect(manager.currentContextPackageMaps[projPath], isEmpty);
      // However, changing the package map dependency should.
      resourceProvider.modifyFile(dependencyPath, 'new contents');
      return pumpEventQueue().then((_) {
        expect(
            manager.currentContextPackageMaps[projPath],
            equals(packageMapProvider.packageMap));
      });
    });
  }

  test_watch_modifyPackageMapDependency_fail() {
    // create a dependency file
    String dependencyPath = posix.join(projPath, 'dep');
    resourceProvider.newFile(dependencyPath, 'contents');
    packageMapProvider.dependencies.add(dependencyPath);
    // create a Dart file
    String dartFilePath = posix.join(projPath, 'main.dart');
    resourceProvider.newFile(dartFilePath, 'contents');
    // the created context has the expected empty package map
    manager.setRoots(<String>[projPath], <String>[]);
    expect(manager.currentContextPackageMaps[projPath], isEmpty);
    // Change the package map dependency so that the packageMapProvider is
    // re-run, and arrange for it to return null from computePackageMap().
    packageMapProvider.packageMap = null;
    resourceProvider.modifyFile(dependencyPath, 'new contents');
    return pumpEventQueue().then((_) {
      // The package map should have been changed to null.
      expect(manager.currentContextPackageMaps[projPath], isNull);
    });
  }
}


class TestContextManager extends ContextManager {
  /**
   * Source of timestamps stored in [currentContextFilePaths].
   */
  int now = 0;

  /**
   * Map from context to the timestamp when the context was created.
   */
  Map<String, int> currentContextTimestamps = <String, int>{};

  /**
   * Iterable of the paths to contexts that currently exist.
   */
  Iterable<String> get currentContextPaths => currentContextTimestamps.keys;

  /**
   * Map from context to (map from file path to timestamp of last event).
   */
  final Map<String, Map<String, int>> currentContextFilePaths = <String,
      Map<String, int>>{};

  /**
   * Map from context to package map.
   */
  final Map<String, Map<String, List<Folder>>> currentContextPackageMaps =
      <String, Map<String, List<Folder>>>{};

  TestContextManager(MemoryResourceProvider resourceProvider,
      PackageMapProvider packageMapProvider)
      : super(resourceProvider, packageMapProvider);

  @override
  void addContext(Folder folder, Map<String, List<Folder>> packageMap) {
    String path = folder.path;
    expect(currentContextPaths, isNot(contains(path)));
    currentContextTimestamps[path] = now;
    currentContextFilePaths[path] = <String, int>{};
    currentContextPackageMaps[path] = packageMap;
  }

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    Map<String, int> filePaths = currentContextFilePaths[contextFolder.path];
    for (Source source in changeSet.addedSources) {
      expect(filePaths, isNot(contains(source.fullName)));
      filePaths[source.fullName] = now;
    }
    for (Source source in changeSet.removedSources) {
      expect(filePaths, contains(source.fullName));
      filePaths.remove(source.fullName);
    }
    for (Source source in changeSet.changedSources) {
      expect(filePaths, contains(source.fullName));
      filePaths[source.fullName] = now;
    }
  }

  void assertContextFiles(String contextPath, List<String> expectedFiles) {
    var actualFiles = currentContextFilePaths[contextPath].keys;
    expect(actualFiles, unorderedEquals(expectedFiles));
  }

  void assertContextPaths(List<String> expected) {
    expect(currentContextPaths, unorderedEquals(expected));
  }

  @override
  void removeContext(Folder folder) {
    String path = folder.path;
    expect(currentContextPaths, contains(path));
    currentContextTimestamps.remove(path);
    currentContextFilePaths.remove(path);
    currentContextPackageMaps.remove(path);
  }

  @override
  void updateContextPackageMap(Folder contextFolder, Map<String,
      List<Folder>> packageMap) {
    currentContextPackageMaps[contextFolder.path] = packageMap;
  }
}
