// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'analysis_options_parser.dart';

/// The linter rule state exported by an options file after applying its own
/// includes and local overrides.
///
/// Both enabled and disabled rules are retained because a local disable must
/// hide a lower-priority enabled rule when this state is merged into an
/// including file. The maps are keyed by the canonical rule object returned by
/// the registry, not by the spelling used in YAML.
final class _EffectiveLinterRules {
  final Map<AbstractAnalysisRule, _RuleData> enabled = {};
  final Map<AbstractAnalysisRule, _RuleData> disabled = {};

  _EffectiveLinterRules();

  _EffectiveLinterRules.from(_EffectiveLinterRules other) {
    enabled.addAll(other.enabled);
    disabled.addAll(other.disabled);
  }

  void apply(_EffectiveLinterRules other) {
    for (var ruleData in other.disabled.values) {
      enabled.remove(ruleData.rule);
      disabled[ruleData.rule] = ruleData;
    }
    for (var ruleData in other.enabled.values) {
      disabled.remove(ruleData.rule);
      enabled[ruleData.rule] = ruleData;
    }
  }

  void applyLocal(_LocalLinterRules localRules) {
    for (var ruleData in localRules.disabled) {
      enabled.remove(ruleData.rule);
      disabled[ruleData.rule] = ruleData;
    }
    for (var ruleData in localRules.enabled) {
      disabled.remove(ruleData.rule);
      enabled[ruleData.rule] = ruleData;
    }
  }

  _EffectiveLinterRules copy() => _EffectiveLinterRules.from(this);
}

/// The effective linter rule state contributed through one `include` entry.
///
/// The [includeNode] is the include site in the current file, not the source of
/// the rules themselves. Keeping it with the effective rules lets
/// [diag.incompatibleLintIncluded] point at the include that introduced the
/// conflicting subtree while its context messages still point at actual rule
/// nodes.
final class _IncludedLinterRules {
  final YamlScalar includeNode;
  final _EffectiveLinterRules rules;

  _IncludedLinterRules({required this.includeNode, required this.rules});
}

/// An enabled rule together with the include entry that made it visible.
///
/// This is only needed while comparing sibling includes. The rule data carries
/// the precise YAML location; the include node carries the current-file
/// provenance needed for the primary diagnostic and file-count calculation.
final class _IncludedRuleData {
  final YamlScalar includeNode;
  final _RuleData ruleData;

  _IncludedRuleData({required this.includeNode, required this.ruleData});
}

/// Reports linter-rule diagnostics whose meaning depends on included files.
abstract final class _LinterRuleDiagnostics {
  static final diagnosticFactory = DiagnosticFactory();

  static List<_RuleData> findIncompatibleRules(
    AbstractAnalysisRule rule, {
    required Iterable<_RuleData> rules,
  }) {
    List<_RuleData> incompatibleRules = [];
    for (var incompatibleRuleName in rule.incompatibleRules) {
      var incompatibleRule = Registry.ruleRegistry[incompatibleRuleName];
      if (incompatibleRule == null) {
        continue;
      }
      for (var ruleData in rules) {
        if (ruleData.rule == incompatibleRule) {
          incompatibleRules.add(ruleData);
        }
      }
    }
    return incompatibleRules;
  }

  /// Reports conflicts between rules introduced by different include entries.
  ///
  /// [includedRules] must be in include-list order. Rules enabled or disabled
  /// by a higher-priority entry replace matching rules from lower-priority
  /// includes before incompatible-rule comparison. Rules disabled in the
  /// current file suppress conflicts from all includes.
  static void reportIncompatibleIncluded({
    required DiagnosticReporter reporter,
    required List<_IncludedLinterRules> includedRules,
    required List<_RuleData> disabledRules,
  }) {
    var seenRules = <AbstractAnalysisRule, _IncludedRuleData>{};
    var disabledRuleSet = disabledRules
        .map((ruleData) => ruleData.rule)
        .toSet();
    for (var current in includedRules) {
      for (var ruleData in current.rules.disabled.values) {
        seenRules.remove(ruleData.rule);
      }
      for (var ruleData in current.rules.enabled.values) {
        seenRules.remove(ruleData.rule);
      }
      for (var rule in disabledRuleSet) {
        seenRules.remove(rule);
      }

      var incompatible = <_IncludedRuleData>[];
      void add(_IncludedRuleData data) {
        if (!incompatible.any((existing) {
          return identical(existing.ruleData.node, data.ruleData.node);
        })) {
          incompatible.add(data);
        }
      }

      for (var ruleData in current.rules.enabled.values) {
        if (disabledRuleSet.contains(ruleData.rule)) {
          continue;
        }
        var previousIncompatible = findIncompatibleRules(
          ruleData.rule,
          rules: seenRules.values.map((data) => data.ruleData),
        );
        if (previousIncompatible.isEmpty) {
          continue;
        }
        add(
          _IncludedRuleData(
            includeNode: current.includeNode,
            ruleData: ruleData,
          ),
        );
        for (var previousRule in previousIncompatible) {
          var previousIncludedRule = seenRules[previousRule.rule];
          if (previousIncludedRule != null) {
            add(previousIncludedRule);
          }
        }
      }

      if (incompatible.isNotEmpty) {
        reporter.report(
          diagnosticFactory.incompatibleLintIncluded(
            source: reporter.source,
            reference: current.includeNode,
            incompatibleRules: {
              for (var data in incompatible)
                data.ruleData.file.path: data.ruleData.node,
            },
            fileCount: incompatible
                .map((data) => data.includeNode)
                .toSet()
                .length,
          ),
        );
      }

      for (var ruleData in current.rules.enabled.values) {
        if (disabledRuleSet.contains(ruleData.rule)) {
          continue;
        }
        seenRules[ruleData.rule] = _IncludedRuleData(
          includeNode: current.includeNode,
          ruleData: ruleData,
        );
      }
    }
  }

  /// Reports conflicts between local enabled rules and effective included rules.
  ///
  /// Local enabled and disabled rules are applied before comparison so that
  /// local declarations replace inherited declarations. The primary diagnostic
  /// is reported on the local rule node; context messages point at the
  /// included rule nodes.
  static void reportIncompatibleWithIncluded({
    required DiagnosticReporter reporter,
    required _LocalLinterRules localRules,
    required _EffectiveLinterRules includedRules,
  }) {
    var activeIncludedRules = includedRules.copy();
    for (var localRule in localRules.enabled) {
      activeIncludedRules.enabled.remove(localRule.rule);
    }
    for (var disabledRule in localRules.disabled) {
      activeIncludedRules.enabled.remove(disabledRule.rule);
    }

    for (var ruleData in localRules.enabled) {
      var incompatible = findIncompatibleRules(
        ruleData.rule,
        rules: activeIncludedRules.enabled.values,
      );
      if (incompatible.isEmpty) {
        continue;
      }
      reporter.report(
        diagnosticFactory.incompatibleLintFiles(
          source: reporter.source,
          reference: ruleData.node,
          incompatibleRules: {
            for (var data in incompatible) data.file.path: data.node,
          },
        ),
      );
    }
  }
}

/// Linter rule declarations found directly in one physical options file.
///
/// This is intentionally not an effective view: it does not know about includes
/// and it preserves the local enabled/disabled declarations after syntax and
/// rule-name validation. The walker combines these local facts with included
/// effective state using analysis-options precedence.
final class _LocalLinterRules {
  static const _LocalLinterRules empty = .new(enabled: [], disabled: []);

  final List<_RuleData> enabled;
  final List<_RuleData> disabled;

  const _LocalLinterRules({required this.enabled, required this.disabled});
}

/// A source-preserving occurrence of a registered linter rule.
///
/// [rule] provides canonical identity and compatibility metadata, while [node]
/// preserves the user's spelling and offset for diagnostics. [file] is stored
/// explicitly so cross-file diagnostics can avoid depending on URI details from
/// YAML spans.
final class _RuleData {
  final AbstractAnalysisRule rule;

  final YamlScalar node;
  final File file;
  final bool isEnabled;

  _RuleData(
    this.rule,
    this.node, {
    required this.file,
    required this.isEnabled,
  });
}
