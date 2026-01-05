// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../utilities/git.dart';
import 'project_generator.dart';

/// A [ProjectGenerator] that just uses the current directory.
class CurrentDirectoryGenerator implements ProjectGenerator {
  @override
  String get description => 'Using the current directory';

  @override
  Future<Iterable<Directory>> setUp() async {
    var statusResult = await runGitCommand([
      'status',
      '--porcelain',
    ], Directory.current);
    if ((statusResult.stdout as String).isNotEmpty) {
      throw StateError(
        'Working tree is not clean, stash or commit changes before running '
        'this scenario.',
      );
    }
    return [Directory.current];
  }

  @override
  Future<void> tearDown(Iterable<Directory> workspaceDirs) async {
    await runGitCommand(['reset', 'HEAD'], workspaceDirs.single);
  }
}
