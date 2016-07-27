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
  MemoryResourceProvider resourceProvider;

  Folder empty;
  Folder tmp_sdk_ext;
  Folder tmp_embedder;
  Map<String, List<Folder>> packageMap;

  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    empty = resourceProvider.newFolder('/empty');
    tmp_sdk_ext = resourceProvider.newFolder('/tmp_sdk_ext');
    tmp_embedder = resourceProvider.newFolder('/tmp_embedder');
    packageMap = <String, List<Folder>>{
      'empty': [empty],
      'tmp_embedder': [tmp_embedder],
      'tmp_sdk_ext': [tmp_sdk_ext]
    };
  }

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
    expect(proc.embeddedLibraries.getLibrary('dart:core').path,
        '/tmp_embedder/core.dart');
    expect(proc.extendedLibraries.size(), 1);
    expect(proc.extendedLibraries.getLibrary('dart:ui').path,
        '/tmp_sdk_ext/ui.dart');
  }

  void test_empty_package_map() {
    PackageMapProcessor proc =
        new PackageMapProcessor(<String, List<Folder>>{});
    expect(proc.embeddedLibraries.size(), 0);
    expect(proc.extendedLibraries.size(), 0);
    expect(proc.libraryMap.size(), 0);
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

  void test_invalid_embedder() {
    resourceProvider.newFile(
        '/tmp_embedder/_embedder.yaml',
        r'''
invalid contents, will not parse
''');

    PackageMapProcessor proc = new PackageMapProcessor(packageMap);
    expect(proc.embeddedLibraries.size(), 0);
    expect(proc.extendedLibraries.size(), 0);
    expect(proc.libraryMap.size(), 0);
  }

  void test_invalid_extender() {
    resourceProvider.newFile(
        '/tmp_sdk_ext/_sdkext',
        r'''
invalid contents, will not parse
''');

    PackageMapProcessor proc = new PackageMapProcessor(packageMap);
    expect(proc.embeddedLibraries.size(), 0);
    expect(proc.extendedLibraries.size(), 0);
    expect(proc.libraryMap.size(), 0);
  }

  void test_no_embedder() {
    resourceProvider.newFile(
        '/tmp_sdk_ext/_sdkext',
        r'''
  {
    "dart:ui": "ui2.dart"
  }''');

    PackageMapProcessor proc = new PackageMapProcessor(packageMap);
    expect(proc.embeddedLibraries.size(), 0);
    expect(proc.extendedLibraries.size(), 1);
    expect(proc.libraryMap.size(), 1);
  }

  void test_no_embedder_or_extender() {
    PackageMapProcessor proc = new PackageMapProcessor(packageMap);
    expect(proc.embeddedLibraries.size(), 0);
    expect(proc.extendedLibraries.size(), 0);
    expect(proc.libraryMap.size(), 0);
  }

  void test_no_extender() {
    resourceProvider.newFile(
        '/tmp_embedder/_embedder.yaml',
        r'''
embedded_libs:
  "dart:core" : "core.dart"
  "dart:ui": "ui.dart"
''');

    PackageMapProcessor proc = new PackageMapProcessor(packageMap);
    expect(proc.embeddedLibraries.size(), 2);
    expect(proc.extendedLibraries.size(), 0);
    expect(proc.libraryMap.size(), 2);
  }
}
