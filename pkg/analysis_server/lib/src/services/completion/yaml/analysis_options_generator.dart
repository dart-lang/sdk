// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/yaml/producer.dart';
import 'package:analysis_server/src/services/completion/yaml/yaml_completion_generator.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/lint/registry.dart';

/// A completion generator that can produce completion suggestions for analysis
/// options files.
class AnalysisOptionsGenerator extends YamlCompletionGenerator {
  /// The producer representing the known valid structure of an analysis options
  /// file.
  // TODO(brianwilkerson): We need to support multiple valid formats.
  //  For example, the lint rules can either be a list or a map, but we only
  //  suggest list items.
  static MapProducer analysisOptionsProducer = MapProducer({
    AnalysisOptionsFile.analyzer: MapProducer({
      AnalysisOptionsFile.enableExperiment: ListProducer(_ExperimentProducer()),
      AnalysisOptionsFile.errors: _ErrorProducer(),
      AnalysisOptionsFile.exclude: EmptyProducer(),
      AnalysisOptionsFile.language: MapProducer({
        AnalysisOptionsFile.strictCasts: BooleanProducer(),
        AnalysisOptionsFile.strictInference: BooleanProducer(),
        AnalysisOptionsFile.strictRawTypes: BooleanProducer(),
      }),
      AnalysisOptionsFile.optionalChecks: MapProducer({
        AnalysisOptionsFile.chromeOsManifestChecks: EmptyProducer(),
      }),
      AnalysisOptionsFile.plugins: EmptyProducer(),
      AnalysisOptionsFile.propagateLinterExceptions: EmptyProducer(),
    }),
    AnalysisOptionsFile.codeStyle: MapProducer({
      AnalysisOptionsFile.format: BooleanProducer(),
    }),
    AnalysisOptionsFile.formatter: MapProducer({
      AnalysisOptionsFile.pageWidth: EmptyProducer(),
      AnalysisOptionsFile.trailingCommas: EnumProducer(
        TrailingCommas.values.map((item) => item.name).toList(),
      ),
    }),
    // TODO(brianwilkerson): Create a producer to produce `package:` URIs.
    AnalysisOptionsFile.include: EmptyProducer(),
    // TODO(brianwilkerson): Create constants for 'linter' and 'rules'.
    'linter': MapProducer({'rules': ListProducer(_LintRuleProducer())}),
  });

  /// Initialize a newly created suggestion generator for analysis options
  /// files.
  AnalysisOptionsGenerator(ResourceProvider resourceProvider)
    : super(resourceProvider, null);

  @override
  Producer get topLevelProducer => analysisOptionsProducer;
}

class _ErrorProducer extends KeyValueProducer {
  static const enumProducer = EnumProducer([
    'ignore',
    'info',
    'warning',
    'error',
  ]);

  @override
  Producer? producerForKey(String key) => enumProducer;

  @override
  Iterable<CompletionSuggestion> suggestions(YamlCompletionRequest request) {
    // There may be overlaps in these names, so use a set.
    var names = {
      for (var diagnostic in diagnosticCodeValues)
        diagnostic.name.toLowerCase(),
      for (var rule in Registry.ruleRegistry.rules) rule.name,
    };
    return {for (var name in names) identifier('$name: ')};
  }
}

class _ExperimentProducer extends Producer {
  /// Initialize a location whose valid values are the names of the known
  /// experimental features.
  const _ExperimentProducer();

  @override
  Iterable<CompletionSuggestion> suggestions(YamlCompletionRequest request) {
    return [
      for (var feature in ExperimentStatus.knownFeatures.values)
        if (!feature.isEnabledByDefault) identifier(feature.enableString),
    ];
  }
}

class _LintRuleProducer extends Producer {
  /// Initialize a location whose valid values are the names of the registered
  /// lint rules.
  const _LintRuleProducer();

  @override
  Iterable<CompletionSuggestion> suggestions(YamlCompletionRequest request) {
    return [
      for (var rule in Registry.ruleRegistry.rules)
        // TODO(pq): consider suggesting internal lints if editing an SDK
        // options file.
        if (!rule.state.isInternal && !rule.state.isRemoved)
          identifier(rule.name, docComplete: rule.description),
    ];
  }
}
