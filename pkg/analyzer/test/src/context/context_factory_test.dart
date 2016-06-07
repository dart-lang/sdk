// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.context.context_factory_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/context_factory.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(PackageMapProcessorTest);
}

@reflectiveTest
class PackageMapProcessorTest {
  static MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  static Folder empty = resourceProvider.newFolder('/empty');
  static Folder tmp_sdk_ext = resourceProvider.newFolder('/tmp_sdk_ext');
  static Folder tmp_embedder = resourceProvider.newFolder('/tmp_embedder');

  static Map<String, List<Folder>> packageMap = <String, List<Folder>>{
    'empty': [empty],
    'tmp_embedder': [tmp_embedder],
    'tmp_sdk_ext': [tmp_sdk_ext]
  };

  void test_basic_processing() {
    resourceProvider.newFile(
        '/tmp_sdk_ext/_sdkext',
        r'''
  {
    "dart:ui": "ui.dart"
  }''');
    resourceProvider.newFile(
        '/tmp_embedder/_embedder.yaml',
        r'''
embedded_libs:
  "dart:core" : "core.dart"
  "dart:fox": "slippy.dart"
  "dart:bear": "grizzly.dart"
  "dart:relative": "../relative.dart"
  "dart:deep": "deep/directory/file.dart"
''');

    PackageMapProcessor proc = new PackageMapProcessor(packageMap);
    expect(proc.embeddedLibraries.size(), 5);
    expect(proc.extendedLibraries.size(), 1);
  }

  void test_extenders_do_not_override() {
    resourceProvider.newFile(
        '/tmp_sdk_ext/_sdkext',
        r'''
  {
    "dart:ui": "ui2.dart"
  }''');
    resourceProvider.newFile(
        '/tmp_embedder/_embedder.yaml',
        r'''
embedded_libs:
  "dart:core" : "core.dart"
  "dart:ui": "ui.dart"
''');

    PackageMapProcessor proc = new PackageMapProcessor(packageMap);
    expect(proc.embeddedLibraries.size(), 2);
    expect(proc.extendedLibraries.size(), 1);
    expect(proc.libraryMap.size(), 2);
    expect(proc.libraryMap.getLibrary('dart:ui').path, '/tmp_embedder/ui.dart');
  }
}
