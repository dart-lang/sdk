// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

/// Runs `dart pub get` in [projectDir] if it contains a pubspec.
//
// TODO(jakemac): Support flutter projects and workspaces.
Future<void> runPubGet(Directory projectDir) async {
  var pubspec = File(p.join(p.normalize(projectDir.path), 'pubspec.yaml'));
  if (pubspec.existsSync()) {
    print('Fetching dependencies with pub in ${projectDir.path}');
    var pubGetResult = await Process.run('dart', [
      'pub',
      'get',
    ], workingDirectory: projectDir.path);
    if (pubGetResult.exitCode != 0) {
      throw StateError(
        'Failed to run `dart pub get`:\n'
        'StdOut:\n${pubGetResult.stdout}\n'
        'StdErr:\n${pubGetResult.stderr}',
      );
    }
  } else {
    print('No pubspec.yaml found in ${projectDir.path}, skipping `pub get`');
  }
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
  final Iterable<ContextRoot> contextRoots;

  /// The actual root directories containing the projects.
  ///
  /// These are typically just used for cleanup.
  final Iterable<Directory> rootDirectories;

  Workspace(this.contextRoots, this.rootDirectories);
}
