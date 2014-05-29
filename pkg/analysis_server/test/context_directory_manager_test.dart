// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.context.directory.manager;

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
    currentContextPaths.add(folder.fullName);
    currentContextPubspecPaths[folder.fullName] = pubspecFile != null ? pubspecFile.fullName : null;
    currentContextFilePaths[folder.fullName] = new Set<String>();
  }

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    Set<String> filePaths = currentContextFilePaths[contextFolder.fullName];
    for (Source source in changeSet.addedSources) {
      filePaths.add(source.fullName);
    }
    // TODO(paulberry): handle source.changedSources and source.removedSources.
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
  });
}