// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';

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
    resolver = BazelFileUriResolver(workspace);
    newFile('/workspace/test.dart');
    newFile('/workspace/bazel-bin/gen1.dart');
    newFile('/workspace/bazel-genfiles/gen2.dart');
    expect(workspace.isBazel, isTrue);
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
    Uri uri = Uri(scheme: 'dart', path: 'core');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_notFile_httpsUri() {
    Uri uri = Uri(scheme: 'https', path: '127.0.0.1/test.dart');
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
        resolver
            .restoreAbsolute(NonExistingSource(source.fullName, null, null)),
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

  void test_resolveAbsolute_file_bin_to_genfiles() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/my/foo/test/foo1.dart',
      '/workspace/bazel-bin/'
    ]);
    _assertResolve('file:///workspace/bazel-bin/my/foo/test/foo1.dart',
        '/workspace/bazel-genfiles/my/foo/test/foo1.dart',
        restore: false);
  }

  void test_resolveAbsolute_file_genfiles_to_workspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/workspace/my/foo/test/foo1.dart'
    ]);
    _assertResolve('file:///workspace/bazel-genfiles/my/foo/test/foo1.dart',
        '/workspace/my/foo/test/foo1.dart',
        restore: false);
  }

  void test_resolveAbsolute_file_not_in_workspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
      '/other/my/foo/test/foo1.dart'
    ]);
    _assertNoResolve('file:///other/my/foo/test/foo1.dart');
  }

  void test_resolveAbsolute_file_readonly_to_workspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/READONLY/workspace/',
      '/workspace/my/foo/test/foo1.dart'
    ]);
    _assertResolve('file:///READONLY/workspace/my/foo/test/foo1.dart',
        '/workspace/my/foo/test/foo1.dart',
        restore: false);
  }

  void test_resolveAbsolute_file_workspace_to_genfiles() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/my/foo/test/foo1.dart'
    ]);
    _assertResolve('file:///workspace/my/foo/test/foo1.dart',
        '/workspace/bazel-genfiles/my/foo/test/foo1.dart',
        restore: false);
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

  void test_resolveAbsolute_null_doubleDot() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
    ]);
    var uri = Uri.parse('package:foo..bar/baz.dart');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_doubleSlash() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
    ]);
    var uri = Uri.parse('package:foo//bar/baz.dart');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
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

  void _addResources(List<String> paths,
      {String workspacePath = '/workspace'}) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        newFolder(path.substring(0, path.length - 1));
      } else {
        newFile(path);
      }
    }
    workspace =
        BazelWorkspace.find(resourceProvider, convertPath(workspacePath));
    resolver = BazelPackageUriResolver(workspace);
  }

  void _assertNoResolve(String uriStr) {
    var uri = Uri.parse(uriStr);
    expect(resolver.resolveAbsolute(uri), isNull);
  }

  void _assertResolve(String uriStr, String posixPath,
      {bool exists = true, bool restore = true}) {
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
    _MockSource source = _MockSource(path);
    Uri uri = resolver.restoreAbsolute(source);
    expect(uri?.toString(), expectedUri);
  }
}

@reflectiveTest
class BazelWorkspacePackageTest with ResourceProviderMixin {
  BazelWorkspace workspace;
  BazelWorkspacePackage package;

  void test_contains_differentPackage_summarySource() {
    _setUpPackage();
    var source = _inSummarySource('package:some.other.code/file.dart');
    expect(package.contains(source), isFalse);
  }

  void test_contains_differentPackageInWorkspace() {
    _setUpPackage();

    // A file that is _not_ in this package is not required to have a BUILD
    // file above it, for simplicity and reduced I/O.
    expect(
      package.contains(
        _testSource('/ws/some/other/code/file.dart'),
      ),
      isFalse,
    );
  }

  void test_contains_differentWorkspace() {
    _setUpPackage();
    expect(
      package.contains(
        _testSource('/ws2/some/file.dart'),
      ),
      isFalse,
    );
  }

  void test_contains_samePackage() {
    _setUpPackage();
    final targetFile = newFile('/ws/some/code/lib/code2.dart');
    final targetFile2 = newFile('/ws/some/code/lib/src/code3.dart');
    final targetBinFile = newFile('/ws/some/code/bin/code.dart');
    final targetTestFile = newFile('/ws/some/code/test/code_test.dart');

    expect(package.contains(_testSource(targetFile.path)), isTrue);
    expect(package.contains(_testSource(targetFile2.path)), isTrue);
    expect(package.contains(_testSource(targetBinFile.path)), isTrue);
    expect(package.contains(_testSource(targetTestFile.path)), isTrue);
  }

  void test_contains_samePackage_summarySource() {
    _setUpPackage();
    newFile('/ws/some/code/lib/code2.dart');
    newFile('/ws/some/code/lib/src/code3.dart');
    final file2Source = _inSummarySource('package:some.code/code2.dart');
    final file3Source = _inSummarySource('package:some.code/src/code2.dart');

    expect(package.contains(file2Source), isTrue);
    expect(package.contains(file3Source), isTrue);
  }

  void test_contains_subPackage() {
    _setUpPackage();
    newFile('/ws/some/code/testing/BUILD');
    newFile('/ws/some/code/testing/lib/testing.dart');

    expect(
      package.contains(
        _testSource('/ws/some/code/testing/lib/testing.dart'),
      ),
      isFalse,
    );
  }

  void test_findPackageFor_buildFileExists() {
    _setUpPackage();

    expect(package, isNotNull);
    expect(package.root, convertPath('/ws/some/code'));
    expect(package.workspace, equals(workspace));
  }

  void test_findPackageFor_missingMarkerFiles() {
    _addResources([
      '/ws/WORKSPACE',
      '/ws/bazel-genfiles',
    ]);
    workspace = BazelWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code'),
    );
    final targetFile = newFile('/ws/some/code/lib/code.dart');

    package = workspace.findPackageFor(targetFile.path);
    expect(package, isNull);
  }

  void test_findPackageFor_packagesFileExistsInOneOfSeveralBinPaths() {
    _addResources([
      '/ws/blaze-out/host/bin/some/code/code.packages',
      '/ws/blaze-out/k8-opt/bin/some/code/',
      '/ws/some/code/lib/code.dart',
    ]);
    workspace = BazelWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code'),
    );

    package = workspace.findPackageFor(
      convertPath('/ws/some/code/lib/code.dart'),
    );
    expect(package, isNotNull);
    expect(package.root, convertPath('/ws/some/code'));
    expect(package.workspace, equals(workspace));
  }

  void test_findPackageFor_packagesFileExistsInOnlyBinPath() {
    _addResources([
      '/ws/blaze-out/host/bin/some/code/code.packages',
      '/ws/some/code/lib/code.dart',
    ]);
    workspace = BazelWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code'),
    );

    package = workspace.findPackageFor(
      convertPath('/ws/some/code/lib/code.dart'),
    );
    expect(package, isNotNull);
    expect(package.root, convertPath('/ws/some/code'));
    expect(package.workspace, equals(workspace));
  }

  void test_findPackageFor_packagesFileInBinExists_subPackage() {
    _addResources([
      '/ws/blaze-out/host/bin/some/code/code.packages',
      '/ws/blaze-out/host/bin/some/code/testing/testing.packages',
      '/ws/some/code/lib/code.dart',
      '/ws/some/code/testing/lib/testing.dart',
    ]);
    workspace = BazelWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code/testing'),
    );

    package = workspace.findPackageFor(
      convertPath('/ws/some/code/testing/lib/testing.dart'),
    );
    expect(package, isNotNull);
    expect(package.root, convertPath('/ws/some/code/testing'));
    expect(package.workspace, equals(workspace));
  }

  void test_packagesAvailableTo() {
    _setUpPackage();
    var packageMap =
        package.packagesAvailableTo(convertPath('/ws/some/code/lib/code.dart'));
    expect(packageMap, isEmpty);
  }

  /// Create new files and directories from [paths].
  void _addResources(List<String> paths) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        newFolder(path.substring(0, path.length - 1));
      } else {
        newFile(path);
      }
    }
  }

  Source _inSummarySource(String uriStr) {
    var uri = Uri.parse(uriStr);
    return InSummarySource(uri, '');
  }

  void _setUpPackage() {
    _addResources([
      '/ws/WORKSPACE',
      '/ws/bazel-genfiles/',
      '/ws/some/code/BUILD',
      '/ws/some/code/lib/code.dart',
    ]);

    workspace = BazelWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code'),
    );
    package = workspace.findPackageFor(
      convertPath('/ws/some/code/lib/code.dart'),
    );
  }

  Source _testSource(String path) {
    path = convertPath(path);
    return TestSource(path);
  }
}

@reflectiveTest
class BazelWorkspaceTest with ResourceProviderMixin {
  BazelWorkspace workspace;

  void test_find_fail_notAbsolute() {
    expect(
        () =>
            BazelWorkspace.find(resourceProvider, convertPath('not_absolute')),
        throwsA(const TypeMatcher<ArgumentError>()));
  }

  void test_find_hasBlazeBinFolderInOutFolder() {
    _addResources([
      '/workspace/blaze-out/host/bin/',
      '/workspace/my/module/BUILD',
    ]);
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.binPaths.single,
        convertPath('/workspace/blaze-out/host/bin'));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
    expect(
        workspace
            .findPackageFor(convertPath(
                '/workspace/blaze-out/host/bin/my/module/lib/foo.dart'))
            .root,
        convertPath('/workspace/my/module'));
  }

  void test_find_hasBlazeOutFolder_missingBinFolder() {
    _addResources([
      '/workspace/blaze-genfiles/',
      '/workspace/blaze-out/',
      '/workspace/my/module/',
    ]);
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.binPaths.single, convertPath('/workspace/blaze-bin'));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
  }

  void test_find_hasMultipleBlazeBinFolderInOutFolder() {
    _addResources([
      '/workspace/blaze-out/host/bin/',
      '/workspace/blaze-out/k8-fastbuild/bin/',
      '/workspace/my/module/',
    ]);
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.binPaths, hasLength(2));
    expect(workspace.binPaths,
        contains(convertPath('/workspace/blaze-out/host/bin')));
    expect(workspace.binPaths,
        contains(convertPath('/workspace/blaze-out/k8-fastbuild/bin')));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
  }

  void test_find_hasReadonlyFolder() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/prime/',
      '/Users/user/test/prime/bazel-genfiles/',
    ]);
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/Users/user/test/prime/my/module'));
    expect(workspace.root, convertPath('/Users/user/test/prime'));
    expect(workspace.readonly, convertPath('/Users/user/test/READONLY/prime'));
    expect(workspace.binPaths.single,
        convertPath('/Users/user/test/prime/bazel-bin'));
    expect(workspace.genfiles,
        convertPath('/Users/user/test/prime/bazel-genfiles'));
  }

  void test_find_hasReadonlyFolder_bad_actuallyHasWorkspaceFile() {
    _addResources([
      '/Users/user/test/READONLY/',
      '/Users/user/test/prime/WORKSPACE',
      '/Users/user/test/prime/bazel-genfiles/',
    ]);
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/Users/user/test/prime/my/module'));
    expect(workspace.root, convertPath('/Users/user/test/prime'));
    expect(workspace.readonly, isNull);
    expect(workspace.binPaths.single,
        convertPath('/Users/user/test/prime/bazel-bin'));
    expect(workspace.genfiles,
        convertPath('/Users/user/test/prime/bazel-genfiles'));
  }

  void test_find_hasReadonlyFolder_blaze() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/prime/',
      '/Users/user/test/prime/blaze-genfiles/',
    ]);
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/Users/user/test/prime/my/module'));
    expect(workspace.root, convertPath('/Users/user/test/prime'));
    expect(workspace.readonly, convertPath('/Users/user/test/READONLY/prime'));
    expect(workspace.binPaths.single,
        convertPath('/Users/user/test/prime/blaze-bin'));
    expect(workspace.genfiles,
        convertPath('/Users/user/test/prime/blaze-genfiles'));
  }

  void test_find_hasWorkspaceFile() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
    ]);
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.binPaths.single, convertPath('/workspace/bazel-bin'));
    expect(workspace.genfiles, convertPath('/workspace/bazel-genfiles'));
  }

  void test_find_hasWorkspaceFile_forModuleInWorkspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
    ]);
    BazelWorkspace workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.binPaths.single, convertPath('/workspace/bazel-bin'));
    expect(workspace.genfiles, convertPath('/workspace/bazel-genfiles'));
  }

  void test_find_hasWorkspaceFile_forWorkspace() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/bazel-genfiles/',
    ]);
    BazelWorkspace workspace =
        BazelWorkspace.find(resourceProvider, convertPath('/workspace'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.binPaths.single, convertPath('/workspace/bazel-bin'));
    expect(workspace.genfiles, convertPath('/workspace/bazel-genfiles'));
  }

  void test_find_hasWorkspaceFile_forWorkspace_blaze() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/blaze-genfiles/',
    ]);
    BazelWorkspace workspace =
        BazelWorkspace.find(resourceProvider, convertPath('/workspace'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.readonly, isNull);
    expect(workspace.binPaths.single, convertPath('/workspace/blaze-bin'));
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
    expect(workspace.binPaths.single, convertPath('/workspace/$prefix-bin'));
    expect(workspace.genfiles, convertPath('/workspace/$prefix-genfiles'));
  }

  void test_findFile_hasReadonlyFolder() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/prime/',
      '/Users/user/test/prime/my/module/test1.dart',
      '/Users/user/test/prime/my/module/test2.dart',
      '/Users/user/test/prime/my/module/test3.dart',
      '/Users/user/test/prime/bazel-bin/my/module/test2.dart',
      '/Users/user/test/prime/bazel-genfiles/my/module/test3.dart',
      '/Users/user/test/READONLY/prime/other/module/test4.dart',
    ]);
    workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/Users/user/test/prime/my/module'));
    _expectFindFile('/Users/user/test/prime/my/module/test1.dart',
        equals: '/Users/user/test/prime/my/module/test1.dart');
    _expectFindFile('/Users/user/test/prime/my/module/test2.dart',
        equals: '/Users/user/test/prime/bazel-bin/my/module/test2.dart');
    _expectFindFile('/Users/user/test/prime/my/module/test3.dart',
        equals: '/Users/user/test/prime/bazel-genfiles/my/module/test3.dart');
    _expectFindFile('/Users/user/test/prime/other/module/test4.dart',
        equals: '/Users/user/test/READONLY/prime/other/module/test4.dart');
  }

  void test_findFile_main_overrides_readonly() {
    _addResources([
      '/Users/user/test/READONLY/prime/',
      '/Users/user/test/prime/',
      '/Users/user/test/prime/bazel-genfiles/',
      '/Users/user/test/prime/my/module/test.dart',
      '/Users/user/test/READONLY/prime/my/module/test.dart',
    ]);
    workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/Users/user/test/prime/my/module'));
    _expectFindFile('/Users/user/test/prime/my/module/test.dart',
        equals: '/Users/user/test/prime/my/module/test.dart');
  }

  void test_findFile_noReadOnly() {
    _addResources([
      '/workspace/WORKSPACE',
      '/workspace/my/module/test1.dart',
      '/workspace/my/module/test2.dart',
      '/workspace/my/module/test3.dart',
      '/workspace/bazel-bin/my/module/test2.dart',
      '/workspace/bazel-genfiles/my/module/test3.dart',
    ]);
    workspace = BazelWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    _expectFindFile('/workspace/my/module/test1.dart',
        equals: '/workspace/my/module/test1.dart');
    _expectFindFile('/workspace/my/module/test2.dart',
        equals: '/workspace/bazel-bin/my/module/test2.dart');
    _expectFindFile('/workspace/my/module/test3.dart',
        equals: '/workspace/bazel-genfiles/my/module/test3.dart');
  }

  /// Create new files and directories from [paths].
  void _addResources(List<String> paths) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        newFolder(path.substring(0, path.length - 1));
      } else {
        newFile(path);
      }
    }
  }

  /// Expect that [BazelWorkspace.findFile], given [path], returns [equals].
  void _expectFindFile(String path, {@required String equals}) =>
      expect(workspace.findFile(convertPath(path)).path, convertPath(equals));
}

class _MockSource implements Source {
  @override
  final String fullName;

  _MockSource(this.fullName);

  @override
  noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected invocation of ${invocation.memberName}');
  }
}
