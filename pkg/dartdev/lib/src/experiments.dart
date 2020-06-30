// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:args/args.dart';

const experimentFlagName = 'enable-experiment';

/// Return a list of all the non-expired Dart experiments.
List<ExperimentalFeature> get experimentalFeatures {
  List<ExperimentalFeature> features = ExperimentStatus.knownFeatures.values
      .where((feature) => !feature.isExpired)
      .toList();
  features.sort((a, b) => a.enableString.compareTo(b.enableString));
  return features;
}

/// Return whether any Dart experiments were specified by the user.
bool wereExperimentsSpecified(ArgResults argResults) =>
    argResults.wasParsed(experimentFlagName);

/// Return the list of Dart experiment flags specified by the user.
List<String> specifiedExperiments(ArgResults argResults) =>
    argResults[experimentFlagName];
