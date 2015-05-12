// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Support for client code that extends the analysis engine by adding new
/// lint rules.
library analyzer.plugin.linter;

import 'package:linter/src/linter.dart';
import 'package:linter/src/plugin/linter_plugin.dart';
import 'package:plugin/plugin.dart';

/// The identifier of the extension point that allows plugins to register new
/// lints. The object used as an extension must implement [LintRule].
final String LINT_RULE_EXTENSION_POINT_ID = Plugin.join(
    LinterPlugin.UNIQUE_IDENTIFIER, LinterPlugin.LINT_RULE_EXTENSION_POINT);
