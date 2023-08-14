// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:args/args.dart';
import 'package:collection/collection.dart' show IterableExtension;

const experimentFlagName = 'enable-experiment';

/// Return a list of all the non-expired Dart experiments.
List<ExperimentalFeature> get experimentalFeatures =>
    ExperimentStatus.knownFeatures.values
        .where((feature) => !feature.isExpired)
        .toList()
      ..sort((a, b) => a.enableString.compareTo(b.enableString));

extension ArgParserExtensions on ArgParser {
  void addExperimentalFlags({bool verbose = false}) {
    List<ExperimentalFeature> features = experimentalFeatures;

    Map<String, String> allowedHelp = {};
    for (ExperimentalFeature feature in features) {
      String suffix =
          feature.isEnabledByDefault ? ' (no-op - enabled by default)' : '';
      allowedHelp[feature.enableString] = '${feature.documentation}$suffix';
    }

    addMultiOption(
      experimentFlagName,
      valueHelp: 'experiment',
      allowedHelp: verbose ? allowedHelp : null,
      help: 'Enable one or more experimental features '
          '(see dart.dev/go/experiments).',
      hide: !verbose,
    );
  }
}

extension ArgResultsExtensions on ArgResults {
  List<String> get enabledExperiments {
    List<String> enabledExperiments = [];
    // Check to see if the ArgParser which generated this result accepts
    // `--enable-experiment` as an option. If so, return the result if it was
    // provided.
    if (options.contains(experimentFlagName)) {
      if (wasParsed(experimentFlagName)) {
        enabledExperiments = this[experimentFlagName] as List<String>;
      }
    } else {
      // In the case where a command uses `ArgParser.allowAnything()` as its
      // parser, the valid set of options for the command isn't specified and
      // isn't enforced. Instead, we have to manually parse the arguments to
      // look for `--enable-experiment=`. Currently, this path is only taken for
      // the `pub` and `test` commands, as well as when we are trying to send
      // analytics.
      final experiments = arguments.firstWhereOrNull(
        (e) => e.startsWith('--$experimentFlagName='),
      );
      if (experiments == null) {
        return [];
      }
      enabledExperiments = experiments.split('=')[1].split(',');
    }

    for (final feature in experimentalFeatures) {
      // We allow default true flags, but complain when they are passed in.
      if (feature.isEnabledByDefault &&
          enabledExperiments.contains(feature.enableString)) {
        stderr.writeln("'${feature.enableString}' is now enabled by default; "
            'this flag is no longer required.');
      }
    }
    return enabledExperiments;
  }
}

List<String> parseVmEnabledExperiments(List<String> vmArgs) {
  var experiments = <String>[];
  var itr = vmArgs.iterator;
  while (itr.moveNext()) {
    var arg = itr.current;
    if (arg == '--$experimentFlagName') {
      if (!itr.moveNext()) break;
      experiments.add(itr.current);
    } else if (arg.startsWith('--$experimentFlagName=')) {
      var parts = arg.split('=');
      if (parts.length == 2) {
        experiments.addAll(parts[1].split(','));
      }
    }
  }
  return experiments;
}

bool nativeAssetsEnabled(List<String> vmEnabledExperiments) =>
    vmEnabledExperiments
        .contains(ExperimentalFeatures.native_assets.enableString);
