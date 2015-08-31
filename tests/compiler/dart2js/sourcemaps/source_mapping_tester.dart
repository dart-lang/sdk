// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'sourcemap_helper.dart';

main(List<String> arguments) {
  Set<String> configurations = new Set<String>();
  Set<String> files = new Set<String>();
  for (String argument in arguments) {
    if (!parseArgument(argument, configurations, files)) {
      return;
    }
  }

  if (configurations.isEmpty) {
    configurations.addAll(TEST_CONFIGURATIONS.keys);
    configurations.remove('old');
  }
  if (files.isEmpty) {
    files.addAll(TEST_FILES.keys);
  }

  asyncTest(() async {
    bool missingCodePointsFound = false;
    for (String config in configurations) {
      List<String> options = TEST_CONFIGURATIONS[config];
      for (String file in files) {
        String filename = TEST_FILES[file];
        TestResult result = await runTests(config, filename, options);
        if (result.failureMap.isNotEmpty) {
          result.failureMap.forEach((info, missingCodePoints) {
            print("Missing code points for ${info.element} in '$filename' "
                  "in config '$config':");
            for (CodePoint codePoint in missingCodePoints) {
              print("  $codePoint");
            }
          });
          missingCodePointsFound = true;
        }
      }
    }
    Expect.isFalse(missingCodePointsFound,
        "Missing code points found. "
        "Run the test with a URI option, "
        "`source_mapping_test_viewer [--out=<uri>] [configs] [tests]`, to "
        "create a html visualization of the missing code points.");
  });
}

/// Parse [argument] for a valid configuration or test-file option.
///
/// On success, the configuration name is added to [configurations] or the
/// test-file name is added to [files], and `true` is returned.
/// On failure, a message is printed and `false` is returned.
///
bool parseArgument(String argument,
                   Set<String> configurations,
                   Set<String> files) {
  if (TEST_CONFIGURATIONS.containsKey(argument)) {
    configurations.add(argument);
  } else if (TEST_FILES.containsKey(argument)) {
    files.add(argument);
  } else {
    print("Unknown configuration or file '$argument'. "
          "Must be one of '${TEST_CONFIGURATIONS.keys.join("', '")}' or "
          "'${TEST_FILES.keys.join("', '")}'.");
    return false;
  }
  return true;
}

const Map<String, List<String>> TEST_CONFIGURATIONS = const {
  'ssa': const ['--use-new-source-info', ],
  'cps': const ['--use-new-source-info', '--use-cps-ir'],
  'old': const [],
};

const Map<String, String> TEST_FILES = const <String, String>{
  'invokes': 'tests/compiler/dart2js/sourcemaps/invokes_test_file.dart',
  'operators': 'tests/compiler/dart2js/sourcemaps/operators_test_file.dart',
};

Future<TestResult> runTests(
    String config,
    String filename,
    List<String> options,
    {bool verbose: true}) async {
  SourceMapProcessor processor = new SourceMapProcessor(filename);
  List<SourceMapInfo> infoList = await processor.process(
      ['--csp', '--disable-inlining']
      ..addAll(options),
      verbose: verbose);
  TestResult result = new TestResult(config, filename, processor);
  for (SourceMapInfo info in infoList) {
    if (info.element.library.isPlatformLibrary) continue;
    result.userInfoList.add(info);
    Iterable<CodePoint> missingCodePoints =
        info.codePoints.where((c) => c.isMissing);
    if (missingCodePoints.isNotEmpty) {
      result.failureMap[info] = missingCodePoints;
    }
  }
  return result;
}

class TestResult {
  final String config;
  final String file;
  final SourceMapProcessor processor;
  List<SourceMapInfo> userInfoList = <SourceMapInfo>[];
  Map<SourceMapInfo, Iterable<CodePoint>> failureMap =
      <SourceMapInfo, Iterable<CodePoint>>{};

  TestResult(this.config, this.file, this.processor);
}
