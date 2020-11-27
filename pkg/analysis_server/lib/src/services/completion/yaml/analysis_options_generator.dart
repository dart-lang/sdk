// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/yaml/producer.dart';
import 'package:analysis_server/src/services/completion/yaml/yaml_completion_generator.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/task/options.dart';

/// A completion generator that can produce completion suggestions for analysis
/// options files.
class AnalysisOptionsGenerator extends YamlCompletionGenerator {
  /// The producer representing the known valid structure of an analysis options
  /// file.
  // TODO(brianwilkerson) We need to support multiple valid formats.
  //  For example, the lint rules can either be a list or a map, but we only
  //  suggest list items.
  static const MapProducer analysisOptionsProducer = MapProducer({
    AnalyzerOptions.analyzer: MapProducer({
      AnalyzerOptions.enableExperiment: EmptyProducer(),
      AnalyzerOptions.errors: EmptyProducer(),
      AnalyzerOptions.exclude: EmptyProducer(),
      AnalyzerOptions.language: MapProducer({
        AnalyzerOptions.strictInference: EmptyProducer(),
        AnalyzerOptions.strictRawTypes: EmptyProducer(),
      }),
      AnalyzerOptions.optionalChecks: MapProducer({
        AnalyzerOptions.chromeOsManifestChecks: EmptyProducer(),
      }),
      AnalyzerOptions.plugins: EmptyProducer(),
      AnalyzerOptions.strong_mode: MapProducer({
        AnalyzerOptions.declarationCasts: EmptyProducer(),
        AnalyzerOptions.implicitCasts: EmptyProducer(),
        AnalyzerOptions.implicitDynamic: EmptyProducer(),
      }),
    }),
    // TODO(brianwilkerson) Create a producer to produce `package:` URIs.
    AnalyzerOptions.include: EmptyProducer(),
    // TODO(brianwilkerson) Create constants for 'linter' and 'rules'.
    'linter': MapProducer({
      'rules': ListProducer(LintRuleProducer()),
    }),
  });

  /// Initialize a newly created suggestion generator for analysis options
  /// files.
  AnalysisOptionsGenerator(ResourceProvider resourceProvider)
      : super(resourceProvider);

  @override
  Producer get topLevelProducer => analysisOptionsProducer;
}

class LintRuleProducer extends Producer {
  /// Initialize a location whose valid values are the names of the registered
  /// lint rules.
  const LintRuleProducer();

  @override
  Iterable<CompletionSuggestion> suggestions(
      YamlCompletionRequest request) sync* {
    for (var rule in Registry.ruleRegistry.rules) {
      yield identifier(rule.name);
    }
  }
}
