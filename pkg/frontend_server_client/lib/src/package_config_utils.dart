// Utility functions to locate a package_config.json for pub/workspace setups.

import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

/// Walks up from [start] (or the current directory if omitted) to find the
/// nearest `.dart_tool/package_config.json`.
///
/// Returns the absolute file path, or `null` if none is found.
String? findNearestPackageConfigPath([Directory? start]) {
  var dir = (start ?? Directory.current).absolute;
  while (true) {
    final file = File(p.join(dir.path, '.dart_tool', 'package_config.json'));
    if (file.existsSync()) return file.path;
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// Returns an absolute path under the given [packageName]'s root directory,
/// resolving using the nearest workspace `.dart_tool/package_config.json`.
///
/// This is robust for pub workspace monorepos where the nearest package
/// config lives at the repo root and contains individual entries for each
/// package with its own root.
Future<String> pathFromNearestPackageConfig(
  String relativePath, {
  String packageName = 'frontend_server_client',
}) async {
  final configPath = findNearestPackageConfigPath();
  if (configPath == null) {
    throw StateError('Could not locate .dart_tool/package_config.json');
  }
  final config = await loadPackageConfigUri(Uri.file(configPath));
  final pkg = config.packages.firstWhere(
    (p0) => p0.name == packageName,
    orElse: () => throw StateError(
      'Package $packageName not found in package config at $configPath',
    ),
  );
  final packageRootDir = p.fromUri(pkg.root);
  return p.normalize(p.join(packageRootDir, relativePath));
}
