// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';

/// Data structure maintaining intermediate analysis results for testing
/// purposes.  Under normal execution, no instance of this class should be
/// created.
class TestingData {
  /// Map containing the results of flow analysis.
  final Map<Uri, FlowAnalysisResult> uriToFlowAnalysisResult = {};

  /// Called by the analysis driver after performing flow analysis, to record
  /// flow analysis results.
  void recordFlowAnalysisResult(Uri uri, FlowAnalysisResult result) {
    uriToFlowAnalysisResult[uri] = result;
  }
}
