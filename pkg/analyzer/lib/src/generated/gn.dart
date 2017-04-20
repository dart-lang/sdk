// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.gn;

import 'dart:collection';
import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/workspace.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/packages_file.dart';
import 'package:package_config/src/packages_impl.dart';
import 'package:path/path.dart';

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
   * The paths to the .packages files.
   */
  final List<String> _packagesFilePaths;

  /**
   * The map of package locations indexed by package name.
   *
   * This is a cached field.
   */
  Map<String, List<Folder>> _packageMap;

  /**
   * The package location strategy.
   *
   * This is a cached field.
   */
  Packages _packages;

  GnWorkspace._(this.provider, this.root, this._packagesFilePaths);

  @override
  Map<String, List<Folder>> get packageMap =>
      _packageMap ??= _convertPackagesToMap(packages);

  Packages get packages => _packages ??= _createPackages();

  /**
   * Creates an alternate representation for available packages.
   */
  Map<String, List<Folder>> _convertPackagesToMap(Packages packages) {
    Map<String, List<Folder>> folderMap = new HashMap<String, List<Folder>>();
    if (packages != null && packages != Packages.noPackages) {
      packages.asMap().forEach((String packageName, Uri uri) {
        String path = provider.pathContext.fromUri(uri);
        folderMap[packageName] = [provider.getFolder(path)];
      });
    }
    return folderMap;
  }

  /**
   * Loads the packages from the .packages file.
   */
  Packages _createPackages() {
    Map<String, Uri> map = _packagesFilePaths.map((String path) {
      File configFile = provider.getFile(path);
      List<int> bytes = configFile.readAsBytesSync();
      return parse(bytes, configFile.toUri());
    }).reduce((mapOne, mapTwo) {
      mapOne.addAll(mapTwo);
      return mapOne;
    });
    _resolveSymbolicLinks(map);
    return new MapPackages(map);
  }

  /**
   * Resolve any symbolic links encoded in the path to the given [folder].
   */
  String _resolveSymbolicLink(Folder folder) {
    try {
      return folder.resolveSymbolicLinksSync().path;
    } on FileSystemException {
      return folder.path;
    }
  }

  /**
   * Resolve any symbolic links encoded in the URI's in the given [map] by
   * replacing the values in the map.
   */
  void _resolveSymbolicLinks(Map<String, Uri> map) {
    Context pathContext = provider.pathContext;
    for (String packageName in map.keys) {
      Folder folder = provider.getFolder(pathContext.fromUri(map[packageName]));
      String folderPath = _resolveSymbolicLink(folder);
      // Add a '.' so that the URI is suitable for resolving relative URI's
      // against it.
      String uriPath = pathContext.join(folderPath, '.');
      map[packageName] = pathContext.toUri(uriPath);
    }
  }

  @override
  UriResolver get packageUriResolver =>
      new PackageMapUriResolver(provider, packageMap);

  @override
  SourceFactory createSourceFactory(DartSdk sdk) {
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(new DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(new ResourceUriResolver(provider));
    return new SourceFactory(resolvers, packages, provider);
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
   * For a source at `$root/foo/bar`, the packages files are generated in
   * `$root/out/<debug|release>-XYZ/[hostABC/]gen/foo/bar`.
   *
   * Note that in some cases multiple .packages files can be found at that
   * location, for example if the package contains both a library and a binary
   * target.
   */
  static List<String> _findPackagesFile(
      ResourceProvider provider, String root, String path,
      {forHost: false}) {
    Context pathContext = provider.pathContext;
    String sourceDirectory = pathContext.relative(path, from: root);
    Folder outDirectory = provider.getFolder(pathContext.join(root, 'out'));
    if (!outDirectory.exists) {
      return const <String>[];
    }
    outDirectory = outDirectory
        .getChildren()
        .where((resource) => resource is Folder)
        .map((resource) => resource as Folder)
        .firstWhere((Folder folder) {
      String baseName = pathContext.basename(folder.path);
      // TODO(pylaligand): find a better way to locate the proper directory.
      return baseName.startsWith('debug') || baseName.startsWith('release');
    }, orElse: () => null);
    if (outDirectory == null) {
      return const <String>[];
    }
    if (forHost) {
      outDirectory = outDirectory
          .getChildren()
          .where((resource) => resource is Folder)
          .map((resource) => resource as Folder)
          .firstWhere(
              (Folder folder) =>
                  pathContext.basename(folder.path).startsWith('host'),
              orElse: () => null);
    }
    if (outDirectory == null) {
      return const <String>[];
    }
    Folder genDir = outDirectory
        .getChildAssumingFolder(pathContext.join('gen', sourceDirectory));
    if (!genDir.exists) {
      return const <String>[];
    }
    return genDir
        .getChildren()
        .where((resource) => resource is File)
        .map((resource) => resource as File)
        .where((File file) => pathContext.extension(file.path) == '.packages')
        .map((File file) => file.path)
        .toList();
  }

  /**
   * Find the GN workspace that contains the given [path].
   *
   * Return `null` if a workspace could not be found.
   */
  static GnWorkspace find(ResourceProvider provider, String path) {
    Context context = provider.pathContext;

    // Ensure that the path is absolute and normalized.
    if (!context.isAbsolute(path)) {
      throw new ArgumentError('Not an absolute path: $path');
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
        List<String> packagesFiles =
            _findPackagesFile(provider, root, path, forHost: false);
        if (packagesFiles.isEmpty) {
          packagesFiles =
              _findPackagesFile(provider, root, path, forHost: true);
        }
        if (packagesFiles.isEmpty) {
          return null;
        }
        return new GnWorkspace._(provider, path, packagesFiles);
      }

      // Go up the folder.
      folder = parent;
    }
  }
}
