// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'sourcemap_helper.dart';
import 'sourcemap_html_helper.dart';
import 'package:compiler/src/filenames.dart';

main(List<String> arguments) {
  bool showAll = false;
  bool measure = false;
  Uri outputUri;
  Set<String> configurations = new Set<String>();
  for (String argument in arguments) {
    if (argument.startsWith('-')) {
      if (argument == '-a') {
        /// Generate visualization for all user methods.
        showAll = true;
      } else if (argument == '-m') {
        /// Measure instead of reporting the number of missing code points.
        measure = true;
      } else if (argument.startsWith('--out=')) {
        /// Generate visualization for the first configuration.
        outputUri = Uri.base.resolve(
            nativeToUriPath(argument.substring('--out='.length)));
      } else if (argument.startsWith('-o')) {
        /// Generate visualization for the first configuration.
        outputUri = Uri.base.resolve(
            nativeToUriPath(argument.substring('-o'.length)));
      } else {
        print("Unknown option '$argument'.");
        return;
      }
    } else {
      if (TEST_CONFIGURATIONS.containsKey(argument)) {
        configurations.add(argument);
      } else {
        print("Unknown configuration '$argument'. "
              "Must be one of '${TEST_CONFIGURATIONS.keys.join("', '")}'");
        return;
      }
    }
  }

  if (configurations.isEmpty) {
    configurations.addAll(TEST_CONFIGURATIONS.keys);
  }
  String outputConfig = configurations.first;

  asyncTest(() async {
    List<Measurement> measurements = <Measurement>[];
    for (String config in configurations) {
      List<String> options = TEST_CONFIGURATIONS[config];
      Measurement measurement = await runTests(
          config,
          options,
          showAll: showAll,
          measure: measure,
          outputUri: outputConfig == config ? outputUri : null);
      if (measurement != null) {
        measurements.add(measurement);
      }
    }
    for (Measurement measurement in measurements) {
      print(measurement);
    }
  });
}

const Map<String, List<String>> TEST_CONFIGURATIONS = const {
  'old': const [],
  'ssa': const ['--use-new-source-info', ],
  'cps': const ['--use-new-source-info', '--use-cps-ir'],
};

Future<Measurement> runTests(
    String config,
    List<String> options,
    {bool showAll: false,
     Uri outputUri,
     bool measure: false}) async {
  if (config == 'old' && !measure) return null;

  String filename =
      'tests/compiler/dart2js/sourcemaps/invokes_test_file.dart';
  SourceMapProcessor processor = new SourceMapProcessor(filename);
  List<SourceMapInfo> infoList = await processor.process(
      ['--csp', '--disable-inlining']
      ..addAll(options),
      verbose: !measure);
  List<SourceMapInfo> userInfoList = <SourceMapInfo>[];
  List<SourceMapInfo> failureList = <SourceMapInfo>[];
  Measurement measurement = new Measurement(config);
  for (SourceMapInfo info in infoList) {
    if (info.element.library.isPlatformLibrary) continue;
    userInfoList.add(info);
    Iterable<CodePoint> missingCodePoints =
        info.codePoints.where((c) => c.isMissing);
    measurement.missing += missingCodePoints.length;
    measurement.count += info.codePoints.length;
    if (!measure) {
      if (!missingCodePoints.isEmpty) {
        print("Missing code points for ${info.element} in '$filename':");
        for (CodePoint codePoint in missingCodePoints) {
          print("  $codePoint");
        }
        failureList.add(info);
      }
    }
  }
  if (failureList.isNotEmpty) {
    if (outputUri == null) {
      if (!measure) {
        Expect.fail(
            "Missing code points found. "
            "Run the test with a URI option, "
            "`source_mapping_test --out=<uri> $config`, to "
            "create a html visualization of the missing code points.");
      }
    } else {
      createTraceSourceMapHtml(outputUri, processor,
                               showAll ? userInfoList : failureList);
    }
  } else if (outputUri != null) {
    createTraceSourceMapHtml(outputUri, processor, userInfoList);
  }
  return measurement;
}

class Measurement {
  final String config;
  int missing = 0;
  int count = 0;

  Measurement(this.config);

  String toString() {
    double percentage = 100 * missing / count;
    return "Config '${config}': $missing of $count ($percentage%) missing";
  }
}
