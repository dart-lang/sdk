// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';

import '../analyzer.dart';

const _desc =
    r'Avoid overriding a final field to return '
    'different values if called multiple times.';

final avoidUnstableFinalFields = RemovedAnalysisRule(
  name: LintNames.avoid_unstable_final_fields,
  description: _desc,
);
