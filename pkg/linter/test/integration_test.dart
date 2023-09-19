// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/state.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:linter/src/rules.dart';
import 'package:linter/src/utils.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'integration/avoid_web_libraries_in_flutter.dart'
    as avoid_web_libraries_in_flutter;
import 'mocks.dart';
import 'test_constants.dart';

void main() {
  group('integration', () {
    ruleTests();
    coreTests();
  });
}

void coreTests() {
  group('core', () {
    group('config', () {
      var currentOut = outSink;
      var collectingOut = CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });
      test('overrides', () async {
        await cli.run([
          '$integrationTestDir/p2',
          '-c',
          '$integrationTestDir/p2/lintconfig2.yaml'
        ]);
        expect(collectingOut.trim(),
            stringContainsInOrder(['4 files analyzed, 0 issues found, in']));
        expect(exitCode, 0);
      });
      test('default', () async {
        await cli.run(['$integrationTestDir/p2']);
        expect(collectingOut.trim(),
            stringContainsInOrder(['4 files analyzed, 3 issues found, in']));
        expect(exitCode, 1);
      });
    });

    group('examples', () {
      test('all.yaml', () {
        var src = readFile(pathRelativeToPackageRoot(['example', 'all.yaml']));

        var options = _getOptionsFromString(src);
        var configuredLints =
            // ignore: cast_nullable_to_non_nullable
            (options['linter'] as YamlMap)['rules'] as YamlList;

        // rules are sorted
        expect(
            configuredLints, orderedEquals(configuredLints.toList()..sort()));

        registerLintRules();

        var registered = Analyzer.facade.registeredRules
            .where((r) => !r.state.isDeprecated && !r.state.isRemoved)
            .map((r) => r.name);

        for (var l in configuredLints) {
          if (!registered.contains(l)) {
            printToConsole(l);
          }
        }

        expect(configuredLints, unorderedEquals(registered));
      });
    });
  });
}

void ruleTests() {
  // ignore: unnecessary_lambdas
  group('rule', () {
    avoid_web_libraries_in_flutter.main();
  });
}

/// Provide the options found in [optionsSource].
Map<String, YamlNode> _getOptionsFromString(String optionsSource) {
  var options = <String, YamlNode>{};
  var doc = loadYamlNode(optionsSource);

  // Empty options.
  if (doc is YamlScalar && doc.value == null) {
    return options;
  }
  if (doc is! YamlMap) {
    throw Exception(
        'Bad options file format (expected map, got ${doc.runtimeType})');
  }
  doc.nodes.forEach((k, YamlNode v) {
    Object? key;
    if (k is YamlScalar) {
      key = k.value;
    }
    if (key is! String) {
      throw Exception('Bad options file format (expected String scope key, '
          'got ${k.runtimeType})');
    }
    options[key] = v;
  });
  return options;
}
