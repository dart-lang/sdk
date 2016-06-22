// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.bazel_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/bazel.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(BazelFileUriResolverTest);
}

@reflectiveTest
class BazelFileUriResolverTest {
  MemoryResourceProvider provider;
  Folder workspace;
  List<Folder> buildDirs;
  ResourceUriResolver resolver;

  void setUp() {
    provider = new MemoryResourceProvider();
    workspace = provider.newFolder('/workspace');
    buildDirs = [provider.newFolder('/workspace/one'), provider.newFolder('/workspace/two')];
    resolver = new BazelFileUriResolver(provider, workspace, buildDirs);
    provider.newFile('/workspace/test.dart', '');
    provider.newFile('/workspace/one/gen1.dart', '');
    provider.newFile('/workspace/two/gen2.dart', '');
  }

  void test_creation() {
    expect(provider, isNotNull);
    expect(workspace, isNotNull);
    expect(buildDirs, isNotNull);
    expect(buildDirs.length, 2);
    expect(resolver, isNotNull);
  }

  void test_resolveAbsolute_file() {
    var uri = new Uri(scheme: 'file', path: '/workspace/test.dart');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName, '/workspace/test.dart');
  }

  void test_resolveAbsolute_folder() {
    var uri = new Uri(scheme: 'file', path: '/workspace');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_notFile_httpsUri() {
    var uri = new Uri(scheme: 'https', path: '127.0.0.1/test.dart');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_notFile_dartUri() {
    var uri = new Uri(scheme: 'dart', path: 'core');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_generated_file_exists_one() {
    var uri = new Uri(scheme: 'file', path: '/workspace/gen1.dart');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName, '/workspace/one/gen1.dart');
  }

  void test_resolveAbsolute_generated_file_exists_two() {
    var uri = new Uri(scheme: 'file', path: '/workspace/gen2.dart');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName, '/workspace/two/gen2.dart');
  }

  void test_resolveAbsolute_generated_file_does_not_exist_three() {
    var uri = new Uri(scheme: 'file', path: '/workspace/gen3.dart');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_restoreAbsolute() {
    var uri = new Uri(scheme: 'file', path: '/workspace/test.dart');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(resolver.restoreAbsolute(source), uri);
    expect(
        resolver.restoreAbsolute(
            new NonExistingSource(source.fullName, null, null)),
        uri);
  }
}
