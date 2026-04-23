// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';

/// A reader for Dart sources and related source maps.
abstract class AssetReader {
  /// Base path of the application, for example, set up in the index file:
  ///
  /// ```
  /// <html>
  ///   <head>
  ///     <base href="/abc/">
  ///     <script src="main.dart.js"></script>
  ///   </head>
  /// </html>
  /// ```
  String get basePath;

  /// Returns the contents for a source map at the provided server path, or
  /// null if the resource does not exist.
  Future<String?> sourceMapContents(String serverPath);

  /// Returns the contents for a dart source at the provided server path, or
  /// null if the resource does not exist.
  Future<String?> dartSourceContents(String serverPath);

  /// Returns the contents for the merged metadata output at the provided path,
  /// or null if the resource does not exist.
  Future<String?> metadataContents(String serverPath);

  /// Closes connections
  Future<void> close();
}

class PackageUriMapper {
  final _logger = Logger('PackageUriMapper');
  final PackageConfig packageConfig;
  final bool useDebuggerModuleNames;

  static Future<PackageUriMapper> create(
    FileSystem fileSystem,
    Uri packageConfigFile, {
    bool useDebuggerModuleNames = false,
  }) async {
    final packageConfig = await loadPackageConfig(
      fileSystem.file(packageConfigFile),
    );
    return PackageUriMapper(
      packageConfig,
      useDebuggerModuleNames: useDebuggerModuleNames,
    );
  }

  PackageUriMapper(this.packageConfig, {this.useDebuggerModuleNames = false});

  /// Compute server path for package uri.
  ///
  /// Note: needs to match `urlForComponentUri` in javascript_bundle.dart
  /// in SDK code.
  String? packageUriToServerPath(Uri packageUri) {
    final defaultServerPath = '/packages/${packageUri.path}';
    if (packageUri.isScheme('package')) {
      if (!useDebuggerModuleNames) {
        return defaultServerPath;
      }
      final resolvedUri = packageConfig.resolve(packageUri);
      if (resolvedUri == null) {
        _logger.severe('Cannot resolve package uri $packageUri');
        return defaultServerPath;
      }
      final package = packageConfig.packageOf(resolvedUri);
      if (package == null) {
        _logger.severe('Cannot find package for package uri $packageUri');
        return defaultServerPath;
      }
      final root = package.root;
      final relativeUrl = resolvedUri.toString().replaceFirst('$root', '');
      final relativeRoot = _getRelativeRoot(root);
      final ret = relativeRoot == null
          ? 'packages/$relativeUrl'
          : 'packages/$relativeRoot/$relativeUrl';
      return ret;
    }
    _logger.severe('Expected package uri, but found $packageUri');
    return null;
  }

  /// Compute resolved file uri for a server path.
  Uri? serverPathToResolvedUri(String serverPath) {
    serverPath = stripLeadingSlashes(serverPath);
    final segments = serverPath.split('/');
    if (segments.first == 'packages') {
      if (!useDebuggerModuleNames) {
        return packageConfig.resolve(
          Uri(scheme: 'package', pathSegments: segments.skip(1)),
        );
      }
      final relativeRoot = segments.skip(1).first;
      final relativeUrl = segments.skip(2).join('/');
      final package = packageConfig.packages.firstWhere(
        (Package p) => _getRelativeRoot(p.root) == relativeRoot,
      );
      final resolvedUri = package.root.resolve(relativeUrl);

      return resolvedUri;
    }
    _logger.severe('Expected "packages/" path, but found $serverPath');
    return null;
  }
}

String stripLeadingSlashes(String path) {
  while (path.startsWith('/') || path.startsWith('\\')) {
    path = path.substring(1);
  }
  return path;
}

String? _getRelativeRoot(Uri root) =>
    root.pathSegments.lastWhereOrNull((segment) => segment.isNotEmpty);
