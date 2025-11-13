// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'analyzer.dart';
import 'diagnostic.dart' as diag;

part 'package:linter/src/diagnostic.g.dart';

/// A lint code that removed lints can specify as their `lintCode`.
///
/// Avoid other usages as it should be made unnecessary and removed.
const LintCode removedLint = LinterLintCode(
  name: 'removed_lint',
  problemMessage: 'Removed lint.',
  expectedTypes: [],
  uniqueName: 'LintCode.removed_lint',
);
