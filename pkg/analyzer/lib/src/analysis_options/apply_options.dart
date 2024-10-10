// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/code_style_options.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:yaml/yaml.dart';

extension on YamlNode? {
  bool? get boolValue {
    var self = this;
    if (self is YamlScalar) {
      var value = self.value;
      if (value is bool) {
        return value;
      }
    }
    return null;
  }

  String? get stringValue {
    var self = this;
    if (self is YamlScalar) {
      var value = self.value;
      if (value is String) {
        return value;
      }
    }
    return null;
  }
}

extension on AnalysisOptionsImpl {
  void applyExcludes(YamlNode? excludes) {
    if (excludes is YamlList) {
      // TODO(srawlins): Report non-String items
      excludePatterns = excludes.whereType<String>().toList();
    }
    // TODO(srawlins): Report non-List with
    // AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT.
  }

  void applyLanguageOptions(YamlNode? configs) {
    if (configs is! YamlMap) {
      return;
    }
    configs.nodes.forEach((key, value) {
      if (key is YamlScalar && value is YamlScalar) {
        var feature = key.value?.toString();
        var boolValue = value.boolValue;
        if (boolValue == null) {
          return;
        }

        if (feature == AnalyzerOptions.strictCasts) {
          strictCasts = boolValue;
        }
        if (feature == AnalyzerOptions.strictInference) {
          strictInference = boolValue;
        }
        if (feature == AnalyzerOptions.strictRawTypes) {
          strictRawTypes = boolValue;
        }
      }
    });
  }

  void applyOptionalChecks(YamlNode? config) {
    switch (config) {
      case YamlMap():
        for (var MapEntry(:key, :value) in config.nodes.entries) {
          if (key is YamlScalar && value is YamlScalar) {
            if (value.boolValue case var boolValue?) {
              switch ('${key.value}') {
                case AnalyzerOptions.chromeOsManifestChecks:
                  chromeOsManifestChecks = boolValue;
                case AnalyzerOptions.propagateLinterExceptions:
                  propagateLinterExceptions = boolValue;
              }
            }
          }
        }
      case YamlScalar():
        switch ('${config.value}') {
          case AnalyzerOptions.chromeOsManifestChecks:
            chromeOsManifestChecks = true;
          case AnalyzerOptions.propagateLinterExceptions:
            propagateLinterExceptions = true;
        }
    }
  }

  void applyUnignorables(YamlNode? cannotIgnore) {
    if (cannotIgnore is! YamlList) {
      return;
    }
    var names = <String>{};
    var stringValues = cannotIgnore.whereType<String>().toSet();
    for (var severity in AnalyzerOptions.severities) {
      if (stringValues.contains(severity)) {
        // [severity] is a marker denoting all error codes with severity
        // equal to [severity].
        stringValues.remove(severity);
        // Replace name like 'error' with error codes with this named
        // severity.
        for (var e in errorCodeValues) {
          // If the severity of [error] is also changed in this options file
          // to be [severity], we add [error] to the un-ignorable list.
          var processors =
              errorProcessors.where((processor) => processor.code == e.name);
          if (processors.isNotEmpty &&
              processors.first.severity?.displayName == severity) {
            names.add(e.name);
            continue;
          }
          // Otherwise, add [error] if its default severity is [severity].
          if (e.errorSeverity.displayName == severity) {
            names.add(e.name);
          }
        }
      }
    }
    names.addAll(stringValues.map((name) => name.toUpperCase()));
    unignorableNames = names;
  }

  CodeStyleOptions buildCodeStyleOptions(YamlNode? codeStyle) {
    var useFormatter = false;
    if (codeStyle is YamlMap) {
      var formatNode = codeStyle.valueAt(AnalyzerOptions.format);
      if (formatNode != null) {
        var formatValue = toBool(formatNode);
        if (formatValue is bool) {
          useFormatter = formatValue;
        }
      }
    }
    return CodeStyleOptionsImpl(this, useFormatter: useFormatter);
  }

  FormatterOptions buildFormatterOptions(YamlNode? formatter) {
    int? pageWidth;
    if (formatter is YamlMap) {
      var formatNode = formatter.valueAt(AnalyzerOptions.pageWidth);
      var formatValue = formatNode?.value;
      if (formatValue is int && formatValue > 0) {
        pageWidth = formatValue;
      }
    }
    return FormatterOptions(pageWidth: pageWidth);
  }

  void _applyLegacyPlugins(YamlNode? plugins) {
    var pluginName = plugins.stringValue;
    if (pluginName != null) {
      enabledLegacyPluginNames = [pluginName];
    } else if (plugins is YamlList) {
      for (var element in plugins.nodes) {
        var pluginName = element.stringValue;
        if (pluginName != null) {
          // Only the first legacy plugin is supported.
          enabledLegacyPluginNames = [pluginName];
          return;
        }
      }
    } else if (plugins is YamlMap) {
      for (var key in plugins.nodes.keys.cast<YamlNode?>()) {
        var pluginName = key.stringValue;
        if (pluginName != null) {
          // Only the first legacy plugin is supported.
          enabledLegacyPluginNames = [pluginName];
          return;
        }
      }
    }
  }
}

extension AnalysisOptionsImplExtensions on AnalysisOptionsImpl {
  /// Applies the options in the given [optionMap] to `this` analysis options.
  void applyOptions(YamlMap? optionMap) {
    if (optionMap == null) {
      return;
    }
    var analyzer = optionMap.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      // Process filters.
      var filters = analyzer.valueAt(AnalyzerOptions.errors);
      errorProcessors = ErrorConfig(filters).processors;

      // Process enabled experiments.
      var experimentNames = analyzer.valueAt(AnalyzerOptions.enableExperiment);
      if (experimentNames is YamlList) {
        var enabledExperiments = <String>[];
        for (var element in experimentNames.nodes) {
          var experimentName = element.stringValue;
          if (experimentName != null) {
            enabledExperiments.add(experimentName);
          }
        }
        contextFeatures = FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: ExperimentStatus.currentVersion,
          flags: enabledExperiments,
        );
      }

      // Process optional checks options.
      var optionalChecks = analyzer.valueAt(AnalyzerOptions.optionalChecks);
      applyOptionalChecks(optionalChecks);

      // Process language options.
      var language = analyzer.valueAt(AnalyzerOptions.language);
      applyLanguageOptions(language);

      // Process excludes.
      var excludes = analyzer.valueAt(AnalyzerOptions.exclude);
      applyExcludes(excludes);

      var cannotIgnore = analyzer.valueAt(AnalyzerOptions.cannotIgnore);
      applyUnignorables(cannotIgnore);

      // Process plugins.
      var plugins = analyzer.valueAt(AnalyzerOptions.plugins);
      _applyLegacyPlugins(plugins);
    }

    // Process the 'code-style' option.
    var codeStyle = optionMap.valueAt(AnalyzerOptions.codeStyle);
    codeStyleOptions = buildCodeStyleOptions(codeStyle);

    // Process the 'formatter' option.
    var formatter = optionMap.valueAt(AnalyzerOptions.formatter);
    formatterOptions = buildFormatterOptions(formatter);

    var config = parseConfig(optionMap);
    if (config != null) {
      var enabledRules = Registry.ruleRegistry.enabled(config);
      if (enabledRules.isNotEmpty) {
        lint = true;
        lintRules = enabledRules.toList();
      }
    }
  }
}
