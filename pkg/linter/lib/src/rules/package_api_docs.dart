// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';
import 'package:pub_semver/pub_semver.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

class PackageApiDocs extends AnalysisRule {
  PackageApiDocs()
    : super(
        name: LintNames.package_api_docs,
        description: r'Provide doc comments for all public APIs.',
        state: RuleState.removed(since: Version(3, 7, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.removedLint;
}
