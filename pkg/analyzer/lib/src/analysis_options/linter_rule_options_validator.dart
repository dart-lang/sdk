// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'analysis_options_validator.dart';

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

  _EffectiveLinterRules.fromLocal(_LocalLinterRules localRules) {
    applyLocal(localRules);
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

/// Validates `linter` rule configurations in a single options file.
class _LinterRuleOptionsValidator extends OptionsValidator {
  static const _linter = 'linter';
  static const _rulesKey = 'rules';

  static final _diagnosticFactory = DiagnosticFactory();

  static const _trueValue = 'true';
  static const _falseValue = 'false';
  static const _ignoreValue = 'ignore';
  static const _infoValue = 'info';
  static const _warningValue = 'warning';
  static const _errorValue = 'error';
  static const _validLintValues = [
    _trueValue,
    _falseValue,
    ..._validLintStringValues,
  ];
  static const _validLintStringValues = [
    _ignoreValue,
    _infoValue,
    _warningValue,
    _errorValue,
  ];

  final VersionConstraint? _sdkVersionConstraint;

  /// Whether the linter section being validated as a "primary source;" that is,
  /// whether it is not being analyzed as part of a chain of 'include's.
  final bool _isPrimarySource;

  final File _file;

  _LocalLinterRules localRules = _LocalLinterRules.empty;

  _LinterRuleOptionsValidator({
    required File file,
    VersionConstraint? sdkVersionConstraint,
    bool isPrimarySource = true,
  }) : _file = file,
       _isPrimarySource = isPrimarySource,
       _sdkVersionConstraint = sdkVersionConstraint;

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var node = options.valueAt(_linter);

    YamlNode? rules;
    if (node is YamlMap) {
      rules = node.valueAt(_rulesKey);
    }
    localRules = _validateRules(rules, reporter);
  }

  bool _beforeCurrentConstraint(Version? since) {
    // No "since" applies to all SDKs.
    if (since == null) return true;

    return switch (_sdkVersionConstraint) {
      VersionRange(min: var min?) => since <= min,
      _ => false,
    };
  }

  AbstractAnalysisRule? _getRegisteredLint(String value) =>
      Registry.ruleRegistry[value];

  bool _isDeprecatedInCurrentOrEarlierSdk(RuleState state) =>
      state.isDeprecated && _beforeCurrentConstraint(state.since);

  bool _isRemovedInCurrentOrEarlierSdk(RuleState state) =>
      state.isRemoved && _beforeCurrentConstraint(state.since);

  /// Processes an enabled rule by checking for incompatible rules and reporting
  /// any issues found.
  void _processEnabledRule({
    required _RuleData ruleData,
    required Map<AbstractAnalysisRule, _RuleData> activeRules,
    required DiagnosticReporter reporter,
  }) {
    String value = ruleData.node.value.toString();
    var incompatible = _findIncompatibleRules(
      ruleData.rule,
      rules: activeRules.values,
    );
    if (incompatible.isNotEmpty) {
      reporter.report(
        _diagnosticFactory.incompatibleLint(
          source: reporter.source,
          reference: ruleData.node,
          incompatibleRules: {
            for (var data in incompatible) data.file.path: data.node,
          },
        ),
      );
    }
    if (activeRules.containsKey(ruleData.rule)) {
      reporter.report(
        diag.duplicateRule
            .withArguments(ruleName: value)
            .atSourceSpan(ruleData.node.span),
      );
    }
  }

  _LocalLinterRules _validateRules(
    YamlNode? rules,
    DiagnosticReporter reporter,
  ) {
    if (rules is! YamlList &&
        rules is! YamlMap &&
        // This handles empty keys like
        // linter:
        //   rules:
        (rules is! YamlScalar || rules.value != null) &&
        // We accept 'null' for triggering `INCOMPATIBLE_LINT_INCLUDED`
        rules != null) {
      return _LocalLinterRules.empty;
    }

    _RuleData? validateRule(YamlScalar node, Object? enabled) {
      var value = node.value;
      if (value is! String) return null;
      if (enabled == null) return null;

      var rule = _getRegisteredLint(value);
      if (rule == null) {
        reporter.report(
          diag.undefinedLint
              .withArguments(ruleName: value)
              .atSourceSpan(node.span),
        );
        return null;
      }

      Object? ruleValue;
      bool enabledValue;
      if (enabled is YamlNode) {
        ruleValue = enabled.value;
      } else if (enabled is bool) {
        ruleValue = enabled;
        enabledValue = enabled;
      }

      if (ruleValue == null) {
        return null;
      }

      if (ruleValue is String && _validLintStringValues.contains(ruleValue)) {
        enabledValue = ruleValue != _ignoreValue;
      } else if (ruleValue is bool) {
        enabledValue = ruleValue;
      } else {
        enabledValue = false;
        var warningNode = enabled is YamlNode ? enabled : node;
        reporter.report(
          diag.unsupportedValue
              .withArguments(
                optionName: value.toString(),
                invalidValue: ruleValue.toString(),
                legalValues: _validLintValues.quotedAndCommaSeparatedWithOr,
              )
              .atSourceSpan(warningNode.span),
        );
      }

      // Report removed or deprecated lint warnings defined directly (and not in
      // includes).
      if (_isPrimarySource) {
        var state = rule.state;
        if (_isDeprecatedInCurrentOrEarlierSdk(state)) {
          var replacedBy = state.replacedBy;
          if (replacedBy != null) {
            reporter.report(
              diag.deprecatedLintWithReplacement
                  .withArguments(
                    deprecatedRuleName: value,
                    replacementRuleName: replacedBy,
                  )
                  .atSourceSpan(node.span),
            );
          } else {
            reporter.report(
              diag.deprecatedLint
                  .withArguments(ruleName: value)
                  .atSourceSpan(node.span),
            );
          }
        } else if (_isRemovedInCurrentOrEarlierSdk(state)) {
          var since = state.since.toString();
          var replacedBy = state.replacedBy;
          if (replacedBy != null) {
            reporter.report(
              diag.replacedLint
                  .withArguments(
                    ruleName: value,
                    sdkVersion: since,
                    replacingLintName: replacedBy,
                  )
                  .atSourceSpan(node.span),
            );
          } else {
            reporter.report(
              diag.removedLint
                  .withArguments(ruleName: value, sdkVersion: since)
                  .atSourceSpan(node.span),
            );
          }
        }
      }

      return _RuleData(rule, node, file: _file, isEnabled: enabledValue);
    }

    var activeRules = <AbstractAnalysisRule, _RuleData>{};
    var disabledRules = <_RuleData>[];
    var ruleDataList = <_RuleData>[];

    var entries = switch (rules) {
      YamlList(:var nodes) => nodes.map((rule) => MapEntry(rule, true)),
      YamlMap(:var nodeMap) => nodeMap.entries,
      _ => const <MapEntry<YamlNode, Object>>[],
    };

    for (var MapEntry(:key, :value) in entries) {
      if (key is! YamlScalar) {
        continue;
      }
      var rule = validateRule(key, value);
      if (rule == null) {
        continue;
      }
      if (rule.isEnabled) {
        ruleDataList.add(rule);
      } else {
        disabledRules.add(rule);
      }
    }

    for (var rule in ruleDataList) {
      _processEnabledRule(
        ruleData: rule,
        reporter: reporter,
        activeRules: activeRules,
      );
      activeRules[rule.rule] = rule;
    }

    return _LocalLinterRules(enabled: ruleDataList, disabled: disabledRules);
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
        var previousIncompatible = _findIncompatibleRules(
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
          _diagnosticFactory.incompatibleLintIncluded(
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
      var incompatible = _findIncompatibleRules(
        ruleData.rule,
        rules: activeIncludedRules.enabled.values,
      );
      if (incompatible.isEmpty) {
        continue;
      }
      reporter.report(
        _diagnosticFactory.incompatibleLintFiles(
          source: reporter.source,
          reference: ruleData.node,
          incompatibleRules: {
            for (var data in incompatible) data.file.path: data.node,
          },
        ),
      );
    }
  }

  static List<_RuleData> _findIncompatibleRules(
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
