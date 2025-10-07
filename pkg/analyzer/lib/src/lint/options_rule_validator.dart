// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/analysis_options/options_validator.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Validates `linter` rule configurations.
class LinterRuleOptionsValidator extends OptionsValidator {
  static const includeKey = 'include';
  static const linter = 'linter';
  static const rulesKey = 'rules';

  static final diagnosticFactory = DiagnosticFactory();

  static const trueValue = 'true';
  static const falseValue = 'false';
  static const ignoreValue = 'ignore';
  static const infoValue = 'info';
  static const warningValue = 'warning';
  static const errorValue = 'error';
  static const validLintValues = [
    trueValue,
    falseValue,
    ...validLintStringValues,
  ];
  static const validLintStringValues = [
    ignoreValue,
    infoValue,
    warningValue,
    errorValue,
  ];

  final VersionConstraint? sdkVersionConstraint;

  /// Whether the linter section being validated as a "primary source;" that is,
  /// whether it is not being analyzed as part of a chain of 'include's.
  final bool isPrimarySource;

  final AnalysisOptionsProvider optionsProvider;
  final ResourceProvider resourceProvider;
  final SourceFactory sourceFactory;

  LinterRuleOptionsValidator({
    required this.resourceProvider,
    required this.optionsProvider,
    required this.sourceFactory,
    this.sdkVersionConstraint,
    this.isPrimarySource = true,
  });

  bool currentSdkAllows(Version? since) {
    if (since == null) return true;
    var sdk = sdkVersionConstraint;
    if (sdk == null) return false;
    return sdk.allows(since);
  }

  AbstractAnalysisRule? getRegisteredLint(String value) => Registry
      .ruleRegistry
      .rules
      .firstWhereOrNull((rule) => rule.name == value);

  bool isDeprecatedInCurrentSdk(RuleState state) =>
      state.isDeprecated && currentSdkAllows(state.since);

  bool isRemovedInCurrentSdk(RuleState state) {
    return state.isRemoved && currentSdkAllows(state.since);
  }

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var node = options.valueAt(linter);

    YamlNode? rules;
    if (node is YamlMap) {
      rules = node.valueAt(rulesKey);
    }
    _validateRules(rules, reporter, options.valueAt(includeKey));
  }

  Uri? _actualIncludePath(String includePath, Uri? sourceUri) {
    var (first, last) = (
      includePath.codeUnits.firstOrNull,
      includePath.codeUnits.lastOrNull,
    );
    if ((first == 0x0022 || first == 0x0027) && first == last) {
      // The URI begins and ends with either a double quote or single quote
      // i.e. the value of the "include" field is quoted.
      includePath = includePath.substring(1, includePath.length - 1);
    }

    if (includePath.isEmpty) return null;

    if (sourceUri != null) {
      var source = FileSource(resourceProvider.getFile(sourceUri.toFilePath()));
      var resolved = sourceFactory.resolveUri(source, includePath);
      if (resolved is FileSource) {
        return resolved.file.toUri();
      }
    }

    var uri = Uri.parse(includePath);
    if (uri == sourceUri) {
      // The URI is the same as the source URI, so we don't need to resolve it.
      return null;
    }

    if (uri.isAbsolute) {
      // The URI is absolute, so we don't need to resolve it.
      return uri;
    }

    if (sourceUri == null) {
      // The URI is relative, but we don't have a base URI to resolve it
      // against.
      return null;
    }

    return uriCache.resolveRelative(sourceUri, uri);
  }

  Set<YamlScalar> _collectRules(YamlNode? rules) {
    var includeRules = <YamlScalar>{};
    if (rules is YamlList) {
      for (var ruleNode in rules.nodes) {
        var value = ruleNode.value;
        if (value is String) {
          var rule = getRegisteredLint(value);
          if (rule != null && ruleNode is YamlScalar) {
            includeRules.add(ruleNode);
          }
        }
      }
    } else if (rules is YamlMap) {
      for (var entry in rules.nodeMap.entries) {
        var value = entry.key.value as Object?;
        if (value is! String) {
          continue;
        }
        var enabled = entry.value.value;
        if (enabled is! bool) {
          continue;
        }
        if (enabled) {
          var rule = getRegisteredLint(value);
          if (entry.key case YamlScalar yaml when rule != null) {
            includeRules.add(yaml);
          }
        }
      }
    }
    return includeRules;
  }

  /// Returns the first rule that is incompatible with the given [rule].
  ///
  /// If the rule is found in the [rules] map, it returns the file path
  /// and the rule name.
  List<_IncompatibleRuleData> _findIncompatibleRules(
    AbstractAnalysisRule rule, {
    required Map<YamlScalar?, Set<YamlScalar>> rules,
  }) {
    List<_IncompatibleRuleData> incompatibleRules = [];
    for (var incompatibleRule in rule.incompatibleRules) {
      for (var MapEntry(:key, value: rules) in rules.entries) {
        if (rules.map((node) => node.value).contains(incompatibleRule)) {
          var list = rules.where((scalar) => scalar.value == incompatibleRule);
          for (var scalar in list) {
            var rule = getRegisteredLint(scalar.value.toString())!;
            incompatibleRules.add(
              _IncompatibleRuleData(
                _RuleData(rule, scalar, isEnabled: true),
                file: key,
              ),
            );
          }
        }
      }
    }
    if (incompatibleRules.isNotEmpty) {
      return incompatibleRules;
    }
    return const [];
  }

  /// Processes an enabled rule by checking for incompatible rules and reporting
  /// any issues found.
  ///
  /// The [ruleData] contains information about the rule being processed.
  ///
  /// The [rules] map contains rules from included files which were not
  /// disabled by the current file. When the [YamlScalar] ([MapEntry.key]) is
  /// `null`, it indicates that the rule is from the current file.
  ///
  /// The [reporter] is used to report any issues found during processing.
  void _processEnabledRule({
    required _RuleData ruleData,
    required Map<YamlScalar?, Set<YamlScalar>> rules,
    required DiagnosticReporter reporter,
  }) {
    String value = ruleData.node.value.toString();
    var incompatible = _findIncompatibleRules(ruleData.rule, rules: rules);
    if (incompatible.isNotEmpty) {
      if (incompatible.where((data) => data.file == null)
          case var localIncompatible when localIncompatible.isNotEmpty) {
        reporter.reportError(
          diagnosticFactory.incompatibleLint(
            source: FileSource(
              resourceProvider.getFile(
                ruleData.node.span.sourceUrl!.toFilePath(),
              ),
            ),
            reference: ruleData.node,
            incompatibleRules: {
              for (var data in localIncompatible)
                if (ruleData.node.span.sourceUrl!.toString() case var value)
                  fromUri(value): data.ruleData.node,
            },
          ),
        );
      }
      if (incompatible.where((data) => data.file != null)
          case var includedIncompatible when includedIncompatible.isNotEmpty) {
        reporter.reportError(
          diagnosticFactory.incompatibleLintFiles(
            source: FileSource(
              resourceProvider.getFile(
                ruleData.node.span.sourceUrl!.toFilePath(),
              ),
            ),
            reference: ruleData.node,
            incompatibleRules: {
              for (var data in includedIncompatible)
                if (data.file?.value case String value)
                  if (_actualIncludePath(value, data.file?.span.sourceUrl)
                      case var uri?)
                    fromUri(uri): data.ruleData.node,
            },
          ),
        );
      }
    }
    if (rules[null]!.map((e) => e.value).contains(ruleData.node.value)) {
      reporter.atSourceSpan(
        ruleData.node.span,
        AnalysisOptionsWarningCode.duplicateRule,
        arguments: [value],
      );
    }
  }

  Map<YamlScalar, Set<YamlScalar>> _processIncludes(
    YamlNode includeNode,
    DiagnosticReporter reporter,
    List<AbstractAnalysisRule> disabledRules,
  ) {
    var seenRules = <YamlScalar, Set<YamlScalar>>{};
    var includes = <(YamlScalar, String)>[];
    if (includeNode is YamlScalar) {
      includes.add((includeNode, includeNode.value.toString()));
    } else if (includeNode is YamlList) {
      for (var node in includeNode.nodes) {
        if (node is YamlScalar) {
          includes.add((node, node.value.toString()));
        }
      }
    }

    var uri = includeNode.span.sourceUrl;
    for (var (includeNode, includePath) in includes) {
      File file;
      try {
        var pathStr = _actualIncludePath(includePath, uri);
        if (pathStr == null) continue;
        if (pathStr.path == uri?.path) {
          continue;
        }
        file = resourceProvider.getFile(fromUri(pathStr));
      } catch (_) {
        // if files are invalid, we ignore them
        continue;
      }
      var includedOptions = optionsProvider.getOptionsFromFile(file);
      var linterNode = includedOptions.valueAt(linter);
      if (linterNode is! YamlMap) {
        continue;
      }
      var rulesNode = linterNode.valueAt(rulesKey);
      var rules = _collectRules(rulesNode);
      Set<_IncompatibleRuleData> incompatible = {};
      for (var rule in rules.toList()) {
        var value = rule.value;
        if (value is! String) {
          continue;
        }
        var lintRule = getRegisteredLint(value);
        if (lintRule == null || disabledRules.contains(lintRule)) {
          rules.remove(rule);
          continue;
        }
        var incompatibleRules = _findIncompatibleRules(
          lintRule,
          rules: seenRules,
        );
        if (incompatibleRules.isEmpty) {
          continue;
        }
        incompatible.add(
          _IncompatibleRuleData(
            _RuleData(lintRule, rule, isEnabled: true),
            file: includeNode,
          ),
        );
        incompatible.addAll(incompatibleRules);
      }
      if (incompatible.isNotEmpty) {
        reporter.reportError(
          diagnosticFactory.incompatibleLintIncluded(
            source: FileSource(
              resourceProvider.getFile(
                includeNode.span.sourceUrl!.toFilePath(),
              ),
            ),
            reference: includeNode,
            incompatibleRules: {
              for (var data in incompatible)
                if (data.file?.value case String value)
                  if (_actualIncludePath(value, data.file?.span.sourceUrl)
                      case var uri?)
                    fromUri(uri): data.ruleData.node,
            },
            fileCount: incompatible.map((data) => data.file).toSet().length,
          ),
        );
      }
      seenRules[includeNode] = rules;
    }
    return seenRules;
  }

  void _validateRules(
    YamlNode? rules,
    DiagnosticReporter reporter,
    YamlNode? includeNode,
  ) {
    if (rules is! YamlList &&
        rules is! YamlMap &&
        // This handles empty keys like
        // linter:
        //   rules:
        (rules is! YamlScalar || rules.value != null) &&
        // We accept 'null' for triggering `INCOMPATIBLE_LINT_INCLUDED`
        rules != null) {
      return;
    }

    _RuleData? validateRule(YamlScalar node, Object? enabled) {
      var value = node.value;
      if (value is! String) return null;
      if (enabled == null) return null;

      var rule = getRegisteredLint(value);
      if (rule == null) {
        reporter.atSourceSpan(
          node.span,
          AnalysisOptionsWarningCode.undefinedLint,
          arguments: [value],
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

      if (ruleValue is String && validLintStringValues.contains(ruleValue)) {
        enabledValue = ruleValue != ignoreValue;
      } else if (ruleValue is bool) {
        enabledValue = ruleValue;
      } else {
        enabledValue = false;
        var warningNode = enabled is YamlNode ? enabled : node;
        reporter.atSourceSpan(
          warningNode.span,
          AnalysisOptionsWarningCode.unsupportedValue,
          arguments: [
            value,
            ruleValue,
            validLintValues.quotedAndCommaSeparatedWithOr,
          ],
        );
      }

      // Report removed or deprecated lint warnings defined directly (and not in
      // includes).
      if (isPrimarySource) {
        var state = rule.state;
        if (state.isDeprecated && isDeprecatedInCurrentSdk(state)) {
          var replacedBy = state.replacedBy;
          if (replacedBy != null) {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.deprecatedLintWithReplacement,
              arguments: [value, replacedBy],
            );
          } else {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.deprecatedLint,
              arguments: [value],
            );
          }
        } else if (isRemovedInCurrentSdk(state)) {
          var since = state.since.toString();
          var replacedBy = state.replacedBy;
          if (replacedBy != null) {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.replacedLint,
              arguments: [value, since, replacedBy],
            );
          } else {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.removedLint,
              arguments: [value, since],
            );
          }
        }
      }

      return _RuleData(rule, node, isEnabled: enabledValue);
    }

    var activeRules = <YamlScalar>{};
    var disabledRules = <AbstractAnalysisRule>[];
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
        disabledRules.add(rule.rule);
      }
    }

    if (ruleDataList.isNotEmpty) {
      for (var rule in ruleDataList) {
        _processEnabledRule(
          ruleData: rule,
          reporter: reporter,
          rules: {
            null: activeRules,
            if (includeNode != null)
              ..._processIncludes(includeNode, reporter, disabledRules),
          },
        );
        activeRules.add(rule.node);
      }
    } else {
      if (includeNode != null) {
        _processIncludes(includeNode, reporter, disabledRules);
      }
    }
  }
}

class _IncompatibleRuleData {
  final _RuleData ruleData;

  final YamlScalar? file;
  _IncompatibleRuleData(this.ruleData, {this.file});
}

class _RuleData {
  final AbstractAnalysisRule rule;

  final YamlScalar node;
  final bool isEnabled;
  _RuleData(this.rule, this.node, {required this.isEnabled});
}
