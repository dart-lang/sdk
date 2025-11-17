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
  /// [Directory] under which it was created.
  Future<Directory> setUp();

  /// Invoked once the project is no longer needed, should perform any
  /// necessary cleanup for the project.
  Future<void> tearDown(Directory projectDir);
}
