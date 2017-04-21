// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.gn;

import 'dart:collection';
import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/workspace.dart';
import 'package:path/path.dart';

/**
 * Similar to Map#putIfAbsent, except that a value is stored only if it is not
 * null.
 */
V _putIfNotNull<K, V>(Map<K, V> map, K key, V ifAbsent()) {
  if (map.containsKey(key)) {
    return map[key];
  }
  V computed = ifAbsent();
  if (computed != null) {
    map[key] = computed;
  }
  return computed;
}

/**
 * The [UriResolver] used to resolve `file` URIs in a [GnWorkspace].
 */
class GnFileUriResolver extends ResourceUriResolver {
  /**
   * The workspace associated with this resolver.
   */
  final GnWorkspace workspace;

  /**
   * Initialize a newly created resolver to be associated with the given
   * [workspace].
   */
  GnFileUriResolver(GnWorkspace workspace)
      : workspace = workspace,
        super(workspace.provider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (!ResourceUriResolver.isFileUri(uri)) {
      return null;
    }
    String path = provider.pathContext.fromUri(uri);
    File file = workspace.findFile(path);
    if (file != null) {
      return file.createSource(actualUri ?? uri);
    }
    return null;
  }
}

/**
 * The [UriResolver] used to resolve `package` URIs in a [GnWorkspace].
 */
class GnPackageUriResolver extends UriResolver {
  /**
   * The workspace associated with this resolver.
   */
  final GnWorkspace workspace;

  /**
   * The path context that should be used to manipulate file system paths.
   */
  final Context pathContext;

  /**
   * The cache of absolute [Uri]s to [Source]s mappings.
   */
  final Map<Uri, Source> _sourceCache = new HashMap<Uri, Source>();

  /**
   * Initialize a newly created resolver to be associated with the given
   * [workspace].
   */
  GnPackageUriResolver(GnWorkspace workspace)
      : workspace = workspace,
        pathContext = workspace.provider.pathContext;

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    return _putIfNotNull(_sourceCache, uri, () {
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
      String filePath = fileUriPart.replaceAll('/', pathContext.separator);

      String packageBase = workspace.getPackageSource(packageName);
      if (packageBase == null) {
        return null;
      }
      String path = pathContext.join(packageBase, filePath);
      File file = workspace.findFile(path);
      return file?.createSource(uri);
    });
  }

  @override
  Uri restoreAbsolute(Source source) {
    Context context = workspace.provider.pathContext;
    String path = source.fullName;

    if (!context.isWithin(workspace.root, path)) {
      return null;
    }

    String package = workspace.packages.keys.firstWhere(
        (key) => context.isWithin(workspace.packages[key], path),
        orElse: () => null);
    if (package == null) {
      return null;
    }

    String sourcePath =
        context.relative(path, from: workspace.packages[package]);

    return Uri.parse('package:$package/$sourcePath');
  }
}

/**
 * Information about a Gn workspace.
 */
class GnWorkspace extends Workspace {
  /**
   * The name of the directory that identifies the root of the workspace.
   */
  static const String _jiriRootName = '.jiri_root';

  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider provider;

  /**
   * The absolute workspace root path (the directory containing the `.jiri_root`
   * directory).
   */
  final String root;

  /**
   * The path to the directory with source locations.
   *
   * Each file in this directory is named after a Dart package and contains the
   * path to the package's sources.
   */
  final String _packagesDirectoryPath;

  /**
   * The cache of package locations indexed by package name.
   */
  final Map<String, String> _packageCache = new HashMap<String, String>();

  GnWorkspace._internal(this.provider, this.root, this._packagesDirectoryPath);

  factory GnWorkspace._(
      ResourceProvider provider, String root, String packagesDirectoryPath) {
    GnWorkspace workspace =
        new GnWorkspace._internal(provider, root, packagesDirectoryPath);
    // Preload known packages.
    provider
        .getFolder(packagesDirectoryPath)
        .getChildren()
        .where((resource) => resource is File)
        .map((resource) => resource as File)
        .forEach((file) {
      String packageName = basename(file.path);
      workspace.getPackageSource(packageName);
    });
    return workspace;
  }

  Map<String, String> get packages => _packageCache;

  @override
  Map<String, List<Folder>> get packageMap {
    Map<String, List<Folder>> result = new HashMap<String, List<Folder>>();
    _packageCache.forEach((package, sourceDir) {
      result[package] = [provider.getFolder(sourceDir)];
    });
    return result;
  }

  @override
  UriResolver get packageUriResolver => new GnPackageUriResolver(this);

  @override
  SourceFactory createSourceFactory(DartSdk sdk) {
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(new DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(new GnFileUriResolver(this));
    return new SourceFactory(resolvers, null, provider);
  }

  /**
   * Return the source directory for the given package, or null if it could not
   * be found.
   */
  String getPackageSource(String packageName) {
    return _putIfNotNull(_packageCache, packageName, () {
      String path =
          provider.pathContext.join(_packagesDirectoryPath, packageName);
      return findFile(path)?.readAsStringSync();
    });
  }

  /**
   * Return the file with the given [absolutePath].
   *
   * Return `null` if the given [absolutePath] is not in the workspace [root].
   */
  File findFile(String absolutePath) {
    try {
      File writableFile = provider.getFile(absolutePath);
      if (writableFile.exists) {
        return writableFile;
      }
    } catch (_) {}
    return null;
  }

  /**
   * Locate the Dart sources directory.
   *
   * Return `null` if it could not be found.
   */
  static String _getPackagesDirectory(ResourceProvider provider, String root) {
    Context pathContext = provider.pathContext;
    String outDirectory = provider
        .getFolder(pathContext.join(root, 'out'))
        .getChildren()
        .where((resource) => resource is Folder)
        .map((resource) => resource as Folder)
        .firstWhere((Folder folder) {
      String baseName = basename(folder.path);
      // TODO(pylaligand): find a better way to locate the proper directory.
      return baseName.startsWith('debug') || baseName.startsWith('release');
    }, orElse: () => null)?.path;
    return outDirectory == null
        ? null
        : provider.pathContext.join(outDirectory, 'gen', 'dart.sources');
  }

  /**
   * Find the Gn workspace that contains the given [path].
   *
   * Return `null` if a workspace markers, such as the `.jiri_root` directory
   * cannot be found.
   */
  static GnWorkspace find(ResourceProvider provider, String path) {
    Context context = provider.pathContext;

    // Ensure that the path is absolute and normalized.
    if (!context.isAbsolute(path)) {
      throw new ArgumentError('not absolute: $path');
    }
    path = context.normalize(path);

    Folder folder = provider.getFolder(path);
    while (true) {
      Folder parent = folder.parent;
      if (parent == null) {
        return null;
      }

      // Found the .jiri_root file, must be a non-git workspace.
      if (folder.getChildAssumingFolder(_jiriRootName).exists) {
        String root = folder.path;
        String packagesDirectory = _getPackagesDirectory(provider, root);
        return new GnWorkspace._(provider, root, packagesDirectory);
      }

      // Go up the folder.
      folder = parent;
    }
  }
}
