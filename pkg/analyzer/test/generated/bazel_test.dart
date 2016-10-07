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
    defineReflectiveTests(BazelFileUriResolverTest);
    defineReflectiveTests(BazelPackageUriResolverTest);
    defineReflectiveTests(BazelWorkspaceTest);
  });
}

@reflectiveTest
class BazelFileUriResolverTest extends _BaseTest {
  BazelWorkspace workspace;
  BazelFileUriResolver resolver;

  void setUp() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    provider.newFolder(_p('/workspace/bazel-genfiles'));
    workspace = BazelWorkspace.find(provider, _p('/workspace'));
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
class BazelPackageUriResolverTest extends _BaseTest {
  BazelWorkspace workspace;
  BazelPackageUriResolver resolver;

  void setUp() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    provider.newFolder(_p('/workspace/bazel-genfiles'));
    workspace = BazelWorkspace.find(provider, _p('/workspace'));
    resolver = new BazelPackageUriResolver(workspace);
    provider.newFile(_p('/workspace/my/foo/lib/foo1.dart'), '');
    provider.newFile(_p('/workspace/my/foo/lib/gen1.dart'), '');
    provider.newFile(_p('/workspace/my/foo/lib/gen2.dart'), '');
    provider.newFile(_p('/workspace/my/foo/lib/src/foo4.dart'), '');
    provider.newFile(_p('/workspace/third_party/dart/bar/lib/bar1.dart'), '');
    provider.newFile(
        _p('/workspace/third_party/dart/bar/lib/src/bar2.dart'), '');
    provider.newFile(_p('/workspace/bazel-bin/my/foo/lib/gen1.dart'), '');
    provider.newFile(_p('/workspace/bazel-genfiles/my/foo/lib/gen2.dart'), '');
    provider.newFile(_p('/workspace/bazel-genfiles/my/foo/lib/gen3.dart'), '');
  }

  void test_resolveAbsolute_inBazelBin() {
    _assertResolve(
        'package:my.foo/gen1.dart', '/workspace/bazel-bin/my/foo/lib/gen1.dart',
        exists: true);
  }

  void test_resolveAbsolute_inBazelGenfiles() {
    _assertResolve('package:my.foo/gen2.dart',
        '/workspace/bazel-genfiles/my/foo/lib/gen2.dart',
        exists: true);
  }

  void test_resolveAbsolute_inBazelGenfiles_notInWorkspace() {
    _assertResolve('package:my.foo/gen3.dart',
        '/workspace/bazel-genfiles/my/foo/lib/gen3.dart',
        exists: true);
  }

  void test_resolveAbsolute_inWorkspace_doesNotExist() {
    _assertResolve('package:my.foo/doesNotExist.dart',
        '/workspace/my/foo/lib/doesNotExist.dart',
        exists: false);
  }

  void test_resolveAbsolute_inWorkspace_exists() {
    _assertResolve(
        'package:my.foo/foo1.dart', '/workspace/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_null_noSlash() {
    Source source = resolver.resolveAbsolute(Uri.parse('package:foo'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_notPackage() {
    Source source = resolver.resolveAbsolute(Uri.parse('dart:async'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_startsWithSlash() {
    Source source =
        resolver.resolveAbsolute(Uri.parse('package:/foo/bar.dart'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_thirdParty_doesNotExist() {
    _assertResolve('package:baz/baz1.dart',
        '/workspace/third_party/dart/baz/lib/baz1.dart',
        exists: false);
  }

  void test_resolveAbsolute_thirdParty_exists() {
    _assertResolve('package:bar/bar1.dart',
        '/workspace/third_party/dart/bar/lib/bar1.dart',
        exists: true);
    _assertResolve('package:bar/src/bar2.dart',
        '/workspace/third_party/dart/bar/lib/src/bar2.dart',
        exists: true);
  }

  void _assertResolve(String uriStr, String posixPath, {bool exists: true}) {
    Uri uri = Uri.parse(uriStr);
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(source.fullName, _p(posixPath));
    expect(source.uri, uri);
    expect(source.exists(), exists);
  }
}

@reflectiveTest
class BazelWorkspaceTest extends _BaseTest {
  void test_find_fail_notAbsolute() {
    expect(() => BazelWorkspace.find(provider, _p('not_absolute')),
        throwsArgumentError);
  }

  void test_find_hasReadonlyFolder() {
    provider.newFolder(_p('/Users/user/test/READONLY/prime'));
    provider.newFolder(_p('/Users/user/test/prime'));
    provider.newFolder(_p('/Users/user/test/prime/bazel-genfiles'));
    BazelWorkspace workspace =
        BazelWorkspace.find(provider, _p('/Users/user/test/prime/my/module'));
    expect(workspace.root, _p('/Users/user/test/prime'));
    expect(workspace.readonly, _p('/Users/user/test/READONLY/prime'));
    expect(workspace.bin, _p('/Users/user/test/prime/bazel-bin'));
    expect(workspace.genfiles, _p('/Users/user/test/prime/bazel-genfiles'));
  }

  void test_find_hasReadonlyFolder_bad_actuallyHasWorkspaceFile() {
    provider.newFolder(_p('/Users/user/test/READONLY'));
    provider.newFile(_p('/Users/user/test/prime/WORKSPACE'), '');
    provider.newFolder(_p('/Users/user/test/prime/bazel-genfiles'));
    BazelWorkspace workspace =
        BazelWorkspace.find(provider, _p('/Users/user/test/prime/my/module'));
    expect(workspace.root, _p('/Users/user/test/prime'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, _p('/Users/user/test/prime/bazel-bin'));
    expect(workspace.genfiles, _p('/Users/user/test/prime/bazel-genfiles'));
  }

  void test_find_hasReadonlyFolder_blaze() {
    provider.newFolder(_p('/Users/user/test/READONLY/prime'));
    provider.newFolder(_p('/Users/user/test/prime'));
    provider.newFolder(_p('/Users/user/test/prime/blaze-genfiles'));
    BazelWorkspace workspace =
        BazelWorkspace.find(provider, _p('/Users/user/test/prime/my/module'));
    expect(workspace.root, _p('/Users/user/test/prime'));
    expect(workspace.readonly, _p('/Users/user/test/READONLY/prime'));
    expect(workspace.bin, _p('/Users/user/test/prime/blaze-bin'));
    expect(workspace.genfiles, _p('/Users/user/test/prime/blaze-genfiles'));
  }

  void test_find_hasWorkspaceFile() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    provider.newFolder(_p('/workspace/bazel-genfiles'));
    BazelWorkspace workspace =
        BazelWorkspace.find(provider, _p('/workspace/my/module'));
    expect(workspace.root, _p('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, _p('/workspace/bazel-bin'));
    expect(workspace.genfiles, _p('/workspace/bazel-genfiles'));
  }

  void test_find_hasWorkspaceFile_forModuleInWorkspace() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    provider.newFolder(_p('/workspace/bazel-genfiles'));
    BazelWorkspace workspace =
        BazelWorkspace.find(provider, _p('/workspace/my/module'));
    expect(workspace.root, _p('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, _p('/workspace/bazel-bin'));
    expect(workspace.genfiles, _p('/workspace/bazel-genfiles'));
  }

  void test_find_hasWorkspaceFile_forWorkspace() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    provider.newFolder(_p('/workspace/bazel-genfiles'));
    BazelWorkspace workspace = BazelWorkspace.find(provider, _p('/workspace'));
    expect(workspace.root, _p('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, _p('/workspace/bazel-bin'));
    expect(workspace.genfiles, _p('/workspace/bazel-genfiles'));
  }

  void test_find_hasWorkspaceFile_forWorkspace_blaze() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    provider.newFolder(_p('/workspace/blaze-genfiles'));
    BazelWorkspace workspace = BazelWorkspace.find(provider, _p('/workspace'));
    expect(workspace.root, _p('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, _p('/workspace/blaze-bin'));
    expect(workspace.genfiles, _p('/workspace/blaze-genfiles'));
  }

  void test_find_null_noWorkspaceMarkers() {
    BazelWorkspace workspace =
        BazelWorkspace.find(provider, _p('/workspace/my/module'));
    expect(workspace, isNull);
  }

  void test_find_null_noWorkspaceMarkers_inRoot() {
    BazelWorkspace workspace = BazelWorkspace.find(provider, _p('/'));
    expect(workspace, isNull);
  }

  void test_find_null_symlinkPrefix() {
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    BazelWorkspace workspace =
        BazelWorkspace.find(provider, _p('/workspace/my/module'));
    expect(workspace, isNull);
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
    BazelWorkspace workspace =
        BazelWorkspace.find(provider, _p('/Users/user/test/prime/my/module'));
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
        BazelWorkspace.find(provider, _p('/workspace/my/module'));
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
