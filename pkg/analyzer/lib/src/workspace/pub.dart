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
import 'package:yaml/yaml.dart';

/// Instances of the class `PackageBuildFileUriResolver` resolve `file` URI's by
/// first resolving file uri's in the expected way, and then by looking in the
/// corresponding generated directories.
class PackageBuildFileUriResolver extends ResourceUriResolver {
  final PubWorkspace workspace;

  PackageBuildFileUriResolver(this.workspace) : super(workspace.provider);

  @override
  Uri pathToUri(String path) {
    var pathContext = workspace.provider.pathContext;
    if (pathContext.isWithin(workspace.root, path)) {
      var relative = pathContext.relative(path, from: workspace.root);
      var components = pathContext.split(relative);
      if (components.length > 4 &&
          components[0] == '.dart_tool' &&
          components[1] == 'build' &&
          components[2] == 'generated' &&
          components[3] == workspace.projectPackageName) {
        var canonicalPath = pathContext.joinAll([
          workspace.root,
          ...components.skip(4),
        ]);
        return pathContext.toUri(canonicalPath);
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

  /// TODO(scheglov) Finish switching to [Packages].
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
  /// The name of the directory that identifies the root of the workspace. Note,
  /// the presence of this file does not show package:build is used. For that,
  /// the subdirectory [_dartToolBuildName] must exist. A `pub` subdirectory
  /// will usually exist in non-package:build projects too.
  static const String _dartToolRootName = '.dart_tool';

  /// The name of the subdirectory in [_dartToolRootName] that distinguishes
  /// projects built with package:build.
  static const String _dartToolBuildName = 'build';

  static const List<String> _generatedPathParts = [
    '.dart_tool',
    'build',
    'generated'
  ];

  /// The singular package in this workspace.
  ///
  /// Each Pub workspace is itself one package.
  late final PubWorkspacePackage _theOnlyPackage;

  /// The associated pubspec file.
  final File _pubspecFile;

  /// The content of the `pubspec.yaml` file.
  /// We read it once, so that all usages return consistent results.
  final String? _pubspecContent;

  /// The name of the package under development as defined in pubspec.yaml. This
  /// matches the behavior of package:build.
  @visibleForTesting
  final String projectPackageName;

  /// `.dart_tool/build/generated` in [root].
  final String? _generatedRootPath;

  /// [projectPackageName] in [_generatedRootPath].
  final String? _generatedThisPath;

  /// Indicates whether this workspace uses package build.
  @visibleForTesting
  final bool usesPackageBuild;

  factory PubWorkspace(ResourceProvider provider, Packages packages,
      String root, File pubspecFile) {
    var folder = pubspecFile.parent;
    final dartToolDir = folder.getChildAssumingFolder(_dartToolRootName);
    final dartToolBuildDir =
        dartToolDir.getChildAssumingFolder(_dartToolBuildName);
    var pubspecContent = _fileContentOrNull(pubspecFile);
    String? generatedRootPath;
    String? generatedThisPath;
    var projectPackageName = '';
    var usesPackageBuild = false;
    // Found the .dart_tool file, that's our project root. We also require a
    // pubspec, to know the package name that package:build will assume.
    try {
      final yaml = loadYaml(pubspecContent!) as YamlMap;
      projectPackageName = yaml['name'] as String;
      if (dartToolBuildDir.exists) {
        generatedRootPath =
            provider.pathContext.joinAll([folder.path, ..._generatedPathParts]);
        generatedThisPath =
            provider.pathContext.join(generatedRootPath, projectPackageName);
        usesPackageBuild = true;
      }
    } catch (_) {}

    return PubWorkspace._(
        provider,
        packages,
        root,
        pubspecFile,
        pubspecContent,
        generatedRootPath,
        generatedThisPath,
        projectPackageName,
        usesPackageBuild);
  }

  PubWorkspace._(
      ResourceProvider provider,
      Packages packages,
      String root,
      this._pubspecFile,
      this._pubspecContent,
      this._generatedRootPath,
      this._generatedThisPath,
      this.projectPackageName,
      this.usesPackageBuild)
      : super(provider, packages, root) {
    _theOnlyPackage = PubWorkspacePackage(root, this);
  }

  @override
  bool get isConsistentWithFileSystem {
    return _fileContentOrNull(_pubspecFile) == _pubspecContent;
  }

  @override
  UriResolver get packageUriResolver {
    if (usesPackageBuild) {
      return PackageBuildPackageUriResolver(
          this, PackageMapUriResolver(provider, packageMap));
    }
    return PackageMapUriResolver(provider, packageMap);
  }

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
        root, _dartToolRootName, 'build', 'generated', packageName, builtPath));
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
    if (usesPackageBuild && summaryData != null) {
      throw UnsupportedError(
          'Summary files are not supported in a package:build workspace.');
    }
    var resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    if (usesPackageBuild) {
      resolvers.add(PackageBuildFileUriResolver(this));
    }
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
      final relativePath = context.relative(filePath, from: root);
      final file = builtFile(relativePath, projectPackageName);

      if (file!.exists) {
        return file;
      }

      return provider.getFile(filePath);
    } catch (_) {
      return null;
    }
  }

  @override
  PubWorkspacePackage? findPackageFor(String filePath) {
    var pathContext = provider.pathContext;
    // Must be in this workspace.
    if (!pathContext.isWithin(root, filePath)) {
      return null;
    }

    if (usesPackageBuild) {
      // If generated, must be for this package.
      if (pathContext.isWithin(_generatedRootPath!, filePath)) {
        if (!pathContext.isWithin(_generatedThisPath!, filePath)) {
          return null;
        }
      }
    }
    return _theOnlyPackage;
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
  static PubWorkspace? find(
    ResourceProvider provider,
    Packages packages,
    String filePath,
  ) {
    var start = provider.getFolder(filePath);
    for (var current in start.withAncestors) {
      var pubspec = current.getChildAssumingFile(file_paths.pubspecYaml);
      if (pubspec.exists) {
        if (_isInThirdPartyDart(pubspec)) {
          return null;
        }
        var root = current.path;
        return PubWorkspace(provider, packages, root, pubspec);
      }
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
  @override
  final String root;

  Pubspec? _pubspec;

  /// A flag to indicate if we've tried to parse the pubspec.
  bool _parsedPubspec = false;

  @override
  final PubWorkspace workspace;

  PubWorkspacePackage(this.root, this.workspace);

  /// Get the associated parsed [Pubspec], or `null` if there was an error in
  /// reading or parsing.
  Pubspec? get pubspec {
    if (!_parsedPubspec) {
      _parsedPubspec = true;
      final content = workspace._pubspecContent;
      if (content != null) {
        _pubspec = Pubspec.parse(content);
      }
    }
    return _pubspec;
  }

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
  Packages packagesAvailableTo(String libraryPath) {
    // TODO(brianwilkerson) Consider differentiating based on whether the
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

    if (workspace.usesPackageBuild) {
      libFolder = workspace.provider.pathContext
          .joinAll([root, ...PubWorkspace._generatedPathParts, 'test', 'lib']);
      if (workspace.provider.pathContext.isWithin(libFolder, filePath)) {
        // A file in "$generated/lib" is public iff it is not in
        // "$generated/lib/src".
        var libSrcFolder =
            workspace.provider.pathContext.join(libFolder, 'src');
        return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
      }
    }
    return false;
  }
}
