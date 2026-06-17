// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'analysis_options_validator.dart';

/// Validates `analyzer` options.
class _AnalyzerOptionsValidator extends _CompositeValidator {
  _AnalyzerOptionsValidator()
    : super([
        _AnalyzerTopLevelOptionsValidator(),
        _StrongModeOptionValueValidator(),
        _ErrorFilterOptionValidator(),
        _EnableExperimentsValidator(),
        _LanguageOptionValidator(),
        _OptionalChecksValueValidator(),
        _CannotIgnoreOptionValidator(),
      ]);
}

/// Validates `analyzer` top-level options.
class _AnalyzerTopLevelOptionsValidator extends _TopLevelOptionValidator {
  _AnalyzerTopLevelOptionsValidator()
    : super(
        AnalysisOptionsFileKeys.analyzer,
        AnalysisOptionsFileKeys.analyzerOptions,
      );
}

/// Validates the `analyzer` `cannot-ignore` option.
///
/// This includes the format of the `cannot-ignore` section, the format of
/// values in the section, and whether each value is a valid string.
class _CannotIgnoreOptionValidator extends OptionsValidator {
  /// Lazily populated set of diagnostic code names.
  static final Set<String> _diagnosticCodes = diagnosticCodeValues
      .map((DiagnosticCode code) => code.lowerCaseName.toUpperCase())
      .toSet();

  /// The diagnostic code names that existed, but were removed.
  /// We don't want to report these, this breaks clients.
  // TODO(scheglov): https://github.com/flutter/flutter/issues/141576
  static const Set<String> _removedDiagnosticCodes = {'MISSING_RETURN'};

  /// Lazily populated set of lint code names.
  late final Set<String> _lintCodes = Registry.ruleRegistry.rules
      .map((rule) => rule.name.toUpperCase())
      .toSet();

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalysisOptionsFileKeys.analyzer);
    if (analyzer is YamlMap) {
      var unignorableNames = analyzer.valueAt(
        AnalysisOptionsFileKeys.cannotIgnore,
      );
      if (unignorableNames is YamlList) {
        var listedNames = <String>{};
        for (var unignorableNameNode in unignorableNames.nodes) {
          var unignorableName = unignorableNameNode.value;
          if (unignorableName is String) {
            if (AnalysisOptionsFileKeys.severities.contains(unignorableName)) {
              listedNames.add(unignorableName);
              continue;
            }
            var upperCaseName = unignorableName.toUpperCase();
            if (!_diagnosticCodes.contains(upperCaseName) &&
                !_lintCodes.contains(upperCaseName) &&
                !_removedDiagnosticCodes.contains(upperCaseName)) {
              reporter.report(
                diag.unrecognizedErrorCode
                    .withArguments(codeName: unignorableName)
                    .atSourceSpan(unignorableNameNode.span),
              );
            } else if (listedNames.contains(upperCaseName)) {
              // TODO(srawlins): Create a "duplicate value" code and report it
              // here.
            } else {
              listedNames.add(upperCaseName);
            }
          } else {
            reporter.report(
              diag.invalidSectionFormat
                  .withArguments(
                    sectionName: AnalysisOptionsFileKeys.cannotIgnore,
                  )
                  .atSourceSpan(unignorableNameNode.span),
            );
          }
        }
      } else if (unignorableNames != null) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFileKeys.cannotIgnore)
              .atSourceSpan(unignorableNames.span),
        );
      }
    }
  }
}

/// Validates `code-style` options.
class _CodeStyleOptionsValidator extends OptionsValidator {
  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var codeStyle = options.valueAt(AnalysisOptionsFileKeys.codeStyle);
    if (codeStyle is YamlMap) {
      codeStyle.nodeMap.forEach((keyNode, valueNode) {
        var key = keyNode.value;
        if (key == AnalysisOptionsFileKeys.format) {
          _validateFormat(reporter, valueNode);
        } else {
          reporter.report(
            diag.unsupportedOptionWithoutValues
                .withArguments(
                  sectionName: AnalysisOptionsFileKeys.codeStyle,
                  optionKey: keyNode.toString(),
                )
                .atSourceSpan(keyNode.span),
          );
        }
      });
    } else if (codeStyle is YamlScalar && codeStyle.value != null) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.codeStyle)
            .atSourceSpan(codeStyle.span),
      );
    } else if (codeStyle is YamlList) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.codeStyle)
            .atSourceSpan(codeStyle.span),
      );
    }
  }

  void _validateFormat(DiagnosticReporter reporter, YamlNode format) {
    if (format is! YamlScalar) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.format)
            .atSourceSpan(format.span),
      );
      return;
    }
    var formatValue = format.toBool();
    if (formatValue == null) {
      reporter.report(
        diag.unsupportedValue
            .withArguments(
              optionName: AnalysisOptionsFileKeys.format,
              invalidValue: format.value.toString(),
              legalValues: AnalysisOptionsFileKeys.trueOrFalseProposal,
            )
            .atSourceSpan(format.span),
      );
    }
  }
}

/// Convenience class for composing validators.
class _CompositeValidator extends OptionsValidator {
  final List<OptionsValidator> validators;

  _CompositeValidator(this.validators);

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    for (var validator in validators) {
      validator.validate(reporter, options);
    }
  }
}

/// Validates the `analyzer` `enable-experiments` configuration options.
class _EnableExperimentsValidator extends OptionsValidator {
  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalysisOptionsFileKeys.analyzer);
    if (analyzer is YamlMap) {
      var experimentNames = analyzer.valueAt(
        AnalysisOptionsFileKeys.enableExperiment,
      );
      if (experimentNames is YamlList) {
        var flags = experimentNames.nodes
            .map((node) => node.toString())
            .toList();
        for (var validationResult in validateFlags(flags)) {
          var flagIndex = validationResult.stringIndex;
          var span = experimentNames.nodes[flagIndex].span;
          if (validationResult is UnrecognizedFlag) {
            reporter.report(
              diag.unsupportedOptionWithoutValues
                  .withArguments(
                    sectionName: AnalysisOptionsFileKeys.enableExperiment,
                    optionKey: flags[flagIndex],
                  )
                  .atSourceSpan(span),
            );
          } else {
            reporter.report(
              diag.invalidOption
                  .withArguments(
                    optionName: AnalysisOptionsFileKeys.enableExperiment,
                    detailMessage: validationResult.message,
                  )
                  .atSourceSpan(span),
            );
          }
        }
      } else if (experimentNames != null) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(
                sectionName: AnalysisOptionsFileKeys.enableExperiment,
              )
              .atSourceSpan(experimentNames.span),
        );
      }
    }
  }
}

/// Builds error reports with value proposals.
class _ErrorBuilder {
  /// Report an unsupported `node` value, defined in the given `scopeName`.
  void Function(DiagnosticReporter reporter, String scopeName, YamlNode node)
  reportError;

  /// Create a builder for the given [supportedOptions].
  factory _ErrorBuilder(Set<String> supportedOptions) {
    if (supportedOptions.isEmpty) {
      return _ErrorBuilder._(
        reportError: (reporter, scopeName, node) => reporter.report(
          diag.unsupportedOptionWithoutValues
              .withArguments(
                sectionName: scopeName,
                optionKey: node.value.toString(),
              )
              .atSourceSpan(node.span),
        ),
      );
    } else if (supportedOptions.length == 1) {
      return _ErrorBuilder._(
        reportError: (reporter, scopeName, node) => reporter.report(
          diag.unsupportedOptionWithLegalValue
              .withArguments(
                sectionName: scopeName,
                optionKey: node.value.toString(),
                legalValue: supportedOptions.single,
              )
              .atSourceSpan(node.span),
        ),
      );
    } else {
      return _ErrorBuilder._(
        reportError: (reporter, scopeName, node) => reporter.report(
          diag.unsupportedOptionWithLegalValues
              .withArguments(
                sectionName: scopeName,
                optionKey: node.value.toString(),
                legalValues: supportedOptions.quotedAndCommaSeparatedWithAnd,
              )
              .atSourceSpan(node.span),
        ),
      );
    }
  }

  _ErrorBuilder._({required this.reportError});
}

/// Validates `analyzer` error filter options.
class _ErrorFilterOptionValidator extends OptionsValidator {
  /// Legal values.
  static final List<String> legalValues = [
    ...AnalysisOptionsFileKeys.ignoreSynonyms,
    ...AnalysisOptionsFileKeys.trueOrFalse,
    ...AnalysisOptionsFileKeys.severities,
  ];

  /// Pretty String listing legal values.
  static final String legalValueString =
      legalValues.quotedAndCommaSeparatedWithAnd;

  /// Lazily populated set of diagnostic code names.
  static final Set<String> _diagnosticCodes = diagnosticCodeValues
      .map((DiagnosticCode code) => code.lowerCaseName.toUpperCase())
      .toSet();

  /// The diagnostic code names that existed, but were removed.
  /// We don't want to report these, this breaks clients.
  // TODO(scheglov): https://github.com/flutter/flutter/issues/141576
  static const Set<String> _removedDiagnosticCodes = {'MISSING_RETURN'};

  /// Lazily populated set of lint code names.
  late final Set<String> _lintCodes = Registry.ruleRegistry.rules
      .map((rule) => rule.name.toUpperCase())
      .toSet();

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalysisOptionsFileKeys.analyzer);
    if (analyzer is YamlMap) {
      var filters = analyzer.valueAt(AnalysisOptionsFileKeys.errors);
      if (filters is YamlMap) {
        filters.nodes.forEach((k, v) {
          String? value;
          if (k is YamlScalar) {
            value = k.toUpperCase();
            if (!_diagnosticCodes.contains(value) &&
                !_lintCodes.contains(value) &&
                !_removedDiagnosticCodes.contains(value)) {
              reporter.report(
                diag.unrecognizedErrorCode
                    .withArguments(codeName: k.value.toString())
                    .atSourceSpan(k.span),
              );
            }
          }
          if (v is YamlScalar) {
            value = v.toLowerCase();
            if (!legalValues.contains(value)) {
              reporter.report(
                diag.unsupportedOptionWithLegalValues
                    .withArguments(
                      sectionName: AnalysisOptionsFileKeys.errors,
                      optionKey: v.value.toString(),
                      legalValues: legalValueString,
                    )
                    .atSourceSpan(v.span),
              );
            }
          } else {
            reporter.report(
              diag.invalidSectionFormat
                  .withArguments(
                    sectionName: AnalysisOptionsFileKeys.enableExperiment,
                  )
                  .atSourceSpan(v.span),
            );
          }
        });
      } else if (filters != null) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(
                sectionName: AnalysisOptionsFileKeys.enableExperiment,
              )
              .atSourceSpan(filters.span),
        );
      }
    }
  }
}

/// Validates `formatter` options.
class _FormatterOptionsValidator extends OptionsValidator {
  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var formatter = options.valueAt(AnalysisOptionsFileKeys.formatter);
    if (formatter == null) {
      return;
    }

    if (formatter is YamlMap) {
      for (var MapEntry(key: keyNode, value: valueNode)
          in formatter.nodeMap.entries) {
        if (keyNode.value == AnalysisOptionsFileKeys.pageWidth) {
          _validatePageWidth(keyNode, valueNode, reporter);
        } else if (keyNode.value == AnalysisOptionsFileKeys.trailingCommas) {
          _validateTrailingCommas(keyNode, valueNode, reporter);
        } else {
          reporter.report(
            diag.unsupportedOptionWithoutValues
                .withArguments(
                  sectionName: AnalysisOptionsFileKeys.formatter,
                  optionKey: keyNode.toString(),
                )
                .atSourceSpan(keyNode.span),
          );
        }
      }
    } else if (formatter.value != null) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.formatter)
            .atSourceSpan(formatter.span),
      );
    }
  }

  void _validatePageWidth(
    YamlNode keyNode,
    YamlNode valueNode,
    DiagnosticReporter reporter,
  ) {
    var value = valueNode.value;
    if (value is! int || value <= 0) {
      reporter.report(
        diag.invalidOption
            .withArguments(
              optionName: keyNode.toString(),
              detailMessage: '"page_width" must be a positive integer.',
            )
            .atSourceSpan(valueNode.span),
      );
    }
  }

  void _validateTrailingCommas(
    YamlNode keyNode,
    YamlNode valueNode,
    DiagnosticReporter reporter,
  ) {
    var value = valueNode.value;

    if (!TrailingCommas.values.any((item) => item.name == value)) {
      reporter.report(
        diag.invalidOption
            .withArguments(
              optionName: keyNode.toString(),
              detailMessage:
                  '"trailing_commas" must be "automate" or "preserve".',
            )
            .atSourceSpan(valueNode.span),
      );
    }
  }
}

/// Validates `analyzer` language configuration options.
class _LanguageOptionValidator extends OptionsValidator {
  final _ErrorBuilder _builder = _ErrorBuilder(
    AnalysisOptionsFileKeys.languageOptions,
  );

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalysisOptionsFileKeys.analyzer);
    if (analyzer is YamlMap) {
      var language = analyzer.valueAt(AnalysisOptionsFileKeys.language);
      if (language is YamlMap) {
        language.nodes.forEach((k, v) {
          if (k is! YamlScalar) return;
          var key = k.value?.toString();
          if (!AnalysisOptionsFileKeys.languageOptions.contains(key)) {
            _builder.reportError(reporter, AnalysisOptionsFileKeys.language, k);
            return;
          }

          if (v is YamlScalar) {
            var value = v.toBool();
            if (value == null) {
              // `null` is not a valid key, so we can safely assume `key` is
              // non-`null`.
              reporter.report(
                diag.unsupportedValue
                    .withArguments(
                      optionName: key!,
                      invalidValue: v.value.toString(),
                      legalValues: AnalysisOptionsFileKeys.trueOrFalseProposal,
                    )
                    .atSourceSpan(v.span),
              );
            } else if (key == AnalysisOptionsFileKeys.strictRawTypes && value) {
              // TODO(srawlins): Enable once the `no_raw_types` lint rule is
              // available in Flutter main, so that developers have something to
              // migrate to.
              if (1 == 2) {
                reporter.report(
                  diag.analysisOptionDeprecated
                      .withArguments(optionName: key!)
                      .atSourceSpan(k.span),
                );
              }
            }
          }
        });
      } else if (language is YamlScalar && language.value != null) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFileKeys.language)
              .atSourceSpan(language.span),
        );
      } else if (language is YamlList) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFileKeys.language)
              .atSourceSpan(language.span),
        );
      }
    }
  }
}

/// Validates `linter` top-level options.
class _LinterTopLevelOptionsValidator extends _TopLevelOptionValidator {
  _LinterTopLevelOptionsValidator()
    : super(
        AnalysisOptionsFileKeys.linter,
        AnalysisOptionsFileKeys.linterOptions,
      );
}

/// Validates `analyzer` optional-checks value configuration options.
class _OptionalChecksValueValidator extends OptionsValidator {
  final _ErrorBuilder _builder = _ErrorBuilder(
    AnalysisOptionsFileKeys.optionalChecksOptions,
  );

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalysisOptionsFileKeys.analyzer);
    if (analyzer is YamlMap) {
      var v = analyzer.valueAt(AnalysisOptionsFileKeys.optionalChecks);
      if (v is YamlScalar) {
        var value = v.toLowerCase();
        if (!AnalysisOptionsFileKeys.optionalChecksOptions.contains(value)) {
          _builder.reportError(
            reporter,
            AnalysisOptionsFileKeys
                .optionalChecksOptions
                .quotedAndCommaSeparatedWithOr,
            v,
          );
        }
      } else if (v is YamlMap) {
        v.nodes.forEach((k, v) {
          if (k is YamlScalar) {
            var key = k.value?.toString();
            if (!AnalysisOptionsFileKeys.optionalChecksOptions.contains(key)) {
              _builder.reportError(
                reporter,
                AnalysisOptionsFileKeys
                    .optionalChecksOptions
                    .quotedAndCommaSeparatedWithOr,
                k,
              );
            } else {
              if (v is! YamlScalar || v.toBool() == null) {
                reporter.report(
                  diag.unsupportedValue
                      .withArguments(
                        optionName: key!,
                        invalidValue: v.value.toString(),
                        legalValues:
                            AnalysisOptionsFileKeys.trueOrFalseProposal,
                      )
                      .atSourceSpan(v.span),
                );
              }
            }
          }
        });
      } else if (v != null) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(
                sectionName: AnalysisOptionsFileKeys.enableExperiment,
              )
              .atSourceSpan(v.span),
        );
      }
    }
  }
}

final class _OptionsFileValidationResult {
  final _LocalLinterRules linterRules;

  _OptionsFileValidationResult({required this.linterRules});
}

/// Validates one physical analysis options file.
///
/// This class does not follow `include` directives. It reports diagnostics that
/// can be decided from the current file alone and returns the local facts that
/// the include walker needs to validate rules whose meaning depends on the
/// surrounding include graph.
class _OptionsFileValidator {
  late final _LinterRuleOptionsValidator _linterRuleOptionsValidator;
  late final List<OptionsValidator> _validators;

  _OptionsFileValidator(
    File file, {
    VersionConstraint? sdkVersionConstraint,
    required Folder contextRoot,
    required bool isPrimarySource,
  }) {
    _linterRuleOptionsValidator = _LinterRuleOptionsValidator(
      file: file,
      sdkVersionConstraint: sdkVersionConstraint,
      isPrimarySource: isPrimarySource,
    );
    _validators = [
      _AnalyzerOptionsValidator(),
      _CodeStyleOptionsValidator(),
      _FormatterOptionsValidator(),
      _LinterTopLevelOptionsValidator(),
      _linterRuleOptionsValidator,
      _PluginsOptionsValidator(
        contextRoot: contextRoot,
        file: file,
        isPrimarySource: isPrimarySource,
      ),
    ];
  }

  /// Reports single-file diagnostics for [options] and returns local rule data.
  ///
  /// The returned data is intentionally source-preserving: callers use it to
  /// merge linter rule state across includes without losing the YAML nodes that
  /// should appear in context messages.
  _OptionsFileValidationResult validate(
    YamlMap options,
    DiagnosticReporter reporter,
  ) {
    for (var validator in _validators) {
      validator.validate(reporter, options);
    }
    return _OptionsFileValidationResult(
      linterRules: _linterRuleOptionsValidator.localRules,
    );
  }
}

/// Validates options for each `plugins` map value.
class _PluginsOptionsValidator extends OptionsValidator {
  final _ErrorBuilder _builder = _ErrorBuilder(
    AnalysisOptionsFileKeys.pluginsOptions,
  );

  final _ErrorBuilder _gitBuilder = _ErrorBuilder(
    AnalysisOptionsFileKeys.gitOptions,
  );

  final Folder _contextRoot;

  final File _file;

  final bool _isPrimarySource;

  _PluginsOptionsValidator({
    required Folder contextRoot,
    required File file,
    required bool isPrimarySource,
  }) : _contextRoot = contextRoot,
       _file = file,
       _isPrimarySource = isPrimarySource;

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var plugins = options.valueAt(AnalysisOptionsFileKeys.plugins);
    switch (plugins) {
      case YamlMap():
        var isAtContextRoot = _file.parent == _contextRoot;
        if (!isAtContextRoot && _isPrimarySource) {
          reporter.report(
            diag.pluginsInInnerOptions
                .withArguments(contextRoot: _contextRoot.path)
                .atSourceSpan(plugins.span),
          );
        }
        plugins.nodes.forEach((pluginNameNode, pluginValue) {
          if (pluginNameNode is! YamlScalar) {
            return;
          }
          var pluginName = pluginNameNode.value;
          if (pluginName is! String) {
            return;
          }
          if (pluginName == AnalysisOptionsFileKeys.dependencyOverrides) {
            switch (pluginValue) {
              case YamlMap():
                pluginValue.nodes.forEach((
                  overriddenPluginNameNode,
                  overriddenPluginValue,
                ) {
                  if (overriddenPluginNameNode is! YamlScalar) {
                    return;
                  }
                  var overriddenPluginName = overriddenPluginNameNode.value;
                  if (overriddenPluginName is! String) {
                    return;
                  }
                  _validatePlugin(
                    reporter,
                    '${AnalysisOptionsFileKeys.plugins}/${AnalysisOptionsFileKeys.dependencyOverrides}',
                    overriddenPluginName,
                    overriddenPluginValue,
                  );
                });
              default:
                reporter.report(
                  diag.invalidSectionFormat
                      .withArguments(
                        sectionName:
                            '${AnalysisOptionsFileKeys.plugins}/${AnalysisOptionsFileKeys.dependencyOverrides}',
                      )
                      .atSourceSpan(pluginValue.span),
                );
            }
          } else {
            _validatePlugin(
              reporter,
              AnalysisOptionsFileKeys.plugins,
              pluginName,
              pluginValue,
            );
          }
        });
      case YamlList():
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFileKeys.plugins)
              .atSourceSpan(plugins.span),
        );
      case YamlScalar(:var value):
        if (value != null) {
          reporter.report(
            diag.invalidSectionFormat
                .withArguments(sectionName: AnalysisOptionsFileKeys.plugins)
                .atSourceSpan(plugins.span),
          );
        }
    }
  }

  void _validateDiagnostics(
    DiagnosticReporter reporter,
    String pluginPath,
    YamlNode diagnosticsValue,
  ) {
    var sectionName = [
      pluginPath,
      AnalysisOptionsFileKeys.diagnostics,
    ].join('/');
    if (diagnosticsValue is! YamlMap) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: sectionName)
            .atSourceSpan(diagnosticsValue.span),
      );
      return;
    }

    diagnosticsValue.nodes.forEach((codeNameNode, severityNode) {
      // The keys are diagnostic codes.
      if (severityNode is! YamlScalar) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: sectionName)
              .atSourceSpan(severityNode.span),
        );
        return;
      }

      var severity = severityNode.value?.toString().toLowerCase();
      if (!_ErrorFilterOptionValidator.legalValues.contains(severity)) {
        reporter.report(
          diag.unsupportedOptionWithLegalValues
              .withArguments(
                sectionName: sectionName,
                optionKey: severityNode.value.toString(),
                legalValues: _ErrorFilterOptionValidator.legalValueString,
              )
              .atSourceSpan(severityNode.span),
        );
      }
    });
  }

  void _validateGit(
    DiagnosticReporter reporter,
    String pluginPath,
    YamlNode gitValue,
  ) {
    var sectionName = [pluginPath, AnalysisOptionsFileKeys.git].join('/');

    if (gitValue is YamlScalar) {
      if (gitValue.value is! String) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: sectionName)
              .atSourceSpan(gitValue.span),
        );
      }
      return;
    }

    if (gitValue is! YamlMap) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: sectionName)
            .atSourceSpan(gitValue.span),
      );
      return;
    }

    gitValue.nodes.forEach((keyNode, valueNode) {
      if (keyNode case YamlScalar(value: String key)) {
        if (!AnalysisOptionsFileKeys.gitOptions.contains(key)) {
          _gitBuilder.reportError(reporter, sectionName, keyNode);
        } else if (valueNode is! YamlScalar || valueNode.value is! String) {
          reporter.report(
            diag.invalidSectionFormat
                .withArguments(sectionName: '$sectionName/$key')
                .atSourceSpan(valueNode.span),
          );
        }
      }
    });
  }

  void _validatePlugin(
    DiagnosticReporter reporter,
    String parentPath,
    String pluginName,
    YamlNode pluginValue,
  ) {
    var pluginPath = '$parentPath/$pluginName';
    switch (pluginValue) {
      case YamlScalar(value: String()):
        // Valid enough. We could validate that it is a legal VersionConstraint
        // from the pub_semver package.
        break;
      case YamlMap():
        _validatePluginMap(reporter, pluginPath, pluginValue);
      default:
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: pluginPath)
              .atSourceSpan(pluginValue.span),
        );
    }
  }

  void _validatePluginMap(
    DiagnosticReporter reporter,
    String pluginPath,
    YamlMap pluginValue,
  ) {
    pluginValue.nodes.forEach((pluginMapKeyNode, pluginMapValueNode) {
      if (pluginMapKeyNode case YamlScalar(value: String pluginMapKey)) {
        if (pluginMapKey == AnalysisOptionsFileKeys.diagnostics) {
          _validateDiagnostics(reporter, pluginPath, pluginMapValueNode);
        } else if (pluginMapKey == AnalysisOptionsFileKeys.git) {
          _validateGit(reporter, pluginPath, pluginMapValueNode);
        } else if (!AnalysisOptionsFileKeys.pluginsOptions.contains(
          pluginMapKey,
        )) {
          _builder.reportError(reporter, pluginPath, pluginMapKeyNode);
        }
      }
      // TODO(srawlins): Validate 'path' is a YamlScalar.
    });
  }
}

/// Validates `analyzer` strong-mode value configuration options.
class _StrongModeOptionValueValidator extends OptionsValidator {
  final _ErrorBuilder _builder = _ErrorBuilder(
    AnalysisOptionsFileKeys.strongModeOptions,
  );

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalysisOptionsFileKeys.analyzer);
    if (analyzer is YamlMap) {
      var strongModeNode = analyzer.valueAt(AnalysisOptionsFileKeys.strongMode);
      if (strongModeNode is YamlMap) {
        return _validateStrongModeAsMap(reporter, strongModeNode);
      } else if (strongModeNode != null) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFileKeys.strongMode)
              .atSourceSpan(strongModeNode.span),
        );
      }
    }
  }

  void _validateStrongModeAsMap(
    DiagnosticReporter reporter,
    YamlMap strongModeNode,
  ) {
    strongModeNode.nodes.forEach((k, v) {
      if (k is YamlScalar) {
        var key = k.value?.toString();
        if (!AnalysisOptionsFileKeys.strongModeOptions.contains(key)) {
          _builder.reportError(reporter, AnalysisOptionsFileKeys.strongMode, k);
        } else if (key == AnalysisOptionsFileKeys.declarationCasts) {
          reporter.report(
            diag.unsupportedValue
                .withArguments(
                  optionName: AnalysisOptionsFileKeys.strongMode,
                  invalidValue: v.value.toString(),
                  legalValues: AnalysisOptionsFileKeys.trueOrFalseProposal,
                )
                .atSourceSpan(v.span),
          );
        } else {
          // The key is valid.
          if (v is YamlScalar) {
            if (v.toBool() == null) {
              reporter.report(
                diag.unsupportedValue
                    .withArguments(
                      optionName: key!,
                      invalidValue: v.value.toString(),
                      legalValues: AnalysisOptionsFileKeys.trueOrFalseProposal,
                    )
                    .atSourceSpan(v.span),
              );
            }
          }
        }
      }
    });
  }
}

/// Validates top-level options. For example,
///
/// ```yaml
/// analyzer:
///   exclude:
///   - lib/generated/
/// ```
class _TopLevelOptionValidator extends OptionsValidator {
  final String sectionName;
  final Set<String> supportedOptions;
  final String _valueProposal;

  _TopLevelOptionValidator(this.sectionName, this.supportedOptions)
    : assert(supportedOptions.isNotEmpty),
      _valueProposal = supportedOptions.quotedAndCommaSeparatedWithAnd;

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var node = options.valueAt(sectionName);
    if (node == null) return;
    if (node is YamlScalar && node.value == null) return;

    if (node is! YamlMap) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.cannotIgnore)
            .atSourceSpan(node.span),
      );
      return;
    }
    node.nodes.forEach((k, v) {
      if (k is YamlScalar) {
        if (!supportedOptions.contains(k.value)) {
          var optionKey = k.value.toString();
          var locatableDiagnostic = supportedOptions.length == 1
              ? diag.unsupportedOptionWithLegalValue.withArguments(
                  sectionName: sectionName,
                  optionKey: optionKey,
                  legalValue: _valueProposal,
                )
              : diag.unsupportedOptionWithLegalValues.withArguments(
                  sectionName: sectionName,
                  optionKey: optionKey,
                  legalValues: _valueProposal,
                );
          reporter.report(locatableDiagnostic.atSourceSpan(k.span));
        }
      }
      // TODO(pq): consider an error if the node is not a Scalar.
    });
  }
}
