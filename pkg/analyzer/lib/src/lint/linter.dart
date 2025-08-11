// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/error/error.dart';

/// A soon-to-be deprecated alias for [RuleContext].
typedef LinterContext = RuleContext;

/// Describes an [AbstractAnalysisRule] which reports diagnostics using exactly
/// one [DiagnosticCode].
typedef LintRule = AnalysisRule;
