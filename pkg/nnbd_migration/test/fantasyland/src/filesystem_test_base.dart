// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:nnbd_migration/src/fantasyland/fantasy_repo_impl.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace_impl.dart';
import 'package:nnbd_migration/src/utilities/subprocess_launcher.dart';
import 'package:path/path.dart' as path;
import 'package:mockito/mockito.dart';

class MockSubprocessLauncher extends Mock implements SubprocessLauncher {}

class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

class MockLink extends Mock implements Link {}

class FilesystemTestBase {
  // TODO(jcollins-g): extend MemoryResourceProvider and analyzer File
  // implementations and port over, or add mock_filesystem to third_party.
  Map<String, MockFile> mockFiles;
  Map<String, MockDirectory> mockDirectories;
  Map<String, MockLink> mockLinks;
  MockDirectory Function(String) directoryBuilder;
  MockFile Function(String) fileBuilder;
  MockLink Function(String) linkBuilder;
  MockSubprocessLauncher mockLauncher;
  FantasyRepoDependencies fantasyRepoDependencies;
  FantasyWorkspaceDependencies workspaceDependencies;

  setUp() {
    mockFiles = {};
    mockDirectories = {};
    mockLinks = {};
    mockLauncher = MockSubprocessLauncher();

    fileBuilder = (String s) {
      s = path.normalize(s);
      mockFiles[s] ??= MockFile();
      when(mockFiles[s].path).thenReturn(s);
      return mockFiles[s];
    };
    directoryBuilder = (String s) {
      s = path.normalize(s);
      mockDirectories[s] ??= MockDirectory();
      when(mockDirectories[s].path).thenReturn(s);
      return mockDirectories[s];
    };
    linkBuilder = (String s) {
      s = path.normalize(s);
      mockLinks[s] ??= MockLink();
      when(mockLinks[s].path).thenReturn(s);
      return mockLinks[s];
    };

    workspaceDependencies = FantasyWorkspaceDependencies(
        fileBuilder: fileBuilder,
        directoryBuilder: directoryBuilder,
        linkBuilder: linkBuilder,
        launcher: mockLauncher);
    fantasyRepoDependencies = FantasyRepoDependencies.fromWorkspaceDependencies(
        workspaceDependencies);
  }
}
