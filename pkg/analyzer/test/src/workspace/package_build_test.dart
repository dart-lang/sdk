// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/package_build.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackageBuildFileUriResolverTest);
    defineReflectiveTests(PackageBuildPackageUriResolverTest);
    defineReflectiveTests(PackageBuildWorkspaceTest);
    defineReflectiveTests(PackageBuildWorkspacePackageTest);
  });
}

class MockUriResolver implements UriResolver {
  Map<Uri, File> uriToFile = {};
  Map<String, Uri> pathToUri = {};

  void add(Uri uri, File file) {
    uriToFile[uri] = file;
    pathToUri[file.path] = uri;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    return uriToFile[uri]?.createSource(uri);
  }

  @override
  Uri restoreAbsolute(Source source) => pathToUri[source.fullName];
}

@reflectiveTest
class PackageBuildFileUriResolverTest with ResourceProviderMixin {
  PackageBuildWorkspace workspace;
  PackageBuildFileUriResolver resolver;

  void setUp() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFile('/workspace/pubspec.yaml', content: 'name: project');

    workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {
        'project': [getFolder('/workspace')]
      },
      convertPath('/workspace'),
    );
    resolver = PackageBuildFileUriResolver(workspace);
    newFile('/workspace/test.dart');
    newFile('/workspace/.dart_tool/build/generated/project/gen.dart');
    expect(workspace.isBazel, isFalse);
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
    Source source = _resolvePath('/workspace/gen.dart');
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName,
        convertPath('/workspace/.dart_tool/build/generated/project/gen.dart'));
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

  Source _resolvePath(String path) {
    Uri uri = toUri(path);
    return resolver.resolveAbsolute(uri);
  }
}

@reflectiveTest
class PackageBuildPackageUriResolverTest with ResourceProviderMixin {
  PackageBuildWorkspace workspace;
  PackageBuildPackageUriResolver resolver;
  MockUriResolver packageUriResolver;

  Uri addPackageSource(String path, String uriStr, {bool create = true}) {
    Uri uri = Uri.parse(uriStr);
    final File file = create
        ? newFile(path)
        : resourceProvider.getResource(convertPath(path));
    packageUriResolver.add(uri, file);
    return uri;
  }

  void setUp() {
    newFile('/workspace/pubspec.yaml', content: 'name: project');
  }

  void test_resolveAbsolute_generated() {
    _addResources([
      '/workspace/.dart_tool/build/generated/project/lib/generated_file.dart',
    ]);
    final Uri sourceUri = addPackageSource('/workspace/lib/generated_file.dart',
        'package:project/generated_file.dart',
        create: false);
    _assertResolveUri(sourceUri,
        '/workspace/.dart_tool/build/generated/project/lib/generated_file.dart',
        exists: true);
  }

  void test_resolveAbsolute_null_notPackage() {
    _addResources([
      '/workspace/.dart_tool/build/generated',
    ]);
    Source source = resolver.resolveAbsolute(Uri.parse('dart:async'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_startsWithSlash() {
    _addResources([
      '/workspace/.dart_tool/build/generated',
    ]);
    Source source =
        resolver.resolveAbsolute(Uri.parse('package:/foo/bar.dart'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_source() {
    _addResources([
      '/workspace/.dart_tool/build/generated/project/lib/source_file.dart',
    ]);
    final Uri sourceUri = addPackageSource(
        '/workspace/lib/source_file.dart', 'package:project/source_file.dart');
    _assertResolveUri(sourceUri, '/workspace/lib/source_file.dart',
        exists: true);
  }

  void test_resolveAbsolute_workspace_doesNotExist() {
    _addResources([
      '/workspace/.dart_tool/build/generated',
    ]);
    final Uri sourceUri = addPackageSource(
        '/workspace/lib/doesNotExist.dart', 'package:project/doesNotExist.dart',
        create: false);
    _assertResolveUri(sourceUri, '/workspace/lib/doesNotExist.dart',
        exists: false);
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
    workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {
        'project': [getFolder('/workspace')]
      },
      convertPath(workspacePath),
    );
    packageUriResolver = MockUriResolver();
    resolver = PackageBuildPackageUriResolver(workspace, packageUriResolver);
  }

  Source _assertResolveUri(Uri uri, String posixPath,
      {bool exists = true, bool restore = true}) {
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(source.fullName, convertPath(posixPath));
    expect(source.uri, uri);
    expect(source.exists(), exists);
    // If enabled, test also "restoreAbsolute".
    if (restore) {
      Uri restoredUri = resolver.restoreAbsolute(source);
      expect(restoredUri.toString(), uri.toString());
    }
    return source;
  }
}

@reflectiveTest
class PackageBuildWorkspacePackageTest with ResourceProviderMixin {
  PackageBuildWorkspace myWorkspace;
  PackageBuildWorkspacePackage myPackage;

  String get fooPackageLibPath => '$fooPackageRootPath/lib';

  String get fooPackageRootPath => '$myWorkspacePath/foo';

  String get myPackageGeneratedPath {
    return '$myPackageRootPath/.dart_tool/build/generated';
  }

  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$myWorkspacePath/my';

  String get myWorkspacePath => '/workspace';

  void setUp() {
    newFile('$myPackageRootPath/pubspec.yaml', content: 'name: my');
    newFolder(myPackageGeneratedPath);

    myWorkspace = PackageBuildWorkspace.find(
      resourceProvider,
      {
        'my': [getFolder(myPackageLibPath)],
        'foo': [getFolder(fooPackageLibPath)],
      },
      convertPath(myPackageRootPath),
    );

    myPackage = myWorkspace.findPackageFor('$myPackageLibPath/fake.dart');
  }

  test_contains_fileUri() {
    expect(
      myPackage.contains(
        _sourceWithFileUri('$myPackageRootPath/test/a.dart'),
      ),
      isTrue,
    );

    expect(
      myPackage.contains(
        _sourceWithFileUri('$fooPackageRootPath/test/a.dart'),
      ),
      isFalse,
    );
  }

  test_contains_fileUri_generated() {
    var myGeneratedPath = '$myPackageGeneratedPath/my/test/a.dart';
    newFile(myGeneratedPath, content: '');

    var fooGeneratedPath = '$myPackageGeneratedPath/foo/test/a.dart';
    newFile(fooGeneratedPath, content: '');

    expect(
      myPackage.contains(
        _sourceWithFileUri(myGeneratedPath),
      ),
      isTrue,
    );

    expect(
      myPackage.contains(
        _sourceWithFileUri(fooGeneratedPath),
      ),
      isFalse,
    );
  }

  test_contains_packageUri() {
    expect(
      myPackage.contains(
        _sourceWithPackageUriWithoutPath('package:my/a.dart'),
      ),
      isTrue,
    );

    expect(
      myPackage.contains(
        _sourceWithPackageUriWithoutPath('package:foo/a.dart'),
      ),
      isFalse,
    );
  }

  test_findPackageFor_my_generated_libFile() {
    var package = myWorkspace.findPackageFor(
      convertPath('$myPackageGeneratedPath/my/lib/a.dart'),
    );
    expect(package, isNotNull);
    expect(package.root, convertPath(myPackageRootPath));
    expect(package.workspace, myWorkspace);
  }

  test_findPackageFor_my_generated_other() {
    expect(
      myWorkspace.findPackageFor(
        convertPath('$myPackageGeneratedPath/foo/lib/a.dart'),
      ),
      isNull,
    );

    expect(
      myWorkspace.findPackageFor(
        convertPath('$myPackageGeneratedPath/foo/test/a.dart'),
      ),
      isNull,
    );
  }

  test_findPackageFor_my_generated_testFile() {
    var package = myWorkspace.findPackageFor(
      convertPath('$myPackageGeneratedPath/my/test/a.dart'),
    );
    expect(package, isNotNull);
    expect(package.root, convertPath(myPackageRootPath));
    expect(package.workspace, myWorkspace);
  }

  test_findPackageFor_my_libFile() {
    var package = myWorkspace.findPackageFor(
      convertPath('$myPackageLibPath/a.dart'),
    );
    expect(package, isNotNull);
    expect(package.root, convertPath(myPackageRootPath));
    expect(package.workspace, myWorkspace);
  }

  test_findPackageFor_my_testFile() {
    var package = myWorkspace.findPackageFor(
      convertPath('$myPackageRootPath/test/a.dart'),
    );
    expect(package, isNotNull);
    expect(package.root, convertPath(myPackageRootPath));
    expect(package.workspace, myWorkspace);
  }

  test_findPackageFor_other() {
    expect(
      myWorkspace.findPackageFor(
        convertPath('$fooPackageRootPath/lib/a.dart'),
      ),
      isNull,
    );

    expect(
      myWorkspace.findPackageFor(
        convertPath('$fooPackageRootPath/test/a.dart'),
      ),
      isNull,
    );
  }

  Source _sourceWithFileUri(String path) {
    return _MockSource(path: convertPath(path), uri: toUri(path));
  }

  Source _sourceWithPackageUriWithoutPath(String uriStr) {
    var uri = Uri.parse(uriStr);
    return _MockSource(path: null, uri: uri);
  }
}

@reflectiveTest
class PackageBuildWorkspaceTest with ResourceProviderMixin {
  void test_builtFile_currentProject() {
    newFolder('/workspace/.dart_tool/build');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final libFile =
        newFile('/workspace/.dart_tool/build/generated/project/lib/file.dart');
    expect(
        workspace.builtFile(convertPath('lib/file.dart'), 'project'), libFile);
  }

  void test_builtFile_importedPackage() {
    newFolder('/workspace/.dart_tool/build');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project', 'foo']);

    final libFile =
        newFile('/workspace/.dart_tool/build/generated/foo/lib/file.dart');
    expect(workspace.builtFile(convertPath('lib/file.dart'), 'foo'), libFile);
  }

  void test_builtFile_notInPackagesGetsHidden() {
    newFolder('/workspace/.dart_tool/build');
    newFile('/workspace/pubspec.yaml', content: 'name: project');

    // Ensure package:bar is not configured.
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project', 'foo']);

    // Create a generated file in package:bar.
    newFile('/workspace/.dart_tool/build/generated/bar/lib/file.dart');

    // Bar not in packages, file should not be returned.
    expect(workspace.builtFile('lib/file.dart', 'bar'), isNull);
  }

  void test_find_fail_notAbsolute() {
    expect(
      () {
        return PackageBuildWorkspace.find(
          resourceProvider,
          {},
          convertPath('not_absolute'),
        );
      },
      throwsArgumentError,
    );
  }

  void test_find_hasBuild_hasPubspec_malformed_dontGoToUp() {
    newFolder('/workspace/.dart_tool/build/generated');
    newFile('/workspace/pubspec.yaml', content: 'name: project');

    newFolder('/workspace/aaa/.dart_tool/build/generated');
    newFile('/workspace/aaa/pubspec.yaml', content: '*');

    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {},
      convertPath('/workspace/aaa/lib'),
    );
    expect(workspace, isNull);
  }

  void test_find_hasDartToolAndPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {},
      convertPath('/workspace'),
    );
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolAndPubspec_inParentDirectory() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFolder('/workspace/opened/up/a/child/dir/.dart_tool/build');
    newFile('/workspace/opened/up/a/child/dir/pubspec.yaml',
        content: 'name: subproject');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {},
      convertPath('/workspace/opened/up/a/child/dir'),
    );
    expect(workspace.root, convertPath('/workspace/opened/up/a/child/dir'));
    expect(workspace.projectPackageName, 'subproject');
  }

  void test_find_hasDartToolAndPubspec_inParentDirectory_ignoresSoloDartTool() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFolder('/workspace/opened/up/a/child/dir');
    newFolder('/workspace/opened/up/a/child/dir/.dart_tool/build');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {},
      convertPath('/workspace/opened/up/a/child/dir'),
    );
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolNoBuild() {
    // Edge case: an empty .dart_tool directory. Don't assume package:build.
    newFolder('/workspace/.dart_tool');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {},
      convertPath('/workspace'),
    );
    expect(workspace, isNull);
  }

  void test_find_hasDartToolNoPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {},
      convertPath('/workspace'),
    );
    expect(workspace, isNull);
  }

  void test_find_hasDartToolPubButNotBuild() {
    // Dart projects will have this directory, that don't use package:build.
    newFolder('/workspace/.dart_tool/pub');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {},
      convertPath('/workspace'),
    );
    expect(workspace, isNull);
  }

  void test_find_hasMalformedPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFile('/workspace/pubspec.yaml', content: 'not: yaml: here! 1111');
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {},
      convertPath('/workspace'),
    );
    expect(workspace, isNull);
  }

  void test_find_hasPubspec_noDartTool_dontGoUp() {
    newFolder('/workspace/.dart_tool/build/generated');
    newFile('/workspace/pubspec.yaml', content: 'name: project');

    newFile('/workspace/aaa/pubspec.yaml', content: '*');

    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {},
      convertPath('/workspace/aaa/lib'),
    );
    expect(workspace, isNull);
  }

  void test_find_hasPubspecNoDartTool() {
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
      resourceProvider,
      {},
      convertPath('/workspace'),
    );
    expect(workspace, isNull);
  }

  void test_findFile_bin() {
    newFolder('/workspace/.dart_tool/build/generated/project/bin');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final binFile = newFile('/workspace/bin/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/bin/file.dart')), binFile);
  }

  void test_findFile_binGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/bin');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final binFile =
        newFile('/workspace/.dart_tool/build/generated/project/bin/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/bin/file.dart')), binFile);
  }

  void test_findFile_libGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final libFile =
        newFile('/workspace/.dart_tool/build/generated/project/lib/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/lib/file.dart')), libFile);
  }

  void test_findFile_test() {
    newFolder('/workspace/.dart_tool/build/generated/project/test');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final testFile = newFile('/workspace/test/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/test/file.dart')), testFile);
  }

  void test_findFile_testGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/test');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final testFile =
        newFile('/workspace/.dart_tool/build/generated/project/test/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/test/file.dart')), testFile);
  }

  void test_findFile_web() {
    newFolder('/workspace/.dart_tool/build/generated/project/web');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final webFile = newFile('/workspace/web/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/web/file.dart')), webFile);
  }

  void test_findFile_webGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/web');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final webFile =
        newFile('/workspace/.dart_tool/build/generated/project/web/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/web/file.dart')), webFile);
  }

  PackageBuildWorkspace _createWorkspace(
      String root, List<String> packageNames) {
    return PackageBuildWorkspace.find(
      resourceProvider,
      Map.fromIterables(
        packageNames,
        packageNames.map(
          (name) => [getFolder('/packages/$name/lib')],
        ),
      ),
      convertPath(root),
    );
  }
}

class _MockSource implements Source {
  final String path;

  @override
  final Uri uri;

  _MockSource({@required this.path, @required this.uri});

  @override
  String get fullName {
    if (path == null) {
      throw StateError('This source has no path, '
          'and we do not expect that it will be accessed.');
    }
    return path;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
