// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis_server.src.single_context_manager;

import 'dart:core' hide Resource;

import 'package:analysis_server/src/single_context_manager.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:linter/src/plugin/linter_plugin.dart';
import 'package:path/path.dart';
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import 'context_manager_test.dart' show TestContextManagerCallbacks;
import 'mock_sdk.dart';
import 'utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(SingleContextManagerTest);
}

@reflectiveTest
class SingleContextManagerTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  TestUriResolver packageResolver;
  TestContextManagerCallbacks callbacks;
  SingleContextManager manager;

  /**
   * TODO(scheglov) rename after copying tests!
   */
  String projPath = '/my/project';
  Folder rootFolder;

  List<Glob> get analysisFilesGlobs {
    List<String> patterns = <String>[
      '**/*.${AnalysisEngine.SUFFIX_DART}',
      '**/*.${AnalysisEngine.SUFFIX_HTML}',
    ];
    return patterns
        .map((pattern) => new Glob(JavaFile.pathContext.separator, pattern))
        .toList();
  }

  String newFile(List<String> pathComponents, [String content = '']) {
    String filePath = posix.joinAll(pathComponents);
    resourceProvider.newFile(filePath, content);
    return filePath;
  }

  String newFolder(List<String> pathComponents) {
    String folderPath = posix.joinAll(pathComponents);
    resourceProvider.newFolder(folderPath);
    return folderPath;
  }

  void setUp() {
    rootFolder = resourceProvider.newFolder(projPath);
    packageResolver = new TestUriResolver(resourceProvider, rootFolder);

    _processRequiredPlugins();
    DartSdkManager sdkManager = new DartSdkManager((_) {
      return new MockSdk();
    });
    manager = new SingleContextManager(resourceProvider, sdkManager,
        _providePackageResolver, analysisFilesGlobs);
    callbacks = new TestContextManagerCallbacks(resourceProvider);
    manager.callbacks = callbacks;
    resourceProvider.newFolder(projPath);
  }

  void test_setRoots_addFolderWithDartFile() {
    String filePath = posix.join(projPath, 'lib', 'foo.dart');
    resourceProvider.newFile(filePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // verify
    Map<String, int> filePaths = callbacks.currentContextFilePaths[projPath];
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
    // There is an analysis context.
    List<AnalysisContext> contextsInAnalysisRoot =
        manager.contextsInAnalysisRoot(rootFolder);
    expect(contextsInAnalysisRoot, hasLength(1));
    AnalysisContext context = contextsInAnalysisRoot[0];
    expect(context, isNotNull);
    // Files in lib/ have package: URIs.
    Source result = context.sourceFactory.forUri('package:foo/foo.dart');
    expect(result, isNotNull);
    expect(result.exists(), isTrue);
  }

  void test_setRoots_addFolderWithDartFileInSubfolder() {
    String filePath = posix.join(projPath, 'foo', 'bar.dart');
    resourceProvider.newFile(filePath, 'contents');
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // verify
    Map<String, int> filePaths = callbacks.currentContextFilePaths[projPath];
    expect(filePaths, hasLength(1));
    expect(filePaths, contains(filePath));
  }

  void test_setRoots_addFolderWithDummyLink() {
    String filePath = posix.join(projPath, 'foo.dart');
    resourceProvider.newDummyLink(filePath);
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // verify
    Map<String, int> filePaths = callbacks.currentContextFilePaths[projPath];
    expect(filePaths, isEmpty);
  }

  void test_setRoots_addFolderWithNestedPackageSpec() {
    newFile([projPath, 'aaa', 'pubspec.yaml']);
    newFile([projPath, 'bbb', 'pubspec.yaml']);
    manager.setRoots(<String>[projPath], <String>[], <String, String>{});
    // We don't care about pubspec.yaml files - still just one context.
    callbacks.assertContextPaths([projPath]);
    expect(manager.contextsInAnalysisRoot(rootFolder), hasLength(1));
  }

  void test_setRoots_exclude_newRoot_withExcludedFile() {
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

  void _processRequiredPlugins() {
    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    plugins.add(AnalysisEngine.instance.commandLinePlugin);
    plugins.add(AnalysisEngine.instance.optionsPlugin);
    plugins.add(linterPlugin);
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);
  }

  UriResolver _providePackageResolver(Folder folder) => packageResolver;
}

class TestUriResolver extends UriResolver {
  final ResourceProvider resourceProvider;
  final Folder rootFolder;

  TestUriResolver(this.resourceProvider, this.rootFolder);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (uri.scheme == 'package') {
      List<String> segments = uri.pathSegments;
      if (segments.length >= 2) {
        List<String> relSegments = <String>['lib']..addAll(segments.skip(1));
        String relPath = resourceProvider.pathContext.joinAll(relSegments);
        Resource file = rootFolder.getChild(relPath);
        if (file is File && file.exists) {
          return file.createSource(uri);
        }
      }
    }
    return null;
  }
}
