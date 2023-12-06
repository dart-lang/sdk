// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:analyzer/src/workspace/simple.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

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
class PackageBuildFileUriResolver extends ResourceUriResolver {
  final PubWorkspace workspace;

  PackageBuildFileUriResolver(this.workspace) : super(workspace.provider);

  @override
  Uri pathToUri(String path) {
    var pathContext = workspace.provider.pathContext;
    var package = workspace.findPackageFor(path);
    if (package != null) {
      if (pathContext.isWithin(package.root, path)) {
        var relative = pathContext.relative(path, from: package.root);
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
      return file.createSource(uri);
    }
    return null;
  }
}

/// The [UriResolver] that can resolve `package` URIs in
/// [PackageBuildWorkspace].
class PackageBuildPackageUriResolver extends UriResolver {
  final PubWorkspace _workspace;
  final UriResolver _normalUriResolver;
  final Context _context;

  PackageBuildPackageUriResolver(
      PubWorkspace workspace, this._normalUriResolver)
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
      return file.createSource(uri);
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

/// Information about a Pub workspace.
class PubWorkspace extends SimpleWorkspace {
  /// A Pub workspace can have just one package or multiple packages. The
  /// single package in the workspace is the _rootPackage.
  /// A Pub workspace contains a single package when both the pubspec.yaml and
  /// a package_config.json files are present at the root.
  late final PubWorkspacePackage _rootPackage;

  /// A map of paths to packages defined in a [PubWorkspace]. This map is
  /// populated when there are multiple packages in a workspace.
  final Map<Folder, PubWorkspacePackage> _containedPackages = {};

  /// The associated pubspec file.
  final File _pubspecFile;

  /// The content of the `pubspec.yaml` file.
  /// We read it once, so that all usages return consistent results.
  final String? _pubspecContent;

  PubWorkspace._(
    ResourceProvider provider,
    Packages packages,
    String root,
    this._pubspecFile,
    this._pubspecContent,
  ) : super(provider, packages, root) {
    _rootPackage = PubWorkspacePackage(root, this, _pubspecFile);
  }

  @override
  bool get isConsistentWithFileSystem {
    return _fileContentOrNull(_pubspecFile) == _pubspecContent;
  }

  @override
  UriResolver get packageUriResolver {
    return PackageBuildPackageUriResolver(
        this, PackageMapUriResolver(provider, packageMap));
  }

  @visibleForTesting
  Set<PubWorkspacePackage> get pubPackages => {
        ..._containedPackages.values,
        ...[_rootPackage]
      };

  /// For some package file, which may or may not be a package source (it could
  /// be in `bin/`, `web/`, etc), find where its built counterpart will exist if
  /// its a generated source.
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
    buffer.addString(_pubspecContent ?? '');
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
    resolvers.add(packageUriResolver);
    resolvers.add(PackageBuildFileUriResolver(this));
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
      if (package != null) {
        final relativePath = context.relative(filePath, from: package.root);
        final file = builtFile(relativePath, package._name);
        if (file == null) {
          return null;
        }
        if (file.exists) {
          return file;
        }
      }
      return provider.getFile(filePath);
    } catch (_) {
      return null;
    }
  }

  /// Find the [PubWorkspacePackage] that contains the given file path. The path
  /// can be for a source file or a generated file. Generated files are located
  /// in the '.dart_tool/build/generated' folder of the containing package.
  @override
  PubWorkspacePackage? findPackageFor(String filePath) {
    var pathContext = provider.pathContext;
    // Must be in this workspace.
    if (!pathContext.isWithin(root, filePath)) {
      return null;
    }

    // If given path is for a generated file, check to make sure it is in the
    // generated directory and package name are the same.
    // For eg. roots are not the same here.
    // 'workspace/my/.dart_tool/build/generated/foo/lib/a.dart'
    var segments = pathContext.split(filePath);
    var buildRootIndex = segments.indexOf(file_paths.dotDartTool);
    if (buildRootIndex != -1) {
      if (_isPackageBuildGeneratedPath(segments, buildRootIndex)) {
        var packageName = segments[buildRootIndex - 1];
        if (packageName != segments[buildRootIndex + 3]) {
          return null;
        }
      }
    }

    PubWorkspacePackage? result;
    int resultPathLength = 0;
    for (var package in _containedPackages.entries) {
      if (pathContext.isWithin(package.key.path, filePath)) {
        var packagePathLength = package.key.path.length;
        if (result == null || resultPathLength < packagePathLength) {
          result = package.value;
          resultPathLength = packagePathLength;
        }
      }
    }
    if (result != null) {
      return result;
    }

    var folder = provider.getFile(filePath).parent;
    // Look for pubspec in folder and ancestors.
    for (var current in folder.withAncestors) {
      if (current.path == root) {
        return _rootPackage;
      }
      var pubspec = current.getChildAssumingFile(file_paths.pubspecYaml);
      if (pubspec.exists) {
        var package = PubWorkspacePackage(current.path, this, pubspec);
        _containedPackages[current] = package;
        return package;
      }
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

  /// Find the pub workspace that contains the given [filePath].
  /// A [PubWorkspace] is rooted at the innermost pubspec/package-config pair,
  /// or if that's not found, then the outermost pubspec.
  static PubWorkspace? find(
    ResourceProvider provider,
    Packages packages,
    String filePath,
  ) {
    File? pubspec;
    var start = provider.getFolder(filePath);
    // Walking up from filePath, look for files named pubspec.yaml.
    // When we find one, if there is an accompanying .dart_tool/package_config.json file,
    // then we've found the workspace.
    // If we never found a package config, then use the highest (closest to the
    // root) pubspec we ever found.
    for (var current in start.withAncestors) {
      var currentPubspec = current.getChildAssumingFile(file_paths.pubspecYaml);
      if (currentPubspec.exists) {
        if (_isInThirdPartyDart(currentPubspec)) {
          return null;
        }
        // Check for package config file.
        var packagesFile = current
            .getChildAssumingFolder(file_paths.dotDartTool)
            .getChildAssumingFile(file_paths.packageConfigJson);
        if (packagesFile.exists) {
          var root = current.path;
          return PubWorkspace._(
            provider,
            packages,
            root,
            currentPubspec,
            _fileContentOrNull(currentPubspec),
          );
        }
        pubspec = currentPubspec;
      }
    }
    // We found a pubspec but no package config file.
    if (pubspec != null) {
      return PubWorkspace._(provider, packages, pubspec.parent.path, pubspec,
          _fileContentOrNull(pubspec));
    }
    return null;
  }

  /// Return the content of the [file], `null` if cannot be read.
  static String? _fileContentOrNull(File file) {
    try {
      return file.readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  /// See https://buganizer.corp.google.com/issues/273584249
  ///
  /// Check if `/home/workspace/third_party/dart/my/pubspec.yaml`
  /// If so, we are in a Blaze workspace, and should not create Pub.
  static bool _isInThirdPartyDart(File pubspec) {
    final path = pubspec.path;
    final pathContext = pubspec.provider.pathContext;
    final pathComponents = pathContext.split(path);
    return pathComponents.length > 4 &&
        pathComponents[pathComponents.length - 3] == 'dart' &&
        pathComponents[pathComponents.length - 4] == 'third_party';
  }
}

/// Information about a package defined in a [PubWorkspace].
///
/// Separate from [Packages] or package maps, this class is designed to simply
/// understand whether arbitrary file paths represent libraries declared within
/// a given package in a [PubWorkspace].
class PubWorkspacePackage extends WorkspacePackage {
  static const List<String> _generatedPathParts = [
    file_paths.dotDartTool,
    file_paths.packageBuild,
    file_paths.packageBuildGenerated,
  ];

  @override
  final String root;

  late final String _name;

  late final String? _pubspecContent;

  Pubspec? _pubspec;

  /// A flag to indicate if we've tried to parse the pubspec.
  bool _parsedPubspec = false;

  VersionConstraint? _sdkVersionConstraint;

  /// A flag to indicate if we've tried to parse the sdk constraint.
  bool _parsedSdkConstraint = false;

  @override
  final PubWorkspace workspace;

  late final String _generatedThisPath;

  PubWorkspacePackage(this.root, this.workspace, File pubspecFile) {
    _pubspecContent = PubWorkspace._fileContentOrNull(pubspecFile);
    _name = pubspec?.name?.value.text ?? '';
    _generatedThisPath = workspace.provider.pathContext
        .joinAll([root, ...PubWorkspacePackage._generatedPathParts, _name]);
  }

  /// Get the associated parsed [Pubspec], or `null` if there was an error in
  /// reading or parsing.
  Pubspec? get pubspec {
    if (!_parsedPubspec) {
      _parsedPubspec = true;
      final content = _pubspecContent;
      if (content != null) {
        _pubspec = Pubspec.parse(content);
      }
    }
    return _pubspec;
  }

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
      return _name == packageName;
    }

    if (uri.isScheme('file')) {
      var path = source.fullName;
      if (path.contains(file_paths.dotDartTool)) {
        return workspace.provider.pathContext
            .isWithin(_generatedThisPath, path);
      }
      return workspace.provider.pathContext.isWithin(root, path);
    }

    return false;
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
