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

void addExperimentalFlags(ArgParser argParser, bool verbose) {
  List<ExperimentalFeature> features = experimentalFeatures;

  Map<String, String> allowedHelp = {};
  for (ExperimentalFeature feature in features) {
    String suffix =
        feature.isEnabledByDefault ? ' (no-op - enabled by default)' : '';
    allowedHelp[feature.enableString] = '${feature.documentation}$suffix';
  }

  argParser.addMultiOption(
    experimentFlagName,
    valueHelp: 'experiment',
    allowedHelp: verbose ? allowedHelp : null,
    help: 'Enable one or more experimental features '
        '(see dart.dev/go/experiments).',
    hide: !verbose,
  );
}

extension EnabledExperimentsArg on ArgResults {
  List<String> get enabledExperiments {
    List<String> enabledExperiments = [];
    // Check to see if the ArgParser which generated this result accepts
    // --enable-experiment as an option. If so, return the result if it was
    // provided.
    if (options.contains(experimentFlagName)) {
      if (wasParsed(experimentFlagName)) {
        enabledExperiments = this[experimentFlagName];
      }
    } else {
      // In the case where a command uses ArgParser.allowAnything() as its
      // parser the valid set of options for the command isn't specified and
      // isn't enforced. Instead, we have to manually parse the arguments to
      // look for --enable-experiment=. Currently, this path is only taken for
      // the pub and test commands, as well as when we are trying to send
      // analytics.
      final String experiments = arguments.firstWhere(
        (e) => e.startsWith('--enable-experiment='),
        orElse: () => null,
      );
      if (experiments == null) {
        return [];
      }
      enabledExperiments = experiments.split('=')[1].split(',');
    }

    for (ExperimentalFeature feature in experimentalFeatures) {
      // We allow default true flags, but complain when they are passed in.
      if (feature.isEnabledByDefault &&
          enabledExperiments.contains(feature.enableString)) {
        print("'${feature.enableString}' is now enabled by default; this "
            'flag is no longer required.');
      }
    }
    return enabledExperiments;
  }
}
