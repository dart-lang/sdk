// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/lint_names.dart';
import 'package:pub_semver/pub_semver.dart';

/// A registry mapping target SDK versions to post-migration lint rules
/// that should be applied and fixes *after* the SDK constraint is bumped.
///
/// Each registered lint rule must have exactly one bulk-fix enabled
/// correction producer associated with it.
final Map<Version, List<String>> postMigrationLintsRegistry = {
  Version(3, 13, 0): [LintNames.unnecessary_type_name_in_constructor],
};

/// A registry mapping target SDK versions to pre-migration lint rules
/// that should be applied and fixes *before* the SDK constraint is bumped.
///
/// Each registered lint rule must have exactly one bulk-fix enabled
/// correction producer associated with it.
final Map<Version, List<String>> preMigrationLintsRegistry = {
  Version(3, 13, 0): [
    LintNames.avoid_final_parameters,
    LintNames.var_with_no_type_annotation,
  ],
};
