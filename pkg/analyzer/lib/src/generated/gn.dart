// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.gn;

import 'dart:collection';
import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:path/path.dart';

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
   * The map of package sources indexed by package name.
   */
  final Map<String, String> _packages;

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
        pathContext = workspace.provider.pathContext,
        _packages = workspace.packages;

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    return _sourceCache.putIfAbsent(uri, () {
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

      if (!_packages.containsKey(packageName)) {
        return null;
      }
      String packageBase = _packages[packageName];
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

    String package = _packages.keys.firstWhere(
        (key) => context.isWithin(_packages[key], path),
        orElse: () => null);

    if (package == null) {
      return null;
    }

    String sourcePath = context.relative(path, from: _packages[package]);

    return FastUri.parse('package:$package/$sourcePath');
  }
}

/**
 * Information about a Gn workspace.
 */
class GnWorkspace {
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
   * The map of package sources indexed by package name.
   */
  final Map<String, String> packages;

  GnWorkspace._(this.provider, this.root, this.packages);

  /**
   * Return a map of package sources.
   */
  Map<String, List<Folder>> get packageMap {
    Map<String, List<Folder>> result = new HashMap<String, List<Folder>>();
    packages.forEach((package, sourceDir) {
      result[package] = [provider.getFolder(sourceDir)];
    });
    return result;
  }

  /**
   * Return the file with the given [absolutePath].
   *
   * Return `null` if the given [absolutePath] is not in the workspace [root].
   */
  File findFile(String absolutePath) {
    try {
      File writableFile = provider.getFile(absolutePath);
      return writableFile;
    } catch (_) {
      return null;
    }
  }

  /**
   * Locate the output directory.
   *
   * Return `null` if it could not be found.
   */
  static String _getOutDirectory(ResourceProvider provider, String root) =>
      provider
          .getFolder('$root/out')
          .getChildren()
          .where((resource) => resource is Folder)
          .map((resource) => resource as Folder)
          .firstWhere((Folder folder) {
        String baseName = basename(folder.path);
        // TODO(pylaligand): find a better way to locate the proper directory.
        return baseName.startsWith('debug') || baseName.startsWith('release');
      }, orElse: () => null)?.path;

  /**
   * Return a map of package source locations indexed by package name.
   */
  static Map<String, String> _getPackages(
      ResourceProvider provider, String outDirectory) {
    String packagesDir = '$outDirectory/gen/dart.sources';
    Map<String, String> result = new HashMap<String, String>();
    provider
        .getFolder(packagesDir)
        .getChildren()
        .where((resource) => resource is File)
        .map((resource) => resource as File)
        .forEach((file) {
      String packageName = basename(file.path);
      String source = file.readAsStringSync();
      result[packageName] = source;
    });
    return result;
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
        String outDirectory = _getOutDirectory(provider, root);
        Map<String, String> packages = _getPackages(provider, outDirectory);
        return new GnWorkspace._(provider, root, packages);
      }

      // Go up the folder.
      folder = parent;
    }
  }
}
