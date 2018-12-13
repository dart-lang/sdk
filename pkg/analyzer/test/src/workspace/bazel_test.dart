// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BazelFileUriResolverTest);
    defineReflectiveTests(BazelPackageUriResolverTest);
    defineReflectiveTests(BazelWorkspaceTest);
    defineReflectiveTests(BazelWorkspacePackageTest);
  });
}

@reflectiveTest
class BazelFileUriResolverTest with ResourceProviderMixin {
  BazelWorkspace workspace;
  BazelFileUriResolver resolver;

  void setUp() {
    newFile('/workspace/WORKSPACE');
    newFolder('/workspace/bazel-genfiles');
    workspace =
        BazelWorkspace.find(resourceProvider, convertPath('/workspace'));
    resolver = new BazelFileUriResolver(workspace);
    newFile('/workspace/test.dart');
    newFile('/workspace/bazel-bin/gen1.dart');
    newFile('/workspace/bazel-genfiles/gen2.dart');
  }

  void test_resolveAbsolute_doesNotExist() {
    Source source = _resolvePath('/workspace/foo.dart');
    expect(source, isNotNull);
    expect(source.exists(), isFalse);
    expect(source.fullName, convertPath('/workspace/foo.dart'));
  }

  void test_resolveAbsolute_file() {
    Source source = _resolvePath('/workspace/test.dart');
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName, convertPath('/workspace/test.dart'));
  }

  void test_resolveAbsolute_folder() {
    Source source = _resolvePath('/workspace');
    expect(source, isNull);
  }

  void test_resolveAbsolute_generated_file_exists_one() {
    Source source = _resolvePath('/workspace/gen1.dart');
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName, convertPath('/workspace/bazel-bin/gen1.dart'));
  }

  void test_resolveAbsolute_generated_file_exists_two() {
    Source source = _resolvePath('/workspace/gen2.dart');
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName, convertPath('/workspace/bazel-genfiles/gen2.dart'));
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
    Uri uri =
        resourceProvider.pathContext.toUri(convertPath('/workspace/test.dart'));
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(resolver.restoreAbsolute(source), uri);
    expect(
        resolver.restoreAbsolute(
            new NonExistingSource(source.fullName, null, null)),
        uri);
  }

  Source _resolvePath(String absolutePosixPath) {
    String absolutePath = convertPath(absolutePosixPath);
    Uri uri = resourceProvider.pathContext.toUri(absolutePath);
    return resolver.resolveAbsolute(uri);
  }
}

@reflectiveTest
class BazelPackageUriResolverTest with ResourceProviderMixin {
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
        newFolder(path.substring(0, path.length - 1));
      } else {
        newFile(path);
      }
    }
    workspace =
        BazelWorkspace.find(resourceProvider, convertPath(workspacePath));
    resolver = new BazelPackageUriResolver(workspace);
  }

  void _assertResolve(String uriStr, String posixPath,
      {bool exists: true, bool restore: true}) {
    Uri uri = Uri.parse(uriStr);
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(source.fullName, convertPath(posixPath));
    expect(source.uri, uri);
    expect(source.exists(), exists);
    // If enabled, test also "restoreAbsolute".
    if (restore) {
      Uri uri = resolver.restoreAbsolute(source);
      expect(uri.toString(), uriStr);
    }
  }

  void _assertRestore(String posixPath, String expectedUri) {
    String path = convertPath(posixPath);
    _MockSource source = new _MockSource(path);
    Uri uri = resolver.restoreAbsolute(source);
    expect(uri?.toString(), expectedUri);
  }
}

@reflectiveTest
class BazelWorkspaceTest with ResourceProviderMixin {
  void test_find_fail_notAbsolute() {
    expect(
        () =>
            BazelWorkspace.find(resourceProvider, convertPath('not_absolute')),
        throwsA(const TypeMatcher<ArgumentError>()));
  }

  void test_find_hasReadonlyFolder() {
    newFolder('/Users/user/test/READONLY/prime');
    newFolder('/Users/user/test/prime');
    newFolder('/Users/user/test/prime/bazel-genfiles');
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/Users/user/test/prime/my/module'));
    expect(workspace.root, convertPath('/Users/user/test/prime'));
    expect(workspace.readonly, convertPath('/Users/user/test/READONLY/prime'));
    expect(workspace.bin, convertPath('/Users/user/test/prime/bazel-bin'));
    expect(workspace.genfiles,
        convertPath('/Users/user/test/prime/bazel-genfiles'));
  }

  void test_find_hasReadonlyFolder_bad_actuallyHasWorkspaceFile() {
    newFolder('/Users/user/test/READONLY');
    newFile('/Users/user/test/prime/WORKSPACE');
    newFolder('/Users/user/test/prime/bazel-genfiles');
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/Users/user/test/prime/my/module'));
    expect(workspace.root, convertPath('/Users/user/test/prime'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, convertPath('/Users/user/test/prime/bazel-bin'));
    expect(workspace.genfiles,
        convertPath('/Users/user/test/prime/bazel-genfiles'));
  }

  void test_find_hasReadonlyFolder_blaze() {
    newFolder('/Users/user/test/READONLY/prime');
    newFolder('/Users/user/test/prime');
    newFolder('/Users/user/test/prime/blaze-genfiles');
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/Users/user/test/prime/my/module'));
    expect(workspace.root, convertPath('/Users/user/test/prime'));
    expect(workspace.readonly, convertPath('/Users/user/test/READONLY/prime'));
    expect(workspace.bin, convertPath('/Users/user/test/prime/blaze-bin'));
    expect(workspace.genfiles,
        convertPath('/Users/user/test/prime/blaze-genfiles'));
  }

  void test_find_hasWorkspaceFile() {
    newFile('/workspace/WORKSPACE');
    newFolder('/workspace/bazel-genfiles');
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, convertPath('/workspace/bazel-bin'));
    expect(workspace.genfiles, convertPath('/workspace/bazel-genfiles'));
  }

  void test_find_hasWorkspaceFile_forModuleInWorkspace() {
    newFile('/workspace/WORKSPACE');
    newFolder('/workspace/bazel-genfiles');
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, convertPath('/workspace/bazel-bin'));
    expect(workspace.genfiles, convertPath('/workspace/bazel-genfiles'));
  }

  void test_find_hasWorkspaceFile_forWorkspace() {
    newFile('/workspace/WORKSPACE');
    newFolder('/workspace/bazel-genfiles');
    BazelWorkspace workspace =
        BazelWorkspace.find(resourceProvider, convertPath('/workspace'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, convertPath('/workspace/bazel-bin'));
    expect(workspace.genfiles, convertPath('/workspace/bazel-genfiles'));
  }

  void test_find_hasWorkspaceFile_forWorkspace_blaze() {
    newFile('/workspace/WORKSPACE');
    newFolder('/workspace/blaze-genfiles');
    BazelWorkspace workspace =
        BazelWorkspace.find(resourceProvider, convertPath('/workspace'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, convertPath('/workspace/blaze-bin'));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
  }

  void test_find_null_noWorkspaceMarkers() {
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    expect(workspace, isNull);
  }

  void test_find_null_noWorkspaceMarkers_inRoot() {
    BazelWorkspace workspace =
        BazelWorkspace.find(resourceProvider, convertPath('/'));
    expect(workspace, isNull);
  }

  void test_find_null_symlinkPrefix() {
    String prefix = BazelWorkspace.defaultSymlinkPrefix;
    newFile('/workspace/WORKSPACE');
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.bin, convertPath('/workspace/$prefix-bin'));
    expect(workspace.genfiles, convertPath('/workspace/$prefix-genfiles'));
  }

  void test_findFile_hasReadonlyFolder() {
    newFolder('/Users/user/test/READONLY/prime');
    newFolder('/Users/user/test/prime');
    newFile('/Users/user/test/prime/my/module/test1.dart');
    newFile('/Users/user/test/prime/my/module/test2.dart');
    newFile('/Users/user/test/prime/my/module/test3.dart');
    newFile('/Users/user/test/prime/bazel-bin/my/module/test2.dart');
    newFile('/Users/user/test/prime/bazel-genfiles/my/module/test3.dart');
    newFile('/Users/user/test/READONLY/prime/other/module/test4.dart');
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/Users/user/test/prime/my/module'));
    expect(
        workspace
            .findFile(
                convertPath('/Users/user/test/prime/my/module/test1.dart'))
            .path,
        convertPath('/Users/user/test/prime/my/module/test1.dart'));
    expect(
        workspace
            .findFile(
                convertPath('/Users/user/test/prime/my/module/test2.dart'))
            .path,
        convertPath('/Users/user/test/prime/bazel-bin/my/module/test2.dart'));
    expect(
        workspace
            .findFile(
                convertPath('/Users/user/test/prime/my/module/test3.dart'))
            .path,
        convertPath(
            '/Users/user/test/prime/bazel-genfiles/my/module/test3.dart'));
    expect(
        workspace
            .findFile(
                convertPath('/Users/user/test/prime/other/module/test4.dart'))
            .path,
        convertPath('/Users/user/test/READONLY/prime/other/module/test4.dart'));
  }

  void test_findFile_main_overrides_readonly() {
    newFolder('/Users/user/test/READONLY/prime');
    newFolder('/Users/user/test/prime');
    newFolder('/Users/user/test/prime/bazel-genfiles');
    newFile('/Users/user/test/prime/my/module/test.dart');
    newFile('/Users/user/test/READONLY/prime/my/module/test.dart');
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/Users/user/test/prime/my/module'));
    expect(
        workspace
            .findFile(convertPath('/Users/user/test/prime/my/module/test.dart'))
            .path,
        convertPath('/Users/user/test/prime/my/module/test.dart'));
  }

  void test_findFile_noReadOnly() {
    newFile('/workspace/WORKSPACE');
    newFile('/workspace/my/module/test1.dart');
    newFile('/workspace/my/module/test2.dart');
    newFile('/workspace/my/module/test3.dart');
    newFile('/workspace/bazel-bin/my/module/test2.dart');
    newFile('/workspace/bazel-genfiles/my/module/test3.dart');
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    expect(
        workspace.findFile(convertPath('/workspace/my/module/test1.dart')).path,
        convertPath('/workspace/my/module/test1.dart'));
    expect(
        workspace.findFile(convertPath('/workspace/my/module/test2.dart')).path,
        convertPath('/workspace/bazel-bin/my/module/test2.dart'));
    expect(
        workspace.findFile(convertPath('/workspace/my/module/test3.dart')).path,
        convertPath('/workspace/bazel-genfiles/my/module/test3.dart'));
  }
}

@reflectiveTest
class BazelWorkspacePackageTest with ResourceProviderMixin {
  BazelWorkspace workspace;

  void setUp() {
    newFile('/ws/WORKSPACE');
    newFolder('/ws/bazel-genfiles');
    workspace =
        BazelWorkspace.find(resourceProvider, convertPath('/ws/some/code'));
  }

  void test_findPackageFor_missingBuildFile() {
    final targetFile = newFile('/ws/some/code/lib/code.dart');

    var package = workspace.findPackageFor(targetFile.path);
    expect(package, isNull);
  }

  void test_findPackageFor_buildFileExists() {
    newFile('/ws/some/code/BUILD');
    final targetFile = newFile('/ws/some/code/lib/code.dart');

    var package = workspace.findPackageFor(targetFile.path);
    expect(package, isNotNull);
    expect(package.root, convertPath('/ws/some/code'));
    expect(package.workspace, equals(workspace));
  }

  void test_contains_differentWorkspace() {
    newFile('/ws/some/code/BUILD');
    final targetFile = newFile('/ws/some/code/lib/code.dart');

    var package = workspace.findPackageFor(targetFile.path);
    expect(package.contains('/ws2/some/file.dart'), isFalse);
  }

  void test_contains_differentPackageInWorkspace() {
    newFile('/ws/some/code/BUILD');
    final targetFile = newFile('/ws/some/code/lib/code.dart');

    var package = workspace.findPackageFor(targetFile.path);
    // A file that is _not_ in this package is not required to have a BUILD.gn
    // file above it, for simplicity and reduced I/O.
    expect(package.contains('/ws/some/other/code/file.dart'), isFalse);
  }

  void test_contains_samePackage() {
    newFile('/ws/some/code/BUILD');
    final targetFile = newFile('/ws/some/code/lib/code.dart');
    final targetFile2 = newFile('/ws/some/code/lib/code2.dart');
    final targetFile3 = newFile('/ws/some/code/lib/src/code3.dart');
    final targetBinFile = newFile('/ws/some/code/bin/code.dart');
    final targetTestFile = newFile('/ws/some/code/test/code_test.dart');

    var package = workspace.findPackageFor(targetFile.path);
    expect(package.contains(targetFile2.path), isTrue);
    expect(package.contains(targetFile3.path), isTrue);
    expect(package.contains(targetBinFile.path), isTrue);
    expect(package.contains(targetTestFile.path), isTrue);
  }

  void test_contains_subPackage() {
    newFile('/ws/some/code/BUILD');
    newFile('/ws/some/code/lib/code.dart');
    newFile('/ws/some/code/testing/BUILD');
    newFile('/ws/some/code/testing/lib/testing.dart');

    var package =
        workspace.findPackageFor(convertPath('/ws/some/code/lib/code.dart'));
    expect(
        package.contains(convertPath('/ws/some/code/testing/lib/testing.dart')),
        isFalse);
  }
}

class _MockSource implements Source {
  @override
  final String fullName;

  _MockSource(this.fullName);

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}
