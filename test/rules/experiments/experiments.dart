// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules/experiments/spread_collections.dart';


final experiments = [
  new SpreadCollections(),
];

void registerLintRuleExperiments() {
  experiments.forEach(Analyzer.facade.register);
}

