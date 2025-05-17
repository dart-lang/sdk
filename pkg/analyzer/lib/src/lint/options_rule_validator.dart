// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/state.dart';
import 'package:analyzer/src/plugin/options.dart';
import 'package:analyzer/src/util/yaml.dart';
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

  final VersionConstraint? sdkVersionConstraint;
  final bool sourceIsOptionsForContextRoot;
  final AnalysisOptionsProvider optionsProvider;
  final ResourceProvider resourceProvider;

  LinterRuleOptionsValidator({
    required this.resourceProvider,
    required this.optionsProvider,
    this.sdkVersionConstraint,
    this.sourceIsOptionsForContextRoot = true,
  });

  bool currentSdkAllows(Version? since) {
    if (since == null) return true;
    var sdk = sdkVersionConstraint;
    if (sdk == null) return false;
    return sdk.allows(since);
  }

  AbstractAnalysisRule? getRegisteredLint(Object value) => Registry
      .ruleRegistry
      .rules
      .firstWhereOrNull((rule) => rule.name == value);

  bool isDeprecatedInCurrentSdk(DeprecatedState state) =>
      currentSdkAllows(state.since);

  bool isRemovedInCurrentSdk(State state) {
    if (state is! RemovedState) return false;
    return currentSdkAllows(state.since);
  }

  @override
  List<Diagnostic> validate(ErrorReporter reporter, YamlMap options) {
    var includeRules = <YamlScalar, Set<String>>{};
    var node = options.valueAt(linter);

    var includeNode = options.valueAt(includeKey);
    if (includeNode != null) {
      includeRules = _processIncludes(includeNode, reporter);
    }

    if (node is YamlMap) {
      var rules = node.valueAt(rulesKey);
      _validateRules(rules, reporter, includeRules);
    }
    return const [];
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

  Set<String> _collectRules(YamlNode? rules) {
    var includeRules = <String>{};
    if (rules is YamlList) {
      for (var ruleNode in rules.nodes) {
        var value = ruleNode.value;
        if (value != null) {
          var rule = getRegisteredLint(value as Object);
          if (rule != null) {
            includeRules.add(rule.name);
          }
        }
      }
    } else if (rules is YamlMap) {
      for (var entry in rules.nodeMap.entries) {
        var value = entry.key.value as Object?;
        if (value == null) {
          continue;
        }
        var enabled = entry.value.value;
        if (enabled is! bool) {
          continue;
        }
        if (enabled) {
          var rule = getRegisteredLint(value);
          if (rule != null) {
            includeRules.add(rule.name);
          }
        }
      }
    }
    return includeRules;
  }

  /// Returns the first rule that is incompatible with the given [rule].
  ///
  /// If the rule is found in the [activeRules] set, it returns the rule name
  /// and null for the file path.
  ///
  /// If the rule is found in the [includeRules] map, it returns the file path
  /// and the rule name.
  (YamlScalar?, String)? _findIncompatibleRule(
    AbstractAnalysisRule rule, {
    required Set<String> activeRules,
    required Map<YamlScalar, Set<String>> includeRules,
  }) {
    for (var incompatibleRule in rule.incompatibleRules) {
      if (activeRules.contains(incompatibleRule)) {
        return (null, incompatibleRule);
      }
      for (var MapEntry(key: filePath, value: rules) in includeRules.entries) {
        if (rules.contains(incompatibleRule)) {
          return (filePath, incompatibleRule);
        }
      }
    }
    return null;
  }

  Map<YamlScalar, Set<String>> _processIncludes(
    YamlNode includeNode,
    ErrorReporter reporter,
  ) {
    var seenRules = <YamlScalar, Set<String>>{};
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
        file = resourceProvider.getFile(fromUri(pathStr));
      } catch (_) {
        // if files are invalid, we ignore them
        continue;
      }
      var includedOptions = optionsProvider.getOptionsFromFile(file);
      var linterNode = includedOptions.valueAt(linter);
      if (linterNode is YamlMap) {
        var rulesNode = linterNode.valueAt(rulesKey);
        var rules = _collectRules(rulesNode);
        AbstractAnalysisRule? lintRule;
        YamlScalar? filePath;
        String? incompatible;
        for (var rule in rules) {
          lintRule = getRegisteredLint(rule);
          if (lintRule == null) {
            continue;
          }
          var record = _findIncompatibleRule(
            lintRule,
            activeRules: {},
            includeRules: seenRules,
          );
          if (record != null) {
            filePath = record.$1!;
            incompatible = record.$2;
            break;
          }
        }
        if (filePath != null && incompatible != null && lintRule != null) {
          // Report the first incompatible rule found.
          reporter.reportError(
            diagnosticFactory.incompatibleIncludedLint(
              source: FileSource(
                resourceProvider.getFile(
                  includeNode.span.sourceUrl!.toFilePath(),
                ),
              ),
              referenceRule: lintRule.name,
              incompatibleRule: incompatible,
              reference: includeNode,
              incompatible: filePath,
            ),
          );
        }
        seenRules[includeNode] = rules;
      }
    }
    return seenRules;
  }

  void _validateRules(
    YamlNode? rules,
    ErrorReporter reporter,
    Map<YamlScalar, Set<String>> includeRules,
  ) {
    var activeRules = <String>{};

    void validateRule(YamlNode node, Object? enabled) {
      var value = node.value;
      if (value == null) return;
      if (enabled == null) return;

      var rule = getRegisteredLint(value as Object);
      if (rule == null) {
        reporter.atSourceSpan(
          node.span,
          AnalysisOptionsWarningCode.UNDEFINED_LINT,
          arguments: [value],
        );
        return;
      }

      Object? enabledValue;
      if (enabled is YamlNode) {
        enabledValue = enabled.value;
      } else if (enabled is bool) {
        enabledValue = enabled;
      }

      if (enabledValue == null) {
        return;
      }

      if (enabledValue is! bool) {
        var warningNode = enabled is YamlNode ? enabled : node;
        reporter.atSourceSpan(
          warningNode.span,
          AnalysisOptionsWarningCode.UNSUPPORTED_VALUE,
          arguments: [value, enabledValue, "'true' or 'false'"],
        );
        return;
      }

      if (enabledValue) {
        var incompatible = _findIncompatibleRule(
          rule,
          activeRules: activeRules,
          includeRules: includeRules,
        );
        if (incompatible != null) {
          var (filePath, incompatibleRule) = incompatible;
          if (filePath == null) {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.INCOMPATIBLE_LINT,
              arguments: [value, incompatibleRule],
            );
          } else {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.INCOMPATIBLE_LINT_FILE,
              arguments: [value, incompatibleRule, filePath.toString()],
            );
          }
        } else if (!activeRules.add(rule.name)) {
          reporter.atSourceSpan(
            node.span,
            AnalysisOptionsWarningCode.DUPLICATE_RULE,
            arguments: [value],
          );
        }
      }
      // Report removed or deprecated lint warnings defined directly (and not in
      // includes).
      if (sourceIsOptionsForContextRoot) {
        var state = rule.state;
        if (state is DeprecatedState && isDeprecatedInCurrentSdk(state)) {
          var replacedBy = state.replacedBy;
          if (replacedBy != null) {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.DEPRECATED_LINT_WITH_REPLACEMENT,
              arguments: [value, replacedBy],
            );
          } else {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.DEPRECATED_LINT,
              arguments: [value],
            );
          }
        } else if (isRemovedInCurrentSdk(state)) {
          var since = state.since.toString();
          var replacedBy = (state as RemovedState).replacedBy;
          if (replacedBy != null) {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.REPLACED_LINT,
              arguments: [value, since, replacedBy],
            );
          } else {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.REMOVED_LINT,
              arguments: [value, since],
            );
          }
        }
      }
    }

    if (rules is YamlList) {
      for (var ruleNode in rules.nodes) {
        validateRule(ruleNode, true);
      }
    } else if (rules is YamlMap) {
      for (var MapEntry(:key, :value) in rules.nodeMap.entries) {
        validateRule(key, value);
      }
    }
  }
}
