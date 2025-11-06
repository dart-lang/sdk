// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/analysis_options/options_validator.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

List<Diagnostic> analyzeAnalysisOptions(
  Source source,
  String content,
  SourceFactory sourceFactory,
  String contextRoot,
  VersionConstraint? sdkVersionConstraint,
  ResourceProvider resourceProvider,
) {
  List<Diagnostic> errors = [];
  Source initialSource = source;
  SourceSpan? initialIncludeSpan;
  AnalysisOptionsProvider optionsProvider = AnalysisOptionsProvider(
    sourceFactory,
  );
  String? firstPluginName;
  Map<Source, SourceSpan> includeChain = {};

  // TODO(srawlins): This code is getting quite complex, with multiple local
  // functions, and should be refactored to a class maintaining state, with less
  // variable shadowing.
  void addDirectErrorOrIncludedError(
    List<Diagnostic> validationErrors,
    Source source, {
    required bool isSourcePrimary,
  }) {
    if (!isSourcePrimary) {
      // [source] is an included file, and we should only report errors in
      // [initialSource], noting that the included file has warnings.
      for (Diagnostic error in validationErrors) {
        var args = [
          source.fullName,
          error.offset.toString(),
          (error.offset + error.length - 1).toString(),
          error.message,
        ];
        errors.add(
          Diagnostic.tmp(
            source: initialSource,
            offset: initialIncludeSpan!.start.offset,
            length: initialIncludeSpan!.length,
            diagnosticCode: AnalysisOptionsWarningCode.includedFileWarning,
            arguments: args,
          ),
        );
      }
    } else {
      // [source] is the options file for [contextRoot]. Report all errors
      // directly.
      errors.addAll(validationErrors);
    }
  }

  // Validates the specified options and any included option files.
  void validate(Source source, YamlMap options, {required String contextRoot}) {
    var isSourcePrimary = initialIncludeSpan == null;
    var validationErrors = OptionsFileValidator(
      source,
      sdkVersionConstraint: sdkVersionConstraint,
      contextRoot: contextRoot,
      isPrimarySource: isSourcePrimary,
      optionsProvider: optionsProvider,
      sourceFactory: sourceFactory,
      resourceProvider: resourceProvider,
    ).validate(options);
    addDirectErrorOrIncludedError(
      validationErrors,
      source,
      isSourcePrimary: isSourcePrimary,
    );

    var includeNode = options.valueAt(AnalysisOptionsFile.include);
    if (includeNode == null) {
      // Validate the 'plugins' option in [options], understanding that no other
      // options are included.
      addDirectErrorOrIncludedError(
        _validateLegacyPluginsOption(source, options: options),
        source,
        isSourcePrimary: isSourcePrimary,
      );
      return;
    }

    void validateInclude(YamlNode includeNode) {
      var includeSpan = includeNode.span;
      initialIncludeSpan ??= includeSpan;
      var includeUri = includeSpan.text;
      var (first, last) = (
        includeUri.codeUnits.firstOrNull,
        includeUri.codeUnits.lastOrNull,
      );
      if ((first == 0x0022 || first == 0x0027) && first == last) {
        // The URI begins and ends with either a double quote or single quote
        // i.e. the value of the "include" field is quoted.
        includeUri = includeUri.substring(1, includeUri.length - 1);
      }

      var includedSource = sourceFactory.resolveUri(source, includeUri);
      if (includedSource == initialSource) {
        errors.add(
          Diagnostic.tmp(
            source: initialSource,
            offset: initialIncludeSpan!.start.offset,
            length: initialIncludeSpan!.length,
            diagnosticCode: AnalysisOptionsWarningCode.recursiveIncludeFile,
            arguments: [includeUri, source.fullName],
          ),
        );
        return;
      }
      if (includedSource == null || !includedSource.exists()) {
        errors.add(
          Diagnostic.tmp(
            source: initialSource,
            offset: initialIncludeSpan!.start.offset,
            length: initialIncludeSpan!.length,
            diagnosticCode: AnalysisOptionsWarningCode.includeFileNotFound,
            arguments: [includeUri, source.fullName, contextRoot],
          ),
        );
        return;
      }
      var spanInChain = includeChain[includedSource];
      if (spanInChain != null) {
        errors.add(
          Diagnostic.tmp(
            source: initialSource,
            offset: initialIncludeSpan!.start.offset,
            length: initialIncludeSpan!.length,
            diagnosticCode: AnalysisOptionsWarningCode.includedFileWarning,
            arguments: [
              includedSource,
              spanInChain.start.offset,
              spanInChain.length,
              'The file includes itself recursively.',
            ],
          ),
        );
        return;
      }
      includeChain[includedSource] = includeSpan;

      try {
        var includedOptions = optionsProvider.getOptionsFromString(
          includedSource.contents.data,
        );
        validate(includedSource, includedOptions, contextRoot: contextRoot);
        firstPluginName ??= _firstPluginName(includedOptions);
        // Validate the 'plugins' option in [options], taking into account any
        // plugins enabled by [includedOptions].
        addDirectErrorOrIncludedError(
          _validateLegacyPluginsOption(
            source,
            options: options,
            firstEnabledPluginName: firstPluginName,
          ),
          source,
          isSourcePrimary: isSourcePrimary,
        );
      } on OptionsFormatException catch (e) {
        var args = [
          includedSource.fullName,
          e.span!.start.offset.toString(),
          e.span!.end.offset.toString(),
          e.message,
        ];
        // Report errors for included option files on the `include` directive
        // located in the initial options file.
        errors.add(
          Diagnostic.tmp(
            source: initialSource,
            offset: initialIncludeSpan!.start.offset,
            length: initialIncludeSpan!.length,
            diagnosticCode: AnalysisOptionsErrorCode.includedFileParseError,
            arguments: args,
          ),
        );
      }
    }

    var includes = switch (includeNode) {
      YamlScalar node => [node],
      YamlList(:var nodes) => nodes.whereType<YamlScalar>().toList(),
      _ => const <YamlScalar>[],
    };

    for (var includeValue in includes) {
      if (isSourcePrimary) {
        initialIncludeSpan = null;
        includeChain.clear();
      }
      validateInclude(includeValue);
    }
  }

  try {
    YamlMap options = optionsProvider.getOptionsFromString(
      content,
      sourceUrl: source.uri,
    );
    validate(source, options, contextRoot: contextRoot);
  } on OptionsFormatException catch (e) {
    SourceSpan span = e.span!;
    errors.add(
      Diagnostic.tmp(
        source: source,
        offset: span.start.offset,
        length: span.length,
        diagnosticCode: AnalysisOptionsErrorCode.parseError,
        arguments: [e.message],
      ),
    );
  }
  return errors;
}

/// Returns the name of the first legacy plugin, if one is specified in
/// [options], otherwise `null`.
String? _firstPluginName(YamlMap options) {
  var analyzerMap = options.valueAt(AnalysisOptionsFile.analyzer);
  if (analyzerMap is! YamlMap) {
    return null;
  }
  var plugins = analyzerMap.valueAt(AnalysisOptionsFile.plugins);
  if (plugins is YamlScalar) {
    return plugins.value as String?;
  } else if (plugins is YamlList) {
    return plugins.first as String?;
  } else if (plugins is YamlMap) {
    return plugins.keys.first as String?;
  } else {
    return null;
  }
}

/// Validates the legacy 'plugins' options in [options], given
/// [firstEnabledPluginName].
List<Diagnostic> _validateLegacyPluginsOption(
  Source source, {
  required YamlMap options,
  String? firstEnabledPluginName,
}) {
  RecordingDiagnosticListener recorder = RecordingDiagnosticListener();
  DiagnosticReporter reporter = DiagnosticReporter(recorder, source);
  _LegacyPluginsOptionValidator(
    firstEnabledPluginName,
  ).validate(reporter, options);
  return recorder.diagnostics;
}

/// Validates `analyzer` options.
class AnalyzerOptionsValidator extends _CompositeValidator {
  AnalyzerOptionsValidator()
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

/// Validates options defined in an analysis options file.
@visibleForTesting
class OptionsFileValidator {
  /// The source being validated.
  final Source _source;

  final List<OptionsValidator> _validators;

  OptionsFileValidator(
    this._source, {
    VersionConstraint? sdkVersionConstraint,
    required String contextRoot,
    required bool isPrimarySource,
    required AnalysisOptionsProvider optionsProvider,
    required ResourceProvider resourceProvider,
    required SourceFactory sourceFactory,
  }) : _validators = [
         AnalyzerOptionsValidator(),
         _CodeStyleOptionsValidator(),
         _FormatterOptionsValidator(),
         _LinterTopLevelOptionsValidator(),
         LinterRuleOptionsValidator(
           resourceProvider: resourceProvider,
           optionsProvider: optionsProvider,
           sourceFactory: sourceFactory,
           sdkVersionConstraint: sdkVersionConstraint,
           isPrimarySource: isPrimarySource,
         ),
         _PluginsOptionsValidator(
           contextRoot: contextRoot,
           filePath: _source.fullName,
           isPrimarySource: isPrimarySource,
           resourceProvider: resourceProvider,
         ),
       ];

  List<Diagnostic> validate(YamlMap options) {
    RecordingDiagnosticListener recorder = RecordingDiagnosticListener();
    DiagnosticReporter reporter = DiagnosticReporter(recorder, _source);
    for (var validator in _validators) {
      validator.validate(reporter, options);
    }
    return recorder.diagnostics;
  }
}

/// Validates `analyzer` top-level options.
class _AnalyzerTopLevelOptionsValidator extends _TopLevelOptionValidator {
  _AnalyzerTopLevelOptionsValidator()
    : super(AnalysisOptionsFile.analyzer, AnalysisOptionsFile.analyzerOptions);
}

/// Validates the `analyzer` `cannot-ignore` option.
///
/// This includes the format of the `cannot-ignore` section, the format of
/// values in the section, and whether each value is a valid string.
class _CannotIgnoreOptionValidator extends OptionsValidator {
  /// Lazily populated set of diagnostic code names.
  static final Set<String> _diagnosticCodes = diagnosticCodeValues
      .map((DiagnosticCode code) => code.name)
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
    var analyzer = options.valueAt(AnalysisOptionsFile.analyzer);
    if (analyzer is YamlMap) {
      var unignorableNames = analyzer.valueAt(AnalysisOptionsFile.cannotIgnore);
      if (unignorableNames is YamlList) {
        var listedNames = <String>{};
        for (var unignorableNameNode in unignorableNames.nodes) {
          var unignorableName = unignorableNameNode.value;
          if (unignorableName is String) {
            if (AnalysisOptionsFile.severities.contains(unignorableName)) {
              listedNames.add(unignorableName);
              continue;
            }
            var upperCaseName = unignorableName.toUpperCase();
            if (!_diagnosticCodes.contains(upperCaseName) &&
                !_lintCodes.contains(upperCaseName) &&
                !_removedDiagnosticCodes.contains(upperCaseName)) {
              reporter.atSourceSpan(
                unignorableNameNode.span,
                AnalysisOptionsWarningCode.unrecognizedErrorCode,
                arguments: [unignorableName],
              );
            } else if (listedNames.contains(upperCaseName)) {
              // TODO(srawlins): Create a "duplicate value" code and report it
              // here.
            } else {
              listedNames.add(upperCaseName);
            }
          } else {
            reporter.atSourceSpan(
              unignorableNameNode.span,
              AnalysisOptionsWarningCode.invalidSectionFormat,
              arguments: [AnalysisOptionsFile.cannotIgnore],
            );
          }
        }
      } else if (unignorableNames != null) {
        reporter.atSourceSpan(
          unignorableNames.span,
          AnalysisOptionsWarningCode.invalidSectionFormat,
          arguments: [AnalysisOptionsFile.cannotIgnore],
        );
      }
    }
  }
}

/// Validates `code-style` options.
class _CodeStyleOptionsValidator extends OptionsValidator {
  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var codeStyle = options.valueAt(AnalysisOptionsFile.codeStyle);
    if (codeStyle is YamlMap) {
      codeStyle.nodeMap.forEach((keyNode, valueNode) {
        var key = keyNode.value;
        if (key == AnalysisOptionsFile.format) {
          _validateFormat(reporter, valueNode);
        } else {
          reporter.atSourceSpan(
            keyNode.span,
            AnalysisOptionsWarningCode.unsupportedOptionWithoutValues,
            arguments: [AnalysisOptionsFile.codeStyle, keyNode.toString()],
          );
        }
      });
    } else if (codeStyle is YamlScalar && codeStyle.value != null) {
      reporter.atSourceSpan(
        codeStyle.span,
        AnalysisOptionsWarningCode.invalidSectionFormat,
        arguments: [AnalysisOptionsFile.codeStyle],
      );
    } else if (codeStyle is YamlList) {
      reporter.atSourceSpan(
        codeStyle.span,
        AnalysisOptionsWarningCode.invalidSectionFormat,
        arguments: [AnalysisOptionsFile.codeStyle],
      );
    }
  }

  void _validateFormat(DiagnosticReporter reporter, YamlNode format) {
    if (format is! YamlScalar) {
      reporter.atSourceSpan(
        format.span,
        AnalysisOptionsWarningCode.invalidSectionFormat,
        arguments: [AnalysisOptionsFile.format],
      );
      return;
    }
    var formatValue = toBool(format.valueOrThrow);
    if (formatValue == null) {
      reporter.atSourceSpan(
        format.span,
        AnalysisOptionsWarningCode.unsupportedValue,
        arguments: [
          AnalysisOptionsFile.format,
          format.valueOrThrow,
          AnalysisOptionsFile.trueOrFalseProposal,
        ],
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
    var analyzer = options.valueAt(AnalysisOptionsFile.analyzer);
    if (analyzer is YamlMap) {
      var experimentNames = analyzer.valueAt(
        AnalysisOptionsFile.enableExperiment,
      );
      if (experimentNames is YamlList) {
        var flags = experimentNames.nodes
            .map((node) => node.toString())
            .toList();
        for (var validationResult in validateFlags(flags)) {
          var flagIndex = validationResult.stringIndex;
          var span = experimentNames.nodes[flagIndex].span;
          if (validationResult is UnrecognizedFlag) {
            reporter.atSourceSpan(
              span,
              AnalysisOptionsWarningCode.unsupportedOptionWithoutValues,
              arguments: [
                AnalysisOptionsFile.enableExperiment,
                flags[flagIndex],
              ],
            );
          } else {
            reporter.atSourceSpan(
              span,
              AnalysisOptionsWarningCode.invalidOption,
              arguments: [
                AnalysisOptionsFile.enableExperiment,
                validationResult.message,
              ],
            );
          }
        }
      } else if (experimentNames != null) {
        reporter.atSourceSpan(
          experimentNames.span,
          AnalysisOptionsWarningCode.invalidSectionFormat,
          arguments: [AnalysisOptionsFile.enableExperiment],
        );
      }
    }
  }
}

/// Builds error reports with value proposals.
class _ErrorBuilder {
  static AnalysisOptionsWarningCode get noProposalCode =>
      AnalysisOptionsWarningCode.unsupportedOptionWithoutValues;

  static AnalysisOptionsWarningCode get pluralProposalCode =>
      AnalysisOptionsWarningCode.unsupportedOptionWithLegalValues;

  static AnalysisOptionsWarningCode get singularProposalCode =>
      AnalysisOptionsWarningCode.unsupportedOptionWithLegalValue;

  final String proposal;

  final AnalysisOptionsWarningCode code;

  /// Create a builder for the given [supportedOptions].
  factory _ErrorBuilder(Set<String> supportedOptions) {
    var proposal = supportedOptions.quotedAndCommaSeparatedWithAnd;
    if (supportedOptions.isEmpty) {
      return _ErrorBuilder._(proposal: proposal, code: noProposalCode);
    } else if (supportedOptions.length == 1) {
      return _ErrorBuilder._(proposal: proposal, code: singularProposalCode);
    } else {
      return _ErrorBuilder._(proposal: proposal, code: pluralProposalCode);
    }
  }

  _ErrorBuilder._({required this.proposal, required this.code});

  /// Report an unsupported [node] value, defined in the given [scopeName].
  void reportError(
    DiagnosticReporter reporter,
    String scopeName,
    YamlNode node,
  ) {
    if (proposal.isNotEmpty) {
      reporter.atSourceSpan(
        node.span,
        code,
        arguments: [scopeName, node.valueOrThrow, proposal],
      );
    } else {
      reporter.atSourceSpan(
        node.span,
        code,
        arguments: [scopeName, node.valueOrThrow],
      );
    }
  }
}

/// Validates `analyzer` error filter options.
class _ErrorFilterOptionValidator extends OptionsValidator {
  /// Legal values.
  static final List<String> legalValues = [
    ...AnalysisOptionsFile.ignoreSynonyms,
    ...AnalysisOptionsFile.includeSynonyms,
    ...AnalysisOptionsFile.severities,
  ];

  /// Pretty String listing legal values.
  static final String legalValueString =
      legalValues.quotedAndCommaSeparatedWithAnd;

  /// Lazily populated set of diagnostic code names.
  static final Set<String> _diagnosticCodes = diagnosticCodeValues
      .map((DiagnosticCode code) => code.name)
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
    var analyzer = options.valueAt(AnalysisOptionsFile.analyzer);
    if (analyzer is YamlMap) {
      var filters = analyzer.valueAt(AnalysisOptionsFile.errors);
      if (filters is YamlMap) {
        filters.nodes.forEach((k, v) {
          String? value;
          if (k is YamlScalar) {
            value = toUpperCase(k.value);
            if (!_diagnosticCodes.contains(value) &&
                !_lintCodes.contains(value) &&
                !_removedDiagnosticCodes.contains(value)) {
              reporter.atSourceSpan(
                k.span,
                AnalysisOptionsWarningCode.unrecognizedErrorCode,
                arguments: [k.value.toString()],
              );
            }
          }
          if (v is YamlScalar) {
            value = toLowerCase(v.value);
            if (!legalValues.contains(value)) {
              reporter.atSourceSpan(
                v.span,
                AnalysisOptionsWarningCode.unsupportedOptionWithLegalValues,
                arguments: [
                  AnalysisOptionsFile.errors,
                  v.value.toString(),
                  legalValueString,
                ],
              );
            }
          } else {
            reporter.atSourceSpan(
              v.span,
              AnalysisOptionsWarningCode.invalidSectionFormat,
              arguments: [AnalysisOptionsFile.enableExperiment],
            );
          }
        });
      } else if (filters != null) {
        reporter.atSourceSpan(
          filters.span,
          AnalysisOptionsWarningCode.invalidSectionFormat,
          arguments: [AnalysisOptionsFile.enableExperiment],
        );
      }
    }
  }
}

/// Validates `formatter` options.
class _FormatterOptionsValidator extends OptionsValidator {
  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var formatter = options.valueAt(AnalysisOptionsFile.formatter);
    if (formatter == null) {
      return;
    }

    if (formatter is YamlMap) {
      for (var MapEntry(key: keyNode, value: valueNode)
          in formatter.nodeMap.entries) {
        if (keyNode.value == AnalysisOptionsFile.pageWidth) {
          _validatePageWidth(keyNode, valueNode, reporter);
        } else if (keyNode.value == AnalysisOptionsFile.trailingCommas) {
          _validateTrailingCommas(keyNode, valueNode, reporter);
        } else {
          reporter.atSourceSpan(
            keyNode.span,
            AnalysisOptionsWarningCode.unsupportedOptionWithoutValues,
            arguments: [AnalysisOptionsFile.formatter, keyNode.toString()],
          );
        }
      }
    } else if (formatter.value != null) {
      reporter.atSourceSpan(
        formatter.span,
        AnalysisOptionsWarningCode.invalidSectionFormat,
        arguments: [AnalysisOptionsFile.formatter],
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
      reporter.atSourceSpan(
        valueNode.span,
        AnalysisOptionsWarningCode.invalidOption,
        arguments: [
          keyNode.toString(),
          '"page_width" must be a positive integer.',
        ],
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
      reporter.atSourceSpan(
        valueNode.span,
        AnalysisOptionsWarningCode.invalidOption,
        arguments: [
          keyNode.toString(),
          '"trailing_commas" must be "automate" or "preserve".',
        ],
      );
    }
  }
}

/// Validates `analyzer` language configuration options.
class _LanguageOptionValidator extends OptionsValidator {
  final _ErrorBuilder _builder = _ErrorBuilder(
    AnalysisOptionsFile.languageOptions,
  );

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalysisOptionsFile.analyzer);
    if (analyzer is YamlMap) {
      var language = analyzer.valueAt(AnalysisOptionsFile.language);
      if (language is YamlMap) {
        language.nodes.forEach((k, v) {
          String? key, value;
          bool validKey = false;
          if (k is YamlScalar) {
            key = k.value?.toString();
            if (!AnalysisOptionsFile.languageOptions.contains(key)) {
              _builder.reportError(reporter, AnalysisOptionsFile.language, k);
            } else {
              // If we have a valid key, go on and check the value.
              validKey = true;
            }
          }
          if (validKey && v is YamlScalar) {
            value = toLowerCase(v.value);
            // `null` is not a valid key, so we can safely assume `key` is
            // non-`null`.
            if (!AnalysisOptionsFile.trueOrFalse.contains(value)) {
              reporter.atSourceSpan(
                v.span,
                AnalysisOptionsWarningCode.unsupportedValue,
                arguments: [
                  key!,
                  v.valueOrThrow,
                  AnalysisOptionsFile.trueOrFalseProposal,
                ],
              );
            }
          }
        });
      } else if (language is YamlScalar && language.value != null) {
        reporter.atSourceSpan(
          language.span,
          AnalysisOptionsWarningCode.invalidSectionFormat,
          arguments: [AnalysisOptionsFile.language],
        );
      } else if (language is YamlList) {
        reporter.atSourceSpan(
          language.span,
          AnalysisOptionsWarningCode.invalidSectionFormat,
          arguments: [AnalysisOptionsFile.language],
        );
      }
    }
  }
}

/// Validates `analyzer` plugins configuration options.
class _LegacyPluginsOptionValidator extends OptionsValidator {
  /// The name of the first included legacy plugin, if there is one.
  ///
  /// If there are no included legacy plugins, this is `null`.
  final String? _firstIncludedPluginName;

  _LegacyPluginsOptionValidator(this._firstIncludedPluginName);

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalysisOptionsFile.analyzer);
    if (analyzer is! YamlMap) {
      return;
    }
    var plugins = analyzer.valueAt(AnalysisOptionsFile.plugins);
    if (plugins is YamlScalar && plugins.value != null) {
      if (_firstIncludedPluginName != null &&
          _firstIncludedPluginName != plugins.value) {
        reporter.atSourceSpan(
          plugins.span,
          AnalysisOptionsWarningCode.multiplePlugins,
          arguments: [_firstIncludedPluginName],
        );
      }
    } else if (plugins is YamlList) {
      var pluginValues = plugins.nodes.whereType<YamlNode>().toList();
      if (_firstIncludedPluginName != null) {
        // There is already at least one plugin specified in included options.
        for (var plugin in pluginValues) {
          if (plugin.value != _firstIncludedPluginName) {
            reporter.atSourceSpan(
              plugin.span,
              AnalysisOptionsWarningCode.multiplePlugins,
              arguments: [_firstIncludedPluginName],
            );
          }
        }
      } else if (plugins.length > 1) {
        String? firstPlugin;
        for (var plugin in pluginValues) {
          if (firstPlugin == null) {
            var pluginValue = plugin.value;
            if (pluginValue is String) {
              firstPlugin = pluginValue;
              continue;
            } else {
              // This plugin is bad and should not be marked as the first one.
              continue;
            }
          } else if (plugin.value != firstPlugin) {
            reporter.atSourceSpan(
              plugin.span,
              AnalysisOptionsWarningCode.multiplePlugins,
              arguments: [firstPlugin],
            );
          }
        }
      }
    } else if (plugins is YamlMap) {
      var pluginValues = plugins.nodes.keys.cast<YamlNode?>();
      if (_firstIncludedPluginName != null) {
        // There is already at least one plugin specified in included options.
        for (var plugin in pluginValues) {
          if (plugin != null && plugin.value != _firstIncludedPluginName) {
            reporter.atSourceSpan(
              plugin.span,
              AnalysisOptionsWarningCode.multiplePlugins,
              arguments: [_firstIncludedPluginName],
            );
          }
        }
      } else if (plugins.length > 1) {
        String? firstPlugin;
        for (var plugin in pluginValues) {
          if (firstPlugin == null) {
            var pluginValue = plugin?.value;
            if (pluginValue is String) {
              firstPlugin = pluginValue;
              continue;
            } else {
              // This plugin is bad and should not be marked as the first one.
              continue;
            }
          } else if (plugin != null && plugin.value != firstPlugin) {
            reporter.atSourceSpan(
              plugin.span,
              AnalysisOptionsWarningCode.multiplePlugins,
              arguments: [firstPlugin],
            );
          }
        }
      }
    }
  }
}

/// Validates `linter` top-level options.
class _LinterTopLevelOptionsValidator extends _TopLevelOptionValidator {
  _LinterTopLevelOptionsValidator()
    : super(AnalysisOptionsFile.linter, AnalysisOptionsFile.linterOptions);
}

/// Validates `analyzer` optional-checks value configuration options.
class _OptionalChecksValueValidator extends OptionsValidator {
  final _ErrorBuilder _builder = _ErrorBuilder(
    AnalysisOptionsFile.optionalChecksOptions,
  );

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalysisOptionsFile.analyzer);
    if (analyzer is YamlMap) {
      var v = analyzer.valueAt(AnalysisOptionsFile.optionalChecks);
      if (v is YamlScalar) {
        var value = toLowerCase(v.value);
        if (value != AnalysisOptionsFile.chromeOsManifestChecks) {
          _builder.reportError(
            reporter,
            AnalysisOptionsFile.chromeOsManifestChecks,
            v,
          );
        }
      } else if (v is YamlMap) {
        v.nodes.forEach((k, v) {
          String? key, value;
          if (k is YamlScalar) {
            key = k.value?.toString();
            if (key != AnalysisOptionsFile.chromeOsManifestChecks) {
              _builder.reportError(
                reporter,
                AnalysisOptionsFile.chromeOsManifestChecks,
                k,
              );
            } else {
              value = toLowerCase(v.value);
              if (!AnalysisOptionsFile.trueOrFalse.contains(value)) {
                reporter.atSourceSpan(
                  v.span,
                  AnalysisOptionsWarningCode.unsupportedValue,
                  arguments: [
                    key!,
                    v.valueOrThrow,
                    AnalysisOptionsFile.trueOrFalseProposal,
                  ],
                );
              }
            }
          }
        });
      } else if (v != null) {
        reporter.atSourceSpan(
          v.span,
          AnalysisOptionsWarningCode.invalidSectionFormat,
          arguments: [AnalysisOptionsFile.enableExperiment],
        );
      }
    }
  }
}

/// Validates options for each `plugins` map value.
class _PluginsOptionsValidator extends OptionsValidator {
  final _ErrorBuilder _builder = _ErrorBuilder(
    AnalysisOptionsFile.pluginsOptions,
  );

  final String _contextRoot;

  final String _filePath;

  final bool _isPrimarySource;

  final ResourceProvider _resourceProvider;

  _PluginsOptionsValidator({
    required String contextRoot,
    required String filePath,
    required bool isPrimarySource,
    required ResourceProvider resourceProvider,
  }) : _contextRoot = contextRoot,
       _filePath = filePath,
       _isPrimarySource = isPrimarySource,
       _resourceProvider = resourceProvider;

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var plugins = options.valueAt(AnalysisOptionsFile.plugins);
    switch (plugins) {
      case YamlMap():
        var sourceDir = _resourceProvider.pathContext.dirname(_filePath);
        var isAtContextRoot = sourceDir == _contextRoot;
        if (!isAtContextRoot && _isPrimarySource) {
          reporter.atSourceSpan(
            plugins.span,
            AnalysisOptionsWarningCode.pluginsInInnerOptions,
            arguments: [_contextRoot],
          );
        }
        plugins.nodes.forEach((pluginName, pluginValue) {
          if (pluginName is! String) {
            return;
          }
          switch (pluginValue) {
            case YamlScalar(value: String()):
              // Valid enough. We could validate that it is a legal VersionConstraint
              // from the pub_semver package.
              break;
            case YamlMap():
              _validatePluginMap(reporter, pluginName, pluginValue);
            default:
              reporter.atSourceSpan(
                plugins.span,
                AnalysisOptionsWarningCode.invalidSectionFormat,
                arguments: ['${AnalysisOptionsFile.plugins}/$pluginName'],
              );
          }
        });
      case YamlList():
        reporter.atSourceSpan(
          plugins.span,
          AnalysisOptionsWarningCode.invalidSectionFormat,
          arguments: [AnalysisOptionsFile.plugins],
        );
      case YamlScalar(:var value):
        if (value != null) {
          reporter.atSourceSpan(
            plugins.span,
            AnalysisOptionsWarningCode.invalidSectionFormat,
            arguments: [AnalysisOptionsFile.plugins],
          );
        }
    }
  }

  void _validatePluginMap(
    DiagnosticReporter reporter,
    String pluginName,
    YamlMap pluginValue,
  ) {
    pluginValue.nodes.forEach((pluginMapKeyNode, pluginMapValueNode) {
      if (pluginMapKeyNode case YamlScalar(value: String pluginMapKey)) {
        if (!AnalysisOptionsFile.pluginsOptions.contains(pluginMapKey)) {
          _builder.reportError(
            reporter,
            '${AnalysisOptionsFile.plugins}/$pluginName',
            pluginMapKeyNode,
          );
        }
      }
      // TODO(srawlins): Validate 'path' is a YamlScalar.
      // TODO(srawlins): Validate 'git' value is a YamlScalar. Change when
      // supporting refs.
    });
  }
}

/// Validates `analyzer` strong-mode value configuration options.
class _StrongModeOptionValueValidator extends OptionsValidator {
  final _ErrorBuilder _builder = _ErrorBuilder(
    AnalysisOptionsFile.strongModeOptions,
  );

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalysisOptionsFile.analyzer);
    if (analyzer is YamlMap) {
      var strongModeNode = analyzer.valueAt(AnalysisOptionsFile.strongMode);
      if (strongModeNode is YamlMap) {
        return _validateStrongModeAsMap(reporter, strongModeNode);
      } else if (strongModeNode != null) {
        reporter.atSourceSpan(
          strongModeNode.span,
          AnalysisOptionsWarningCode.invalidSectionFormat,
          arguments: [AnalysisOptionsFile.strongMode],
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
        if (!AnalysisOptionsFile.strongModeOptions.contains(key)) {
          _builder.reportError(reporter, AnalysisOptionsFile.strongMode, k);
        } else if (key == AnalysisOptionsFile.declarationCasts) {
          reporter.atSourceSpan(
            v.span,
            AnalysisOptionsWarningCode.unsupportedValue,
            arguments: [
              AnalysisOptionsFile.strongMode,
              v.valueOrThrow,
              AnalysisOptionsFile.trueOrFalseProposal,
            ],
          );
        } else {
          // The key is valid.
          if (v is YamlScalar) {
            var value = toLowerCase(v.value);
            if (!AnalysisOptionsFile.trueOrFalse.contains(value)) {
              reporter.atSourceSpan(
                v.span,
                AnalysisOptionsWarningCode.unsupportedValue,
                arguments: [
                  key!,
                  v.valueOrThrow,
                  AnalysisOptionsFile.trueOrFalseProposal,
                ],
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
  final AnalysisOptionsWarningCode _warningCode;

  _TopLevelOptionValidator(this.sectionName, this.supportedOptions)
    : assert(supportedOptions.isNotEmpty),
      _valueProposal = supportedOptions.quotedAndCommaSeparatedWithAnd,
      _warningCode = supportedOptions.length == 1
          ? AnalysisOptionsWarningCode.unsupportedOptionWithLegalValue
          : AnalysisOptionsWarningCode.unsupportedOptionWithLegalValues;

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var node = options.valueAt(sectionName);
    if (node == null) return;
    if (node is YamlScalar && node.value == null) return;

    if (node is! YamlMap) {
      reporter.atSourceSpan(
        node.span,
        AnalysisOptionsWarningCode.invalidSectionFormat,
        arguments: [AnalysisOptionsFile.cannotIgnore],
      );
      return;
    }
    node.nodes.forEach((k, v) {
      if (k is YamlScalar) {
        if (!supportedOptions.contains(k.value)) {
          reporter.atSourceSpan(
            k.span,
            _warningCode,
            arguments: [sectionName, k.valueOrThrow, _valueProposal],
          );
        }
      }
      // TODO(pq): consider an error if the node is not a Scalar.
    });
  }
}
