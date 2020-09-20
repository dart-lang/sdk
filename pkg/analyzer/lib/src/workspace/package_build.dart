// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Instances of the class `PackageBuildFileUriResolver` resolve `file` URI's by
/// first resolving file uri's in the expected way, and then by looking in the
/// corresponding generated directories.
class PackageBuildFileUriResolver extends ResourceUriResolver {
  final PackageBuildWorkspace workspace;

  PackageBuildFileUriResolver(PackageBuildWorkspace workspace)
      : workspace = workspace,
        super(workspace.provider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (!ResourceUriResolver.isFileUri(uri)) {
      return null;
    }
    String filePath = fileUriToNormalizedPath(provider.pathContext, uri);
    Resource resource = provider.getResource(filePath);
    if (resource is! File) {
      return null;
    }
    File file = workspace.findFile(filePath);
    if (file != null) {
      return file.createSource(actualUri ?? uri);
    }
    return null;
  }
}

/// The [UriResolver] that can resolve `package` URIs in
/// [PackageBuildWorkspace].
class PackageBuildPackageUriResolver extends UriResolver {
  final PackageBuildWorkspace _workspace;
  final UriResolver _normalUriResolver;
  final path.Context _context;

  PackageBuildPackageUriResolver(
      PackageBuildWorkspace workspace, this._normalUriResolver)
      : _workspace = workspace,
        _context = workspace.provider.pathContext;

  Map<String, List<Folder>> get packageMap => _workspace._packageMap;

  @override
  Source resolveAbsolute(Uri _ignore, [Uri uri]) {
    uri ??= _ignore;
    if (uri.scheme != 'package') {
      return null;
    }

    Source basicResolverSource = _normalUriResolver.resolveAbsolute(uri);
    if (basicResolverSource != null && basicResolverSource.exists()) {
      return basicResolverSource;
    }

    String uriPath = uri.path;
    int slash = uriPath.indexOf('/');

    // If the path either starts with a slash or has no slash, it is invalid.
    if (slash < 1) {
      return null;
    }

    String packageName = uriPath.substring(0, slash);
    String fileUriPart = uriPath.substring(slash + 1);
    String filePath = fileUriPart.replaceAll('/', _context.separator);

    File file = _workspace.builtFile(
        _workspace.builtPackageSourcePath(filePath), packageName);
    if (file != null && file.exists) {
      return file.createSource(uri);
    }
    return basicResolverSource;
  }

  @override
  Uri restoreAbsolute(Source source) {
    String filePath = source.fullName;

    if (_context.isWithin(_workspace.root, filePath)) {
      List<String> uriParts = _restoreUriParts(filePath);
      if (uriParts != null) {
        return Uri.parse('package:${uriParts[0]}/${uriParts[1]}');
      }
    }

    return _normalUriResolver.restoreAbsolute(source);
  }

  List<String> _restoreUriParts(String filePath) {
    String relative = _context.relative(filePath, from: _workspace.root);
    List<String> components = _context.split(relative);
    if (components.length > 5 &&
        components[0] == '.dart_tool' &&
        components[1] == 'build' &&
        components[2] == 'generated' &&
        components[4] == 'lib') {
      String packageName = components[3];
      String pathInLib = components.skip(5).join('/');
      return [packageName, pathInLib];
    }
    return null;
  }
}

/// Information about a package:build workspace.
class PackageBuildWorkspace extends Workspace {
  /// The name of the directory that identifies the root of the workspace. Note,
  /// the presence of this file does not show package:build is used. For that,
  /// the subdirectory [_dartToolBuildName] must exist. A `pub` subdirectory
  /// will usually exist in non-package:build projects too.
  static const String _dartToolRootName = '.dart_tool';

  /// The name of the subdirectory in [_dartToolName] that distinguishes
  /// projects built with package:build.
  static const String _dartToolBuildName = 'build';

  /// We use pubspec.yaml to get the package name to be consistent with how
  /// package:build does it.
  static const String _pubspecName = 'pubspec.yaml';

  static const List<String> _generatedPathParts = [
    '.dart_tool',
    'build',
    'generated'
  ];

  /// The resource provider used to access the file system.
  final ResourceProvider provider;

  /// The map from a package name to the list of its `lib/` folders.
  final Map<String, List<Folder>> _packageMap;

  /// The absolute workspace root path (the directory containing the
  /// `.dart_tool` directory).
  @override
  final String root;

  /// The name of the package under development as defined in pubspec.yaml. This
  /// matches the behavior of package:build.
  final String projectPackageName;

  /// `.dart_tool/build/generated` in [root].
  final String generatedRootPath;

  /// [projectPackageName] in [generatedRootPath].
  final String generatedThisPath;

  /// The singular package in this workspace.
  ///
  /// Each "package:build" workspace is itself one package.
  PackageBuildWorkspacePackage _theOnlyPackage;

  PackageBuildWorkspace._(
    this.provider,
    this._packageMap,
    this.root,
    this.projectPackageName,
    this.generatedRootPath,
    this.generatedThisPath,
  );

  @override
  UriResolver get packageUriResolver => PackageBuildPackageUriResolver(
      this, PackageMapUriResolver(provider, _packageMap));

  /// For some package file, which may or may not be a package source (it could
  /// be in `bin/`, `web/`, etc), find where its built counterpart will exist if
  /// its a generated source.
  ///
  /// To get a [builtPath] for a package source file to use in this method,
  /// use [builtPackageSourcePath]. For `bin/`, `web/`, etc, it must be relative
  /// to the project root.
  File builtFile(String builtPath, String packageName) {
    if (!_packageMap.containsKey(packageName)) {
      return null;
    }
    path.Context context = provider.pathContext;
    String fullBuiltPath = context.normalize(context.join(
        root, _dartToolRootName, 'build', 'generated', packageName, builtPath));
    return provider.getFile(fullBuiltPath);
  }

  /// Unlike the way that sources are resolved against `.packages` (if foo
  /// points to folder bar, then `foo:baz.dart` is found at `bar/baz.dart`), the
  /// built sources for a package require the `lib/` prefix first. This is
  /// because `bin/`, `web/`, and `test/` etc can all be built as well. This
  /// method exists to give a name to that prefix processing step.
  String builtPackageSourcePath(String filePath) {
    path.Context context = provider.pathContext;
    assert(context.isRelative(filePath), 'Not a relative path: $filePath');
    return context.join('lib', filePath);
  }

  @override
  SourceFactory createSourceFactory(DartSdk sdk, SummaryDataStore summaryData) {
    if (summaryData != null) {
      throw UnsupportedError(
          'Summary files are not supported in a package:build workspace.');
    }
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(PackageBuildFileUriResolver(this));
    return SourceFactory(resolvers);
  }

  /// Return the file with the given [filePath], looking first in the generated
  /// directory `.dart_tool/build/generated/$projectPackageName/`, then in
  /// source directories.
  ///
  /// The file in the workspace [root] is returned even if it does not exist.
  /// Return `null` if the given [filePath] is not in the workspace root.
  File findFile(String filePath) {
    path.Context context = provider.pathContext;
    assert(context.isAbsolute(filePath), 'Not an absolute path: $filePath');
    try {
      final String relativePath = context.relative(filePath, from: root);
      final File file = builtFile(relativePath, projectPackageName);

      if (file.exists) {
        return file;
      }

      return provider.getFile(filePath);
    } catch (_) {
      return null;
    }
  }

  @override
  WorkspacePackage findPackageFor(String path) {
    var pathContext = provider.pathContext;

    // Must be in this workspace.
    if (!pathContext.isWithin(root, path)) {
      return null;
    }

    // If generated, must be for this package.
    if (pathContext.isWithin(generatedRootPath, path)) {
      if (!pathContext.isWithin(generatedThisPath, path)) {
        return null;
      }
    }

    return _theOnlyPackage ??= PackageBuildWorkspacePackage(root, this);
  }

  /// Find the package:build workspace that contains the given [filePath].
  ///
  /// Return `null` if the filePath is not in a package:build workspace.
  static PackageBuildWorkspace find(ResourceProvider provider,
      Map<String, List<Folder>> packageMap, String filePath) {
    Folder folder = provider.getFolder(filePath);
    while (true) {
      Folder parent = folder.parent;
      if (parent == null) {
        return null;
      }

      final File pubspec = folder.getChildAssumingFile(_pubspecName);
      final Folder dartToolDir =
          folder.getChildAssumingFolder(_dartToolRootName);
      final Folder dartToolBuildDir =
          dartToolDir.getChildAssumingFolder(_dartToolBuildName);

      // Found the .dart_tool file, that's our project root. We also require a
      // pubspec, to know the package name that package:build will assume.
      if (dartToolBuildDir.exists && pubspec.exists) {
        try {
          final yaml = loadYaml(pubspec.readAsStringSync());
          final packageName = yaml['name'] as String;
          final generatedRootPath = provider.pathContext
              .joinAll([folder.path, ..._generatedPathParts]);
          final generatedThisPath =
              provider.pathContext.join(generatedRootPath, packageName);
          return PackageBuildWorkspace._(provider, packageMap, folder.path,
              packageName, generatedRootPath, generatedThisPath);
        } catch (_) {}
      }

      // Go up the folder.
      folder = parent;
    }
  }
}

/// Information about a package defined in a PackageBuildWorkspace.
///
/// Separate from [Packages] or package maps, this class is designed to simply
/// understand whether arbitrary file paths represent libraries declared within
/// a given package in a PackageBuildWorkspace.
class PackageBuildWorkspacePackage extends WorkspacePackage {
  @override
  final String root;

  @override
  final PackageBuildWorkspace workspace;

  PackageBuildWorkspacePackage(this.root, this.workspace);

  @override
  bool contains(Source source) {
    var uri = source.uri;

    if (uri.isScheme('package')) {
      var packageName = uri.pathSegments[0];
      return packageName == workspace.projectPackageName;
    }

    if (uri.isScheme('file')) {
      var path = source.fullName;
      return workspace.findPackageFor(path) != null;
    }

    return false;
  }

  @override
  Map<String, List<Folder>> packagesAvailableTo(String libraryPath) =>
      workspace._packageMap;

  @override
  bool sourceIsInPublicApi(Source source) {
    var filePath = filePathFromSource(source);
    if (filePath == null) return false;
    var libFolder = workspace.provider.pathContext.join(root, 'lib');
    if (workspace.provider.pathContext.isWithin(libFolder, filePath)) {
      // A file in "$root/lib" is public iff it is not in "$root/lib/src".
      var libSrcFolder = workspace.provider.pathContext.join(libFolder, 'src');
      return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
    }

    libFolder = workspace.provider.pathContext.joinAll(
        [root, ...PackageBuildWorkspace._generatedPathParts, 'test', 'lib']);
    if (workspace.provider.pathContext.isWithin(libFolder, filePath)) {
      // A file in "$generated/lib" is public iff it is not in
      // "$generated/lib/src".
      var libSrcFolder = workspace.provider.pathContext.join(libFolder, 'src');
      return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
    }
    return false;
  }
}
