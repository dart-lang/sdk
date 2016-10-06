// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.bazel_test;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/bazel.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BazelWorkspaceTest);
    defineReflectiveTests(BazelFileUriResolverTest);
  });
}

@reflectiveTest
class BazelFileUriResolverTest extends _BaseTest {
  BazelWorkspace workspace;
  BazelFileUriResolver resolver;

  void setUp() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    workspace = new BazelWorkspace(provider, _p('/workspace'));
    resolver = new BazelFileUriResolver(workspace);
    provider.newFile(_p('/workspace/test.dart'), '');
    provider.newFile(_p('/workspace/bazel-bin/gen1.dart'), '');
    provider.newFile(_p('/workspace/bazel-genfiles/gen2.dart'), '');
  }

  void test_resolveAbsolute_doesNotExist() {
    Source source = _resolvePath('/workspace/foo.dart');
    expect(source, isNotNull);
    expect(source.exists(), isFalse);
    expect(source.fullName, _p('/workspace/foo.dart'));
  }

  void test_resolveAbsolute_file() {
    Source source = _resolvePath('/workspace/test.dart');
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName, _p('/workspace/test.dart'));
  }

  void test_resolveAbsolute_folder() {
    Source source = _resolvePath('/workspace');
    expect(source, isNotNull);
    expect(source.exists(), isFalse);
    expect(source.fullName, _p('/workspace'));
  }

  void test_resolveAbsolute_generated_file_exists_one() {
    Source source = _resolvePath('/workspace/gen1.dart');
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName, _p('/workspace/bazel-bin/gen1.dart'));
  }

  void test_resolveAbsolute_generated_file_exists_two() {
    Source source = _resolvePath('/workspace/gen2.dart');
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName, _p('/workspace/bazel-genfiles/gen2.dart'));
  }

  void test_resolveAbsolute_notFile_dartUri() {
    Uri uri = new Uri(scheme: 'dart', path: 'core');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_notFile_httpsUri() {
    Uri uri = new Uri(scheme: 'https', path: '127.0.0.1/test.dart');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_restoreAbsolute() {
    Uri uri = provider.pathContext.toUri(_p('/workspace/test.dart'));
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(resolver.restoreAbsolute(source), uri);
    expect(
        resolver.restoreAbsolute(
            new NonExistingSource(source.fullName, null, null)),
        uri);
  }

  Source _resolvePath(String absolutePosixPath) {
    String absolutePath = provider.convertPath(absolutePosixPath);
    Uri uri = provider.pathContext.toUri(absolutePath);
    return resolver.resolveAbsolute(uri);
  }
}

@reflectiveTest
class BazelWorkspaceTest extends _BaseTest {
  void test_factory_fail_notAbsolute() {
    expect(() => new BazelWorkspace(provider, _p('not_absolute')),
        throwsArgumentError);
  }

  void test_factory_hasReadonlyFolder() {
    provider.newFolder(_p('/Users/user/test/READONLY/prime'));
    provider.newFolder(_p('/Users/user/test/prime'));
    BazelWorkspace workspace = new BazelWorkspace(
        provider, _p('/Users/user/test/prime/my/module'),
        readonlySuffix: 'prime');
    expect(workspace.root, _p('/Users/user/test/prime'));
    expect(workspace.readonly, _p('/Users/user/test/READONLY/prime'));
    expect(workspace.bin, _p('/Users/user/test/prime/bazel-bin'));
    expect(workspace.genfiles, _p('/Users/user/test/prime/bazel-genfiles'));
  }

  void test_factory_hasWorkspaceFile() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    BazelWorkspace workspace =
        new BazelWorkspace(provider, _p('/workspace/my/module'));
    expect(workspace.root, _p('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, _p('/workspace/bazel-bin'));
    expect(workspace.genfiles, _p('/workspace/bazel-genfiles'));
  }

  void test_factory_hasWorkspaceFile_forModuleInWorkspace() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    BazelWorkspace workspace =
        new BazelWorkspace(provider, _p('/workspace/my/module'));
    expect(workspace.root, _p('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, _p('/workspace/bazel-bin'));
    expect(workspace.genfiles, _p('/workspace/bazel-genfiles'));
  }

  void test_factory_hasWorkspaceFile_forWorkspace() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    BazelWorkspace workspace = new BazelWorkspace(provider, _p('/workspace'));
    expect(workspace.root, _p('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, _p('/workspace/bazel-bin'));
    expect(workspace.genfiles, _p('/workspace/bazel-genfiles'));
  }

  void test_factory_notInWorkspace() {
    BazelWorkspace workspace =
        new BazelWorkspace(provider, _p('/workspace/my/module'));
    expect(workspace, isNotNull);
    expect(workspace.root, _p('/workspace/my/module'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, isNull);
    expect(workspace.genfiles, isNull);
  }

  void test_factory_symlinkPrefix() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    BazelWorkspace workspace =
        new BazelWorkspace(provider, _p('/workspace'), symlinkPrefix: 'foobar');
    expect(workspace.root, _p('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, _p('/workspace/foobar-bin'));
    expect(workspace.genfiles, _p('/workspace/foobar-genfiles'));
  }

  void test_findFile_hasReadonlyFolder() {
    provider.newFolder(_p('/Users/user/test/READONLY/prime'));
    provider.newFolder(_p('/Users/user/test/prime'));
    provider.newFile(_p('/Users/user/test/prime/my/module/test1.dart'), '');
    provider.newFile(_p('/Users/user/test/prime/my/module/test2.dart'), '');
    provider.newFile(_p('/Users/user/test/prime/my/module/test3.dart'), '');
    provider.newFile(
        _p('/Users/user/test/prime/bazel-bin/my/module/test2.dart'), '');
    provider.newFile(
        _p('/Users/user/test/prime/bazel-genfiles/my/module/test3.dart'), '');
    provider.newFile(
        _p('/Users/user/test/READONLY/prime/other/module/test4.dart'), '');
    BazelWorkspace workspace = new BazelWorkspace(
        provider, _p('/Users/user/test/prime/my/module'),
        readonlySuffix: 'prime');
    expect(
        workspace
            .findFile(_p('/Users/user/test/prime/my/module/test1.dart'))
            .path,
        _p('/Users/user/test/prime/my/module/test1.dart'));
    expect(
        workspace
            .findFile(_p('/Users/user/test/prime/my/module/test2.dart'))
            .path,
        _p('/Users/user/test/prime/bazel-bin/my/module/test2.dart'));
    expect(
        workspace
            .findFile(_p('/Users/user/test/prime/my/module/test3.dart'))
            .path,
        _p('/Users/user/test/prime/bazel-genfiles/my/module/test3.dart'));
    expect(
        workspace
            .findFile(_p('/Users/user/test/prime/other/module/test4.dart'))
            .path,
        _p('/Users/user/test/READONLY/prime/other/module/test4.dart'));
  }

  void test_findFile_noReadOnly() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    provider.newFile(_p('/workspace/my/module/test1.dart'), '');
    provider.newFile(_p('/workspace/my/module/test2.dart'), '');
    provider.newFile(_p('/workspace/my/module/test3.dart'), '');
    provider.newFile(_p('/workspace/bazel-bin/my/module/test2.dart'), '');
    provider.newFile(_p('/workspace/bazel-genfiles/my/module/test3.dart'), '');
    BazelWorkspace workspace =
        new BazelWorkspace(provider, _p('/workspace/my/module'));
    expect(workspace.findFile(_p('/workspace/my/module/test1.dart')).path,
        _p('/workspace/my/module/test1.dart'));
    expect(workspace.findFile(_p('/workspace/my/module/test2.dart')).path,
        _p('/workspace/bazel-bin/my/module/test2.dart'));
    expect(workspace.findFile(_p('/workspace/my/module/test3.dart')).path,
        _p('/workspace/bazel-genfiles/my/module/test3.dart'));
  }
}

class _BaseTest {
  final MemoryResourceProvider provider = new MemoryResourceProvider();

  /**
   * Return the [provider] specific path for the given Posix [path].
   */
  String _p(String path) => provider.convertPath(path);
}
