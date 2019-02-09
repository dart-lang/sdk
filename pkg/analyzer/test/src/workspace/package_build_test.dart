// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/package_build.dart';
import 'package:package_config/packages.dart';
import 'package:path/path.dart' as path;
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

class MockContextBuilder implements ContextBuilder {
  Map<String, Packages> packagesMapMap = <String, Packages>{};
  Map<Packages, Map<String, List<Folder>>> packagesToMapMap =
      <Packages, Map<String, List<Folder>>>{};

  Map<String, List<Folder>> convertPackagesToMap(Packages packages) =>
      packagesToMapMap[packages];

  Packages createPackageMap(String rootDirectoryPath) =>
      packagesMapMap[rootDirectoryPath];

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPackages implements Packages {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUriResolver implements UriResolver {
  Map<Uri, Source> resolveAbsoluteMap = {};

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Source resolveAbsolute(Uri uri, [Uri actualUri]) => resolveAbsoluteMap[uri];
}

@reflectiveTest
class PackageBuildFileUriResolverTest with ResourceProviderMixin {
  PackageBuildWorkspace workspace;
  PackageBuildFileUriResolver resolver;

  void setUp() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    final MockContextBuilder contextBuilder = new MockContextBuilder();
    final Packages packages = new MockPackages();
    contextBuilder.packagesMapMap[convertPath('/workspace')] = packages;
    contextBuilder.packagesToMapMap[packages] = {'project': []};
    workspace = PackageBuildWorkspace.find(
        resourceProvider, convertPath('/workspace'), contextBuilder);
    resolver = new PackageBuildFileUriResolver(workspace);
    newFile('/workspace/test.dart');
    newFile('/workspace/.dart_tool/build/generated/project/gen.dart');
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

  Uri addPackageSource(String path, String uriStr, {bool create: true}) {
    Uri uri = Uri.parse(uriStr);
    final File file = create
        ? newFile(path)
        : resourceProvider.getResource(convertPath(path));
    final Source source = file.createSource(uri);
    packageUriResolver.resolveAbsoluteMap[uri] = source;
    return uri;
  }

  void setUp() {
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
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

  void _addResources(List<String> paths, {String workspacePath: '/workspace'}) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        newFolder(path.substring(0, path.length - 1));
      } else {
        newFile(path);
      }
    }
    final contextBuilder = new MockContextBuilder();
    final packages = new MockPackages();
    contextBuilder.packagesMapMap[convertPath(workspacePath)] = packages;
    contextBuilder.packagesToMapMap[packages] = {'project': []};
    workspace = PackageBuildWorkspace.find(
        resourceProvider, convertPath(workspacePath), contextBuilder);
    packageUriResolver = new MockUriResolver();
    resolver =
        new PackageBuildPackageUriResolver(workspace, packageUriResolver);
  }

  Source _assertResolveUri(Uri uri, String posixPath,
      {bool exists: true, bool restore: true}) {
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
class PackageBuildWorkspaceTest with ResourceProviderMixin {
  void test_builtFile_currentProject() {
    newFolder('/workspace/.dart_tool/build');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final libFile =
        newFile('/workspace/.dart_tool/build/generated/project/lib/file.dart');
    expect(
        workspace.builtFile(convertPath('lib/file.dart'), 'project'), libFile);
  }

  void test_builtFile_importedPackage() {
    newFolder('/workspace/.dart_tool/build');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project', 'foo']);

    final libFile =
        newFile('/workspace/.dart_tool/build/generated/foo/lib/file.dart');
    expect(workspace.builtFile(convertPath('lib/file.dart'), 'foo'), libFile);
  }

  void test_builtFile_notInPackagesGetsHidden() {
    newFolder('/workspace/.dart_tool/build');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);

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
        () => PackageBuildWorkspace.find(resourceProvider,
            convertPath('not_absolute'), new MockContextBuilder()),
        throwsA(const TypeMatcher<ArgumentError>()));
  }

  void test_find_hasDartToolAndPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        resourceProvider, convertPath('/workspace'), new MockContextBuilder());
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolAndPubspec_inParentDirectory() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFolder('/workspace/opened/up/a/child/dir/.dart_tool/build');
    newFileWithBytes('/workspace/opened/up/a/child/dir/pubspec.yaml',
        'name: subproject'.codeUnits);
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        resourceProvider,
        convertPath('/workspace/opened/up/a/child/dir'),
        new MockContextBuilder());
    expect(workspace.root, convertPath('/workspace/opened/up/a/child/dir'));
    expect(workspace.projectPackageName, 'subproject');
  }

  void
      test_find_hasDartToolAndPubspec_inParentDirectory_ignoresMalformedPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFolder('/workspace/opened/up/a/child/dir/.dart_tool/build');
    newFileWithBytes('/workspace/opened/up/a/child/dir/pubspec.yaml',
        'not: yaml: here!!! 111'.codeUnits);
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        resourceProvider,
        convertPath('/workspace/opened/up/a/child/dir'),
        new MockContextBuilder());
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolAndPubspec_inParentDirectory_ignoresSoloDartTool() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFolder('/workspace/opened/up/a/child/dir');
    newFolder('/workspace/opened/up/a/child/dir/.dart_tool/build');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        resourceProvider,
        convertPath('/workspace/opened/up/a/child/dir'),
        new MockContextBuilder());
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolAndPubspec_inParentDirectory_ignoresSoloPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFolder('/workspace/opened/up/a/child/dir');
    newFileWithBytes('/workspace/opened/up/a/child/dir/pubspec.yaml',
        'name: subproject'.codeUnits);
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        resourceProvider,
        convertPath('/workspace/opened/up/a/child/dir'),
        new MockContextBuilder());
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolNoBuild() {
    // Edge case: an empty .dart_tool directory. Don't assume package:build.
    newFolder('/workspace/.dart_tool');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        resourceProvider, convertPath('/workspace'), new MockContextBuilder());
    expect(workspace, isNull);
  }

  void test_find_hasDartToolNoPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        resourceProvider, convertPath('/workspace'), new MockContextBuilder());
    expect(workspace, isNull);
  }

  void test_find_hasDartToolPubButNotBuild() {
    // Dart projects will have this directory, that don't use package:build.
    newFolder('/workspace/.dart_tool/pub');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        resourceProvider, convertPath('/workspace'), new MockContextBuilder());
    expect(workspace, isNull);
  }

  void test_find_hasMalformedPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFileWithBytes(
        '/workspace/pubspec.yaml', 'not: yaml: here! 1111'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        resourceProvider, convertPath('/workspace'), new MockContextBuilder());
    expect(workspace, isNull);
  }

  void test_find_hasPubspecNoDartTool() {
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        resourceProvider, convertPath('/workspace'), new MockContextBuilder());
    expect(workspace, isNull);
  }

  void test_findFile_bin() {
    newFolder('/workspace/.dart_tool/build/generated/project/bin');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final binFile = newFile('/workspace/bin/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/bin/file.dart')), binFile);
  }

  void test_findFile_binGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/bin');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final binFile =
        newFile('/workspace/.dart_tool/build/generated/project/bin/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/bin/file.dart')), binFile);
  }

  void test_findFile_libGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final libFile =
        newFile('/workspace/.dart_tool/build/generated/project/lib/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/lib/file.dart')), libFile);
  }

  void test_findFile_test() {
    newFolder('/workspace/.dart_tool/build/generated/project/test');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final testFile = newFile('/workspace/test/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/test/file.dart')), testFile);
  }

  void test_findFile_testGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/test');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final testFile =
        newFile('/workspace/.dart_tool/build/generated/project/test/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/test/file.dart')), testFile);
  }

  void test_findFile_web() {
    newFolder('/workspace/.dart_tool/build/generated/project/web');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final webFile = newFile('/workspace/web/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/web/file.dart')), webFile);
  }

  void test_findFile_webGenerated() {
    newFolder('/workspace/.dart_tool/build/generated/project/web');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final webFile =
        newFile('/workspace/.dart_tool/build/generated/project/web/file.dart');
    expect(
        workspace.findFile(convertPath('/workspace/web/file.dart')), webFile);
  }

  void test_supports_flutter() {
    newFolder('/workspace/.dart_tool/build');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project', 'flutter']);

    expect(workspace.hasFlutterDependency, true);
  }

  PackageBuildWorkspace _createWorkspace(
      String root, List<String> packageNames) {
    final contextBuilder = new MockContextBuilder();
    final packages = new MockPackages();
    final packageMap = new Map<String, List<Folder>>.fromIterable(packageNames,
        value: ((_) => []));
    contextBuilder.packagesMapMap[convertPath(root)] = packages;
    contextBuilder.packagesToMapMap[packages] = packageMap;
    return PackageBuildWorkspace.find(
        resourceProvider, convertPath(root), contextBuilder);
  }
}

@reflectiveTest
class PackageBuildWorkspacePackageTest with ResourceProviderMixin {
  PackageBuildWorkspace _createPackageBuildWorkspace() {
    final contextBuilder = new MockContextBuilder();
    final packagesForWorkspace = new MockPackages();
    contextBuilder.packagesMapMap[convertPath('/workspace')] =
        packagesForWorkspace;
    contextBuilder.packagesToMapMap[packagesForWorkspace] = {
      'project': <Folder>[]
    };

    final packagesForWorkspace2 = new MockPackages();
    contextBuilder.packagesMapMap[convertPath('/workspace2')] =
        packagesForWorkspace2;
    contextBuilder.packagesToMapMap[packagesForWorkspace2] = {
      'project2': <Folder>[]
    };

    newFolder('/workspace/.dart_tool/build');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    return PackageBuildWorkspace.find(
        resourceProvider, convertPath('/workspace'), contextBuilder);
  }

  void test_findPackageFor_unrelatedFile() {
    PackageBuildWorkspace workspace = _createPackageBuildWorkspace();
    newFile('/workspace/project/lib/file.dart');

    var package = workspace
        .findPackageFor(convertPath('/workspace2/project2/lib/file.dart'));
    expect(package, isNull);
  }

  void test_findPackageFor_includedFile() {
    PackageBuildWorkspace workspace = _createPackageBuildWorkspace();
    newFile('/workspace/project/lib/file.dart');

    var package = workspace
        .findPackageFor(convertPath('/workspace/project/lib/file.dart'));
    expect(package, isNotNull);
    expect(package.root, convertPath('/workspace'));
    expect(package.workspace, equals(workspace));
  }

  void test_contains_differentWorkspace() {
    PackageBuildWorkspace workspace = _createPackageBuildWorkspace();
    newFile('/workspace2/project2/lib/file.dart');

    var package = workspace
        .findPackageFor(convertPath('/workspace/project/lib/code.dart'));
    expect(package.contains('/workspace2/project2/lib/file.dart'), isFalse);
  }

  void test_contains_sameWorkspace() {
    PackageBuildWorkspace workspace = _createPackageBuildWorkspace();
    newFile('/workspace/project/lib/file2.dart');

    var package = workspace
        .findPackageFor(convertPath('/workspace/project/lib/code.dart'));
    var file2Path =
        path.separator + path.join('workspace', 'project', 'lib', 'file2.dart');
    expect(package.contains(file2Path), isTrue);
    var binPath =
        path.separator + path.join('workspace', 'project', 'bin', 'bin.dart');
    expect(package.contains(binPath), isTrue);
    var testPath =
        path.separator + path.join('workspace', 'project', 'test', 'test.dart');
    expect(package.contains(testPath), isTrue);
  }
}
