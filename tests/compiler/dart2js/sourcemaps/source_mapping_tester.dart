// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/io/source_information.dart';
import 'package:compiler/src/js/js_debug.dart';
import 'package:js_ast/js_ast.dart';
import 'sourcemap_helper.dart';

typedef CodePointWhiteListFunction WhiteListFunction(
    String configuration, String file);

typedef bool CodePointWhiteListFunction(CodePoint codePoint);

CodePointWhiteListFunction emptyWhiteListFunction(String config, String file) {
  return emptyWhiteList;
}

bool emptyWhiteList(CodePoint codePoint) => false;

main(List<String> arguments) {
  test(arguments);
}

void test(List<String> arguments,
    {WhiteListFunction whiteListFunction: emptyWhiteListFunction}) {
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
    bool errorsFound = false;
    for (String config in configurations) {
      List<String> options = TEST_CONFIGURATIONS[config];
      for (String file in files) {
        String filename = TEST_FILES[file];
        TestResult result = await runTests(config, filename, options);
        if (result.missingCodePointsMap.isNotEmpty) {
          errorsFound =
              result.printMissingCodePoints(whiteListFunction(config, file));
          true;
        }
        if (result.multipleNodesMap.isNotEmpty) {
          result.printMultipleNodes();
          errorsFound = true;
        }
        if (result.multipleOffsetsMap.isNotEmpty) {
          result.printMultipleOffsets();
          errorsFound = true;
        }
      }
    }
    Expect.isFalse(
        errorsFound,
        "Errors found. "
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
bool parseArgument(
    String argument, Set<String> configurations, Set<String> files) {
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
  'ast': const [
    '--use-new-source-info',
  ],
  'kernel': const [
    Flags.useKernel,
  ],
  'old': const [],
};

const Map<String, String> TEST_FILES = const <String, String>{
  'invokes': 'tests/compiler/dart2js/sourcemaps/data/invokes_test_file.dart',
  'operators':
      'tests/compiler/dart2js/sourcemaps/data/operators_test_file.dart',
  'others': 'tests/compiler/dart2js/sourcemaps/data/others.dart',
};

Future<TestResult> runTests(
    String config, String filename, List<String> options,
    {bool verbose: true}) async {
  SourceMapProcessor processor = new SourceMapProcessor(filename);
  SourceMaps sourceMaps = await processor.process(
      ['--csp', '--disable-inlining']..addAll(options),
      verbose: verbose);
  TestResult result = new TestResult(config, filename, processor);
  for (SourceMapInfo info in sourceMaps.elementSourceMapInfos.values) {
    if (info.element.library.canonicalUri.scheme == 'dart') continue;
    result.userInfoList.add(info);
    Iterable<CodePoint> missingCodePoints =
        info.codePoints.where((c) => c.isMissing);
    if (missingCodePoints.isNotEmpty) {
      result.missingCodePointsMap[info] = missingCodePoints;
    }
    Map<int, Set<SourceLocation>> offsetToLocationsMap =
        <int, Set<SourceLocation>>{};
    for (Node node in info.nodeMap.nodes) {
      info.nodeMap[node]
          .forEach((int targetOffset, List<SourceLocation> sourceLocations) {
        if (sourceLocations.length > 1) {
          Map<Node, List<SourceLocation>> multipleMap = result.multipleNodesMap
              .putIfAbsent(info, () => <Node, List<SourceLocation>>{});
          multipleMap[node] = sourceLocations;
        } else {
          offsetToLocationsMap
              .putIfAbsent(targetOffset, () => new Set<SourceLocation>())
              .addAll(sourceLocations);
        }
      });
    }
    offsetToLocationsMap
        .forEach((int targetOffset, Set<SourceLocation> sourceLocations) {
      if (sourceLocations.length > 1) {
        Map<int, Set<SourceLocation>> multipleMap = result.multipleOffsetsMap
            .putIfAbsent(info, () => <int, Set<SourceLocation>>{});
        multipleMap[targetOffset] = sourceLocations;
      }
    });
  }
  return result;
}

class TestResult {
  final String config;
  final String file;
  final SourceMapProcessor processor;
  List<SourceMapInfo> userInfoList = <SourceMapInfo>[];
  Map<SourceMapInfo, Iterable<CodePoint>> missingCodePointsMap =
      <SourceMapInfo, Iterable<CodePoint>>{};

  /// For each [SourceMapInfo] a map from JS node to multiple source locations
  /// associated with the node.
  Map<SourceMapInfo, Map<Node, List<SourceLocation>>> multipleNodesMap =
      <SourceMapInfo, Map<Node, List<SourceLocation>>>{};

  /// For each [SourceMapInfo] a map from JS offset to multiple source locations
  /// associated with the offset.
  Map<SourceMapInfo, Map<int, Set<SourceLocation>>> multipleOffsetsMap =
      <SourceMapInfo, Map<int, Set<SourceLocation>>>{};

  TestResult(this.config, this.file, this.processor);

  bool printMissingCodePoints(
      [CodePointWhiteListFunction codePointWhiteList = emptyWhiteList]) {
    bool allWhiteListed = true;
    missingCodePointsMap.forEach((info, missingCodePoints) {
      print("Missing code points for ${info.element} in '$file' "
          "in config '$config':");
      for (CodePoint codePoint in missingCodePoints) {
        if (codePointWhiteList(codePoint)) {
          print("  $codePoint (white-listed)");
        } else {
          print("  $codePoint");
          allWhiteListed = false;
        }
      }
    });
    return !allWhiteListed;
  }

  void printMultipleNodes() {
    multipleNodesMap.forEach((info, multipleMap) {
      multipleMap.forEach((node, sourceLocations) {
        print('Multiple source locations:\n ${sourceLocations.join('\n ')}\n'
            'for `${nodeToString(node)}` in ${info.element} in '
            '$file.');
      });
    });
  }

  void printMultipleOffsets() {
    multipleOffsetsMap.forEach((info, multipleMap) {
      multipleMap.forEach((targetOffset, sourceLocations) {
        print('Multiple source locations:\n ${sourceLocations.join('\n ')}\n'
            'for offset $targetOffset in ${info.element} in $file.');
      });
    });
  }
}
