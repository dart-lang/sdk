// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.context.directory.manager;

import 'mocks.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analysis_server/src/context_directory_manager.dart';
import 'package:analysis_server/src/package_map_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

class TestContextDirectoryManager extends ContextDirectoryManager {
  TestContextDirectoryManager(
      MemoryResourceProvider resourceProvider, PackageMapProvider packageMapProvider)
      : super(resourceProvider, packageMapProvider);

  /**
   * Source of timestamps stored in [currentContextFilePaths].
   */
  int now = 0;

  final Set<String> currentContextPaths = new Set<String>();

  /**
   * Map from context to (map from file path to timestamp of last event)
   */
  final Map<String, Map<String, int>> currentContextFilePaths = <String, Map<String, int>>{};

  /**
   * Map from context to package map
   */
  final Map<String, Map<String, List<Folder>>> currentContextPackageMaps =
      <String, Map<String, List<Folder>>>{};

  @override
  void addContext(Folder folder, Map<String, List<Folder>> packageMap) {
    String path = folder.path;
    currentContextPaths.add(path);
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

  @override
  void removeContext(Folder folder) {
    String path = folder.path;
    currentContextPaths.remove(path);
    currentContextFilePaths.remove(path);
    currentContextPackageMaps.remove(path);
  }

  @override
  void updateContextPackageMap(Folder contextFolder,
                               Map<String, List<Folder>> packageMap) {
    currentContextPackageMaps[contextFolder.path]= packageMap;
  }
}

main() {
  groupSep = ' | ';

  group('ContextDirectoryManager', () {
    TestContextDirectoryManager manager;
    MemoryResourceProvider resourceProvider;
    MockPackageMapProvider packageMapProvider;

    setUp(() {
      resourceProvider = new MemoryResourceProvider();
      packageMapProvider = new MockPackageMapProvider();
      manager = new TestContextDirectoryManager(resourceProvider, packageMapProvider);
    });

    test('add folder with pubspec', () {
      String projPath = '/my/proj';
      String pubspecPath = posix.join(projPath, 'pubspec.yaml');
      resourceProvider.newFolder(projPath);
      resourceProvider.newFile(pubspecPath, 'pubspec');
      manager.setRoots(<String>[projPath], <String>[]);
      expect(manager.currentContextPaths, hasLength(1));
      expect(manager.currentContextPaths, contains(projPath));
      expect(manager.currentContextFilePaths[projPath], hasLength(0));
    });

    test('newly added folders get proper package map', () {
      String projPath = '/my/proj';
      String packagePath = '/package/foo';
      resourceProvider.newFolder(projPath);
      Folder packageFolder = resourceProvider.newFolder(packagePath);
      packageMapProvider.packageMap = {'foo': [packageFolder]};
      manager.setRoots(<String>[projPath], <String>[]);
      expect(manager.currentContextPackageMaps[projPath],
          equals(packageMapProvider.packageMap));
    });

    test('add folder without pubspec', () {
      String projPath = '/my/proj';
      resourceProvider.newFolder(projPath);
      packageMapProvider.packageMap = null;
      manager.setRoots(<String>[projPath], <String>[]);
      expect(manager.currentContextPaths, hasLength(1));
      expect(manager.currentContextPaths, contains(projPath));
      expect(manager.currentContextFilePaths[projPath], hasLength(0));
    });

    test('add folder with dart file', () {
      String projPath = '/my/proj';
      resourceProvider.newFolder(projPath);
      String filePath = posix.join(projPath, 'foo.dart');
      resourceProvider.newFile(filePath, 'contents');
      manager.setRoots(<String>[projPath], <String>[]);
      var filePaths = manager.currentContextFilePaths[projPath];
      expect(filePaths, hasLength(1));
      expect(filePaths, contains(filePath));
    });

    test('add folder with dummy link', () {
      String projPath = '/my/proj';
      resourceProvider.newFolder(projPath);
      String filePath = posix.join(projPath, 'foo.dart');
      resourceProvider.newDummyLink(filePath);
      manager.setRoots(<String>[projPath], <String>[]);
      var filePaths = manager.currentContextFilePaths[projPath];
      expect(filePaths, isEmpty);
    });

    test('add folder with dart file in subdir', () {
      String projPath = '/my/proj';
      resourceProvider.newFolder(projPath);
      String filePath = posix.join(projPath, 'foo', 'bar.dart');
      resourceProvider.newFile(filePath, 'contents');
      manager.setRoots(<String>[projPath], <String>[]);
      var filePaths = manager.currentContextFilePaths[projPath];
      expect(filePaths, hasLength(1));
      expect(filePaths, contains(filePath));
    });

    test('remove folder with pubspec', () {
      String projPath = '/my/proj';
      String pubspecPath = posix.join(projPath, 'pubspec.yaml');
      resourceProvider.newFolder(projPath);
      resourceProvider.newFile(pubspecPath, 'pubspec');
      manager.setRoots(<String>[projPath], <String>[]);
      manager.setRoots(<String>[], <String>[]);
      expect(manager.currentContextPaths, hasLength(0));
      expect(manager.currentContextFilePaths, hasLength(0));
    });

    test('remove folder without pubspec', () {
      String projPath = '/my/proj';
      resourceProvider.newFolder(projPath);
      packageMapProvider.packageMap = null;
      manager.setRoots(<String>[projPath], <String>[]);
      manager.setRoots(<String>[], <String>[]);
      expect(manager.currentContextPaths, hasLength(0));
      expect(manager.currentContextFilePaths, hasLength(0));
    });

    test('ignore files in packages dir', () {
      String projPath = '/my/proj';
      resourceProvider.newFolder(projPath);
      String pubspecPath = posix.join(projPath, 'pubspec.yaml');
      resourceProvider.newFile(pubspecPath, 'pubspec');
      String filePath1 = posix.join(projPath, 'packages', 'file1.dart');
      resourceProvider.newFile(filePath1, 'contents');
      manager.setRoots(<String>[projPath], <String>[]);
      Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
      expect(filePaths, hasLength(0));
      String filePath2 = posix.join(projPath, 'packages', 'file2.dart');
      resourceProvider.newFile(filePath2, 'contents');
      return pumpEventQueue().then((_) {
        expect(filePaths, hasLength(0));
      });
    });

    group('isInAnalysisRoot', () {
      test('in root', () {
        String projPath = '/project';
        resourceProvider.newFolder(projPath);
        manager.setRoots(<String>[projPath], <String>[]);
        expect(manager.isInAnalysisRoot('/project/test.dart'), isTrue);
      });

      test('not in root', () {
        String projPath = '/project';
        resourceProvider.newFolder(projPath);
        manager.setRoots(<String>[projPath], <String>[]);
        expect(manager.isInAnalysisRoot('/test.dart'), isFalse);
      });
    });

    group('detect context modifications', () {
      String projPath;

      setUp(() {
        projPath = '/my/proj';
        resourceProvider.newFolder(projPath);
      });

      test('Add dummy link', () {
        manager.setRoots(<String>[projPath], <String>[]);
        Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
        expect(filePaths, isEmpty);
        String filePath = posix.join(projPath, 'foo.dart');
        resourceProvider.newDummyLink(filePath);
        return pumpEventQueue().then((_) {
          expect(filePaths, isEmpty);
        });
      });

      test('Add file', () {
        manager.setRoots(<String>[projPath], <String>[]);
        Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
        expect(filePaths, hasLength(0));
        String filePath = posix.join(projPath, 'foo.dart');
        resourceProvider.newFile(filePath, 'contents');
        return pumpEventQueue().then((_) {
          expect(filePaths, hasLength(1));
          expect(filePaths, contains(filePath));
        });
      });

      test('Add file in subdirectory', () {
        manager.setRoots(<String>[projPath], <String>[]);
        Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
        expect(filePaths, hasLength(0));
        String filePath = posix.join(projPath, 'foo', 'bar.dart');
        resourceProvider.newFile(filePath, 'contents');
        return pumpEventQueue().then((_) {
          expect(filePaths, hasLength(1));
          expect(filePaths, contains(filePath));
        });
      });

      test('Delete file', () {
        String filePath = posix.join(projPath, 'foo.dart');
        resourceProvider.newFile(filePath, 'contents');
        manager.setRoots(<String>[projPath], <String>[]);
        Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
        expect(filePaths, hasLength(1));
        expect(filePaths, contains(filePath));
        resourceProvider.deleteFile(filePath);
        return pumpEventQueue().then((_) => expect(filePaths, hasLength(0)));
      });

      test('Modify file', () {
        String filePath = posix.join(projPath, 'foo.dart');
        resourceProvider.newFile(filePath, 'contents');
        manager.setRoots(<String>[projPath], <String>[]);
        Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
        expect(filePaths, hasLength(1));
        expect(filePaths, contains(filePath));
        expect(filePaths[filePath], equals(manager.now));
        manager.now++;
        resourceProvider.modifyFile(filePath, 'new contents');
        return pumpEventQueue().then((_) => expect(filePaths[filePath], equals(
            manager.now)));
      });

      test('Modify package map dependency', () {
        String dependencyPath = posix.join(projPath, 'dep');
        resourceProvider.newFile(dependencyPath, 'contents');
        String dartFilePath = posix.join(projPath, 'main.dart');
        resourceProvider.newFile(dartFilePath, 'contents');
        packageMapProvider.dependencies.add(dependencyPath);
        manager.setRoots(<String>[projPath], <String>[]);
        expect(manager.currentContextPackageMaps[projPath],
            equals(packageMapProvider.packageMap));
        String packagePath = '/package/foo';
        resourceProvider.newFolder(packagePath);
        packageMapProvider.packageMap = {'foo': projPath};
        // Changing a .dart file in the project shouldn't cause a new
        // package map to be picked up.
        resourceProvider.modifyFile(dartFilePath, 'new contents');
        return pumpEventQueue().then((_) {
          expect(manager.currentContextPackageMaps[projPath], isEmpty);
          // However, changing the package map dependency should.
          resourceProvider.modifyFile(dependencyPath, 'new contents');
          return pumpEventQueue().then((_) {
            expect(manager.currentContextPackageMaps[projPath],
                equals(packageMapProvider.packageMap));
          });
        });
      });

      test('Modify package map dependency - packageMapProvider failure', () {
        String dependencyPath = posix.join(projPath, 'dep');
        resourceProvider.newFile(dependencyPath, 'contents');
        String dartFilePath = posix.join(projPath, 'main.dart');
        resourceProvider.newFile(dartFilePath, 'contents');
        packageMapProvider.dependencies.add(dependencyPath);
        manager.setRoots(<String>[projPath], <String>[]);
        expect(manager.currentContextPackageMaps[projPath],
            equals(packageMapProvider.packageMap));
        // Change the package map dependency so that the packageMapProvider is
        // re-run, and arrange for it to return null from computePackageMap().
        packageMapProvider.packageMap = null;
        resourceProvider.modifyFile(dependencyPath, 'new contents');
        return pumpEventQueue().then((_) {
          // The package map should have been changed to null.
          expect(manager.currentContextPackageMaps[projPath], isNull);
        });
      });
    });
  });
}
