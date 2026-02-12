// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:package_config/package_config.dart';
import 'package:yaml/yaml.dart';

final _pubspecGlob = Glob('**/pubspec.yaml');

/// Searches for all pubspecs under [rootDir] that are a context root (don't
/// have `resolution: workspace`), initializes them, and returns a list of
/// [ContextRoot]s sorted by path.
Future<List<ContextRoot>> getContextRoots(
  String rootDir, {
  bool isSdk = false,
}) async {
  var roots = await _initializeContextRoots(rootDir, isSdk: isSdk).toList();
  _sortContextRoots(roots);
  return roots;
}

/// Runs `dart|flutter pub get` in [projectDir]
///
/// Checks various parts of the [pubspec] for `flutter` dependencies to
/// determine the type of package.
Future<void> runPubGet(Directory projectDir, YamlMap pubspec) async {
  var isFlutter =
      pubspec['environment']?['flutter'] != null ||
      pubspec['dependencies']?['flutter'] != null ||
      pubspec['dev_dependencies']?['flutter'] != null ||
      pubspec['dev_dependencies']?['flutter_test'] != null;
  var sdk = isFlutter ? 'flutter' : 'dart';
  print('Fetching dependencies with `$sdk pub get` in ${projectDir.path}');
  var pubGetResult = await Process.run(sdk, [
    'pub',
    'get',
    '--no-example',
  ], workingDirectory: projectDir.path);
  if (pubGetResult.exitCode != 0) {
    throw StateError(
      'Failed to run `$sdk pub get`:\n'
      'StdOut:\n${pubGetResult.stdout}\n'
      'StdErr:\n${pubGetResult.stderr}',
    );
  }
}

Stream<ContextRoot> _initializeContextRoots(
  String rootDir, {
  bool isSdk = false,
}) async* {
  await for (var pubspecFile in _pubspecGlob.list(root: rootDir)) {
    // Skip hidden dirs.
    if (pubspecFile.uri.pathSegments.any((path) => path.startsWith('.'))) {
      continue;
    }
    try {
      var pubspec =
          loadYaml(await File(pubspecFile.path).readAsString()) as YamlMap;
      if (pubspec['resolution'] == 'workspace') continue;
      var contextRootDir = pubspecFile.parent;
      if (!isSdk) {
        await runPubGet(contextRootDir, pubspec);
      }
      var packageConfig = await findPackageConfig(contextRootDir);
      if (packageConfig == null) {
        throw StateError(
          'Unable to find package config file in ${contextRootDir.path}',
        );
      }
      yield ContextRoot(contextRootDir, packageConfig);
    } catch (e) {
      stderr.writeln(
        'Error initializing context root for pubspec at ${pubspecFile.path}:\n'
        '$e',
      );
    }
  }
}

/// Sorts the [roots] by their path.
void _sortContextRoots(List<ContextRoot> roots) {
  roots.sort((a, b) => a.dir.path.compareTo(b.dir.path));
}

/// An analysis context root for a project, projects may have many context
/// roots, and they can be subdirectories of each other.
class ContextRoot {
  /// The root directory for this analysis context.
  final Directory dir;

  /// The package config for this context root.
  final PackageConfig packageConfig;

  ContextRoot(this.dir, this.packageConfig);
}

/// A [ProjectGenerator] represents a reproducible way to create a pristine
/// copy of a development workspace.
///
/// Each call to [setUp] returns a (typically new) instance of a workspace.
abstract interface class ProjectGenerator {
  /// A short description of the project.
  String get description;

  /// Performs any work necessary to initialize the project and returns the
  /// [Workspace] that was created.
  ///
  /// Note that the order these are returned in should be deterministic and
  /// match the original project order.
  Future<Workspace> setUp();

  /// Invoked once the workspace is no longer needed, should perform any
  /// necessary cleanup (delete or restore workspace to original condition).
  Future<void> tearDown(Workspace workspace);
}

/// A generated workspace, roughly corresponds to an IDE workspace, may contain
/// multiple open projects.
class Workspace {
  /// Each context root is a single directory and associated package config.
  ///
  /// These may be subdirectories of the root directories, or other contexts.
  final List<ContextRoot> contextRoots;

  /// The actual root directories containing the projects.
  ///
  /// These are typically just used for cleanup, and defaults to
  /// [workspaceDirectories].
  final Iterable<Directory> rootDirectories;

  /// The open workspace directories.
  ///
  /// These correspond directly to the `workspaceFolder` entries in LSP.
  final Iterable<Directory> workspaceDirectories;

  Workspace({
    required this.contextRoots,
    required this.workspaceDirectories,
    Iterable<Directory>? rootDirectories,
  }) : rootDirectories = rootDirectories ?? workspaceDirectories;
}
