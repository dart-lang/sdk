// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';

import '../analyzer.dart';

const _desc = r'Prefer using a boolean as the assert condition.';

final preferBoolInAsserts = RemovedAnalysisRule(
  name: LintNames.prefer_bool_in_asserts,
  description: _desc,
  since: dart3,
);
