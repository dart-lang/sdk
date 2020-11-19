// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/front_end/web/navigation_tree.dart';

/// Information about a link to a compilation unit.
class UnitLink {
  final String fullPath;
  final List<String> pathParts;
  final int editCount;

  /// The number of directories deep in which this compilation unit is found.
  ///
  /// A compilation unit in the root has a depth of 0.
  final int depth;

  /// Whether this compilation unit was explicitly opted out of null safety at
  /// the start of this migration.
  final bool wasExplicitlyOptedOut;

  UnitMigrationStatus migrationStatus;

  UnitLink(this.fullPath, this.pathParts, this.editCount,
      this.wasExplicitlyOptedOut, this.migrationStatus)
      : depth = pathParts.length - 1;

  String get fileName => pathParts.last;
}
