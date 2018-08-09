// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/generated/package_build.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:package_config/packages.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackageBuildFileUriResolverTest);
    defineReflectiveTests(PackageBuildPackageUriResolverTest);
    defineReflectiveTests(PackageBuildWorkspaceTest);
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
class PackageBuildFileUriResolverTest extends _BaseTest {
  PackageBuildWorkspace workspace;
  PackageBuildFileUriResolver resolver;

  void setUp() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/lib'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    final MockContextBuilder contextBuilder = new MockContextBuilder();
    final Packages packages = new MockPackages();
    contextBuilder.packagesMapMap[_p('/workspace')] = packages;
    contextBuilder.packagesToMapMap[packages] = {'project': []};
    workspace =
        PackageBuildWorkspace.find(provider, _p('/workspace'), contextBuilder);
    resolver = new PackageBuildFileUriResolver(workspace);
    provider.newFile(_p('/workspace/test.dart'), '');
    provider.newFile(
        _p('/workspace/.dart_tool/build/generated/project/gen.dart'), '');
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
    Source source = _resolvePath('/workspace/gen.dart');
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName,
        _p('/workspace/.dart_tool/build/generated/project/gen.dart'));
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
class PackageBuildPackageUriResolverTest extends _BaseTest {
  PackageBuildWorkspace workspace;
  PackageBuildPackageUriResolver resolver;
  MockUriResolver packageUriResolver;

  Uri addPackageSource(String path, String uriStr, {bool create: true}) {
    Uri uri = Uri.parse(uriStr);
    final File file = create
        ? provider.newFile(_p(path), '')
        : provider.getResource(_p(path));
    final Source source = file.createSource(uri);
    packageUriResolver.resolveAbsoluteMap[uri] = source;
    return uri;
  }

  void setUp() {
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
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
        provider.newFolder(_p(path.substring(0, path.length - 1)));
      } else {
        provider.newFile(_p(path), '');
      }
    }
    final contextBuilder = new MockContextBuilder();
    final packages = new MockPackages();
    contextBuilder.packagesMapMap[_p(workspacePath)] = packages;
    contextBuilder.packagesToMapMap[packages] = {'project': []};
    workspace =
        PackageBuildWorkspace.find(provider, _p(workspacePath), contextBuilder);
    packageUriResolver = new MockUriResolver();
    resolver =
        new PackageBuildPackageUriResolver(workspace, packageUriResolver);
  }

  Source _assertResolveUri(Uri uri, String posixPath,
      {bool exists: true, bool restore: true}) {
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(source.fullName, _p(posixPath));
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
class PackageBuildWorkspaceTest extends _BaseTest {
  void test_builtFile_currentProject() {
    provider.newFolder(_p('/workspace/.dart_tool/build'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final libFile = provider.newFile(
        _p('/workspace/.dart_tool/build/generated/project/lib/file.dart'), '');
    expect(workspace.builtFile(_p('lib/file.dart'), 'project'), libFile);
  }

  void test_builtFile_importedPackage() {
    provider.newFolder(_p('/workspace/.dart_tool/build'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project', 'foo']);

    final libFile = provider.newFile(
        _p('/workspace/.dart_tool/build/generated/foo/lib/file.dart'), '');
    expect(workspace.builtFile(_p('lib/file.dart'), 'foo'), libFile);
  }

  void test_builtFile_notInPackagesGetsHidden() {
    provider.newFolder(_p('/workspace/.dart_tool/build'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);

    // Ensure package:bar is not configured.
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project', 'foo']);

    // Create a generated file in package:bar.
    provider.newFile(
        _p('/workspace/.dart_tool/build/generated/bar/lib/file.dart'), '');

    // Bar not in packages, file should not be returned.
    expect(workspace.builtFile('lib/file.dart', 'bar'), isNull);
  }

  void test_find_fail_notAbsolute() {
    expect(
        () => PackageBuildWorkspace.find(
            provider, _p('not_absolute'), new MockContextBuilder()),
        throwsArgumentError);
  }

  void test_find_hasDartToolAndPubspec() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/lib'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        provider, _p('/workspace'), new MockContextBuilder());
    expect(workspace.root, _p('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolAndPubspec_inParentDirectory() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/lib'));
    provider.newFolder(_p('/workspace/opened/up/a/child/dir/.dart_tool/build'));
    provider.newFileWithBytes(
        _p('/workspace/opened/up/a/child/dir/pubspec.yaml'),
        'name: subproject'.codeUnits);
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(provider,
        _p('/workspace/opened/up/a/child/dir'), new MockContextBuilder());
    expect(workspace.root, _p('/workspace/opened/up/a/child/dir'));
    expect(workspace.projectPackageName, 'subproject');
  }

  void
      test_find_hasDartToolAndPubspec_inParentDirectory_ignoresMalformedPubspec() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/lib'));
    provider.newFolder(_p('/workspace/opened/up/a/child/dir/.dart_tool/build'));
    provider.newFileWithBytes(
        _p('/workspace/opened/up/a/child/dir/pubspec.yaml'),
        'not: yaml: here!!! 111'.codeUnits);
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(provider,
        _p('/workspace/opened/up/a/child/dir'), new MockContextBuilder());
    expect(workspace.root, _p('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolAndPubspec_inParentDirectory_ignoresSoloDartTool() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/lib'));
    provider.newFolder(_p('/workspace/opened/up/a/child/dir'));
    provider.newFolder(_p('/workspace/opened/up/a/child/dir/.dart_tool/build'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(provider,
        _p('/workspace/opened/up/a/child/dir'), new MockContextBuilder());
    expect(workspace.root, _p('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolAndPubspec_inParentDirectory_ignoresSoloPubspec() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/lib'));
    provider.newFolder(_p('/workspace/opened/up/a/child/dir'));
    provider.newFileWithBytes(
        _p('/workspace/opened/up/a/child/dir/pubspec.yaml'),
        'name: subproject'.codeUnits);
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(provider,
        _p('/workspace/opened/up/a/child/dir'), new MockContextBuilder());
    expect(workspace.root, _p('/workspace'));
    expect(workspace.projectPackageName, 'project');
  }

  void test_find_hasDartToolNoBuild() {
    // Edge case: an empty .dart_tool directory. Don't assume package:build.
    provider.newFolder(_p('/workspace/.dart_tool'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        provider, _p('/workspace'), new MockContextBuilder());
    expect(workspace, isNull);
  }

  void test_find_hasDartToolNoPubspec() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/lib'));
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        provider, _p('/workspace'), new MockContextBuilder());
    expect(workspace, isNull);
  }

  void test_find_hasDartToolPubButNotBuild() {
    // Dart projects will have this directory, that don't use package:build.
    provider.newFolder(_p('/workspace/.dart_tool/pub'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        provider, _p('/workspace'), new MockContextBuilder());
    expect(workspace, isNull);
  }

  void test_find_hasMalformedPubspec() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/lib'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'not: yaml: here! 1111'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        provider, _p('/workspace'), new MockContextBuilder());
    expect(workspace, isNull);
  }

  void test_find_hasPubspecNoDartTool() {
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace = PackageBuildWorkspace.find(
        provider, _p('/workspace'), new MockContextBuilder());
    expect(workspace, isNull);
  }

  void test_findFile_bin() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/bin'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final binFile = provider.newFile(_p('/workspace/bin/file.dart'), '');
    expect(workspace.findFile(_p('/workspace/bin/file.dart')), binFile);
  }

  void test_findFile_binGenerated() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/bin'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final binFile = provider.newFile(
        _p('/workspace/.dart_tool/build/generated/project/bin/file.dart'), '');
    expect(workspace.findFile(_p('/workspace/bin/file.dart')), binFile);
  }

  void test_findFile_libGenerated() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/lib'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final libFile = provider.newFile(
        _p('/workspace/.dart_tool/build/generated/project/lib/file.dart'), '');
    expect(workspace.findFile(_p('/workspace/lib/file.dart')), libFile);
  }

  void test_findFile_test() {
    provider
        .newFolder(_p('/workspace/.dart_tool/build/generated/project/test'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final testFile = provider.newFile(_p('/workspace/test/file.dart'), '');
    expect(workspace.findFile(_p('/workspace/test/file.dart')), testFile);
  }

  void test_findFile_testGenerated() {
    provider
        .newFolder(_p('/workspace/.dart_tool/build/generated/project/test'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final testFile = provider.newFile(
        _p('/workspace/.dart_tool/build/generated/project/test/file.dart'), '');
    expect(workspace.findFile(_p('/workspace/test/file.dart')), testFile);
  }

  void test_findFile_web() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/web'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final webFile = provider.newFile(_p('/workspace/web/file.dart'), '');
    expect(workspace.findFile(_p('/workspace/web/file.dart')), webFile);
  }

  void test_findFile_webGenerated() {
    provider.newFolder(_p('/workspace/.dart_tool/build/generated/project/web'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
    PackageBuildWorkspace workspace =
        _createWorkspace('/workspace', ['project']);

    final webFile = provider.newFile(
        _p('/workspace/.dart_tool/build/generated/project/web/file.dart'), '');
    expect(workspace.findFile(_p('/workspace/web/file.dart')), webFile);
  }

  void test_supports_flutter() {
    provider.newFolder(_p('/workspace/.dart_tool/build'));
    provider.newFileWithBytes(
        _p('/workspace/pubspec.yaml'), 'name: project'.codeUnits);
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
    contextBuilder.packagesMapMap[_p(root)] = packages;
    contextBuilder.packagesToMapMap[packages] = packageMap;
    return PackageBuildWorkspace.find(provider, _p(root), contextBuilder);
  }
}

class _BaseTest {
  final MemoryResourceProvider provider = new MemoryResourceProvider();

  /**
   * Return the [provider] specific path for the given Posix [path].
   */
  String _p(String path) => provider.convertPath(path);
}
