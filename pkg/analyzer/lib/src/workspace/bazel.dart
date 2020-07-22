// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:path/path.dart' as path;

/// Instances of the class `BazelFileUriResolver` resolve `file` URI's by first
/// resolving file uri's in the expected way, and then by looking in the
/// corresponding generated directories.
class BazelFileUriResolver extends ResourceUriResolver {
  final BazelWorkspace workspace;

  BazelFileUriResolver(BazelWorkspace workspace)
      : workspace = workspace,
        super(workspace.provider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (!ResourceUriResolver.isFileUri(uri)) {
      return null;
    }
    String filePath = fileUriToNormalizedPath(provider.pathContext, uri);
    File file = workspace.findFile(filePath);
    if (file != null) {
      return file.createSource(actualUri ?? uri);
    }
    return null;
  }
}

/// The [UriResolver] that can resolve `package` URIs in [BazelWorkspace].
class BazelPackageUriResolver extends UriResolver {
  final BazelWorkspace _workspace;
  final path.Context _context;

  /// The cache of absolute [Uri]s to [Source]s mappings.
  final Map<Uri, Source> _sourceCache = HashMap<Uri, Source>();

  BazelPackageUriResolver(BazelWorkspace workspace)
      : _workspace = workspace,
        _context = workspace.provider.pathContext;

  @override
  void clearCache() {
    _sourceCache.clear();
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    return _sourceCache.putIfAbsent(uri, () {
      if (uri.scheme == 'file') {
        var pathRelativeToRoot = _workspace._relativeToRoot(uri.path);
        if (pathRelativeToRoot == null) return null;
        var fullFilePath = _context.join(_workspace.root, pathRelativeToRoot);
        File file = _workspace.findFile(fullFilePath);
        return file?.createSource(uri);
      }
      if (uri.scheme != 'package') {
        return null;
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

      if (!packageName.contains('.')) {
        String fullFilePath = _context.join(_workspace.root, 'third_party',
            'dart', packageName, 'lib', filePath);
        File file = _workspace.findFile(fullFilePath);
        return file?.createSource(uri);
      } else {
        String packagePath = packageName.replaceAll('.', _context.separator);
        String fullFilePath =
            _context.join(_workspace.root, packagePath, 'lib', filePath);
        File file = _workspace.findFile(fullFilePath);
        return file?.createSource(uri);
      }
    });
  }

  @override
  Uri restoreAbsolute(Source source) {
    String filePath = source.fullName;

    // Search in each root.
    for (String root in [
      ..._workspace.binPaths,
      _workspace.genfiles,
      _workspace.readonly,
      _workspace.root
    ]) {
      List<String> uriParts = _restoreUriParts(root, filePath);
      if (uriParts != null) {
        return Uri.parse('package:${uriParts[0]}/${uriParts[1]}');
      }
    }

    return null;
  }

  /// Restore [filePath] to its 'package:' URI parts.
  ///
  /// Returns `null` if [root] is null or if [filePath] is not within [root].
  List<String> _restoreUriParts(String root, String filePath) {
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
        for (int i = 2; i < components.length - 1; i++) {
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

/// Information about a Bazel workspace.
class BazelWorkspace extends Workspace
    implements WorkspaceWithDefaultAnalysisOptions {
  static const String _WORKSPACE = 'WORKSPACE';
  static const String _READONLY = 'READONLY';

  /// The name of the file that identifies a set of Bazel Targets.
  ///
  /// For Dart package purposes, a BUILD file identifies a package.
  static const String _buildFileName = 'BUILD';

  /// Default prefix for "-genfiles" and "-bin" that will be assumed if no build
  /// output symlinks are found.
  static const defaultSymlinkPrefix = 'bazel';

  final ResourceProvider provider;

  /// The absolute workspace root path.
  ///
  /// It contains the `WORKSPACE` file or its parent contains the `READONLY`
  /// folder.
  @override
  final String root;

  /// The absolute path to the optional read only workspace root, in the
  /// `READONLY` folder if a git-based workspace, or `null`.
  final String readonly;

  /// The absolute paths to all `bazel-bin` folders.
  ///
  /// In practice, there is usually one "bin" path, and sometimes there are two,
  /// on distributed build systems. It is very rare to have more than two.
  final List<String> binPaths;

  /// The absolute path to the `bazel-genfiles` folder.
  final String genfiles;

  BazelWorkspace._(
      this.provider, this.root, this.readonly, this.binPaths, this.genfiles);

  @override
  bool get isBazel => true;

  @override
  UriResolver get packageUriResolver => BazelPackageUriResolver(this);

  @override
  SourceFactory createSourceFactory(DartSdk sdk, SummaryDataStore summaryData) {
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(BazelFileUriResolver(this));
    if (summaryData != null) {
      resolvers.add(InSummaryUriResolver(provider, summaryData));
    }
    return SourceFactory(resolvers);
  }

  /// Return the file with the given [absolutePath], looking first into
  /// directories for generated files: `bazel-bin` and `bazel-genfiles`, and
  /// then into the workspace root. The file in the workspace root is returned
  /// even if it does not exist. Return `null` if the given [absolutePath] is
  /// not in the workspace [root].
  File findFile(String absolutePath) {
    path.Context context = provider.pathContext;
    try {
      String relative = context.relative(absolutePath, from: root);
      if (relative == '.') {
        return null;
      }
      // genfiles
      if (genfiles != null) {
        File file = provider.getFile(context.join(genfiles, relative));
        if (file.exists) {
          return file;
        }
      }
      // bin
      for (String bin in binPaths) {
        File file = provider.getFile(context.join(bin, relative));
        if (file.exists) {
          return file;
        }
      }
      // Writable
      File writableFile = provider.getFile(absolutePath);
      if (writableFile.exists) {
        return writableFile;
      }
      // READONLY
      if (readonly != null) {
        File file = provider.getFile(context.join(readonly, relative));
        if (file.exists) {
          return file;
        }
      }
      // Not generated, return the default one.
      return writableFile;
    } catch (_) {
      return null;
    }
  }

  @override
  WorkspacePackage findPackageFor(String filePath) {
    path.Context context = provider.pathContext;
    Folder folder = provider.getFolder(context.dirname(filePath));

    while (true) {
      Folder parent = folder.parent;
      if (parent == null) {
        return null;
      }
      if (parent.path.length < root.length) {
        // We've walked up outside of [root], so [path] is definitely not
        // defined in any package in this workspace.
        return null;
      }

      // Return a Package rooted at [folder].
      BazelWorkspacePackage packageRootedHere() {
        List<String> uriParts = (packageUriResolver as BazelPackageUriResolver)
            ._restoreUriParts(root, '${folder.path}/lib/__fake__.dart');
        if (uriParts == null || uriParts.isEmpty) {
          return BazelWorkspacePackage(null, folder.path, this);
        } else {
          return BazelWorkspacePackage(uriParts[0], folder.path, this);
        }
      }

      // In some distributed build environments, BUILD files are not preserved.
      // We can still look for a ".packages" file in order to determine a
      // package's root. A ".packages" file found in [folder]'s sister path
      // under a "bin" path among [binPaths] denotes a Dart package.
      //
      // For example, if this BazelWorkspace's [root] is
      // "/build/work/abc123/workspace" with two "bin" folders,
      // "/build/work/abc123/workspace/blaze-out/host/bin/" and
      // "/build/work/abc123/workspace/blaze-out/k8-opt/bin/", and [folder]
      // is at "/build/work/abc123/workspace/foo/bar", then we  must look for a
      // file ending in ".packages" in the folders
      // "/build/work/abc123/workspace/blaze-out/host/bin/foo/bar" and
      // "/build/work/abc123/workspace/blaze-out/k8-opt/bin/foo/bar".

      // [folder]'s path, relative to [root]. For example, "foo/bar".
      String relative = context.relative(folder.path, from: root);
      for (String bin in binPaths) {
        Folder binChild = provider.getFolder(context.join(bin, relative));
        if (binChild.exists &&
            binChild.getChildren().any((c) => c.path.endsWith('.packages'))) {
          // [folder]'s sister folder within [bin] contains a ".packages" file.
          return packageRootedHere();
        }
      }

      if (folder.getChildAssumingFile(_buildFileName).exists) {
        // Found the BUILD file, denoting a Dart package.
        return packageRootedHere();
      }

      // Go up a folder.
      folder = parent;
    }
  }

  String _relativeToRoot(String p) {
    path.Context context = provider.pathContext;
    // genfiles
    if (genfiles != null && context.isWithin(genfiles, p)) {
      return context.relative(p, from: genfiles);
    }
    // bin
    for (String bin in binPaths) {
      if (context.isWithin(bin, p)) {
        return context.relative(p, from: bin);
      }
    }
    // READONLY
    if (readonly != null) {
      if (context.isWithin(readonly, p)) {
        return context.relative(p, from: readonly);
      }
    }
    // Not generated
    if (context.isWithin(root, p)) {
      return context.relative(p, from: root);
    }
    // Failed reverse lookup
    return null;
  }

  /// Find the Bazel workspace that contains the given [filePath].
  ///
  /// This method walks up the file system from [filePath], looking for various
  /// "marker" files which indicate a Bazel workspace.
  ///
  /// At each folder _f_ with parent _p_, starting with [filePath]:
  ///
  /// * If _f_ has a sibling folder named "READONLY", and that folder has a
  ///   child folder with the same name as _f_, then a BazelWorkspace rooted at
  ///   _f_ is returned.
  /// * If _f_ has a child folder named "blaze-out" or "bazel-out", then a
  ///   BazelWorkspace rooted at _f_ is returned.
  /// * If _f_ has a child file named "WORKSPACE", then a BazelWorkspace rooted
  ///   at _f_ is returned.
  static BazelWorkspace find(ResourceProvider provider, String filePath) {
    Resource resource = provider.getResource(filePath);
    if (resource is File && resource.parent != null) {
      filePath = resource.parent.path;
    }
    path.Context context = provider.pathContext;
    Folder folder = provider.getFolder(filePath);
    while (true) {
      Folder parent = folder.parent;
      if (parent == null) {
        return null;
      }

      // Found the READONLY folder, might be a git-based workspace.
      Folder readonlyFolder = parent.getChildAssumingFolder(_READONLY);
      if (readonlyFolder.exists) {
        String root = folder.path;
        String readonlyRoot =
            context.join(readonlyFolder.path, folder.shortName);
        if (provider.getFolder(readonlyRoot).exists) {
          List<String> binPaths = _findBinFolderPaths(folder);
          String symlinkPrefix =
              _findSymlinkPrefix(provider, root, binPaths: binPaths);
          binPaths ??= [context.join(root, '$symlinkPrefix-bin')];
          return BazelWorkspace._(provider, root, readonlyRoot, binPaths,
              context.join(root, '$symlinkPrefix-genfiles'));
        }
      }

      if (_firstExistingFolder(parent, ['blaze-out', 'bazel-out']) != null) {
        // Found the "out" folder; must be a bazel workspace.
        String root = parent.path;
        List<String> binPaths = _findBinFolderPaths(parent);
        String symlinkPrefix =
            _findSymlinkPrefix(provider, root, binPaths: binPaths);
        binPaths ??= [context.join(root, '$symlinkPrefix-bin')];
        return BazelWorkspace._(provider, root, null /* readonly */, binPaths,
            context.join(root, '$symlinkPrefix-genfiles'));
      }

      // Found the WORKSPACE file, must be a non-git workspace.
      if (folder.getChildAssumingFile(_WORKSPACE).exists) {
        String root = folder.path;
        List<String> binPaths = _findBinFolderPaths(folder);
        String symlinkPrefix =
            _findSymlinkPrefix(provider, root, binPaths: binPaths);
        binPaths ??= [context.join(root, '$symlinkPrefix-bin')];
        return BazelWorkspace._(provider, root, null /* readonly */, binPaths,
            context.join(root, '$symlinkPrefix-genfiles'));
      }

      // Go up the folder.
      folder = parent;
    }
  }

  /// Find the "bin" folder path, by searching for it.
  ///
  /// Depending on the environment we're working in (source code tree, build
  /// environment subtree of sources, local workspace, blaze, bazel), the "bin"
  /// folder may be available at a symlink found at `$root/blaze-bin/` or
  /// `$root/bazel-bin/`. If that symlink is not available, then we must search
  /// the immediate folders found in `$root/blaze-out/` and `$root/bazel-out/`
  /// for folders named "bin".
  ///
  /// If no "bin" folder is found in any of those locations, `null` is returned.
  static List<String> _findBinFolderPaths(Folder root) {
    Folder out = _firstExistingFolder(root, ['blaze-out', 'bazel-out']);
    if (out == null) {
      return null;
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
    return binPaths.isEmpty ? null : binPaths;
  }

  /// Return the symlink prefix, _X_, for folders `X-bin` or `X-genfiles`.
  ///
  /// If the workspace's "bin" folders were already found, the symlink prefix is
  /// determined from one of the [binPaths]. Otherwise it is determined by
  /// probing the internal `blaze-genfiles` and `bazel-genfiles`. Make a default
  /// assumption according to [defaultSymlinkPrefix] if neither of the folders
  /// exists.
  static String _findSymlinkPrefix(ResourceProvider provider, String root,
      {List<String> binPaths}) {
    path.Context context = provider.pathContext;
    if (binPaths != null && binPaths.isNotEmpty) {
      return context.basename(binPaths.first).startsWith('bazel')
          ? 'bazel'
          : 'blaze';
    }
    if (provider.getFolder(context.join(root, 'blaze-genfiles')).exists) {
      return 'blaze';
    }
    if (provider.getFolder(context.join(root, 'bazel-genfiles')).exists) {
      return 'bazel';
    }
    // Couldn't find it.  Make a default assumption.
    return defaultSymlinkPrefix;
  }

  /// Return the first folder within [root], chosen from [names], which exists.
  static Folder _firstExistingFolder(Folder root, List<String> names) => names
      .map((name) => root.getChildAssumingFolder(name))
      .firstWhere((folder) => folder.exists, orElse: () => null);
}

/// Information about a package defined in a BazelWorkspace.
///
/// Separate from [Packages] or package maps, this class is designed to simply
/// understand whether arbitrary file paths represent libraries declared within
/// a given package in a BazelWorkspace.
class BazelWorkspacePackage extends WorkspacePackage {
  /// A prefix for any URI of a path in this package.
  final String _uriPrefix;

  @override
  final String root;

  @override
  final BazelWorkspace workspace;

  BazelWorkspacePackage(String packageName, this.root, this.workspace)
      : this._uriPrefix = 'package:$packageName/';

  @override
  bool contains(Source source) {
    if (source.uri.isScheme('package')) {
      return source.uri.toString().startsWith(_uriPrefix);
    }
    String filePath = source.fullName;
    if (filePath == null) return false;
    if (workspace.findFile(filePath) == null) {
      return false;
    }
    if (!workspace.provider.pathContext.isWithin(root, filePath)) {
      return false;
    }

    // Just because [filePath] is within [root] does not mean it is in this
    // package; it could be in a "subpackage." Must go through the work of
    // learning exactly which package [filePath] is contained in.
    return workspace.findPackageFor(filePath).root == root;
  }
}
