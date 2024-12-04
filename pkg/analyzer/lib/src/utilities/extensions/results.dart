// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';

extension ResolvedLibraryResultExtension on ResolvedLibraryResult {
  /// Returns the parent unit (the unit that this is a `part of`) from this
  /// result.
  ///
  /// Returns `null` if this result does not contain the parent unit.
  ResolvedUnitResult? parentUnitOf(ResolvedUnitResult unit) {
    var parentPath = unit.libraryFragment.enclosingFragment?.source.fullName;
    return parentPath != null ? unitWithPath(parentPath) : null;
  }
}
