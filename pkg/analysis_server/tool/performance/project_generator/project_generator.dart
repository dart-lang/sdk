// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// A [ProjectGenerator] represents a reproducible way to create a pristine
/// copy of a codebase.
///
/// Each call to [setUp] returns a (typically new) instance of this project.
abstract interface class ProjectGenerator {
  /// A short description of the project.
  String get description;

  /// Performs any work necessary to initialize the project and returns the
  /// workspace [Directory]s that were created.
  ///
  /// Note that the order these are returned in should be deterministic and
  /// match the original project order.
  Future<Iterable<Directory>> setUp();

  /// Invoked once the project is no longer needed, should perform any
  /// necessary cleanup for the workspaces.
  Future<void> tearDown(Iterable<Directory> workspaceDirs);
}
