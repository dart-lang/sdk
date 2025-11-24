// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';

import '../analyzer.dart';

const _desc = r'Invocation of `remove` with references of unrelated types.';

final listRemoveUnrelatedType = RemovedAnalysisRule(
  name: LintNames.list_remove_unrelated_type,
  description: _desc,
  since: dart3_3,
);
