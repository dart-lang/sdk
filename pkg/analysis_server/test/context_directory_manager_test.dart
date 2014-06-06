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

  final Set<String> currentContextPaths = new Set<String>();
  final Map<String, String> currentContextPubspecPaths = <String, String>{};
  final Map<String, Set<String>> currentContextFilePaths = <String, Set<String>>{};

  @override
  void addContext(Folder folder, File pubspecFile) {
    String path = folder.path;
    currentContextPaths.add(path);
    currentContextPubspecPaths[path] = pubspecFile != null ? pubspecFile.path : null;
    currentContextFilePaths[path] = new Set<String>();
  }

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    Set<String> filePaths = currentContextFilePaths[contextFolder.path];
    for (Source source in changeSet.addedSources) {
      expect(filePaths, isNot(contains(source.fullName)));
      filePaths.add(source.fullName);
    }
    for (Source source in changeSet.removedSources) {
      expect(filePaths, contains(source.fullName));
      filePaths.remove(source.fullName);
    }
    // TODO(paulberry): handle source.changedSources.
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

    test('ignore files in packages dir', () {
      String projPath = '/my/proj';
      provider.newFolder(projPath);
      String pubspecPath = posix.join(projPath, 'pubspec.yaml');
      provider.newFile(pubspecPath, 'pubspec');
      String filePath1 = posix.join(projPath, 'packages', 'file1.dart');
      provider.newFile(filePath1, 'contents');
      manager.setRoots(<String>[projPath], <String>[]);
      Set<String> filePaths = manager.currentContextFilePaths[projPath];
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
        Set<String> filePaths = manager.currentContextFilePaths[projPath];
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
        Set<String> filePaths = manager.currentContextFilePaths[projPath];
        expect(filePaths, hasLength(0));
        String filePath = posix.join(projPath, 'foo', 'bar.dart');
        provider.newFile(filePath, 'contents');
        return pumpEventQueue().then((_) {
          expect(filePaths, hasLength(1));
          expect(filePaths, contains(filePath));
        });
      });

      test('Delete file', () {
        String filePath = posix.join(projPath, 'foo.dart');
        provider.newFile(filePath, 'contents');
        manager.setRoots(<String>[projPath], <String>[]);
        Set<String> filePaths = manager.currentContextFilePaths[projPath];
        expect(filePaths, hasLength(1));
        expect(filePaths, contains(filePath));
        provider.deleteFile(filePath);
        return pumpEventQueue().then((_) => expect(filePaths, hasLength(0)));
      });
    });
  });
}