// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/exhaustiveness.dart';

/// Data structure maintaining intermediate analysis results for testing
/// purposes.  Under normal execution, no instance of this class should be
/// created.
class TestingData {
  /// Map containing the results of flow analysis.
  final Map<Uri, FlowAnalysisDataForTesting> uriToFlowAnalysisData = {};

  final Map<Uri, ExhaustivenessDataForTesting> uriToExhaustivenessData = {};

  final Map<Uri, TypeConstraintGenerationDataForTesting>
      uriToTypeConstraintGenerationData = {};

  /// Called by the constant verifier, to record exhaustiveness data used in
  /// testing.
  void recordExhaustivenessDataForTesting(
      Uri uri, ExhaustivenessDataForTesting result) {
    uriToExhaustivenessData[uri] = result;
  }

  /// Called by the analysis driver after performing flow analysis, to record
  /// flow analysis results.
  void recordFlowAnalysisDataForTesting(
      Uri uri, FlowAnalysisDataForTesting result) {
    uriToFlowAnalysisData[uri] = result;
  }

  /// Called by the type inference engine, to record generated type constraints.
  ///
  /// The procedure is destructive to [result] in the sense that it reuses its
  /// internal data structures where possible to avoid extra allocations.
  void recordTypeConstraintGenerationDataForTesting(
      Uri uri, TypeConstraintGenerationDataForTesting result) {
    TypeConstraintGenerationDataForTesting? existing =
        // ignore: analyzer_use_new_elements
        uriToTypeConstraintGenerationData[uri];
    // ignore: analyzer_use_new_elements
    if (existing != null) {
      // ignore: analyzer_use_new_elements
      existing.mergeIn(result);
    } else {
      // ignore: analyzer_use_new_elements
      uriToTypeConstraintGenerationData[uri] = result;
    }
  }
}
