// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.context.directory.manager;

import 'mocks.dart';
import 'package:analysis_server/src/context_directory_manager.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

class TestContextDirectoryManager extends ContextDirectoryManager {
  TestContextDirectoryManager(MemoryResourceProvider provider) : super(provider);

  /**
   * Source of timestamps stored in [currentContextFilePaths].
   */
  int now = 0;

  final Set<String> currentContextPaths = new Set<String>();
  final Map<String, String> currentContextPubspecPaths = <String, String>{};

  /**
   * Map from context to (map from file path to timestamp of last event)
   */
  final Map<String, Map<String, int>> currentContextFilePaths = <String, Map<String, int>>{};

  @override
  void addContext(Folder folder, File pubspecFile) {
    String path = folder.path;
    currentContextPaths.add(path);
    currentContextPubspecPaths[path] = pubspecFile != null ? pubspecFile.path : null;
    currentContextFilePaths[path] = <String, int>{};
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
    currentContextPubspecPaths.remove(path);
    currentContextFilePaths.remove(path);
  }
}

main() {
  groupSep = ' | ';

  group('ContextDirectoryManager', () {
    TestContextDirectoryManager manager;
    MemoryResourceProvider provider;

    setUp(() {
      provider = new MemoryResourceProvider();
      manager = new TestContextDirectoryManager(provider);
    });

    test('add folder with pubspec', () {
      String projPath = '/my/proj';
      String pubspecPath = posix.join(projPath, 'pubspec.yaml');
      provider.newFolder(projPath);
      provider.newFile(pubspecPath, 'pubspec');
      manager.setRoots(<String>[projPath], <String>[]);
      expect(manager.currentContextPaths, hasLength(1));
      expect(manager.currentContextPaths, contains(projPath));
      expect(manager.currentContextPubspecPaths[projPath], equals(pubspecPath));
      expect(manager.currentContextFilePaths[projPath], hasLength(0));
    });

    test('add folder without pubspec', () {
      String projPath = '/my/proj';
      provider.newFolder(projPath);
      manager.setRoots(<String>[projPath], <String>[]);
      expect(manager.currentContextPaths, hasLength(1));
      expect(manager.currentContextPaths, contains(projPath));
      expect(manager.currentContextPubspecPaths[projPath], isNull);
      expect(manager.currentContextFilePaths[projPath], hasLength(0));
    });

    test('add folder with dart file', () {
      String projPath = '/my/proj';
      provider.newFolder(projPath);
      String filePath = posix.join(projPath, 'foo.dart');
      provider.newFile(filePath, 'contents');
      manager.setRoots(<String>[projPath], <String>[]);
      var filePaths = manager.currentContextFilePaths[projPath];
      expect(filePaths, hasLength(1));
      expect(filePaths, contains(filePath));
    });

    test('add folder with dart file in subdir', () {
      String projPath = '/my/proj';
      provider.newFolder(projPath);
      String filePath = posix.join(projPath, 'foo', 'bar.dart');
      provider.newFile(filePath, 'contents');
      manager.setRoots(<String>[projPath], <String>[]);
      var filePaths = manager.currentContextFilePaths[projPath];
      expect(filePaths, hasLength(1));
      expect(filePaths, contains(filePath));
    });

    test('remove folder with pubspec', () {
      String projPath = '/my/proj';
      String pubspecPath = posix.join(projPath, 'pubspec.yaml');
      provider.newFolder(projPath);
      provider.newFile(pubspecPath, 'pubspec');
      manager.setRoots(<String>[projPath], <String>[]);
      manager.setRoots(<String>[], <String>[]);
      expect(manager.currentContextPaths, hasLength(0));
      expect(manager.currentContextPubspecPaths, hasLength(0));
      expect(manager.currentContextFilePaths, hasLength(0));
    });

    test('remove folder without pubspec', () {
      String projPath = '/my/proj';
      provider.newFolder(projPath);
      manager.setRoots(<String>[projPath], <String>[]);
      manager.setRoots(<String>[], <String>[]);
      expect(manager.currentContextPaths, hasLength(0));
      expect(manager.currentContextPubspecPaths, hasLength(0));
      expect(manager.currentContextFilePaths, hasLength(0));
    });

    test('ignore files in packages dir', () {
      String projPath = '/my/proj';
      provider.newFolder(projPath);
      String pubspecPath = posix.join(projPath, 'pubspec.yaml');
      provider.newFile(pubspecPath, 'pubspec');
      String filePath1 = posix.join(projPath, 'packages', 'file1.dart');
      provider.newFile(filePath1, 'contents');
      manager.setRoots(<String>[projPath], <String>[]);
      Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
      expect(filePaths, hasLength(0));
      String filePath2 = posix.join(projPath, 'packages', 'file2.dart');
      provider.newFile(filePath2, 'contents');
      return pumpEventQueue().then((_) {
        expect(filePaths, hasLength(0));
      });
    });

    group('detect context modifications', () {
      String projPath;

      setUp(() {
        projPath = '/my/proj';
        provider.newFolder(projPath);
      });

      test('Add file', () {
        manager.setRoots(<String>[projPath], <String>[]);
        Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
        expect(filePaths, hasLength(0));
        String filePath = posix.join(projPath, 'foo.dart');
        provider.newFile(filePath, 'contents');
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
        provider.newFile(filePath, 'contents');
        return pumpEventQueue().then((_) {
          expect(filePaths, hasLength(1));
          expect(filePaths, contains(filePath));
        });
      });

      test('Add pubspec file', () {
        manager.setRoots(<String>[projPath], <String>[]);
        String pubspecPath = posix.join(projPath, 'pubspec.yaml');
        expect(manager.currentContextPubspecPaths[projPath], isNull);
        provider.newFile(pubspecPath, 'pubspec');
        return pumpEventQueue().then((_) {
          expect(manager.currentContextPubspecPaths[projPath], equals(pubspecPath));
        });
      });

      test('Delete file', () {
        String filePath = posix.join(projPath, 'foo.dart');
        provider.newFile(filePath, 'contents');
        manager.setRoots(<String>[projPath], <String>[]);
        Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
        expect(filePaths, hasLength(1));
        expect(filePaths, contains(filePath));
        provider.deleteFile(filePath);
        return pumpEventQueue().then((_) => expect(filePaths, hasLength(0)));
      });

      test('Delete pubspec file', () {
        String pubspecPath = posix.join(projPath, 'pubspec.yaml');
        provider.newFile(pubspecPath, 'pubspec');
        manager.setRoots(<String>[projPath], <String>[]);
        expect(manager.currentContextPubspecPaths[projPath], equals(pubspecPath));
        provider.deleteFile(pubspecPath);
        return pumpEventQueue().then((_) {
          expect(manager.currentContextPubspecPaths[projPath], isNull);
        });
      });

      test('Modify file', () {
        String filePath = posix.join(projPath, 'foo.dart');
        provider.newFile(filePath, 'contents');
        manager.setRoots(<String>[projPath], <String>[]);
        Map<String, int> filePaths = manager.currentContextFilePaths[projPath];
        expect(filePaths, hasLength(1));
        expect(filePaths, contains(filePath));
        expect(filePaths[filePath], equals(manager.now));
        manager.now++;
        provider.modifyFile(filePath, 'new contents');
        return pumpEventQueue().then((_) => expect(filePaths[filePath], equals(
            manager.now)));
      });
    });
  });
}
