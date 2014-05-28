// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.context.directory.manager;

import 'package:analysis_server/src/context_directory_manager.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:unittest/unittest.dart';

class TestContextDirectoryManager extends ContextDirectoryManager {
  TestContextDirectoryManager(MemoryResourceProvider provider) : super(provider);

  final Set<String> currentContextPaths = new Set<String>();

  @override
  void addContext(Folder folder) {
    currentContextPaths.add(folder.fullName);
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
      provider.newFile('/my/proj/pubspec.yaml', 'pubspec');
      manager.setRoots(<String>['/my/proj'], <String>[]);
      expect(manager.currentContextPaths, hasLength(1));
      expect(manager.currentContextPaths, contains('/my/proj'));
    });
  });
}