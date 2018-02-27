// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';

/**
 * An implementation of a context root.
 */
class ContextRootImpl implements ContextRoot {
  @override
  final Folder root;

  @override
  final List<Resource> included = <Resource>[];

  @override
  final List<Resource> excluded = <Resource>[];

  @override
  File optionsFile;

  @override
  File packagesFile;

  /**
   * Initialize a newly created context root.
   */
  ContextRootImpl(this.root);

  @override
  Iterable<String> get excludedPaths =>
      excluded.map((Resource folder) => folder.path);

  @override
  int get hashCode => root.path.hashCode;

  @override
  Iterable<String> get includedPaths =>
      included.map((Resource folder) => folder.path);

  @override
  bool operator ==(Object other) {
    return other is ContextRoot && root.path == other.root.path;
  }
}
