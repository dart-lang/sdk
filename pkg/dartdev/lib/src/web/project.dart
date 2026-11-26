// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

/// The name of the directory, in the package root, that holds the web app.
const webDirectoryName = 'web';

/// The file name of the default entrypoint, in [webDirectoryName].
const defaultEntrypointName = 'main.dart';

/// A Dart web app to serve: a package with a `web/` directory.
class WebProject {
  /// The absolute path of the package's root directory (with `pubspec.yaml`).
  final String packageRoot;

  /// The absolute path of the `package_config.json` that resolves the
  /// package's dependencies.
  ///
  /// In a pub workspace, it's the workspace root's.
  final String packageConfigPath;

  /// The package config read from [packageConfigPath] when the project was
  /// found, so it isn't read again.
  final PackageConfig packageConfig;

  /// The absolute path of the directory with the web app (`web/`).
  final String webDirectory;

  /// [webDirectory] as a path relative to [packageRoot] with `/` separators,
  /// such as `web`, for messages to the user.
  late final String relativeWebDirectory = _relativeTo(
    packageRoot,
    webDirectory,
  );

  /// The app's entrypoint, as a path relative to [packageRoot] with `/`
  /// separators, such as `web/main.dart`.
  final String entrypoint;

  WebProject._(
    this.packageRoot,
    this.packageConfigPath,
    this.packageConfig,
    this.webDirectory,
    this.entrypoint,
  );

  /// Finds the web project of the package that contains [directory].
  ///
  /// [entrypoint] is a path relative to [directory]. If it's `null`, the
  /// entrypoint is `web/main.dart` in the package's root. The entrypoint must
  /// be a Dart file directly in `web/`, because the scripts that start the
  /// app are served next to it.
  ///
  /// Throws a [ProjectException] that explains what's missing if [directory]
  /// isn't in a web project.
  static Future<WebProject> find(String directory, {String? entrypoint}) async {
    final absoluteDirectory = p.normalize(p.absolute(directory));
    if (!Directory(absoluteDirectory).existsSync()) {
      throw ProjectException('No directory found at $absoluteDirectory.');
    }
    final packageConfigAndFile = await findPackageConfigAndFile(
      Directory(absoluteDirectory),
      onError: (error, file) => throw ProjectException(
        'Could not read ${file.path}: $error\nRun `dart pub get` again.',
      ),
    );
    if (packageConfigAndFile == null) {
      throw ProjectException(
        'No package found for $absoluteDirectory. Run `dart pub get` first.',
      );
    }
    final (config: packageConfig, file: packageConfigFile) =
        packageConfigAndFile;
    final package = packageConfig.packageOf(Uri.directory(absoluteDirectory));
    if (package == null) {
      throw ProjectException(
        "$absoluteDirectory isn't in a package. "
        'Run `dart pub get` in your package first.',
      );
    }
    final packageRoot = p.normalize(package.root.toFilePath());
    final packageConfigPath = packageConfigFile.path;
    // A nested package without a package config of its own (no `dart pub get`
    // yet) would be found as part of the package around it.
    for (
      var current = absoluteDirectory;
      p.isWithin(packageRoot, current);
      current = p.dirname(current)
    ) {
      if (File(p.join(current, 'pubspec.yaml')).existsSync()) {
        throw ProjectException(
          '$current has its own pubspec.yaml. Run `dart pub get` there first.',
        );
      }
    }
    final webDirectory = p.join(packageRoot, webDirectoryName);
    if (!Directory(webDirectory).existsSync()) {
      throw ProjectException(
        'No $webDirectoryName/ directory found in $packageRoot.',
      );
    }
    final entrypointPath = p.normalize(
      entrypoint == null
          ? p.join(webDirectory, defaultEntrypointName)
          : p.join(absoluteDirectory, entrypoint),
    );
    // TODO(https://github.com/dart-lang/sdk/issues/64889): Support
    // entrypoints in subdirectories of web/.
    if (!p.equals(p.dirname(entrypointPath), webDirectory) ||
        p.extension(entrypointPath) != '.dart') {
      // Shows the path the argument resolved to: it's relative to
      // [directory], which isn't always the package root.
      final resolvedEntrypoint = p.isWithin(packageRoot, entrypointPath)
          ? _relativeTo(packageRoot, entrypointPath)
          : entrypointPath;
      throw ProjectException(
        'The entrypoint must be a Dart file directly in $webDirectoryName/, '
        'such as $webDirectoryName/$defaultEntrypointName, but got '
        '$resolvedEntrypoint.',
      );
    }
    final relativeEntrypoint = _relativeTo(packageRoot, entrypointPath);
    if (!File(entrypointPath).existsSync()) {
      throw ProjectException('No entrypoint found at $relativeEntrypoint.');
    }
    return WebProject._(
      packageRoot,
      packageConfigPath,
      packageConfig,
      webDirectory,
      relativeEntrypoint,
    );
  }
}

/// [path] as a path relative to [root], with `/` separators on every
/// platform.
String _relativeTo(String root, String path) =>
    p.url.joinAll(p.split(p.relative(path, from: root)));

/// Thrown when a directory isn't in a web project that can be served.
class ProjectException implements Exception {
  /// What's missing, in words a user can act on.
  final String message;

  ProjectException(this.message);

  @override
  String toString() => message;
}
