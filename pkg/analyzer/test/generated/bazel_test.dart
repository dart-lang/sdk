// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.bazel_test;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/bazel.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:mockito/mockito.dart';
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

  void test_resolveAbsolute_bin() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/my/foo/lib/foo1.dart',
      '/workspace/bazel-bin/my/foo/lib/foo1.dart'
    ]);
    _assertResolve(
        'package:my.foo/foo1.dart', '/workspace/bazel-bin/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_bin_notInWorkspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/bazel-bin/my/foo/lib/foo1.dart'
    ]);
    _assertResolve(
        'package:my.foo/foo1.dart', '/workspace/bazel-bin/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_genfiles() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/my/foo/lib/foo1.dart',
      '/workspace/bazel-genfiles/my/foo/lib/foo1.dart'
    ]);
    _assertResolve('package:my.foo/foo1.dart',
        '/workspace/bazel-genfiles/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_genfiles_notInWorkspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/bazel-genfiles/my/foo/lib/foo1.dart'
    ]);
    _assertResolve('package:my.foo/foo1.dart',
        '/workspace/bazel-genfiles/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_null_noSlash() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
    ]);
    Source source = resolver.resolveAbsolute(Uri.parse('package:foo'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_notPackage() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
    ]);
    Source source = resolver.resolveAbsolute(Uri.parse('dart:async'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_startsWithSlash() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/my/foo/lib/bar.dart',
    ]);
    Source source =
        resolver.resolveAbsolute(Uri.parse('package:/foo/bar.dart'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_readonly_bin() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/READONLY/prime/my/foo/lib/foo1.dart',
      '/Users/user/test/prime/bazel-genfiles/',
      '/Users/user/test/prime/my/module/',
      '/Users/user/test/prime/bazel-bin/my/foo/lib/foo1.dart',
    ], workspacePath: '/Users/user/test/prime/my/module');
    _assertResolve('package:my.foo/foo1.dart',
        '/Users/user/test/prime/bazel-bin/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_readonly_bin_notInWorkspace() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/prime/bazel-genfiles/',
      '/Users/user/test/prime/my/module/',
      '/Users/user/test/prime/bazel-bin/my/foo/lib/foo1.dart',
    ], workspacePath: '/Users/user/test/prime/my/module');
    _assertResolve('package:my.foo/foo1.dart',
        '/Users/user/test/prime/bazel-bin/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_readonly_genfiles() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/READONLY/prime/my/foo/lib/foo1.dart',
      '/Users/user/test/prime/bazel-genfiles/',
      '/Users/user/test/prime/my/module/',
      '/Users/user/test/prime/bazel-genfiles/my/foo/lib/foo1.dart',
    ], workspacePath: '/Users/user/test/prime/my/module');
    _assertResolve('package:my.foo/foo1.dart',
        '/Users/user/test/prime/bazel-genfiles/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_readonly_genfiles_notInWorkspace() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/prime/bazel-genfiles/',
      '/Users/user/test/prime/my/module/',
      '/Users/user/test/prime/bazel-genfiles/my/foo/lib/foo1.dart',
    ], workspacePath: '/Users/user/test/prime/my/module');
    _assertResolve('package:my.foo/foo1.dart',
        '/Users/user/test/prime/bazel-genfiles/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_readonly_thirdParty_bin() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/READONLY/prime/third_party/dart/foo/lib/foo1.dart',
      '/Users/user/test/prime/bazel-genfiles/',
      '/Users/user/test/prime/my/module/',
      '/Users/user/test/prime/bazel-bin/third_party/dart/foo/lib/foo1.dart',
    ], workspacePath: '/Users/user/test/prime/my/module');
    _assertResolve('package:foo/foo1.dart',
        '/Users/user/test/prime/bazel-bin/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_readonly_thirdParty_genfiles() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/READONLY/prime/third_party/dart/foo/lib/foo1.dart',
      '/Users/user/test/prime/bazel-genfiles/',
      '/Users/user/test/prime/my/module/',
      '/Users/user/test/prime/bazel-genfiles/third_party/dart/foo/lib/foo1.dart',
    ], workspacePath: '/Users/user/test/prime/my/module');
    _assertResolve('package:foo/foo1.dart',
        '/Users/user/test/prime/bazel-genfiles/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_readonly_thirdParty_workspace_doesNotExist() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/READONLY/prime/third_party/dart/foo/lib/foo1.dart',
      '/Users/user/test/prime/bazel-genfiles/',
      '/Users/user/test/prime/my/module/',
    ], workspacePath: '/Users/user/test/prime/my/module');
    _assertResolve('package:foo/foo2.dart',
        '/Users/user/test/prime/third_party/dart/foo/lib/foo2.dart',
        exists: false);
  }

  void test_resolveAbsolute_readonly_thirdParty_workspace_exists() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/READONLY/prime/third_party/dart/foo/lib/foo1.dart',
      '/Users/user/test/prime/bazel-genfiles/',
      '/Users/user/test/prime/my/module/',
    ], workspacePath: '/Users/user/test/prime/my/module');
    _assertResolve('package:foo/foo1.dart',
        '/Users/user/test/READONLY/prime/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_readonly_workspace_doesNotExist() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/prime/bazel-genfiles/',
      '/Users/user/test/prime/my/module/',
    ], workspacePath: '/Users/user/test/prime/my/module');
    _assertResolve('package:my.foo/foo1.dart',
        '/Users/user/test/prime/my/foo/lib/foo1.dart',
        exists: false);
  }

  void test_resolveAbsolute_readonly_workspace_exists() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/READONLY/prime/my/foo/lib/foo1.dart',
      '/Users/user/test/prime/bazel-genfiles/',
      '/Users/user/test/prime/my/module/',
    ], workspacePath: '/Users/user/test/prime/my/module');
    _assertResolve('package:my.foo/foo1.dart',
        '/Users/user/test/READONLY/prime/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_thirdParty_bin() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/third_party/dart/foo/lib/foo1.dart',
      '/workspace/bazel-bin/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo1.dart',
        '/workspace/bazel-bin/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_thirdParty_bin_notInWorkspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/bazel-bin/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo1.dart',
        '/workspace/bazel-bin/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_thirdParty_doesNotExist() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo2.dart',
        '/workspace/third_party/dart/foo/lib/foo2.dart',
        exists: false);
  }

  void test_resolveAbsolute_thirdParty_exists() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo1.dart',
        '/workspace/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_thirdParty_genfiles() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/third_party/dart/foo/lib/foo1.dart',
      '/workspace/bazel-genfiles/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo1.dart',
        '/workspace/bazel-genfiles/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_thirdParty_genfiles_notInWorkspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/bazel-genfiles/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo1.dart',
        '/workspace/bazel-genfiles/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_workspace_doesNotExist() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
    ]);
    _assertResolve('package:my.foo/doesNotExist.dart',
        '/workspace/my/foo/lib/doesNotExist.dart',
        exists: false);
  }

  void test_resolveAbsolute_workspace_exists() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/my/foo/lib/foo1.dart',
    ]);
    _assertResolve(
        'package:my.foo/foo1.dart', '/workspace/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_restoreAbsolute_noPackageName_workspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/lib/foo1.dart',
      '/workspace/foo/lib/foo2.dart',
    ]);
    _assertRestore('/workspace/lib/foo1.dart', null);
    _assertRestore('/workspace/foo/lib/foo2.dart', null);
  }

  void test_restoreAbsolute_noPathInLib_bin() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/bazel-bin/my/foo/lib/foo1.dart',
    ]);
    _assertRestore('/workspace/bazel-bin', null);
    _assertRestore('/workspace/bazel-bin/my', null);
    _assertRestore('/workspace/bazel-bin/my/foo', null);
    _assertRestore('/workspace/bazel-bin/my/foo/lib', null);
  }

  void test_restoreAbsolute_noPathInLib_genfiles() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/bazel-genfiles/my/foo/lib/foo1.dart',
    ]);
    _assertRestore('/workspace/bazel-genfiles', null);
    _assertRestore('/workspace/bazel-genfiles/my', null);
    _assertRestore('/workspace/bazel-genfiles/my/foo', null);
    _assertRestore('/workspace/bazel-genfiles/my/foo/lib', null);
  }

  void test_restoreAbsolute_noPathInLib_workspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/my/foo/lib/foo1.dart',
    ]);
    _assertRestore('/workspace', null);
    _assertRestore('/workspace/my', null);
    _assertRestore('/workspace/my/foo', null);
    _assertRestore('/workspace/my/foo/lib', null);
  }

  void test_restoreAbsolute_thirdPartyNotDart_workspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/third_party/something/lib/foo.dart',
    ]);
    _assertRestore('/workspace/third_party/something/lib/foo.dart',
        'package:third_party.something/foo.dart');
  }

  void _addResources(List<String> paths, {String workspacePath: '/workspace'}) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        provider.newFolder(_p(path.substring(0, path.length - 1)));
      } else {
        provider.newFile(_p(path), '');
      }
    }
    workspace = BazelWorkspace.find(provider, _p(workspacePath));
    resolver = new BazelPackageUriResolver(workspace);
  }

  void _assertResolve(String uriStr, String posixPath,
      {bool exists: true, bool restore: true}) {
    Uri uri = Uri.parse(uriStr);
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(source.fullName, _p(posixPath));
    expect(source.uri, uri);
    expect(source.exists(), exists);
    // If enabled, test also "restoreAbsolute".
    if (restore) {
      Uri uri = resolver.restoreAbsolute(source);
      expect(uri.toString(), uriStr);
    }
  }

  void _assertRestore(String posixPath, String expectedUri) {
    String path = _p(posixPath);
    _MockSource source = new _MockSource(path);
    Uri uri = resolver.restoreAbsolute(source);
    expect(uri?.toString(), expectedUri);
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
    String prefix = BazelWorkspace.defaultSymlinkPrefix;
    provider.newFile(_p('/workspace/WORKSPACE'), '');
    BazelWorkspace workspace =
        BazelWorkspace.find(provider, _p('/workspace/my/module'));
    expect(workspace.root, _p('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, _p('/workspace/$prefix-bin'));
    expect(workspace.genfiles, _p('/workspace/$prefix-genfiles'));
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

  void test_findFile_main_overrides_readonly() {
    provider.newFolder(_p('/Users/user/test/READONLY/prime'));
    provider.newFolder(_p('/Users/user/test/prime'));
    provider.newFolder(_p('/Users/user/test/prime/bazel-genfiles'));
    provider.newFile(_p('/Users/user/test/prime/my/module/test.dart'), '');
    provider.newFile(
        _p('/Users/user/test/READONLY/prime/my/module/test.dart'), '');
    BazelWorkspace workspace =
        BazelWorkspace.find(provider, _p('/Users/user/test/prime/my/module'));
    expect(
        workspace
            .findFile(_p('/Users/user/test/prime/my/module/test.dart'))
            .path,
        _p('/Users/user/test/prime/my/module/test.dart'));
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

class _MockSource extends Mock implements Source {
  final String fullName;
  _MockSource(this.fullName);
}
