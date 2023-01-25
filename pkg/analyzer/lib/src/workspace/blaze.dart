// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:analyzer/src/workspace/blaze_watcher.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

/// Instances of the class `BlazeFileUriResolver` resolve `file` URI's by first
/// resolving file uri's in the expected way, and then by looking in the
/// corresponding generated directories.
class BlazeFileUriResolver extends ResourceUriResolver {
  final BlazeWorkspace workspace;

  BlazeFileUriResolver(this.workspace) : super(workspace.provider);

  @override
  Uri pathToUri(String path) {
    var pathContext = workspace.provider.pathContext;
    for (var genRoot in [
      ...workspace.binPaths,
      workspace.genfiles,
    ]) {
      if (pathContext.isWithin(genRoot, path)) {
        String relative = pathContext.relative(path, from: genRoot);
        var writablePath = pathContext.join(workspace.root, relative);
        return pathContext.toUri(writablePath);
      }
    }
    return workspace.provider.pathContext.toUri(path);
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    if (!ResourceUriResolver.isFileUri(uri)) {
      return null;
    }
    String filePath = fileUriToNormalizedPath(provider.pathContext, uri);
    var file = workspace.findFile(filePath);
    if (file != null) {
      return file.createSource(uri);
    }
    return null;
  }
}

/// The [UriResolver] that can resolve `package` URIs in [BlazeWorkspace].
class BlazePackageUriResolver extends UriResolver {
  final BlazeWorkspace _workspace;
  final path.Context _context;

  /// The cache of absolute [Uri]s to [Source]s mappings.
  final Map<Uri, Source> _sourceCache = HashMap<Uri, Source>();

  BlazePackageUriResolver(BlazeWorkspace workspace)
      : _workspace = workspace,
        _context = workspace.provider.pathContext;

  @override
  Uri? pathToUri(String path) {
    // Search in each root.
    for (var root in [
      ..._workspace.binPaths,
      _workspace.genfiles,
      _workspace.root
    ]) {
      var uriParts = _restoreUriParts(root, path);
      if (uriParts != null) {
        return uriCache.parse('package:${uriParts[0]}/${uriParts[1]}');
      }
    }

    return null;
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    var source = _sourceCache[uri];
    if (source == null) {
      source = _resolveAbsolute(uri);
      if (source != null) {
        _sourceCache[uri] = source;
      }
    }
    return source;
  }

  Source? _resolveAbsolute(Uri uri) {
    if (uri.isScheme('file')) {
      var path = fileUriToNormalizedPath(_context, uri);
      var pathRelativeToRoot = _workspace._relativeToRoot(path);
      if (pathRelativeToRoot == null) return null;
      var fullFilePath = _context.join(_workspace.root, pathRelativeToRoot);
      var file = _workspace.findFile(fullFilePath);
      return file?.createSource(uri);
    }
    if (!uri.isScheme('package')) {
      return null;
    }
    String uriPath = Uri.decodeComponent(uri.path);
    int slash = uriPath.indexOf('/');

    // If the path either starts with a slash or has no slash, it is invalid.
    if (slash < 1) {
      return null;
    }

    if (uriPath.contains('//') || uriPath.contains('..')) {
      return null;
    }

    String packageName = uriPath.substring(0, slash);

    String fileUriPart = uriPath.substring(slash + 1);
    if (fileUriPart.isEmpty) {
      return null;
    }

    String filePath = fileUriPart.replaceAll('/', _context.separator);

    if (!packageName.contains('.')) {
      String fullFilePath = _context.join(
          _workspace.root, 'third_party', 'dart', packageName, 'lib', filePath);
      var file = _workspace.findFile(fullFilePath);
      return file?.createSource(uri);
    } else {
      String packagePath = packageName.replaceAll('.', _context.separator);
      String fullFilePath =
          _context.join(_workspace.root, packagePath, 'lib', filePath);
      var file = _workspace.findFile(fullFilePath);
      return file?.createSource(uri);
    }
  }

  /// Restore [filePath] to its 'package:' URI parts.
  ///
  /// Returns `null` if [root] is null or if [filePath] is not within [root].
  List<String>? _restoreUriParts(String? root, String filePath) {
    path.Context context = _workspace.provider.pathContext;
    if (root != null && context.isWithin(root, filePath)) {
      String relative = context.relative(filePath, from: root);
      List<String> components = context.split(relative);
      if (components.length > 4 &&
          components[0] == 'third_party' &&
          components[1] == 'dart' &&
          components[3] == 'lib') {
        String packageName = components[2];
        String pathInLib = components.skip(4).join('/');
        return [packageName, pathInLib];
      } else {
        for (int i = components.length - 2; i >= 2; i--) {
          String component = components[i];
          if (component == 'lib') {
            String packageName = components.getRange(0, i).join('.');
            String pathInLib = components.skip(i + 1).join('/');
            return [packageName, pathInLib];
          }
        }
      }
    }
    return null;
  }
}

/// Information about a Blaze workspace.
class BlazeWorkspace extends Workspace
    implements WorkspaceWithDefaultAnalysisOptions {
  /// The name of the file that identifies a set of Blaze Targets.
  ///
  /// For Dart package purposes, a BUILD file identifies a package.
  static const String _buildFileName = 'BUILD';

  final ResourceProvider provider;

  /// The absolute workspace root path.
  ///
  /// It contains the `WORKSPACE` file or its parent contains the `READONLY`
  /// folder.
  @override
  final String root;

  /// The absolute paths to all `blaze-bin` folders.
  ///
  /// In practice, there is usually one "bin" path, and sometimes there are two,
  /// on distributed build systems. It is very rare to have more than two.
  final List<String> binPaths;

  /// The absolute path to the `blaze-genfiles` folder.
  final String genfiles;

  /// Sometimes `BUILD` files are not preserved, and `xyz.packages` files
  /// are created instead. But looking for them is expensive, so we want
  /// to avoid this in cases when `BUILD` files are always available.
  final bool _lookForBuildFileSubstitutes;

  /// The language version for this workspace, `null` if cannot be read.
  final Version? _languageVersion;

  /// The cache of packages. The key is the directory path, the value is
  /// the corresponding package.
  final Map<String, BlazeWorkspacePackage> _directoryToPackage = {};

  final _blazeCandidateFiles = StreamController<BlazeSearchInfo>.broadcast();

  BlazeWorkspace._(
    this.provider,
    this.root,
    this.binPaths,
    this.genfiles, {
    required bool lookForBuildFileSubstitutes,
  })  : _lookForBuildFileSubstitutes = lookForBuildFileSubstitutes,
        _languageVersion = _readLanguageVersion(provider, root);

  /// Stream of files that we tried to find along with their potential or actual
  /// paths.
  Stream<BlazeSearchInfo> get blazeCandidateFiles =>
      _blazeCandidateFiles.stream;

  @override
  bool get isBlaze => true;

  @override
  UriResolver get packageUriResolver => BlazePackageUriResolver(this);

  @override
  SourceFactory createSourceFactory(
    DartSdk? sdk,
    SummaryDataStore? summaryData,
  ) {
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(BlazeFileUriResolver(this));
    if (summaryData != null) {
      resolvers.add(InSummaryUriResolver(summaryData));
    }
    return SourceFactory(resolvers);
  }

  /// Return the file with the given [absolutePath], looking first into
  /// directories for generated files: `blaze-bin` and `blaze-genfiles`, and
  /// then into the workspace root. The file in the workspace root is returned
  /// even if it does not exist. Return `null` if the given [absolutePath] is
  /// not in the workspace [root].
  File? findFile(String absolutePath) {
    path.Context context = provider.pathContext;
    try {
      String relative = context.relative(absolutePath, from: root);
      if (relative == '.') {
        return null;
      }
      // First check genfiles and bin directories. Note that we always use the
      // symlinks and not the [binPaths] or [genfiles] to make sure we use the
      // files corresponding to the most recent build configuration and get
      // consistent view of all the generated files.
      var generatedCandidates = ['blaze-genfiles', 'blaze-bin']
          .map((prefix) => context.join(root, context.join(prefix, relative)));
      for (var path in generatedCandidates) {
        File file = provider.getFile(path);
        if (file.exists) {
          _blazeCandidateFiles
              .add(BlazeSearchInfo(relative, generatedCandidates.toList()));
          return file;
        }
      }
      // Writable
      File writableFile = provider.getFile(absolutePath);
      if (writableFile.exists) {
        return writableFile;
      }
      // If we couldn't find the file, assume that it has not yet been
      // generated, so send an event with all the paths that we tried.
      _blazeCandidateFiles
          .add(BlazeSearchInfo(relative, generatedCandidates.toList()));
      // Not generated, return the default one.
      return writableFile;
    } catch (_) {
      return null;
    }
  }

  @override
  BlazeWorkspacePackage? findPackageFor(String filePath) {
    path.Context context = provider.pathContext;
    var directoryPath = context.dirname(filePath);

    var cachedPackage = _directoryToPackage[directoryPath];
    if (cachedPackage != null) {
      return cachedPackage;
    }

    if (!context.isWithin(root, directoryPath)) {
      return null;
    }

    // Handle files which are given with their location in "blaze-bin", etc.
    // This does not typically happen during usual analysis, but it still could,
    // and it can come up in tests.
    for (var binPath in [genfiles, ...binPaths]) {
      if (context.isWithin(binPath, directoryPath)) {
        return findPackageFor(
            context.join(root, context.relative(filePath, from: binPath)));
      }
    }

    /// Return the package rooted at [folder].
    BlazeWorkspacePackage? packageRootedAt(Folder folder) {
      var uriParts = (packageUriResolver as BlazePackageUriResolver)
          ._restoreUriParts(root, '${folder.path}/lib/__fake__.dart');
      String? packageName;
      if (uriParts != null && uriParts.isNotEmpty) {
        packageName = uriParts[0];
      }
      // TODO(srawlins): If [packageName] could not be derived from [uriParts],
      //  I imagine this should throw.
      if (packageName == null) {
        return null;
      }
      var package = BlazeWorkspacePackage(packageName, folder.path, this);
      _directoryToPackage[directoryPath] = package;
      return package;
    }

    var startFolder = provider.getFolder(directoryPath);
    for (var folder in startFolder.withAncestors) {
      if (folder.path.length < root.length) {
        // We've walked up outside of [root], so [path] is definitely not
        // defined in any package in this workspace.
        return null;
      }

      if (folder.getChildAssumingFile(_buildFileName).exists) {
        // Found the BUILD file, denoting a Dart package.
        return packageRootedAt(folder);
      }

      if (_hasBuildFileSubstitute(folder)) {
        return packageRootedAt(folder);
      }
    }

    return null;
  }

  /// In some distributed build environments, BUILD files are not preserved.
  /// We can still look for a ".packages" file in order to determine a
  /// package's root. A ".packages" file found in [folder]'s sister path
  /// under a "bin" path among [binPaths] denotes a Dart package.
  ///
  /// For example, if the [root] of this BlazeWorkspace is
  /// "/build/work/abc123/workspace" with two "bin" folders,
  /// "/build/work/abc123/workspace/blaze-out/host/bin/" and
  /// "/build/work/abc123/workspace/blaze-out/k8-opt/bin/", and [folder]
  /// is at "/build/work/abc123/workspace/foo/bar", then we  must look for a
  /// file ending in ".packages" in the folders
  /// "/build/work/abc123/workspace/blaze-out/host/bin/foo/bar" and
  /// "/build/work/abc123/workspace/blaze-out/k8-opt/bin/foo/bar".
  bool _hasBuildFileSubstitute(Folder folder) {
    if (!_lookForBuildFileSubstitutes) {
      return false;
    }

    path.Context context = provider.pathContext;

    // [folder]'s path, relative to [root]. For example, "foo/bar".
    String relative = context.relative(folder.path, from: root);

    for (String bin in binPaths) {
      Folder binChild =
          provider.getFolder(context.normalize(context.join(bin, relative)));
      if (binChild.exists &&
          binChild.getChildren().any((c) => c.path.endsWith('.packages'))) {
        // [folder]'s sister folder within [bin] contains a ".packages" file.
        return true;
      }
    }

    return false;
  }

  String? _relativeToRoot(String p) {
    path.Context context = provider.pathContext;
    // genfiles
    if (context.isWithin(genfiles, p)) {
      return context.relative(p, from: genfiles);
    }
    // bin
    for (String bin in binPaths) {
      if (context.isWithin(bin, p)) {
        return context.relative(p, from: bin);
      }
    }
    // Not generated
    if (context.isWithin(root, p)) {
      return context.relative(p, from: root);
    }
    // Failed reverse lookup
    return null;
  }

  /// Find the Blaze workspace that contains the given [filePath].
  ///
  /// This method walks up the file system from [filePath], looking for various
  /// "marker" files which indicate a Blaze workspace.
  ///
  /// At each folder _f_ with parent _p_, starting with [filePath]:
  ///
  /// * If _f_ has a sibling folder named "READONLY", and that folder has a
  ///   child folder with the same name as _f_, then a [BlazeWorkspace] rooted at
  ///   _f_ is returned.
  /// * If _f_ has a child folder named "blaze-out", then a [BlazeWorkspace]
  ///   rooted at _f_ is returned.
  /// * If _f_ has a child file named [file_paths.blazeWorkspaceMarker], then
  ///   a [BlazeWorkspace] rooted at _f_ is returned.
  static BlazeWorkspace? find(
    ResourceProvider provider,
    String filePath, {
    bool lookForBuildFileSubstitutes = true,
  }) {
    var context = provider.pathContext;
    var startFolder = provider.getFolder(filePath);
    for (var folder in startFolder.withAncestors) {
      var parent = folder.parent;

      final blazeOutFolder = parent.getChildAssumingFolder('blaze-out');
      if (blazeOutFolder.exists) {
        // Found the "out" folder; must be a Blaze workspace.
        String root = parent.path;
        var binPaths = _findBinFolderPaths(parent);
        binPaths = binPaths..add(context.join(root, 'blaze-bin'));
        return BlazeWorkspace._(
            provider, root, binPaths, context.join(root, 'blaze-genfiles'),
            lookForBuildFileSubstitutes: lookForBuildFileSubstitutes);
      }

      // Found the WORKSPACE file, must be a non-git workspace.
      if (folder.getChildAssumingFile(file_paths.blazeWorkspaceMarker).exists) {
        String root = folder.path;
        var binPaths = _findBinFolderPaths(folder);
        binPaths = binPaths..add(context.join(root, 'blaze-bin'));
        return BlazeWorkspace._(
            provider, root, binPaths, context.join(root, 'blaze-genfiles'),
            lookForBuildFileSubstitutes: lookForBuildFileSubstitutes);
      }
    }

    return null;
  }

  /// Create the Blaze workspace with the given [root].
  ///
  /// This method should be used during build in google3, when we know for
  /// sure the workspace root, but [file_paths.blazeWorkspaceMarker] is not
  /// available.
  static BlazeWorkspace forBuild({
    required Folder root,
  }) {
    var provider = root.provider;
    var blazeBin = root.getChildAssumingFolder('blaze-bin');
    var blazeGenfiles = root.getChildAssumingFolder('blaze-genfiles');

    var binPaths = _findBinFolderPaths(root);
    binPaths.add(blazeBin.path);

    return BlazeWorkspace._(provider, root.path, binPaths, blazeGenfiles.path,
        lookForBuildFileSubstitutes: true);
  }

  /// Find the "bin" folder path, by searching for it.
  ///
  /// Depending on the environment we're working in (source code tree, build
  /// environment subtree of sources, local workspace, blaze), the "bin"
  /// folder may be available at a symlink found at `$root/blaze-bin/`. If that
  /// symlink is not available, then we must search the immediate folders found
  /// in `$root/blaze-out/` for folders named "bin".
  ///
  /// If no "bin" folder is found in any of those locations, empty list is
  /// returned.
  static List<String> _findBinFolderPaths(Folder root) {
    final out = root.getChildAssumingFolder('blaze-out');
    if (!out.exists) {
      return [];
    }

    List<String> binPaths = [];
    for (var child in out.getChildren().whereType<Folder>()) {
      // Children are folders denoting architectures and build flags, like
      // 'k8-opt', 'k8-fastbuild', perhaps 'host'.
      Folder possibleBin = child.getChildAssumingFolder('bin');
      if (possibleBin.exists) {
        binPaths.add(possibleBin.path);
      }
    }
    return binPaths;
  }

  /// Return the default language version of the workspace.
  ///
  /// Return `null` if cannot be read, for example because the file does not
  /// exist, or is not available in this build configuration (batch analysis).
  static Version? _readLanguageVersion(
    ResourceProvider resourceProvider,
    String rootPath,
  ) {
    var file = resourceProvider.getFile(
      resourceProvider.pathContext.joinAll(
        [rootPath, 'dart', 'build_defs', 'bzl', 'language.bzl'],
      ),
    );

    String content;
    try {
      content = file.readAsStringSync();
    } on FileSystemException {
      return null;
    }

    final pattern = RegExp(r'_version_null_safety\s*=\s*"(\d+\.\d+)"');
    for (var match in pattern.allMatches(content)) {
      return Version.parse('${match.group(1)}.0');
    }

    return null;
  }
}

/// Information about a package defined in a [BlazeWorkspace].
///
/// Separate from [Packages] or package maps, this class is designed to simply
/// understand whether arbitrary file paths represent libraries declared within
/// a given package in a [BlazeWorkspace].
class BlazeWorkspacePackage extends WorkspacePackage {
  /// A prefix for any URI of a path in this package.
  final String _uriPrefix;

  @override
  final String root;

  @override
  final BlazeWorkspace workspace;

  bool _buildFileReady = false;
  List<String>? _enabledExperiments;
  Version? _languageVersion;

  BlazeWorkspacePackage(String packageName, this.root, this.workspace)
      : _uriPrefix = 'package:$packageName/';

  @override
  List<String>? get enabledExperiments {
    _readBuildFile();
    return _enabledExperiments;
  }

  @override
  Version? get languageVersion {
    _readBuildFile();
    return _languageVersion ?? workspace._languageVersion;
  }

  @override
  bool contains(Source source) {
    var uri = source.uri;
    if (uri.isScheme('package')) {
      return uri.toString().startsWith(_uriPrefix);
    }

    var path = source.fullName;
    return workspace.findPackageFor(path)?.root == root;
  }

  @override
  // TODO(brianwilkerson) Implement this by looking in the BUILD file for 'deps'
  //  lists.
  Packages packagesAvailableTo(String libraryPath) => Packages.empty;

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

    var relativeRoot =
        workspace.provider.pathContext.relative(root, from: workspace.root);
    for (var binPath in workspace.binPaths) {
      libFolder =
          workspace.provider.pathContext.join(binPath, relativeRoot, 'lib');
      if (workspace.provider.pathContext.isWithin(libFolder, filePath)) {
        // A file in "$bin/lib" is public iff it is not in "$bin/lib/src".
        var libSrcFolder =
            workspace.provider.pathContext.join(libFolder, 'src');
        return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
      }
    }

    libFolder = workspace.provider.pathContext
        .join(workspace.genfiles, relativeRoot, 'lib');
    if (workspace.provider.pathContext.isWithin(libFolder, filePath)) {
      // A file in "$genfiles/lib" is public iff it is not in
      // "$genfiles/lib/src".
      var libSrcFolder = workspace.provider.pathContext.join(libFolder, 'src');
      return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
    }

    return false;
  }

  void _readBuildFile() {
    if (_buildFileReady) {
      return;
    }

    try {
      _buildFileReady = true;
      var buildContent = workspace.provider
          .getFolder(root)
          .getChildAssumingFile('BUILD')
          .readAsStringSync();
      var flattenedBuildContent = buildContent
          .split('\n')
          .map((e) => e.trim())
          .where((e) => !e.startsWith('#'))
          .map((e) => e.replaceAll(' ', ''))
          .join();
      var hasNonNullableFlag = const {
        'dart_package(null_safety=True',
        'dart_package(sound_null_safety=True',
      }.any(flattenedBuildContent.contains);
      if (hasNonNullableFlag) {
        // Enabled by default.
      } else {
        _languageVersion = Version.parse('2.9.0');
      }
    } on FileSystemException {
      // ignored
    }
  }
}
