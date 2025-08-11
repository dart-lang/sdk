// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:analyzer/dart/analysis/features.dart';

/// Computes the appropriate value of [TypeAnalyzerOptions] based on a
/// [FeatureSet].
TypeAnalyzerOptions computeTypeAnalyzerOptions(FeatureSet featureSet) =>
    TypeAnalyzerOptions(
      patternsEnabled: featureSet.isEnabled(Feature.patterns),
      inferenceUpdate3Enabled: featureSet.isEnabled(Feature.inference_update_3),
      respectImplicitlyTypedVarInitializers: featureSet.isEnabled(
        Feature.constructor_tearoffs,
      ),
      fieldPromotionEnabled: featureSet.isEnabled(Feature.inference_update_2),
      inferenceUpdate4Enabled: featureSet.isEnabled(Feature.inference_update_4),
      soundFlowAnalysisEnabled: featureSet.isEnabled(
        Feature.sound_flow_analysis,
      ),
    );
