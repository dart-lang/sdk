// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis_server.src.single_context_manager;

import 'dart:core';

import 'package:analysis_server/src/single_context_manager.dart';
import 'package:analysis_server/src/utilities/null_string_sink.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:path/path.dart' as path;
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_manager_test.dart' show TestContextManagerCallbacks;
import 'mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SingleContextManagerTest);
  });
}

@reflectiveTest
class SingleContextManagerTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  TestUriResolver packageResolver;
  TestContextManagerCallbacks callbacks;
  SingleContextManager manager;

  List<Glob> get analysisFilesGlobs {
    List<String> patterns = <String>[
      '**/*.${AnalysisEngine.SUFFIX_DART}',
      '**/*.${AnalysisEngine.SUFFIX_HTML}',
    ];
    return patterns
        .map((pattern) => new Glob(path.posix.separator, pattern))
        .toList();
  }

  String newFile(List<String> pathComponents, [String content = '']) {
    String filePath = path.posix.joinAll(pathComponents);
    resourceProvider.newFile(filePath, content);
    return filePath;
  }

  String newFolder(List<String> pathComponents) {
    String folderPath = path.posix.joinAll(pathComponents);
    resourceProvider.newFolder(folderPath);
    return folderPath;
  }

  void setUp() {
    packageResolver = new TestUriResolver();

    _processRequiredPlugins();
    DartSdkManager sdkManager = new DartSdkManager('/', false);
    manager = new SingleContextManager(resourceProvider, sdkManager,
        (_) => packageResolver, analysisFilesGlobs, new AnalysisOptionsImpl());
    PerformanceLog logger = new PerformanceLog(new NullStringSink());
    AnalysisDriverScheduler scheduler = new AnalysisDriverScheduler(logger);
    callbacks = new TestContextManagerCallbacks(
        resourceProvider, sdkManager, logger, scheduler);
    manager.callbacks = callbacks;
  }

  void test_isIgnored_false() {
    String project = '/project';
    resourceProvider.newFolder(project);
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    expect(manager.isIgnored('$project/file.dart'), isFalse);
  }

  void test_isIgnored_true_inDotFolder() {
    String project = '/project';
    resourceProvider.newFolder(project);
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    expect(manager.isIgnored('$project/foo/.bar/file.dart'), isTrue);
  }

  void test_isIgnored_true_inExcludedPath() {
    String project = '/project';
    String excludedPath = '/project/excluded';
    resourceProvider.newFolder(project);
    manager.setRoots(
        <String>[project], <String>[excludedPath], <String, String>{});
    expect(manager.isIgnored('$excludedPath/file.dart'), isTrue);
  }

  void test_isIgnored_true_notInRoot() {
    String root1 = '/context/root1';
    String root2 = '/context/root2';
    resourceProvider.newFolder(root1);
    resourceProvider.newFolder(root2);
    manager.setRoots(<String>[root1, root2], <String>[], <String, String>{});
    expect(manager.isIgnored('/context/root3/file.dart'), isTrue);
  }

  void test_isInAnalysisRoot_false_inExcludedPath() {
    String project = '/project';
    String excludedPath = '/project/excluded';
    resourceProvider.newFolder(project);
    manager.setRoots(
        <String>[project], <String>[excludedPath], <String, String>{});
    expect(manager.isInAnalysisRoot('$excludedPath/file.dart'), isFalse);
  }

  void test_isInAnalysisRoot_false_notInRoot() {
    String root1 = '/context/root1';
    String root2 = '/context/root2';
    resourceProvider.newFolder(root1);
    resourceProvider.newFolder(root2);
    manager.setRoots(<String>[root1, root2], <String>[], <String, String>{});
    expect(manager.isInAnalysisRoot('/context/root3/file.dart'), isFalse);
  }

  void test_isInAnalysisRoot_true() {
    String project = '/project';
    resourceProvider.newFolder(project);
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    expect(manager.isInAnalysisRoot('$project/file.dart'), isTrue);
  }

  void test_refresh() {
    String project = '/project';
    String file1 = '$project/file1.dart';
    String file2 = '$project/file2.dart';
    // create files
    resourceProvider.newFile(file1, '');
    resourceProvider.newFile(file2, '');
    // set roots
    manager.setRoots(<String>[project], <String>[file2], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1]);
    // refresh
    manager.refresh([]);
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1]);
  }

  void test_setRoots_addFolderWithDartFile() {
    String project = '/project';
    String file = '$project/lib/foo.dart';
    resourceProvider.newFile(file, '');
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    // verify
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file]);
  }

  void test_setRoots_addFolderWithDartFileInSubfolder() {
    String project = '/project';
    String file = '$project/foo/bar.dart';
    resourceProvider.newFile(file, '');
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    // verify
    callbacks.assertContextFiles(project, [file]);
  }

  void test_setRoots_addFolderWithDummyLink() {
    String project = '/project';
    String file = '$project/foo.dart';
    resourceProvider.newDummyLink(file);
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    // verify
    callbacks.assertContextFiles(project, []);
  }

  void test_setRoots_exclude_newRoot_withExcludedFile() {
    String project = '/project';
    String file1 = '$project/file1.dart';
    String file2 = '$project/file2.dart';
    // create files
    resourceProvider.newFile(file1, '');
    resourceProvider.newFile(file2, '');
    // set roots
    manager.setRoots(<String>[project], <String>[file1], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file2]);
  }

  void test_setRoots_exclude_newRoot_withExcludedFolder() {
    String project = '/project';
    String folderA = '$project/aaa';
    String folderB = '$project/bbb';
    String fileA = '$folderA/a.dart';
    String fileB = '$folderB/b.dart';
    // create files
    resourceProvider.newFile(fileA, '');
    resourceProvider.newFile(fileB, '');
    // set roots
    manager.setRoots(<String>[project], <String>[folderB], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  void test_setRoots_exclude_sameRoot_addExcludedFile() {
    String project = '/project';
    String file1 = '$project/file1.dart';
    String file2 = '$project/file2.dart';
    // create files
    resourceProvider.newFile(file1, '');
    resourceProvider.newFile(file2, '');
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

  void test_setRoots_ignoreGlobs() {
    String project = '/project';
    String file1 = '$project/file.dart';
    String file2 = '$project/file.foo';
    // create files
    resourceProvider.newFile(file1, '');
    resourceProvider.newFile(file2, '');
    // set roots
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [file1]);
  }

  void test_setRoots_newContextFolder_coverNewRoot() {
    String contextPath = '/context';
    String root1 = '$contextPath/root1';
    String file1 = '$root1/file1.dart';
    String root2 = '$contextPath/root2';
    String file2 = '$root2/file1.dart';
    // create files
    resourceProvider.newFile(file1, '');
    resourceProvider.newFile(file2, '');
    // cover single root '/context/root1'
    manager.setRoots(<String>[root1], <String>[], <String, String>{});
    callbacks.assertContextPaths([root1]);
    callbacks.assertContextFiles(root1, [file1]);
    // cover two roots
    manager.setRoots(<String>[root1, root2], <String>[], <String, String>{});
    callbacks.assertContextPaths([contextPath]);
    callbacks.assertContextFiles(contextPath, [file1, file2]);
    // cover single root '/context/root2'
    manager.setRoots(<String>[root2], <String>[], <String, String>{});
    callbacks.assertContextPaths([root2]);
    callbacks.assertContextFiles(root2, [file2]);
  }

  void test_setRoots_newContextFolder_replace() {
    String contextPath1 = '/context1';
    String root11 = '$contextPath1/root1';
    String root12 = '$contextPath1/root2';
    String file11 = '$root11/file1.dart';
    String file12 = '$root12/file2.dart';
    String contextPath2 = '/context2';
    String root21 = '$contextPath2/root1';
    String root22 = '$contextPath2/root2';
    String file21 = '$root21/file1.dart';
    String file22 = '$root22/file2.dart';
    // create files
    resourceProvider.newFile(file11, '');
    resourceProvider.newFile(file12, '');
    resourceProvider.newFile(file21, '');
    resourceProvider.newFile(file22, '');
    // set roots in '/context1'
    manager.setRoots(<String>[root11, root12], <String>[], <String, String>{});
    callbacks.assertContextPaths([contextPath1]);
    callbacks.assertContextFiles(contextPath1, [file11, file12]);
    // set roots in '/context2'
    manager.setRoots(<String>[root21, root22], <String>[], <String, String>{});
    callbacks.assertContextPaths([contextPath2]);
    callbacks.assertContextFiles(contextPath2, [file21, file22]);
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

  test_watch_addFile() async {
    String project = '/project';
    resourceProvider.newFolder(project);
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    // empty folder initially
    callbacks.assertContextFiles(project, []);
    // add file
    String file = '$project/foo.dart';
    resourceProvider.newFile(file, 'contents');
    // the file was added
    await pumpEventQueue();
    callbacks.assertContextFiles(project, [file]);
  }

  test_watch_addFile_afterChangingRoots() async {
    String contextPath = '/context';
    String root1 = '$contextPath/root1';
    String root2 = '$contextPath/root2';
    String file1 = '$root1/file1.dart';
    String file2 = '$root2/file2.dart';
    resourceProvider.newFolder(root1);
    resourceProvider.newFolder(root2);
    manager.setRoots(<String>[root1], <String>[], <String, String>{});
    manager.setRoots(<String>[root2], <String>[], <String, String>{});
    manager.setRoots(<String>[root1, root2], <String>[], <String, String>{});
    manager.setRoots(<String>[root2], <String>[], <String, String>{});
    // empty folder initially
    callbacks.assertContextFiles(root2, []);
    // add files
    resourceProvider.newFile(file1, '');
    resourceProvider.newFile(file2, '');
    // the file was added
    await pumpEventQueue();
    callbacks.assertContextFiles(root2, [file2]);
  }

  test_watch_addFile_excluded() async {
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
    await pumpEventQueue();
    callbacks.assertContextPaths([project]);
    callbacks.assertContextFiles(project, [fileA]);
  }

  test_watch_addFile_notInRoot() async {
    String contextPath = '/roots';
    String root1 = '$contextPath/root1';
    String root2 = '$contextPath/root2';
    String root3 = '$contextPath/root3';
    String file1 = '$root1/file1.dart';
    String file2 = '$root2/file2.dart';
    String file3 = '$root3/file3.dart';
    // create files
    resourceProvider.newFile(file1, '');
    resourceProvider.newFile(file2, '');
    // set roots
    manager.setRoots(<String>[root1, root2], <String>[], <String, String>{});
    callbacks.assertContextPaths([contextPath]);
    callbacks.assertContextFiles(contextPath, [file1, file2]);
    // add a file, not in a root - ignored
    resourceProvider.newFile(file3, '');
    await pumpEventQueue();
    callbacks.assertContextPaths([contextPath]);
    callbacks.assertContextFiles(contextPath, [file1, file2]);
  }

  test_watch_addFile_pathContainsDotFile() async {
    // If a file is added and the absolute path to it contains a folder whose
    // name begins with '.', then the file is ignored.
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

  test_watch_addFileInSubFolder() async {
    String project = '/project';
    resourceProvider.newFolder(project);
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    // empty folder initially
    callbacks.assertContextFiles(project, []);
    // add file in subfolder
    String file = '$project/foo/bar.dart';
    resourceProvider.newFile(file, 'contents');
    // the file was added
    await pumpEventQueue();
    callbacks.assertContextFiles(project, [file]);
  }

  test_watch_deleteFile() async {
    String project = '/project';
    String file = '$project/foo.dart';
    // add root with a file
    resourceProvider.newFile(file, 'contents');
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    // the file was added
    callbacks.assertContextFiles(project, [file]);
    // delete the file
    resourceProvider.deleteFile(file);
    await pumpEventQueue();
    callbacks.assertContextFiles(project, []);
  }

  test_watch_deleteFolder() async {
    String project = '/project';
    String file = '$project/foo.dart';
    // add root with a file
    resourceProvider.newFile(file, 'contents');
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    // the file was added
    callbacks.assertContextFiles(project, [file]);
    // delete the folder
    resourceProvider.deleteFolder(project);
    await pumpEventQueue();
    callbacks.assertContextFiles(project, []);
  }

  test_watch_modifyFile() async {
    String project = '/project';
    String file = '$project/foo.dart';
    // add root with a file
    resourceProvider.newFile(file, 'contents');
    manager.setRoots(<String>[project], <String>[], <String, String>{});
    // the file was added
    Map<String, int> filePaths = callbacks.currentContextFilePaths[project];
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(file));
    expect(filePaths[file], equals(callbacks.now));
    // update the file
    callbacks.now++;
    resourceProvider.modifyFile(file, 'new contents');
    await pumpEventQueue();
    return expect(filePaths[file], equals(callbacks.now));
  }

  void _processRequiredPlugins() {
    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);
  }
}

class TestUriResolver extends UriResolver {
  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    return null;
  }
}
