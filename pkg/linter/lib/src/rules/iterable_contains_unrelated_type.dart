// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';

import '../analyzer.dart';

const _desc =
    r'Invocation of `Iterable<E>.contains` with references of'
    r' unrelated types.';

final iterableContainsUnrelatedType = RemovedAnalysisRule(
  name: LintNames.iterable_contains_unrelated_type,
  description: _desc,
  since: dart3_3,
);
