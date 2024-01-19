// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/generated/source.dart' show UriResolver;
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import 'workspace_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubWorkspacePackageTest);
    defineReflectiveTests(PubWorkspaceTest);
    defineReflectiveTests(PackageBuildFileUriResolverTest);
    defineReflectiveTests(PackageBuildPackageUriResolverTest);
  });
}

class MockUriResolver implements UriResolver {
  Map<Uri, File> uriToFile = {};
  Map<String, Uri> pathToUriMap = {};

  void add(Uri uri, File file) {
    uriToFile[uri] = file;
    pathToUriMap[file.path] = uri;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Uri? pathToUri(String path) {
    return pathToUriMap[path];
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    return uriToFile[uri]?.createSource(uri);
  }
}

@reflectiveTest
class PackageBuildFileUriResolverTest with ResourceProviderMixin {
  late final PubWorkspace workspace;
  late final PackageBuildFileUriResolver resolver;

  File get testFile => getFile('$testPackageLibPath/test.dart');

  String get testPackageGeneratedLibPath => '$testPackageGeneratedRootPath/lib';

  String get testPackageGeneratedRootPath =>
      '$testPackageRootPath/.dart_tool/build/generated/test';

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get workspaceRootPath => '/home';

  void setUp() {
    newFolder(testPackageGeneratedLibPath);
    newPubspecYamlFile(testPackageRootPath, 'name: test');

    workspace = PubWorkspace.find(
      resourceProvider,
      Packages({
        'test': Package(
          name: 'test',
          rootFolder: getFolder(testPackageRootPath),
          libFolder: getFolder(testPackageLibPath),
          languageVersion: null,
        ),
      }),
      convertPath(testPackageRootPath),
    )!;
    resolver = PackageBuildFileUriResolver(workspace);
    expect(workspace.isBlaze, isFalse);
  }

  void test_resolveAbsolute_fileUri() {
    var path = testFile.path;
    newFile(path, '');
    _assertResolveUri(toUri(path), path);
  }

  void test_resolveAbsolute_fileUri_doesNotExist() {
    var path = testFile.path;
    _assertResolveUri(toUri(path), path, exists: false);
  }

  void test_resolveAbsolute_fileUri_folder() {
    var uri = toUri(testPackageRootPath);
    var source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_fileUri_generated_lib() {
    var file = newFile('$testPackageGeneratedLibPath/foo.dart', '');
    _assertResolveUri(
      toUri('$testPackageLibPath/foo.dart'),
      file.path,
    );
  }

  void test_resolveAbsolute_fileUri_generated_notLib() {
    var file = newFile('$testPackageGeneratedRootPath/example/foo.dart', '');
    _assertResolveUri(
      toUri('$testPackageRootPath/example/foo.dart'),
      file.path,
    );
  }

  void test_resolveAbsolute_notFileUri_dartUri() {
    var uri = Uri.parse('dart:core');
    var source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_notFileUri_httpsUri() {
    var uri = Uri.parse('https://127.0.0.1/test.dart');
    var source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  Source _assertResolveUri(
    Uri uri,
    String posixPath, {
    bool exists = true,
  }) {
    var source = resolver.resolveAbsolute(uri)!;
    var path = source.fullName;
    expect(path, convertPath(posixPath));
    expect(source.uri, uri);
    expect(source.exists(), exists);
    expect(resolver.pathToUri(path), uri);
    return source;
  }
}

@reflectiveTest
class PackageBuildPackageUriResolverTest with ResourceProviderMixin {
  late final PubWorkspace workspace;
  late final PackageBuildPackageUriResolver resolver;
  late final MockUriResolver packageUriResolver;

  Uri addPackageSource(String path, String uriStr, {bool create = true}) {
    Uri uri = Uri.parse(uriStr);
    final file = create
        ? newFile(path, '')
        : resourceProvider.getResource(convertPath(path)) as File;
    packageUriResolver.add(uri, file);
    return uri;
  }

  void setUp() {
    newPubspecYamlFile('/workspace', 'name: project');
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
    var source = resolver.resolveAbsolute(Uri.parse('dart:async'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_startsWithSlash() {
    _addResources([
      '/workspace/.dart_tool/build/generated',
    ]);
    var source = resolver.resolveAbsolute(Uri.parse('package:/foo/bar.dart'));
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
        newFile(path, '');
      }
    }
    workspace = PubWorkspace.find(
      resourceProvider,
      Packages({
        'project': Package(
          name: 'project',
          rootFolder: getFolder('/workspace'),
          libFolder: getFolder('/workspace'),
          languageVersion: null,
        ),
      }),
      convertPath(workspacePath),
    )!;
    packageUriResolver = MockUriResolver();
    resolver = PackageBuildPackageUriResolver(workspace, packageUriResolver);
  }

  Source _assertResolveUri(
    Uri uri,
    String posixPath, {
    bool exists = true,
  }) {
    var source = resolver.resolveAbsolute(uri)!;
    var path = source.fullName;
    expect(path, convertPath(posixPath));
    expect(source.uri, uri);
    expect(source.exists(), exists);
    expect(resolver.pathToUri(path), uri);
    return source;
  }
}

@reflectiveTest
class PubWorkspacePackageTest extends WorkspacePackageTest {
  late final PubWorkspace myWorkspace;
  late final PubWorkspacePackage myPackage;

  String get fooPackageLibPath => '$fooPackageRootPath/lib';

  String get fooPackageRootPath => '$myWorkspacePath/foo';

  String get myPackageGeneratedPath {
    return '$myPackageRootPath/.dart_tool/build/generated';
  }

  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$myWorkspacePath/my';

  String get myWorkspacePath => '/workspace2';

  setUp() {
    // Setup two workspaces, one at path /workspace that does not have generated
    // files, and the second at path /workspace2 which uses the build package
    // and has generated files.

    // workspace 1 with packages 'p1' and 'workspace'
    newPubspecYamlFile('/workspace', 'name: project');
    workspace = PubWorkspace.find(
      resourceProvider,
      Packages({
        'p1': Package(
          name: 'p1',
          rootFolder: getFolder('/.pubcache/p1'),
          libFolder: getFolder('/.pubcache/p1/lib'),
          languageVersion: null,
        ),
        'workspace': Package(
          name: 'workspace',
          rootFolder: getFolder('/workspace'),
          libFolder: getFolder('/workspace/lib'),
          languageVersion: null,
        ),
      }),
      convertPath('/workspace'),
    )!;
    expect(workspace.isBlaze, isFalse);

    // workspace 2 with packages 'my' and 'foo'
    newPubspecYamlFile(myPackageRootPath, 'name: my');
    newFolder(myPackageGeneratedPath);
    myWorkspace = PubWorkspace.find(
      resourceProvider,
      Packages({
        'my': Package(
          name: 'my',
          rootFolder: getFolder(myPackageRootPath),
          libFolder: getFolder(myPackageLibPath),
          languageVersion: null,
        ),
        'foo': Package(
          name: 'foo',
          rootFolder: getFolder(fooPackageRootPath),
          libFolder: getFolder(fooPackageLibPath),
          languageVersion: null,
        ),
      }),
      convertPath(myPackageRootPath),
    )!;
    final fakeFile = getFile('$myPackageLibPath/fake.dart');
    myPackage = myWorkspace.findPackageFor(fakeFile.path)!;
  }

  void test_contains_differentWorkspace() {
    newFile('$myWorkspacePath/project/lib/file.dart', '');

    var package = findPackage('/workspace/project/lib/code.dart')!;
    expect(
        package.contains(
            TestSource(convertPath('$myWorkspacePath/project/lib/file.dart'))),
        isFalse);
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
    newFile(myGeneratedPath, '');

    var fooGeneratedPath = '$myPackageGeneratedPath/foo/test/a.dart';
    newFile(fooGeneratedPath, '');

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

  void test_contains_sameWorkspace() {
    newFile('/workspace/project/lib/file2.dart', '');

    var package = findPackage('/workspace/project/lib/code.dart')!;
    expect(
        package.contains(
            TestSource(convertPath('/workspace/project/lib/file2.dart'))),
        isTrue);
    expect(
        package.contains(
            TestSource(convertPath('/workspace/project/bin/bin.dart'))),
        isTrue);
    expect(
        package.contains(
            TestSource(convertPath('/workspace/project/test/test.dart'))),
        isTrue);
  }

  void test_findPackageFor_includedFile() {
    newFile('/workspace/project/lib/file.dart', '');

    var package = findPackage('/workspace/project/lib/file.dart')!;
    expect(package.root, convertPath('/workspace'));
    expect(package.workspace, equals(workspace));
  }

  test_findPackageFor_my_build_dir_file() {
    var package = myWorkspace.findPackageFor(
      convertPath('/workspace/build/lib/a.dart'),
    );
    expect(package, null);
  }

  test_findPackageFor_my_generated_file() {
    var package = myWorkspace.findPackageFor(
      convertPath('$myPackageGeneratedPath/my/a.dart'),
    );
    expect(package, myPackage);
  }

  test_findPackageFor_my_generated_libFile() {
    var package = myWorkspace.findPackageFor(
      convertPath('$myPackageGeneratedPath/my/lib/a.dart'),
    )!;
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
    )!;
    expect(package.root, convertPath(myPackageRootPath));
    expect(package.workspace, myWorkspace);
  }

  test_findPackageFor_my_libFile() {
    var package = myWorkspace.findPackageFor(
      convertPath('$myPackageLibPath/a.dart'),
    )!;
    expect(package.root, convertPath(myPackageRootPath));
    expect(package.workspace, myWorkspace);
  }

  test_findPackageFor_my_testFile() {
    var package = myWorkspace.findPackageFor(
      convertPath('$myPackageRootPath/test/a.dart'),
    )!;
    expect(package.root, convertPath(myPackageRootPath));
    expect(package.workspace, myWorkspace);
  }

  test_findPackageFor_my_web_file() {
    var package = myWorkspace.findPackageFor(
      convertPath('$myPackageRootPath/web/a.dart'),
    );
    expect(package, myPackage);
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

  void test_findPackageFor_unrelatedFile() {
    newFile('/workspace/project/lib/file.dart', '');

    var package = findPackage('$myWorkspacePath/project/lib/file.dart');
    expect(package, isNull);
  }

  void test_packagesAvailableTo() {
    var libraryPath = convertPath('/workspace/lib/test.dart');
    var package = findPackage(libraryPath)!;
    var packages = package.packagesAvailableTo(libraryPath);
    expect(
      packages.packages.map((e) => e.name),
      unorderedEquals(['p1', 'workspace']),
    );
  }

  Source _sourceWithFileUri(String path) {
    return _MockSource(path: convertPath(path), uri: toUri(path));
  }

  Source _sourceWithPackageUriWithoutPath(String uriStr) {
    var uri = Uri.parse(uriStr);
    return _MockSource(path: convertPath('/test/lib/test.dart'), uri: uri);
  }
}

@reflectiveTest
class PubWorkspaceTest with ResourceProviderMixin {
  void test_builtFile_currentProject() {
    newFolder('/workspace/.dart_tool/build');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project']);

    final libFile = newFile(
        '/workspace/.dart_tool/build/generated/project/lib/file.dart', '');
    expect(
        workspace.builtFile(convertPath('lib/file.dart'), 'project'), libFile);
  }

  void test_builtFile_importedPackage() {
    newFolder('/workspace/.dart_tool/build');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project', 'foo']);

    final libFile =
        newFile('/workspace/.dart_tool/build/generated/foo/lib/file.dart', '');
    expect(workspace.builtFile(convertPath('lib/file.dart'), 'foo'), libFile);
  }

  void test_builtFile_notInPackagesGetsHidden() {
    newFolder('/workspace/.dart_tool/build');
    newPubspecYamlFile('/workspace', 'name: project');

    // Ensure package:bar is not configured.
    PubWorkspace workspace = _createWorkspace('/workspace', ['project', 'foo']);

    // Create a generated file in package:bar.
    newFile('/workspace/.dart_tool/build/generated/bar/lib/file.dart', '');

    // Bar not in packages, file should not be returned.
    expect(workspace.builtFile('lib/file.dart', 'bar'), isNull);
  }

  void test_find_directory() {
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project']);
    expect(workspace.isBlaze, isFalse);
    expect(workspace.root, convertPath('/workspace'));
  }

  void test_find_fail_notAbsolute() {
    expect(
        () => PubWorkspace.find(
            resourceProvider, Packages.empty, convertPath('not_absolute')),
        throwsA(TypeMatcher<ArgumentError>()));
  }

  void test_find_file() {
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace =
        _createWorkspace('/workspace/lib/lib1.dart', ['project']);
    expect(workspace.root, convertPath('/workspace'));
  }

  void test_find_hasBuild_hasPubspec_malformed_dontGoToUp() {
    newFolder('/workspace/.dart_tool/build/generated');
    newPubspecYamlFile('/workspace', 'name: project');

    newFolder('/workspace/aaa/.dart_tool/build/generated');
    newPubspecYamlFile('/workspace/aaa', '*');
    newPackageConfigJsonFile('/workspace/aaa', '');

    PubWorkspace workspace = _createWorkspace('/workspace/aaa/lib', []);
    expect(workspace, isNotNull);
    expect(workspace.root, convertPath('/workspace/aaa'));
  }

  void test_find_hasDartToolAndPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newPubspecYamlFile('/workspace', 'name: project');

    PubWorkspace workspace = _createWorkspace('/workspace', []);

    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolAndPubspec_inParentDirectory() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFolder('/workspace/opened/up/a/child/dir/.dart_tool/build');
    newPubspecYamlFile('/workspace/opened/up/a/child/dir', 'name: subproject');
    newPackageConfigJsonFile('/workspace/opened/up/a/child/dir', '');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace =
        _createWorkspace('/workspace/opened/up/a/child/dir', ['project']);
    expect(workspace.root, convertPath('/workspace/opened/up/a/child/dir'));
    expect(workspace.projectPackageName, 'subproject');
  }

  void test_find_hasDartToolAndPubspec_inParentDirectory_ignoresSoloDartTool() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFolder('/workspace/opened/up/a/child/dir');
    newFolder('/workspace/opened/up/a/child/dir/.dart_tool/build');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace =
        _createWorkspace('/workspace/opened/up/a/child/dir', ['project']);
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolNoBuild() {
    // Edge case: an empty .dart_tool directory. Don't assume package:build.
    newFolder('/workspace/.dart_tool');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project']);
    expect(workspace, isNotNull);
    expect(workspace.usesPackageBuild, isFalse);
  }

  void test_find_hasDartToolNoPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    var workspace = PubWorkspace.find(
      resourceProvider,
      Packages.empty,
      convertPath('/workspace'),
    );
    expect(workspace, isNull);
  }

  void test_find_hasDartToolPubButNotBuild() {
    // Dart projects will have this directory, that don't use package:build.
    newFolder('/workspace/.dart_tool/pub');
    newPubspecYamlFile('/workspace', 'name: project');
    var workspace = PubWorkspace.find(
      resourceProvider,
      Packages.empty,
      convertPath('/workspace'),
    );
    expect(workspace!.root, convertPath('/workspace'));
    expect(workspace.usesPackageBuild, isFalse);
  }

  void test_find_hasMalformedPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newPubspecYamlFile('/workspace', 'not: yaml: here! 1111');
    var workspace = PubWorkspace.find(
      resourceProvider,
      Packages.empty,
      convertPath('/workspace'),
    );
    expect(workspace?.root, convertPath('/workspace'));
  }

  void test_find_hasPubspec_noDartTool_dontGoUp() {
    newFolder('/workspace/.dart_tool/build/generated');
    newPubspecYamlFile('/workspace', 'name: project');

    newPubspecYamlFile('/workspace/aaa', '*');

    var workspace = PubWorkspace.find(
      resourceProvider,
      Packages.empty,
      convertPath('/workspace/aaa/lib'),
    );
    expect(workspace?.root, convertPath('/workspace/aaa'));
    expect(workspace?.usesPackageBuild, isFalse);
  }

  void test_find_hasPubspecNoDartTool() {
    newPubspecYamlFile('/workspace', 'name: project');
    var workspace = PubWorkspace.find(
      resourceProvider,
      Packages.empty,
      convertPath('/workspace'),
    );
    expect(workspace?.root, convertPath('/workspace'));
    expect(workspace?.usesPackageBuild, isFalse);
  }

  void test_find_missingPubspec() {
    var workspace = PubWorkspace.find(resourceProvider, Packages.empty,
        convertPath('/workspace/lib/lib1.dart'));
    expect(workspace, isNull);
  }

  void test_findFile_bin() {
    newFolder('/workspace/.dart_tool/build/generated/project/bin');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project']);

    final binFile = newFile('/workspace/bin/file.dart', '');
    expect(
        workspace.findFile(convertPath('/workspace/bin/file.dart')), binFile);
  }

  void test_findFile_binGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/bin');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project']);

    final binFile = newFile(
        '/workspace/.dart_tool/build/generated/project/bin/file.dart', '');
    expect(
        workspace.findFile(convertPath('/workspace/bin/file.dart')), binFile);
  }

  void test_findFile_libGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project']);

    final libFile = newFile(
        '/workspace/.dart_tool/build/generated/project/lib/file.dart', '');
    expect(
        workspace.findFile(convertPath('/workspace/lib/file.dart')), libFile);
  }

  void test_findFile_test() {
    newFolder('/workspace/.dart_tool/build/generated/project/test');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project']);

    final testFile = newFile('/workspace/test/file.dart', '');
    expect(
        workspace.findFile(convertPath('/workspace/test/file.dart')), testFile);
  }

  void test_findFile_testGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/test');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project']);

    final testFile = newFile(
        '/workspace/.dart_tool/build/generated/project/test/file.dart', '');
    expect(
        workspace.findFile(convertPath('/workspace/test/file.dart')), testFile);
  }

  void test_findFile_web() {
    newFolder('/workspace/.dart_tool/build/generated/project/web');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project']);

    final webFile = newFile('/workspace/web/file.dart', '');
    expect(
        workspace.findFile(convertPath('/workspace/web/file.dart')), webFile);
  }

  void test_findFile_webGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/web');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project']);

    final webFile = newFile(
        '/workspace/.dart_tool/build/generated/project/web/file.dart', '');
    expect(
        workspace.findFile(convertPath('/workspace/web/file.dart')), webFile);
  }

  void test_isConsistentWithFileSystem() {
    newFolder('/workspace/.dart_tool/build/generated/project/bin');
    newPubspecYamlFile('/workspace', 'name: project');
    PubWorkspace workspace = _createWorkspace('/workspace', ['project']);
    expect(workspace.isConsistentWithFileSystem, isTrue);

    newPubspecYamlFile('/workspace', 'name: my2');
    expect(workspace.isConsistentWithFileSystem, isFalse);
  }

  PubWorkspace _createWorkspace(String root, List<String> packageNames) {
    var packageMap = <String, Package>{};
    for (var name in packageNames) {
      packageMap[name] = Package(
        name: name,
        rootFolder: getFolder('/packages/$name'),
        libFolder: getFolder('/packages/$name/lib'),
        languageVersion: null,
      );
    }

    return PubWorkspace.find(
      resourceProvider,
      Packages(packageMap),
      convertPath(root),
    )!;
  }
}

class _MockSource implements Source {
  final String path;

  @override
  final Uri uri;

  _MockSource({required this.path, required this.uri});

  @override
  String get fullName {
    return path;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
