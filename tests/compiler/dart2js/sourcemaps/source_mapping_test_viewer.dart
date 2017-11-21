// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Visualization of source mappings generated and tested in
/// 'source_mapping_test.dart'.

library source_mapping.test.viewer;

import 'dart:async';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/util/util.dart';
import 'source_mapping_tester.dart';
import 'sourcemap_html_helper.dart';
import 'sourcemap_html_templates.dart';

const String DEFAULT_OUTPUT_PATH = 'out.js.map.html';

main(List<String> arguments) async {
  bool measure = false;
  String outputPath = DEFAULT_OUTPUT_PATH;
  Set<String> configurations = new Set<String>();
  Set<String> files = new Set<String>();
  for (String argument in arguments) {
    if (argument.startsWith('-')) {
      if (argument == '-m') {
        /// Measure instead of reporting the number of missing code points.
        measure = true;
      } else if (argument.startsWith('--out=')) {
        /// Generate visualization for the first configuration.
        outputPath = argument.substring('--out='.length);
      } else if (argument.startsWith('-o')) {
        /// Generate visualization for the first configuration.
        outputPath = argument.substring('-o'.length);
      } else {
        print("Unknown option '$argument'.");
        return;
      }
    }
  }

  if (!parseArguments(arguments, configurations, files, measure: measure)) {
    return;
  }

  OutputConfigurations outputConfigurations =
      new OutputConfigurations(configurations, files);
  bool generateMultiConfigs = false;
  if (outputPath != null) {
    if (configurations.length > 1 || files.length > 1) {
      for (String config in configurations) {
        for (String file in files) {
          String path = '$outputPath.$config.$file';
          Uri uri = Uri.base.resolve(nativeToUriPath(path));
          outputConfigurations.registerPathUri(config, file, path, uri);
        }
      }
      generateMultiConfigs = true;
    } else {
      outputConfigurations.registerPathUri(configurations.first, files.first,
          outputPath, Uri.base.resolve(nativeToUriPath(outputPath)));
    }
  }

  List<Measurement> measurements = <Measurement>[];
  for (String config in configurations) {
    for (String file in files) {
      List<String> options = TEST_CONFIGURATIONS[config];
      Measurement measurement = await runTest(config, TEST_FILES[file], options,
          outputUri: outputConfigurations.getUri(config, file),
          verbose: !measure);
      measurements.add(measurement);
    }
  }
  for (Measurement measurement in measurements) {
    print(measurement);
  }
  if (generateMultiConfigs) {
    outputMultiConfigs(Uri.base.resolve(outputPath), outputConfigurations);
  }
}

class OutputConfigurations implements Configurations {
  final Iterable<String> configs;
  final Iterable<String> files;
  final Map<Pair, String> pathMap = {};
  final Map<Pair, Uri> uriMap = {};

  OutputConfigurations(this.configs, this.files);

  void registerPathUri(String config, String file, String path, Uri uri) {
    Pair key = new Pair(config, file);
    pathMap[key] = path;
    uriMap[key] = uri;
  }

  Uri getUri(String config, String file) {
    Pair key = new Pair(config, file);
    return uriMap[key];
  }

  @override
  String getPath(String config, String file) {
    Pair key = new Pair(config, file);
    return pathMap[key];
  }
}

Future<Measurement> runTest(
    String config, String filename, List<String> options,
    {Uri outputUri, bool verbose}) async {
  TestResult result =
      await runTests(config, filename, options, verbose: verbose);
  if (outputUri != null) {
    if (result.missingCodePointsMap.isNotEmpty) {
      result.printMissingCodePoints();
    }
    if (result.multipleNodesMap.isNotEmpty) {
      result.printMultipleNodes();
    }
    if (result.multipleOffsetsMap.isNotEmpty) {
      result.printMultipleOffsets();
    }
    createTraceSourceMapHtml(outputUri, result.processor, result.userInfoList);
  }
  return new Measurement(
      config,
      filename,
      result.missingCodePointsMap.values.fold(0, (s, i) => s + i.length),
      result.userInfoList.fold(0, (s, i) => s + i.codePoints.length));
}

class Measurement {
  final String config;
  final String filename;

  final int missing;
  final int count;

  Measurement(this.config, this.filename, this.missing, this.count);

  String toString() {
    double percentage = 100 * missing / count;
    return "Config '${config}', file: '${filename}': "
        "$missing of $count ($percentage%) missing";
  }
}
