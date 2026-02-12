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
import 'package:analyzer/src/analysis_options/options_validator.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/source.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

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
void _validateLegacyPluginsOption(
  DiagnosticReporter diagnosticReporter, {
  required YamlMap options,
  String? firstEnabledPluginName,
}) {
  _LegacyPluginsOptionValidator(
    firstEnabledPluginName,
  ).validate(diagnosticReporter, options);
}

class AnalysisOptionsAnalyzer {
  RecordingDiagnosticListener initialDiagnosticListener =
      RecordingDiagnosticListener();
  DiagnosticReporter initialDiagnosticReporter;
  DiagnosticListener diagnosticListener;
  DiagnosticReporter diagnosticReporter;
  final SourceFactory sourceFactory;
  final String contextRoot;
  final VersionConstraint? sdkVersionConstraint;
  final ResourceProvider resourceProvider;
  SourceSpan? initialIncludeSpan;
  final AnalysisOptionsProvider optionsProvider;
  String? firstPluginName;

  /// Map whose keys are source files that were reached via `include`
  /// directives, and whose values are the corresponding [SourceSpan]s of those
  /// `include` directives.
  final Map<Source, SourceSpan> includeChain = {};

  factory AnalysisOptionsAnalyzer({
    required Source initialSource,
    required SourceFactory sourceFactory,
    required String contextRoot,
    required VersionConstraint? sdkVersionConstraint,
    required ResourceProvider resourceProvider,
  }) {
    var initialDiagnosticListener = RecordingDiagnosticListener();
    var initialDiagnosticReporter = DiagnosticReporter(
      initialDiagnosticListener,
      initialSource,
    );
    return AnalysisOptionsAnalyzer._(
      initialDiagnosticListener: initialDiagnosticListener,
      initialDiagnosticReporter: initialDiagnosticReporter,
      diagnosticListener: initialDiagnosticListener,
      diagnosticReporter: initialDiagnosticReporter,
      sourceFactory: sourceFactory,
      contextRoot: contextRoot,
      sdkVersionConstraint: sdkVersionConstraint,
      resourceProvider: resourceProvider,
      optionsProvider: AnalysisOptionsProvider(sourceFactory),
    );
  }

  AnalysisOptionsAnalyzer._({
    required this.initialDiagnosticListener,
    required this.initialDiagnosticReporter,
    required this.diagnosticListener,
    required this.diagnosticReporter,
    required this.sourceFactory,
    required this.contextRoot,
    required this.sdkVersionConstraint,
    required this.resourceProvider,
    required this.optionsProvider,
  });

  Source get initialSource => initialDiagnosticReporter.source;

  /// Whether the source file currently being visited is the initial source
  /// file.
  bool get isPrimarySource => source == initialSource;

  Source get source => diagnosticReporter.source;

  List<Diagnostic> walkIncludes({required String content}) {
    try {
      YamlMap options = optionsProvider.getOptionsFromString(
        content,
        sourceUrl: initialSource.uri,
      );
      _validate(options);
    } on OptionsFormatException catch (e) {
      SourceSpan span = e.span!;
      diagnosticReporter.report(
        diag.parseError
            .withArguments(errorMessage: e.message)
            .atSourceSpan(span),
      );
    }
    // Make sure `initialIncludeSpan`, `source`, `includeChain`,
    // `diagnosticListener`, and `diagnosticReporter` have been restored to
    // their original states.
    assert(initialIncludeSpan == null);
    assert(identical(source, initialSource));
    assert(includeChain.isEmpty);
    assert(identical(diagnosticListener, initialDiagnosticListener));
    assert(identical(diagnosticReporter, initialDiagnosticReporter));
    return initialDiagnosticListener.diagnostics;
  }

  // Validates the specified options and any included option files.
  void _validate(YamlMap options) {
    OptionsFileValidator(
      source,
      sdkVersionConstraint: sdkVersionConstraint,
      contextRoot: contextRoot,
      isPrimarySource: isPrimarySource,
      optionsProvider: optionsProvider,
      sourceFactory: sourceFactory,
      resourceProvider: resourceProvider,
    ).validate(options, diagnosticReporter);

    var includeNode = options.valueAt(AnalysisOptionsFile.include);
    if (includeNode == null) {
      // Validate the 'plugins' option in [options], understanding that no other
      // options are included.
      _validateLegacyPluginsOption(diagnosticReporter, options: options);
      return;
    }

    var includes = switch (includeNode) {
      YamlScalar node => [node],
      YamlList(:var nodes) => nodes.whereType<YamlScalar>().toList(),
      _ => const <YamlScalar>[],
    };

    for (var includeValue in includes) {
      var previousInitialIncludeSpan = initialIncludeSpan;
      try {
        var includeSpan = includeValue.span;
        initialIncludeSpan ??= includeSpan;
        _validateInclude(options, includeSpan);
      } finally {
        initialIncludeSpan = previousInitialIncludeSpan;
      }
    }
  }

  void _validateInclude(YamlMap options, SourceSpan includeSpan) {
    assert(initialIncludeSpan != null);
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
      initialDiagnosticReporter.report(
        diag.recursiveIncludeFile
            .withArguments(
              includedUri: includeUri,
              includingFilePath: source.fullName,
            )
            .atSourceSpan(initialIncludeSpan!),
      );
      return;
    }
    if (includedSource == null || !includedSource.exists()) {
      initialDiagnosticReporter.report(
        diag.includeFileNotFound
            .withArguments(
              includedUri: includeUri,
              includingFilePath: source.fullName,
              contextRootPath: contextRoot,
            )
            .atSourceSpan(initialIncludeSpan!),
      );
      return;
    }
    var spanInChain = includeChain[includedSource];
    if (spanInChain != null) {
      initialDiagnosticReporter.report(
        diag.includedFileWarning
            .withArguments(
              includingFilePath: includedSource,
              startOffset: spanInChain.start.offset,
              // TODO(paulberry): this is wrong (length != endOffset)
              endOffset: spanInChain.length,
              warningMessage: 'The file includes itself recursively.',
            )
            .atSourceSpan(initialIncludeSpan!),
      );
      return;
    }

    try {
      var includedOptions = optionsProvider.getOptionsFromString(
        includedSource.stringContents,
      );
      var previousDiagnosticListener = diagnosticListener;
      var previousDiagnosticReporter = diagnosticReporter;
      try {
        diagnosticListener = _IncludedDiagnosticListener(
          source: includedSource,
          initialDiagnosticReporter: initialDiagnosticReporter,
          initialIncludeSpan: initialIncludeSpan!,
        );
        diagnosticReporter = DiagnosticReporter(
          diagnosticListener,
          includedSource,
        );
        includeChain[includedSource] = includeSpan;
        _validate(includedOptions);
      } finally {
        diagnosticListener = previousDiagnosticListener;
        diagnosticReporter = previousDiagnosticReporter;
        includeChain.remove(includedSource);
      }
      firstPluginName ??= _firstPluginName(includedOptions);
      // Validate the 'plugins' option in [options], taking into account any
      // plugins enabled by [includedOptions].
      _validateLegacyPluginsOption(
        diagnosticReporter,
        options: options,
        firstEnabledPluginName: firstPluginName,
      );
    } on OptionsFormatException catch (e) {
      // Report diagnostics for included option files on the `include` directive
      // located in the initial options file.
      initialDiagnosticReporter.report(
        diag.includedFileParseError
            .withArguments(
              includingFilePath: includedSource.fullName,
              startOffset: e.span!.start.offset,
              endOffset: e.span!.end.offset,
              errorMessage: e.message,
            )
            .atSourceSpan(initialIncludeSpan!),
      );
    }
  }
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
  final List<OptionsValidator> _validators;

  OptionsFileValidator(
    Source source, {
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
           filePath: source.fullName,
           isPrimarySource: isPrimarySource,
           resourceProvider: resourceProvider,
         ),
       ];

  void validate(YamlMap options, DiagnosticReporter reporter) {
    for (var validator in _validators) {
      validator.validate(reporter, options);
    }
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
                  .withArguments(sectionName: AnalysisOptionsFile.cannotIgnore)
                  .atSourceSpan(unignorableNameNode.span),
            );
          }
        }
      } else if (unignorableNames != null) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFile.cannotIgnore)
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
    var codeStyle = options.valueAt(AnalysisOptionsFile.codeStyle);
    if (codeStyle is YamlMap) {
      codeStyle.nodeMap.forEach((keyNode, valueNode) {
        var key = keyNode.value;
        if (key == AnalysisOptionsFile.format) {
          _validateFormat(reporter, valueNode);
        } else {
          reporter.report(
            diag.unsupportedOptionWithoutValues
                .withArguments(
                  sectionName: AnalysisOptionsFile.codeStyle,
                  optionKey: keyNode.toString(),
                )
                .atSourceSpan(keyNode.span),
          );
        }
      });
    } else if (codeStyle is YamlScalar && codeStyle.value != null) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFile.codeStyle)
            .atSourceSpan(codeStyle.span),
      );
    } else if (codeStyle is YamlList) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFile.codeStyle)
            .atSourceSpan(codeStyle.span),
      );
    }
  }

  void _validateFormat(DiagnosticReporter reporter, YamlNode format) {
    if (format is! YamlScalar) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFile.format)
            .atSourceSpan(format.span),
      );
      return;
    }
    var formatValue = toBool(format.valueOrThrow);
    if (formatValue == null) {
      reporter.report(
        diag.unsupportedValue
            .withArguments(
              optionName: AnalysisOptionsFile.format,
              invalidValue: format.valueOrThrow,
              legalValues: AnalysisOptionsFile.trueOrFalseProposal,
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
            reporter.report(
              diag.unsupportedOptionWithoutValues
                  .withArguments(
                    sectionName: AnalysisOptionsFile.enableExperiment,
                    optionKey: flags[flagIndex],
                  )
                  .atSourceSpan(span),
            );
          } else {
            reporter.report(
              diag.invalidOption
                  .withArguments(
                    optionName: AnalysisOptionsFile.enableExperiment,
                    detailMessage: validationResult.message,
                  )
                  .atSourceSpan(span),
            );
          }
        }
      } else if (experimentNames != null) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFile.enableExperiment)
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
                optionKey: node.valueOrThrow.toString(),
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
                optionKey: node.valueOrThrow.toString(),
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
                optionKey: node.valueOrThrow.toString(),
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
    ...AnalysisOptionsFile.ignoreSynonyms,
    ...AnalysisOptionsFile.includeSynonyms,
    ...AnalysisOptionsFile.severities,
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
              reporter.report(
                diag.unrecognizedErrorCode
                    .withArguments(codeName: k.value.toString())
                    .atSourceSpan(k.span),
              );
            }
          }
          if (v is YamlScalar) {
            value = toLowerCase(v.value);
            if (!legalValues.contains(value)) {
              reporter.report(
                diag.unsupportedOptionWithLegalValues
                    .withArguments(
                      sectionName: AnalysisOptionsFile.errors,
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
                    sectionName: AnalysisOptionsFile.enableExperiment,
                  )
                  .atSourceSpan(v.span),
            );
          }
        });
      } else if (filters != null) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFile.enableExperiment)
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
          reporter.report(
            diag.unsupportedOptionWithoutValues
                .withArguments(
                  sectionName: AnalysisOptionsFile.formatter,
                  optionKey: keyNode.toString(),
                )
                .atSourceSpan(keyNode.span),
          );
        }
      }
    } else if (formatter.value != null) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFile.formatter)
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

/// Implementation of [DiagnosticListener] that converts each reported
/// [Diagnostic] into a [diag.includedFileWarning] located at the site of an
/// `include` directive.
///
/// This is used by [AnalysisOptionsAnalyzer] to report diagnostics that occur
/// in included options files.
class _IncludedDiagnosticListener implements DiagnosticListener {
  /// The [Source] file in which diagnostics are being reported.
  final Source source;

  /// The [DiagnosticReporter] for the initial soure file (the one containing
  /// the first `include` in the chain of `include`s that's currently being
  /// processed).
  final DiagnosticReporter initialDiagnosticReporter;

  /// The [SourceSpan] of the first `include` in the chain of `include`s that's
  /// currently being processed.
  final SourceSpan initialIncludeSpan;

  _IncludedDiagnosticListener({
    required this.source,
    required this.initialDiagnosticReporter,
    required this.initialIncludeSpan,
  });

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    initialDiagnosticReporter.report(
      diag.includedFileWarning
          .withArguments(
            includingFilePath: source.fullName,
            startOffset: diagnostic.offset,
            endOffset: diagnostic.offset + diagnostic.length - 1,
            warningMessage: diagnostic.message,
          )
          .atSourceSpan(initialIncludeSpan),
    );
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
              reporter.report(
                diag.unsupportedValue
                    .withArguments(
                      optionName: key!,
                      invalidValue: v.valueOrThrow,
                      legalValues: AnalysisOptionsFile.trueOrFalseProposal,
                    )
                    .atSourceSpan(v.span),
              );
            }
          }
        });
      } else if (language is YamlScalar && language.value != null) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFile.language)
              .atSourceSpan(language.span),
        );
      } else if (language is YamlList) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFile.language)
              .atSourceSpan(language.span),
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
        reporter.report(
          diag.multiplePlugins
              .withArguments(firstPluginName: _firstIncludedPluginName)
              .atSourceSpan(plugins.span),
        );
      }
    } else if (plugins is YamlList) {
      var pluginValues = plugins.nodes.whereType<YamlNode>().toList();
      if (_firstIncludedPluginName != null) {
        // There is already at least one plugin specified in included options.
        for (var plugin in pluginValues) {
          if (plugin.value != _firstIncludedPluginName) {
            reporter.report(
              diag.multiplePlugins
                  .withArguments(firstPluginName: _firstIncludedPluginName)
                  .atSourceSpan(plugin.span),
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
            reporter.report(
              diag.multiplePlugins
                  .withArguments(firstPluginName: firstPlugin)
                  .atSourceSpan(plugin.span),
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
            reporter.report(
              diag.multiplePlugins
                  .withArguments(firstPluginName: _firstIncludedPluginName)
                  .atSourceSpan(plugin.span),
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
            reporter.report(
              diag.multiplePlugins
                  .withArguments(firstPluginName: firstPlugin)
                  .atSourceSpan(plugin.span),
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
        if (!AnalysisOptionsFile.optionalChecksOptions.contains(value)) {
          _builder.reportError(
            reporter,
            AnalysisOptionsFile
                .optionalChecksOptions
                .quotedAndCommaSeparatedWithOr,
            v,
          );
        }
      } else if (v is YamlMap) {
        v.nodes.forEach((k, v) {
          String? key, value;
          if (k is YamlScalar) {
            key = k.value?.toString();
            if (!AnalysisOptionsFile.optionalChecksOptions.contains(key)) {
              _builder.reportError(
                reporter,
                AnalysisOptionsFile
                    .optionalChecksOptions
                    .quotedAndCommaSeparatedWithOr,
                k,
              );
            } else {
              value = toLowerCase(v.value);
              if (!AnalysisOptionsFile.trueOrFalse.contains(value)) {
                reporter.report(
                  diag.unsupportedValue
                      .withArguments(
                        optionName: key!,
                        invalidValue: v.valueOrThrow,
                        legalValues: AnalysisOptionsFile.trueOrFalseProposal,
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
              .withArguments(sectionName: AnalysisOptionsFile.enableExperiment)
              .atSourceSpan(v.span),
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
          reporter.report(
            diag.pluginsInInnerOptions
                .withArguments(contextRoot: _contextRoot)
                .atSourceSpan(plugins.span),
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
              reporter.report(
                diag.invalidSectionFormat
                    .withArguments(
                      sectionName: '${AnalysisOptionsFile.plugins}/$pluginName',
                    )
                    .atSourceSpan(plugins.span),
              );
          }
        });
      case YamlList():
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFile.plugins)
              .atSourceSpan(plugins.span),
        );
      case YamlScalar(:var value):
        if (value != null) {
          reporter.report(
            diag.invalidSectionFormat
                .withArguments(sectionName: AnalysisOptionsFile.plugins)
                .atSourceSpan(plugins.span),
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
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFile.strongMode)
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
        if (!AnalysisOptionsFile.strongModeOptions.contains(key)) {
          _builder.reportError(reporter, AnalysisOptionsFile.strongMode, k);
        } else if (key == AnalysisOptionsFile.declarationCasts) {
          reporter.report(
            diag.unsupportedValue
                .withArguments(
                  optionName: AnalysisOptionsFile.strongMode,
                  invalidValue: v.valueOrThrow,
                  legalValues: AnalysisOptionsFile.trueOrFalseProposal,
                )
                .atSourceSpan(v.span),
          );
        } else {
          // The key is valid.
          if (v is YamlScalar) {
            var value = toLowerCase(v.value);
            if (!AnalysisOptionsFile.trueOrFalse.contains(value)) {
              reporter.report(
                diag.unsupportedValue
                    .withArguments(
                      optionName: key!,
                      invalidValue: v.valueOrThrow,
                      legalValues: AnalysisOptionsFile.trueOrFalseProposal,
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
            .withArguments(sectionName: AnalysisOptionsFile.cannotIgnore)
            .atSourceSpan(node.span),
      );
      return;
    }
    node.nodes.forEach((k, v) {
      if (k is YamlScalar) {
        if (!supportedOptions.contains(k.value)) {
          var optionKey = k.valueOrThrow.toString();
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
