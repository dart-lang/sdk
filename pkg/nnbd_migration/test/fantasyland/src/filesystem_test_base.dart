// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:mockito/mockito.dart';

class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

class FilesystemTestBase {
  // TODO(jcollins-g): extend MemoryResourceProvider and analyzer File
  // implementations and port over, or add mock_filesystem to third_party.
  Map<String, MockFile> mockFiles;
  Map<String, MockDirectory> mockDirectories;
  MockDirectory Function(String) directoryBuilder;
  MockFile Function(String) fileBuilder;

  setUp() {
    mockFiles = {};
    mockDirectories = {};
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
  }
}
