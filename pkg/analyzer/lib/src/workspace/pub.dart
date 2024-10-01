// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/simple.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

/// Return the content of the [file], `null` if cannot be read.
String? _fileContentOrNull(File file) {
  try {
    return file.readAsStringSync();
  } catch (_) {
    return null;
  }
}

/// Check if the given list of path components contains a package build
/// generated directory, it would have the following path segments,
/// '.dart_tool/build/generated'.
bool _isPackageBuildGeneratedPath(List<String> pathComponents, int startIndex) {
  if (pathComponents.length > startIndex + 2) {
    if (pathComponents[startIndex] == file_paths.dotDartTool &&
        pathComponents[startIndex + 1] == file_paths.packageBuild &&
        pathComponents[startIndex + 2] == file_paths.packageBuildGenerated) {
      return true;
    }
  }
  return false;
}

/// Instances of the class `PackageBuildFileUriResolver` resolve `file` URI's by
/// first resolving file uri's in the expected way, and then by looking in the
/// corresponding generated directories.
class PackageConfigFileUriResolver extends ResourceUriResolver {
  final PackageConfigWorkspace workspace;

  PackageConfigFileUriResolver(this.workspace) : super(workspace.provider);

  @override
  Uri pathToUri(String path) {
    var pathContext = workspace.provider.pathContext;

    if (pathContext.isWithin(workspace.root, path)) {
      var package = workspace.findPackageFor(path);
      if (package is PubPackage) {
        var relative = pathContext.relative(path, from: workspace.root);
        var components = pathContext.split(relative);
        if (components.length > 4 &&
            _isPackageBuildGeneratedPath(components, 0) &&
            components[3] == package._name) {
          var canonicalPath = pathContext.joinAll([
            workspace.root,
            ...components.skip(4),
          ]);
          return pathContext.toUri(canonicalPath);
        }
      }
    }

    return super.pathToUri(path);
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    if (!ResourceUriResolver.isFileUri(uri)) {
      return null;
    }
    String filePath = fileUriToNormalizedPath(provider.pathContext, uri);
    Resource resource = provider.getResource(filePath);
    if (resource is! File) {
      return null;
    }
    var file = workspace.findFile(filePath);
    if (file != null) {
      return FileSource(file, uri);
    }
    return null;
  }
}

/// The [UriResolver] that can resolve `package` URIs in
/// [PackageBuildWorkspace].
class PackageConfigPackageUriResolver extends UriResolver {
  final PackageConfigWorkspace _workspace;
  final UriResolver _normalUriResolver;
  final Context _context;

  PackageConfigPackageUriResolver(
      PackageConfigWorkspace workspace, this._normalUriResolver)
      : _workspace = workspace,
        _context = workspace.provider.pathContext;

  // TODO(scheglov): Finish switching to [Packages].
  Map<String, List<Folder>> get packageMap => _workspace.packageMap;

  @override
  Uri? pathToUri(String path) {
    if (_context.isWithin(_workspace.root, path)) {
      var uriParts = _restoreUriParts(path);
      if (uriParts != null) {
        return uriCache.parse('package:${uriParts[0]}/${uriParts[1]}');
      }
    }
    return _normalUriResolver.pathToUri(path);
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    if (!uri.isScheme('package')) {
      return null;
    }

    var basicResolverSource = _normalUriResolver.resolveAbsolute(uri);
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

    var file = _workspace.builtFile(
        _workspace._builtPackageSourcePath(filePath), packageName);
    if (file != null && file.exists) {
      return FileSource(file, uri);
    }
    return basicResolverSource;
  }

  List<String>? _restoreUriParts(String filePath) {
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

/// Information about a Package Config workspace.
class PackageConfigWorkspace extends SimpleWorkspace {
  /// The associated package config file.
  final File packageConfigFile;

  /// The contents of the package config file.
  late final String? _packageConfigContent;

  final Map<String, WorkspacePackage> _workspacePackages = {};

  factory PackageConfigWorkspace(
      ResourceProvider provider, //Packages packages,
      String root,
      File packageConfigFile,
      Packages packages) {
    // Use the default packages if there is one.
    var newPackages = packages == Packages.empty
        ? parsePackageConfigJsonFile(provider, packageConfigFile)
        : packages;

    return PackageConfigWorkspace._(
      provider,
      newPackages,
      root,
      packageConfigFile,
    );
  }

  PackageConfigWorkspace._(
      super.provider, super.packages, super.root, this.packageConfigFile) {
    _packageConfigContent = packageConfigFile.readAsStringSync();
  }

  Iterable<WorkspacePackage> get allPackages =>
      _workspacePackages.values.toSet();

  @override
  bool get isConsistentWithFileSystem {
    return _fileContentOrNull(packageConfigFile) == _packageConfigContent;
  }

  @override
  UriResolver get packageUriResolver {
    return PackageConfigPackageUriResolver(
        this, PackageMapUriResolver(provider, packageMap));
  }

  /// For some package file, which may or may not be a package source (it could
  /// be in `bin/`, `web/`, etc), find where its built counterpart will exist if
  /// it's a generated source.
  ///
  /// To get a [builtPath] for a package source file to use in this method,
  /// use [_builtPackageSourcePath]. For `bin/`, `web/`, etc, it must be relative
  /// to the project root.
  @visibleForTesting
  File? builtFile(String builtPath, String packageName) {
    if (packages[packageName] == null) {
      return null;
    }
    var context = provider.pathContext;
    var fullBuiltPath = context.normalize(context.join(
        root,
        file_paths.dotDartTool,
        file_paths.packageBuild,
        file_paths.packageBuildGenerated,
        packageName,
        builtPath));
    return provider.getFile(fullBuiltPath);
  }

  @internal
  @override
  void contributeToResolutionSalt(ApiSignature buffer) {
    buffer.addString(_packageConfigContent ?? '');
  }

  @override
  SourceFactory createSourceFactory(
    DartSdk? sdk,
    SummaryDataStore? summaryData,
  ) {
    var resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(DartUriResolver(sdk));
    }
    if (summaryData != null) {
      resolvers.add(InSummaryUriResolver(summaryData));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(PackageConfigFileUriResolver(this));
    resolvers.add(ResourceUriResolver(provider));
    return SourceFactory(resolvers);
  }

  /// Return the file with the given [filePath], looking first in the generated
  /// directory `.dart_tool/build/generated/$projectPackageName/`, then in
  /// source directories.
  ///
  /// The file in the workspace [root] is returned even if it does not exist.
  /// Return `null` if the given [filePath] is not in the workspace root.
  File? findFile(String filePath) {
    var context = provider.pathContext;
    assert(context.isAbsolute(filePath), 'Not an absolute path: $filePath');
    try {
      var package = findPackageFor(filePath);
      if (package is PubPackage) {
        var relativePath = context.relative(filePath, from: package.root);
        var file = builtFile(relativePath, package._name ?? '');
        if (file!.exists) {
          return file;
        }
      }
      return provider.getFile(filePath);
    } catch (_) {
      return null;
    }
  }

  /// Find the [PubPackage] that contains the given file path. The path
  /// can be for a source file or a generated file. Generated files are located
  /// in the '.dart_tool/build/generated' folder of the containing package.
  @override
  WorkspacePackage? findPackageFor(String filePath) {
    var pathContext = provider.pathContext;
    // Must be in this workspace.
    if (!pathContext.isWithin(root, filePath)) {
      return null;
    }

    List<String> paths = [];
    var folder = provider.getFile(filePath).parent;

    for (var current in folder.withAncestors) {
      var package = _workspacePackages[current.path];
      if (package != null) {
        for (var path in paths) {
          _workspacePackages[path] = package;
        }
        return package;
      }
      var pubspec = current.getChildAssumingFile(file_paths.pubspecYaml);
      if (pubspec.exists) {
        if (_isInThirdPartyDart(pubspec)) {
          return null;
        }
        var package = PubPackage(current.path, this, pubspec);
        for (var path in paths) {
          _workspacePackages[path] = package;
        }
        _workspacePackages[current.path] = package;
        return package;
      }
      if (current.path == root) {
        var package = BasicWorkspacePackage(root, this);
        for (var path in paths) {
          _workspacePackages[path] = package;
        }
        return package;
      }
      paths.add(current.path);
    }
    return null;
  }

  /// Unlike the way that sources are resolved against `.packages` (if foo
  /// points to folder bar, then `foo:baz.dart` is found at `bar/baz.dart`), the
  /// built sources for a package require the `lib/` prefix first. This is
  /// because `bin/`, `web/`, and `test/` etc can all be built as well. This
  /// method exists to give a name to that prefix processing step.
  String _builtPackageSourcePath(String filePath) {
    var context = provider.pathContext;
    assert(context.isRelative(filePath), 'Not a relative path: $filePath');
    return context.join('lib', filePath);
  }

  /// Find the package config workspace that contains the given [filePath].
  /// A [PackageConfigWorkspace] is rooted at the innermost package-config file.
  static PackageConfigWorkspace? find(
    ResourceProvider provider,
    Packages packages,
    String filePath,
  ) {
    var start = provider.getFolder(filePath);
    for (var current in start.withAncestors) {
      var packageConfigFile = current
          .getChildAssumingFolder(file_paths.dotDartTool)
          .getChildAssumingFile(file_paths.packageConfigJson);
      if (packageConfigFile.exists) {
        var root = current.path;
        return PackageConfigWorkspace(
            provider, root, packageConfigFile, packages);
      }
    }
    return null;
  }

  /// See https://buganizer.corp.google.com/issues/273584249
  ///
  /// Check if `/home/workspace/third_party/dart/my/pubspec.yaml`
  /// If so, we are in a Blaze workspace, and should not create Pub.
  static bool _isInThirdPartyDart(File pubspec) {
    var path = pubspec.path;
    var pathContext = pubspec.provider.pathContext;
    var pathComponents = pathContext.split(path);
    return pathComponents.length > 4 &&
        pathComponents[pathComponents.length - 3] == 'dart' &&
        pathComponents[pathComponents.length - 4] == 'third_party';
  }
}

/// Information about a package defined in a [PackageConfigWorkspace].
///
/// Separate from [Packages] or package maps, this class is designed to simply
/// understand whether arbitrary file paths represent libraries declared within
/// a given package in a [PackageConfigWorkspace].
class PubPackage extends WorkspacePackage {
  static const List<String> _generatedPathParts = [
    file_paths.dotDartTool,
    file_paths.packageBuild,
    file_paths.packageBuildGenerated,
  ];

  @override
  final String root;

  final String? _name;

  final String? pubspecContent;

  // TODO(scheglov): remove when we are done migrating
  final String? analyzerUseNewElementsContent;

  final Pubspec? pubspec;

  final File pubspecFile;

  VersionConstraint? _sdkVersionConstraint;

  /// A flag to indicate if we've tried to parse the sdk constraint.
  bool _parsedSdkConstraint = false;

  @override
  final PackageConfigWorkspace workspace;

  factory PubPackage(
      String root, PackageConfigWorkspace workspace, File pubspecFile) {
    var pubspecContent = pubspecFile.readAsStringSync();
    var pubspec = Pubspec.parse(pubspecContent);
    var packageName = pubspec.name?.value.text;
    return PubPackage._(
      root,
      workspace,
      pubspecContent,
      pubspecFile,
      pubspec,
      packageName,
      analyzerUseNewElementsContent: _fileContentOrNull(
        pubspecFile.parent.getChildAssumingFile(
          'analyzer_use_new_elements.txt',
        ),
      ),
    );
  }

  PubPackage._(
    this.root,
    this.workspace,
    this.pubspecContent,
    this.pubspecFile,
    this.pubspec,
    this._name, {
    required this.analyzerUseNewElementsContent,
  });

  /// The version range for the SDK specified for this package , or `null` if
  /// it is ill-formatted or not set.
  VersionConstraint? get sdkVersionConstraint {
    if (!_parsedSdkConstraint) {
      _parsedSdkConstraint = true;

      var sdkValue = pubspec?.environment?.sdk?.value.text;
      if (sdkValue != null) {
        try {
          _sdkVersionConstraint = VersionConstraint.parse(sdkValue);
        } catch (_) {
          // Ill-formatted constraints, default to a `null` value.
        }
      }
    }
    return _sdkVersionConstraint;
  }

  @override
  bool contains(Source source) {
    var uri = source.uri;

    if (uri.isScheme('package')) {
      // TODO(keertip): Check to see if we can use information from package
      // config to find out if a file is in this package.
      var packageName = uri.pathSegments[0];
      return packageName == _name;
    }

    if (uri.isScheme('file')) {
      var path = source.fullName;
      return workspace.findPackageFor(path) != null;
    }
    return false;
  }

  @override
  bool isInTestDirectory(File file) {
    var resourceProvider = workspace.provider;
    var packageRoot = resourceProvider.getFolder(root);
    return packageRoot.getChildAssumingFolder('test').contains(file.path);
  }

  @override
  Packages packagesAvailableTo(String libraryPath) {
    // TODO(brianwilkerson): Consider differentiating based on whether the
    //  [libraryPath] is inside the `lib` directory.
    return workspace.packages;
  }

  @override

  /// A Pub package's public API consists of libraries found in the top-level
  /// "lib" directory, and any subdirectories, excluding the "src" directory
  /// just inside the top-level "lib" directory.
  bool sourceIsInPublicApi(Source source) {
    var filePath = filePathFromSource(source);
    if (filePath == null) return false;
    var libFolder = workspace.provider.pathContext.join(root, 'lib');
    if (workspace.provider.pathContext.isWithin(libFolder, filePath)) {
      // A file in "$root/lib" is public iff it is not in "$root/lib/src".
      var libSrcFolder = workspace.provider.pathContext.join(libFolder, 'src');
      return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
    }

    libFolder = workspace.provider.pathContext
        .joinAll([root, ..._generatedPathParts, 'test', 'lib']);
    if (workspace.provider.pathContext.isWithin(libFolder, filePath)) {
      // A file in "$generated/lib" is public iff it is not in
      // "$generated/lib/src".
      var libSrcFolder = workspace.provider.pathContext.join(libFolder, 'src');
      return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
    }
    return false;
  }
}
