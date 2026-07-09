// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'analysis_options_parser.dart';

void _reportUnsupportedSectionKeys({
  required YamlMap section,
  required String sectionName,
  required Set<String> supportedOptions,
  required DiagnosticReporter reporter,
}) {
  var valueProposal = supportedOptions.quotedAndCommaSeparatedWithAnd;
  for (var keyNode in section.nodes.keys) {
    if (keyNode is YamlScalar && !supportedOptions.contains(keyNode.value)) {
      var optionKey = keyNode.value.toString();
      var locatableDiagnostic = supportedOptions.length == 1
          ? diag.unsupportedOptionWithLegalValue.withArguments(
              sectionName: sectionName,
              optionKey: optionKey,
              legalValue: valueProposal,
            )
          : diag.unsupportedOptionWithLegalValues.withArguments(
              sectionName: sectionName,
              optionKey: optionKey,
              legalValues: valueProposal,
            );
      reporter.report(locatableDiagnostic.atSourceSpan(keyNode.span));
    }
  }
}

/// The content of a file.
final class AnalysisOptionsFileContent {
  /// The file text.
  final String text;

  /// Line information for [text].
  final LineInfo lineInfo;

  /// The YAML parsed from [text].
  ///
  /// This is `null` if [text] cannot be parsed as YAML.
  final YamlNode? yaml;

  AnalysisOptionsFileContent({
    required this.text,
    required this.lineInfo,
    required this.yaml,
  });

  /// The YAML parsed from [text], if it is a map.
  YamlMap? get yamlMap => yaml.tryCast<YamlMap>();
}

abstract final class _DiagnosticOptions {
  static final Set<String> codeNames = diagnosticCodeValues
      .map((DiagnosticCode code) => code.lowerCaseName.toUpperCase())
      .toSet();

  static final List<String> errorProcessorLegalValues = [
    ...AnalysisOptionsFileKeys.ignoreSynonyms,
    ...AnalysisOptionsFileKeys.trueOrFalse,
    ...AnalysisOptionsFileKeys.severities,
  ];

  /// The diagnostic code names that existed, but were removed.
  ///
  /// We don't want to report these, this breaks clients.
  // TODO(scheglov): https://github.com/flutter/flutter/issues/141576
  static const Set<String> removedCodeNames = {'MISSING_RETURN'};

  static Set<String> currentLintCodeNames() {
    // TODO(scheglov): Move lint-code lookup behind Registry so callers don't
    // need to rebuild this mutable-registry snapshot.
    return Registry.ruleRegistry.rules
        .map((rule) => rule.name.toUpperCase())
        .toSet();
  }

  static bool isKnownDiagnosticOrLintCode(
    String upperCaseName,
    Set<String> lintCodeNames,
  ) {
    // TODO(scheglov): Review whether options parsing should keep
    // accepting removed diagnostic codes as a compatibility case.
    return codeNames.contains(upperCaseName) ||
        lintCodeNames.contains(upperCaseName) ||
        removedCodeNames.contains(upperCaseName);
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

/// Content read and parsed from one file.
sealed class _FileContent {
  final File file;

  _FileContent({required this.file});

  AnalysisOptionsFileContent? get content;
}

/// A file node in the include graph for one parse request.
///
/// The node is [SourceFactory] specific because it includes resolved include
/// edges.
sealed class _FileNode {
  final File file;

  _FileNode({required this.file});

  AnalysisOptionsFileContent? get content;
}

/// A YAML parse failure for a file.
final class _FileParseFailure {
  final String message;
  final SourceSpan? span;

  _FileParseFailure({required this.message, required this.span});
}

/// One valid `include` directive in a parsed file.
final class _IncludeDirective {
  final YamlScalar node;
  final String uri;

  _IncludeDirective({required this.node, required this.uri});
}

/// The resolved meaning of one `include` directive.
sealed class _IncludeResolution {
  final _IncludeDirective include;

  _IncludeResolution({required this.include});
}

/// A parsed string legacy plugin occurrence.
///
/// Non-string entries in `analyzer/plugins` are ignored for multiple-plugin
/// diagnostics, so this model only represents names that participate in legacy
/// plugin precedence checks.
final class _LegacyPluginData {
  final YamlNode node;
  final String name;

  _LegacyPluginData({required this.node, required this.name});
}

/// An `include` directive whose target was read but had malformed YAML.
final class _MalformedInclude extends _IncludeResolution {
  final _MalformedYamlFileNode file;

  _MalformedInclude({required super.include, required this.file});
}

final class _MalformedYamlFileContent extends _FileContent {
  @override
  final AnalysisOptionsFileContent content;

  final _FileParseFailure failure;

  _MalformedYamlFileContent({
    required super.file,
    required this.content,
    required this.failure,
  });
}

/// A readable file whose YAML root could not be parsed.
final class _MalformedYamlFileNode extends _FileNode {
  @override
  final AnalysisOptionsFileContent content;

  final _FileParseFailure failure;

  _MalformedYamlFileNode({
    required super.file,
    required this.content,
    required this.failure,
  });
}

/// An `include` directive whose target could not be resolved to a parsed file.
final class _MissingInclude extends _IncludeResolution {
  _MissingInclude({required super.include});
}

/// Local `analyzer` section semantics computed from one parsed options file.
final class _ParsedAnalyzerData {
  final _ParsedCannotIgnoreData cannotIgnore;
  final _ParsedEnableExperimentsData enableExperiments;
  final _ParsedErrorProcessorsData errorProcessors;
  final _ParsedExcludesData excludes;
  final _ParsedLanguageData language;
  final _ParsedLegacyPluginsData legacyPlugins;
  final _ParsedOptionalChecksData optionalChecks;

  factory _ParsedAnalyzerData.parse(
    YamlNode? analyzer,
    DiagnosticReporter reporter,
  ) {
    if (analyzer == null || analyzer.isNullScalar) {
      return _ParsedAnalyzerData._empty();
    }

    if (analyzer is! YamlMap) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.analyzer)
            .atSourceSpan(analyzer.span),
      );
      return _ParsedAnalyzerData._empty();
    }

    _reportUnsupportedSectionKeys(
      section: analyzer,
      sectionName: AnalysisOptionsFileKeys.analyzer,
      supportedOptions: AnalysisOptionsFileKeys.analyzerOptions,
      reporter: reporter,
    );

    _ParsedStrongModeData.parse(
      analyzer.valueAt(AnalysisOptionsFileKeys.strongMode),
      reporter,
    );

    return _ParsedAnalyzerData._(
      cannotIgnore: _ParsedCannotIgnoreData.parse(
        analyzer.valueAt(AnalysisOptionsFileKeys.cannotIgnore),
        reporter,
      ),
      enableExperiments: _ParsedEnableExperimentsData.parse(
        analyzer.valueAt(AnalysisOptionsFileKeys.enableExperiment),
        reporter,
      ),
      errorProcessors: _ParsedErrorProcessorsData.parse(
        analyzer.valueAt(AnalysisOptionsFileKeys.errors),
        reporter,
      ),
      excludes: _ParsedExcludesData.parse(
        analyzer.valueAt(AnalysisOptionsFileKeys.exclude),
        reporter,
      ),
      language: _ParsedLanguageData.parse(
        analyzer.valueAt(AnalysisOptionsFileKeys.language),
        reporter,
      ),
      legacyPlugins: _ParsedLegacyPluginsData.parse(
        analyzer.valueAt(AnalysisOptionsFileKeys.plugins),
      ),
      optionalChecks: _ParsedOptionalChecksData.parse(
        analyzer.valueAt(AnalysisOptionsFileKeys.optionalChecks),
        reporter,
      ),
    );
  }

  _ParsedAnalyzerData._({
    required this.cannotIgnore,
    required this.enableExperiments,
    required this.errorProcessors,
    required this.excludes,
    required this.language,
    required this.legacyPlugins,
    required this.optionalChecks,
  });

  factory _ParsedAnalyzerData._empty() {
    return _ParsedAnalyzerData._(
      cannotIgnore: _ParsedCannotIgnoreData._(),
      enableExperiments: _ParsedEnableExperimentsData._(),
      errorProcessors: _ParsedErrorProcessorsData._(),
      excludes: _ParsedExcludesData._(),
      language: _ParsedLanguageData._(),
      legacyPlugins: _ParsedLegacyPluginsData._(),
      optionalChecks: _ParsedOptionalChecksData._(),
    );
  }
}

/// Local analyzer cannot-ignore semantics computed from one parsed options file.
final class _ParsedCannotIgnoreData {
  final List<String>? names;

  factory _ParsedCannotIgnoreData.parse(
    YamlNode? cannotIgnore,
    DiagnosticReporter reporter,
  ) {
    if (cannotIgnore == null) {
      return _ParsedCannotIgnoreData._();
    }

    if (cannotIgnore is! YamlList) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.cannotIgnore)
            .atSourceSpan(cannotIgnore.span),
      );
      return _ParsedCannotIgnoreData._();
    }

    var lintCodeNames = _DiagnosticOptions.currentLintCodeNames();
    var listedNames = <String>{};
    var names = <String>[];
    for (var nameNode in cannotIgnore.nodes) {
      if (nameNode case YamlScalar(value: String name)) {
        names.add(name);
        if (AnalysisOptionsFileKeys.severities.contains(name)) {
          listedNames.add(name);
          continue;
        }

        var upperCaseName = name.toUpperCase();
        if (!_DiagnosticOptions.isKnownDiagnosticOrLintCode(
          upperCaseName,
          lintCodeNames,
        )) {
          reporter.report(
            diag.unrecognizedErrorCode
                .withArguments(codeName: name)
                .atSourceSpan(nameNode.span),
          );
        } else if (listedNames.contains(upperCaseName)) {
          // TODO(srawlins): Create a "duplicate value" code and report it.
        } else {
          listedNames.add(upperCaseName);
        }
      } else {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFileKeys.cannotIgnore)
              .atSourceSpan(nameNode.span),
        );
      }
    }

    return _ParsedCannotIgnoreData._(names: names);
  }

  _ParsedCannotIgnoreData._({this.names});
}

/// Local code-style semantics computed from one parsed options file.
final class _ParsedCodeStyleData {
  final bool? useFormatter;

  factory _ParsedCodeStyleData.parse(
    YamlNode? codeStyle,
    DiagnosticReporter reporter,
  ) {
    if (codeStyle == null || codeStyle.isNullScalar) {
      return _ParsedCodeStyleData._();
    }

    if (codeStyle is! YamlMap) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.codeStyle)
            .atSourceSpan(codeStyle.span),
      );
      return _ParsedCodeStyleData._();
    }

    bool? useFormatter;
    for (var (:keyNode, :valueNode) in codeStyle.nodeEntries) {
      switch (keyNode.value) {
        case AnalysisOptionsFileKeys.format:
          if (valueNode is YamlScalar) {
            useFormatter = valueNode.toBool();
            if (useFormatter == null) {
              reporter.report(
                diag.unsupportedValue
                    .withArguments(
                      optionName: AnalysisOptionsFileKeys.format,
                      invalidValue: valueNode.value.toString(),
                      legalValues: AnalysisOptionsFileKeys.trueOrFalseProposal,
                    )
                    .atSourceSpan(valueNode.span),
              );
            }
          } else {
            reporter.report(
              diag.invalidSectionFormat
                  .withArguments(sectionName: AnalysisOptionsFileKeys.format)
                  .atSourceSpan(valueNode.span),
            );
          }
        default:
          reporter.report(
            diag.unsupportedOptionWithoutValues
                .withArguments(
                  sectionName: AnalysisOptionsFileKeys.codeStyle,
                  optionKey: keyNode.toString(),
                )
                .atSourceSpan(keyNode.span),
          );
      }
    }

    return _ParsedCodeStyleData._(useFormatter: useFormatter);
  }

  _ParsedCodeStyleData._({this.useFormatter});
}

/// Local analyzer enable-experiment semantics computed from one parsed options file.
final class _ParsedEnableExperimentsData {
  final List<String>? flags;

  factory _ParsedEnableExperimentsData.parse(
    YamlNode? enableExperiments,
    DiagnosticReporter reporter,
  ) {
    if (enableExperiments == null) {
      return _ParsedEnableExperimentsData._();
    }

    if (enableExperiments is! YamlList) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(
              sectionName: AnalysisOptionsFileKeys.enableExperiment,
            )
            .atSourceSpan(enableExperiments.span),
      );
      return _ParsedEnableExperimentsData._();
    }

    var flags = <String>[];
    var flagSpans = <SourceSpan>[];
    for (var node in enableExperiments.nodes) {
      if (node case YamlScalar(value: String flag)) {
        flags.add(flag);
        flagSpans.add(node.span);
      } else {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(
                sectionName: AnalysisOptionsFileKeys.enableExperiment,
              )
              .atSourceSpan(node.span),
        );
      }
    }

    for (var validationResult in validateFlags(flags)) {
      var flagIndex = validationResult.stringIndex;
      var span = flagSpans[flagIndex];
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

    return _ParsedEnableExperimentsData._(flags: flags);
  }

  _ParsedEnableExperimentsData._({this.flags});
}

/// Local analyzer error-processor semantics computed from one parsed options file.
final class _ParsedErrorProcessorsData {
  final List<ErrorProcessor>? processors;

  factory _ParsedErrorProcessorsData.parse(
    YamlNode? errors,
    DiagnosticReporter reporter,
  ) {
    if (errors == null) {
      return _ParsedErrorProcessorsData._();
    }

    if (errors is! YamlMap) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.errors)
            .atSourceSpan(errors.span),
      );
      return _ParsedErrorProcessorsData._();
    }

    var lintCodeNames = _DiagnosticOptions.currentLintCodeNames();
    var processors = <ErrorProcessor>[];
    for (var (:keyNode, :valueNode) in errors.nodeEntries) {
      String code;
      switch (keyNode) {
        case YamlScalar(value: String keyValue):
          code = keyValue;
          var upperCaseCode = keyValue.toUpperCase();
          if (!_DiagnosticOptions.isKnownDiagnosticOrLintCode(
            upperCaseCode,
            lintCodeNames,
          )) {
            reporter.report(
              diag.unrecognizedErrorCode
                  .withArguments(codeName: keyValue)
                  .atSourceSpan(keyNode.span),
            );
          }
        case YamlScalar():
          reporter.report(
            diag.unrecognizedErrorCode
                .withArguments(codeName: keyNode.value.toString())
                .atSourceSpan(keyNode.span),
          );
          continue;
        default:
          reporter.report(
            diag.invalidSectionFormat
                .withArguments(sectionName: AnalysisOptionsFileKeys.errors)
                .atSourceSpan(keyNode.span),
          );
          continue;
      }

      if (valueNode is! YamlScalar) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFileKeys.errors)
              .atSourceSpan(valueNode.span),
        );
        continue;
      }

      var action = valueNode.value.toString().toLowerCase();
      if (!_DiagnosticOptions.errorProcessorLegalValues.contains(action)) {
        reporter.report(
          diag.unsupportedOptionWithLegalValues
              .withArguments(
                sectionName: AnalysisOptionsFileKeys.errors,
                optionKey: valueNode.value.toString(),
                legalValues: _DiagnosticOptions
                    .errorProcessorLegalValues
                    .quotedAndCommaSeparatedWithAnd,
              )
              .atSourceSpan(valueNode.span),
        );
        continue;
      }

      if (AnalysisOptionsFileKeys.ignoreSynonyms.contains(action)) {
        processors.add(ErrorProcessor.ignore(code));
      } else if (severityMap[action] case var severity?) {
        processors.add(ErrorProcessor(code, severity));
      }
    }

    return _ParsedErrorProcessorsData._(processors: processors);
  }

  _ParsedErrorProcessorsData._({this.processors});
}

/// Local analyzer exclude semantics computed from one parsed options file.
final class _ParsedExcludesData {
  final List<String>? patterns;

  factory _ParsedExcludesData.parse(
    YamlNode? excludes,
    DiagnosticReporter reporter,
  ) {
    if (excludes == null) {
      return _ParsedExcludesData._();
    }

    if (excludes is! YamlList) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.exclude)
            .atSourceSpan(excludes.span),
      );
      return _ParsedExcludesData._();
    }

    var patterns = <String>[];
    for (var node in excludes.nodes) {
      if (node.stringValue case var pattern?) {
        patterns.add(pattern);
      } else {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: AnalysisOptionsFileKeys.exclude)
              .atSourceSpan(node.span),
        );
      }
    }

    return _ParsedExcludesData._(patterns: patterns);
  }

  _ParsedExcludesData._({this.patterns});
}

/// Local facts computed from one parsed options file.
final class _ParsedFileData {
  final File file;
  final List<Diagnostic> diagnostics;

  final _ParsedAnalyzerData analyzer;
  final _ParsedCodeStyleData codeStyle;
  final _ParsedFormatterData formatter;
  final _ParsedLinterData linter;
  final _ParsedPluginsData plugins;

  _ParsedFileData({
    required this.file,
    required this.diagnostics,
    required this.analyzer,
    required this.codeStyle,
    required this.formatter,
    required this.linter,
    required this.plugins,
  });

  factory _ParsedFileData.parse(
    _ParsedFileNode file, {
    required Folder contextRoot,
    required VersionConstraint? sdkVersionConstraint,
    required bool isInitialFile,
  }) {
    var diagnosticListener = RecordingDiagnosticListener();
    var reporter = DiagnosticReporter(
      diagnosticListener,
      FileSource(file.file),
    );
    var yamlMap = file.content.yaml.tryCast<YamlMap>();
    var analyzer = _ParsedAnalyzerData.parse(
      yamlMap?.valueAt(AnalysisOptionsFileKeys.analyzer),
      reporter,
    );
    var codeStyle = _ParsedCodeStyleData.parse(
      yamlMap?.valueAt(AnalysisOptionsFileKeys.codeStyle),
      reporter,
    );
    var formatter = _ParsedFormatterData.parse(
      yamlMap?.valueAt(AnalysisOptionsFileKeys.formatter),
      reporter,
    );
    var linter = _ParsedLinterData.parse(
      yamlMap,
      file: file.file,
      sdkVersionConstraint: sdkVersionConstraint,
      isInitialFile: isInitialFile,
      reporter: reporter,
    );
    var plugins = _ParsedPluginsData.parse(
      yamlMap?.valueAt(AnalysisOptionsFileKeys.plugins),
      file: file.file,
      contextRoot: contextRoot,
      isInitialFile: isInitialFile,
      reporter: reporter,
    );

    return _ParsedFileData(
      file: file.file,
      diagnostics: diagnosticListener.diagnostics,
      analyzer: analyzer,
      codeStyle: codeStyle,
      formatter: formatter,
      linter: linter,
      plugins: plugins,
    );
  }

  _LocalLinterRules get localLinterRules => linter.localRules;
}

/// A successfully parsed file node in the include graph.
///
/// This is an internal file-based model shared by effective options
/// construction and include walking.
final class _ParsedFileNode extends _FileNode {
  @override
  final AnalysisOptionsFileContent content;

  /// The resolved meaning of each valid `include` directive in [content].
  ///
  /// This is assigned by [AnalysisOptionsParseSession] after the node is in
  /// the parse cache, so recursive includes can point back at the same node.
  late final List<_IncludeResolution> includeResolutions;

  _ParsedFileNode({required super.file, required this.content});
}

/// Effective semantics for a parsed file and its includes.
///
/// [localData] holds diagnostics and values from the file itself. The remaining
/// fields describe values inherited from includes and the final values after
/// local options override included options.
final class _ParsedFileSemantics {
  final _ParsedFileData localData;
  final List<_IncludedLinterRules> includedLinterRules;
  final _EffectiveLinterRules includedEffectiveLinterRules;
  final _EffectiveLinterRules effectiveLinterRules;

  /// The legacy plugin node after merging included files.
  final YamlNode? includedLegacyPluginsNode;

  _ParsedFileSemantics({
    required this.localData,
    required this.includedLinterRules,
    required this.includedEffectiveLinterRules,
    required this.effectiveLinterRules,
    required this.includedLegacyPluginsNode,
  });

  /// The legacy plugin node after applying local options over includes.
  YamlNode? get effectiveLegacyPluginsNode {
    var includedNode = includedLegacyPluginsNode;
    var localNode = localData.analyzer.legacyPlugins.node;
    if (includedNode == null) {
      return localNode;
    }
    if (localNode == null) {
      return includedNode;
    }
    // TODO(scheglov): why?
    return Merger().merge(includedNode, localNode);
  }

  /// The first legacy plugin name found while walking included files.
  String? get includedLegacyPluginName {
    if (includedLegacyPluginsNode case var node?) {
      return _ParsedLegacyPluginsData.parse(node).firstPluginName;
    }
    return null;
  }
}

/// Local formatter semantics computed from one parsed options file.
final class _ParsedFormatterData {
  final int? pageWidth;
  final TrailingCommas? trailingCommas;

  factory _ParsedFormatterData.parse(
    YamlNode? formatter,
    DiagnosticReporter reporter,
  ) {
    if (formatter == null || formatter.isNullScalar) {
      return _ParsedFormatterData._();
    }

    if (formatter is! YamlMap) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.formatter)
            .atSourceSpan(formatter.span),
      );
      return _ParsedFormatterData._();
    }

    void reportInvalidPageWidth(YamlNode valueNode) {
      reporter.report(
        diag.invalidOption
            .withArguments(
              optionName: AnalysisOptionsFileKeys.pageWidth,
              detailMessage: '"page_width" must be a positive integer.',
            )
            .atSourceSpan(valueNode.span),
      );
    }

    void reportInvalidTrailingCommas(YamlNode valueNode) {
      reporter.report(
        diag.invalidOption
            .withArguments(
              optionName: AnalysisOptionsFileKeys.trailingCommas,
              detailMessage:
                  '"trailing_commas" must be "automate" or "preserve".',
            )
            .atSourceSpan(valueNode.span),
      );
    }

    int? pageWidth;
    TrailingCommas? trailingCommas;
    for (var (:keyNode, :valueNode) in formatter.nodeEntries) {
      switch (keyNode.value) {
        case AnalysisOptionsFileKeys.pageWidth:
          Object? value = valueNode.value;
          if (value case int value when value > 0) {
            pageWidth = value;
          } else {
            reportInvalidPageWidth(valueNode);
          }
        case AnalysisOptionsFileKeys.trailingCommas:
          Object? value = valueNode.value;
          trailingCommas = TrailingCommas.values.asNameMap()[value];
          if (trailingCommas == null) {
            reportInvalidTrailingCommas(valueNode);
          }
        default:
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

    return _ParsedFormatterData._(
      pageWidth: pageWidth,
      trailingCommas: trailingCommas,
    );
  }

  _ParsedFormatterData._({this.pageWidth, this.trailingCommas});
}

/// An `include` directive whose target was parsed successfully.
final class _ParsedInclude extends _IncludeResolution {
  final _ParsedFileNode file;

  _ParsedInclude({required super.include, required this.file});
}

/// Local analyzer language semantics computed from one parsed options file.
final class _ParsedLanguageData {
  final bool? strictCasts;
  final bool? strictInference;
  final bool? strictRawTypes;

  factory _ParsedLanguageData.parse(
    YamlNode? language,
    DiagnosticReporter reporter,
  ) {
    if (language == null || language.isNullScalar) {
      return _ParsedLanguageData._();
    }

    if (language is! YamlMap) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.language)
            .atSourceSpan(language.span),
      );
      return _ParsedLanguageData._();
    }

    var unsupportedKey = _ErrorBuilder(AnalysisOptionsFileKeys.languageOptions);

    bool? parseBool(String optionName, YamlNode valueNode) {
      if (valueNode is! YamlScalar) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: optionName)
              .atSourceSpan(valueNode.span),
        );
        return null;
      }

      var value = valueNode.toBool();
      if (value == null) {
        reporter.report(
          diag.unsupportedValue
              .withArguments(
                optionName: optionName,
                invalidValue: valueNode.value.toString(),
                legalValues: AnalysisOptionsFileKeys.trueOrFalseProposal,
              )
              .atSourceSpan(valueNode.span),
        );
      }
      return value;
    }

    bool? strictCasts;
    bool? strictInference;
    bool? strictRawTypes;
    for (var (:keyNode, :valueNode) in language.nodeEntries) {
      if (keyNode is! YamlScalar) {
        continue;
      }

      switch (keyNode.value) {
        case AnalysisOptionsFileKeys.strictCasts:
          strictCasts = parseBool(
            AnalysisOptionsFileKeys.strictCasts,
            valueNode,
          );
        case AnalysisOptionsFileKeys.strictInference:
          strictInference = parseBool(
            AnalysisOptionsFileKeys.strictInference,
            valueNode,
          );
        case AnalysisOptionsFileKeys.strictRawTypes:
          strictRawTypes = parseBool(
            AnalysisOptionsFileKeys.strictRawTypes,
            valueNode,
          );
        default:
          unsupportedKey.reportError(
            reporter,
            AnalysisOptionsFileKeys.language,
            keyNode,
          );
      }
    }

    return _ParsedLanguageData._(
      strictCasts: strictCasts,
      strictInference: strictInference,
      strictRawTypes: strictRawTypes,
    );
  }

  _ParsedLanguageData._({
    this.strictCasts,
    this.strictInference,
    this.strictRawTypes,
  });
}

/// Local legacy `analyzer/plugins` semantics computed from one parsed options file.
final class _ParsedLegacyPluginsData {
  final YamlNode? node;
  final String? firstPluginName;
  final List<_LegacyPluginData> entries;
  final List<_LegacyPluginData> localConflicts;

  factory _ParsedLegacyPluginsData.parse(YamlNode? plugins) {
    return switch (plugins) {
      null => _ParsedLegacyPluginsData._(),
      YamlScalar(value: null) => _ParsedLegacyPluginsData._(node: plugins),
      YamlScalar() => _ParsedLegacyPluginsData._fromNodes(plugins, [plugins]),
      YamlList() => _ParsedLegacyPluginsData._fromNodes(plugins, plugins.nodes),
      YamlMap() => _ParsedLegacyPluginsData._fromNodes(
        plugins,
        plugins.nodes.keys.cast<YamlNode?>(),
      ),
      _ => _ParsedLegacyPluginsData._(node: plugins),
    };
  }

  _ParsedLegacyPluginsData._({
    this.node,
    this.firstPluginName,
    this.entries = const [],
    this.localConflicts = const [],
  });

  factory _ParsedLegacyPluginsData._fromNodes(
    YamlNode node,
    Iterable<YamlNode?> nodes,
  ) {
    var entries = <_LegacyPluginData>[];
    var localConflicts = <_LegacyPluginData>[];
    String? firstPluginName;
    for (var node in nodes) {
      if (node == null) {
        continue;
      }
      if (node.stringValue case var pluginName?) {
        var entry = _LegacyPluginData(node: node, name: pluginName);
        entries.add(entry);
        if (firstPluginName == null) {
          firstPluginName = pluginName;
        } else if (pluginName != firstPluginName) {
          localConflicts.add(entry);
        }
      }
    }
    return _ParsedLegacyPluginsData._(
      node: node,
      firstPluginName: firstPluginName,
      entries: entries,
      localConflicts: localConflicts,
    );
  }

  void reportLocalMultiplePlugins(DiagnosticReporter reporter) {
    if (firstPluginName case var firstPluginName?) {
      for (var conflict in localConflicts) {
        _reportMultiplePlugins(reporter, conflict.node, firstPluginName);
      }
    }
  }

  void reportMultiplePluginsWithIncluded(
    DiagnosticReporter reporter, {
    required String includedPluginName,
  }) {
    for (var entry in entries) {
      if (entry.name != includedPluginName) {
        _reportMultiplePlugins(reporter, entry.node, includedPluginName);
      }
    }
  }

  void _reportMultiplePlugins(
    DiagnosticReporter reporter,
    YamlNode node,
    String firstPluginName,
  ) {
    reporter.report(
      diag.multiplePlugins
          .withArguments(firstPluginName: firstPluginName)
          .atSourceSpan(node.span),
    );
  }
}

/// Local runtime linter configuration computed from one parsed options file.
final class _ParsedLinterData {
  static const _falseValue = 'false';
  static const _ignoreValue = 'ignore';
  static const _trueValue = 'true';
  static const _infoValue = 'info';
  static const _warningValue = 'warning';
  static const _errorValue = 'error';
  static const _validLintStringValues = [
    _ignoreValue,
    _infoValue,
    _warningValue,
    _errorValue,
  ];
  static const _validLintValues = [
    _trueValue,
    _falseValue,
    ..._validLintStringValues,
  ];

  final _ParsedLinterDataKind kind;
  final Map<String, RuleConfig> ruleConfigs;
  final _LocalLinterRules localRules;

  factory _ParsedLinterData.absent() {
    return _ParsedLinterData._(
      _ParsedLinterDataKind.absent,
      const {},
      _LocalLinterRules.empty,
    );
  }

  factory _ParsedLinterData.invalid() {
    return _ParsedLinterData._(
      _ParsedLinterDataKind.invalid,
      const {},
      _LocalLinterRules.empty,
    );
  }

  factory _ParsedLinterData.parse(
    YamlMap? yamlMap, {
    required File file,
    required VersionConstraint? sdkVersionConstraint,
    required bool isInitialFile,
    required DiagnosticReporter reporter,
  }) {
    if (yamlMap == null) {
      return _ParsedLinterData.absent();
    }

    var linter = yamlMap.valueAt(AnalysisOptionsFileKeys.linter);
    if (linter == null || linter.isNullScalar) {
      return _ParsedLinterData.absent();
    }

    if (linter is! YamlMap) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.linter)
            .atSourceSpan(linter.span),
      );
      return _ParsedLinterData.invalid();
    }

    var rules = linter.valueAt(AnalysisOptionsFileKeys.rules);
    var localRules = _parseLocalRules(
      rules,
      file: file,
      sdkVersionConstraint: sdkVersionConstraint,
      isInitialFile: isInitialFile,
      reporter: reporter,
    );

    _reportUnsupportedSectionKeys(
      section: linter,
      sectionName: AnalysisOptionsFileKeys.linter,
      supportedOptions: AnalysisOptionsFileKeys.linterOptions,
      reporter: reporter,
    );

    return _ParsedLinterData.valid(
      // TODO(scheglov): Compute rule configs in this parser pass too. This
      // still delegates to the shared linter helper because it is used outside
      // analyzer options parsing, including by pkg/linter.
      parseLinterSection(yamlMap) ?? const {},
      localRules: localRules,
    );
  }

  factory _ParsedLinterData.valid(
    Map<String, RuleConfig> ruleConfigs, {
    required _LocalLinterRules localRules,
  }) {
    return _ParsedLinterData._(
      _ParsedLinterDataKind.valid,
      ruleConfigs,
      localRules,
    );
  }

  _ParsedLinterData._(this.kind, this.ruleConfigs, this.localRules);

  static bool _beforeCurrentConstraint(
    Version? since,
    VersionConstraint? sdkVersionConstraint,
  ) {
    // No "since" applies to all SDKs.
    if (since == null) return true;

    return switch (sdkVersionConstraint) {
      VersionRange(min: var min?) => since <= min,
      _ => false,
    };
  }

  static AbstractAnalysisRule? _getRegisteredLint(String value) =>
      Registry.ruleRegistry[value];

  static bool _isDeprecatedInCurrentOrEarlierSdk(
    RuleState state,
    VersionConstraint? sdkVersionConstraint,
  ) =>
      state.isDeprecated &&
      _beforeCurrentConstraint(state.since, sdkVersionConstraint);

  static bool _isRemovedInCurrentOrEarlierSdk(
    RuleState state,
    VersionConstraint? sdkVersionConstraint,
  ) =>
      state.isRemoved &&
      _beforeCurrentConstraint(state.since, sdkVersionConstraint);

  static _LocalLinterRules _parseLocalRules(
    YamlNode? rules, {
    required File file,
    required VersionConstraint? sdkVersionConstraint,
    required bool isInitialFile,
    required DiagnosticReporter reporter,
  }) {
    if (rules is! YamlList &&
        rules is! YamlMap &&
        // This handles empty keys like
        // linter:
        //   rules:
        (rules is! YamlScalar || rules.value != null) &&
        // We accept 'null' for triggering `INCOMPATIBLE_LINT_INCLUDED`.
        rules != null) {
      return _LocalLinterRules.empty;
    }

    _RuleData? parseRule(YamlScalar node, Object? enabled) {
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

      // Report removed or deprecated lint warnings defined directly (and not
      // in includes).
      if (isInitialFile) {
        var state = rule.state;
        if (_isDeprecatedInCurrentOrEarlierSdk(state, sdkVersionConstraint)) {
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
        } else if (_isRemovedInCurrentOrEarlierSdk(
          state,
          sdkVersionConstraint,
        )) {
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

      return _RuleData(rule, node, file: file, isEnabled: enabledValue);
    }

    var activeRules = <AbstractAnalysisRule, _RuleData>{};
    var disabledRules = <_RuleData>[];
    var enabledRules = <_RuleData>[];

    void parseEntry(YamlNode key, Object? value) {
      if (key is! YamlScalar) {
        return;
      }
      var rule = parseRule(key, value);
      if (rule == null) {
        return;
      }
      if (rule.isEnabled) {
        enabledRules.add(rule);
      } else {
        disabledRules.add(rule);
      }
    }

    switch (rules) {
      case YamlList(:var nodes):
        for (var rule in nodes) {
          parseEntry(rule, true);
        }
      case YamlMap():
        for (var (:keyNode, :valueNode) in rules.nodeEntries) {
          parseEntry(keyNode, valueNode);
        }
    }

    for (var rule in enabledRules) {
      _processEnabledRule(
        ruleData: rule,
        reporter: reporter,
        activeRules: activeRules,
      );
      activeRules[rule.rule] = rule;
    }

    return _LocalLinterRules(enabled: enabledRules, disabled: disabledRules);
  }

  /// Processes an enabled rule by checking for incompatible rules and reporting
  /// any issues found.
  static void _processEnabledRule({
    required _RuleData ruleData,
    required Map<AbstractAnalysisRule, _RuleData> activeRules,
    required DiagnosticReporter reporter,
  }) {
    String value = ruleData.node.value.toString();
    var incompatible = _LinterRuleDiagnostics.findIncompatibleRules(
      ruleData.rule,
      rules: activeRules.values,
    );
    if (incompatible.isNotEmpty) {
      reporter.report(
        _LinterRuleDiagnostics.diagnosticFactory.incompatibleLint(
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
}

enum _ParsedLinterDataKind { absent, invalid, valid }

/// Local analyzer optional-checks semantics computed from one parsed options file.
final class _ParsedOptionalChecksData {
  final bool? chromeOsManifestChecks;
  final bool? propagateLinterExceptions;

  factory _ParsedOptionalChecksData.parse(
    YamlNode? optionalChecks,
    DiagnosticReporter reporter,
  ) {
    void reportUnsupportedKey(YamlNode node) {
      var unsupportedKey = _ErrorBuilder(
        AnalysisOptionsFileKeys.optionalChecksOptions,
      );
      unsupportedKey.reportError(
        reporter,
        AnalysisOptionsFileKeys
            .optionalChecksOptions
            .quotedAndCommaSeparatedWithOr,
        node,
      );
    }

    bool? parseBool(String optionName, YamlNode valueNode) {
      if (valueNode is! YamlScalar) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: optionName)
              .atSourceSpan(valueNode.span),
        );
        return null;
      }

      if (valueNode.toBool() case var value?) {
        return value;
      } else {
        reporter.report(
          diag.unsupportedValue
              .withArguments(
                optionName: optionName,
                invalidValue: valueNode.value.toString(),
                legalValues: AnalysisOptionsFileKeys.trueOrFalseProposal,
              )
              .atSourceSpan(valueNode.span),
        );
      }
      return null;
    }

    bool? chromeOsManifestChecks;
    bool? propagateLinterExceptions;

    switch (optionalChecks) {
      case null:
        break;
      case YamlScalar():
        switch (optionalChecks.value) {
          case AnalysisOptionsFileKeys.chromeOsManifestChecks:
            chromeOsManifestChecks = true;
          case AnalysisOptionsFileKeys.propagateLinterExceptions:
            propagateLinterExceptions = true;
          default:
            reportUnsupportedKey(optionalChecks);
        }
      case YamlMap():
        for (var (:keyNode, :valueNode) in optionalChecks.nodeEntries) {
          if (keyNode is! YamlScalar) {
            continue;
          }

          switch (keyNode.value) {
            case AnalysisOptionsFileKeys.chromeOsManifestChecks:
              chromeOsManifestChecks = parseBool(
                AnalysisOptionsFileKeys.chromeOsManifestChecks,
                valueNode,
              );
            case AnalysisOptionsFileKeys.propagateLinterExceptions:
              propagateLinterExceptions = parseBool(
                AnalysisOptionsFileKeys.propagateLinterExceptions,
                valueNode,
              );
            default:
              reportUnsupportedKey(keyNode);
          }
        }
      default:
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(
                sectionName: AnalysisOptionsFileKeys.optionalChecks,
              )
              .atSourceSpan(optionalChecks.span),
        );
    }

    return _ParsedOptionalChecksData._(
      chromeOsManifestChecks: chromeOsManifestChecks,
      propagateLinterExceptions: propagateLinterExceptions,
    );
  }

  _ParsedOptionalChecksData._({
    this.chromeOsManifestChecks,
    this.propagateLinterExceptions,
  });
}

/// Local top-level `plugins` semantics computed from one parsed options file.
final class _ParsedPluginsData {
  // TODO(scheglov): Decide whether an invalid `plugins` section should keep
  // included plugin options instead of clearing them; this preserves existing
  // behavior while plugin parsing and validation are being unified.
  final bool clearsExisting;
  final List<PluginConfiguration> configurations;
  final Map<String, PluginSource>? dependencyOverrides;

  factory _ParsedPluginsData.parse(
    YamlNode? plugins, {
    required File file,
    required Folder contextRoot,
    required bool isInitialFile,
    required DiagnosticReporter reporter,
  }) {
    if (plugins == null) {
      return _ParsedPluginsData._();
    }

    if (plugins is! YamlMap) {
      switch (plugins) {
        case YamlScalar(value: null):
          break;
        default:
          reporter.report(
            diag.invalidSectionFormat
                .withArguments(sectionName: AnalysisOptionsFileKeys.plugins)
                .atSourceSpan(plugins.span),
          );
      }
      return _ParsedPluginsData._(clearsExisting: true);
    }

    if (file.parent != contextRoot && isInitialFile) {
      reporter.report(
        diag.pluginsInInnerOptions
            .withArguments(contextRoot: contextRoot.path)
            .atSourceSpan(plugins.span),
      );
    }

    var configurations = <PluginConfiguration>[];
    Map<String, PluginSource>? dependencyOverrides;
    for (var (keyNode: nameNode, valueNode: pluginNode)
        in plugins.nodeEntries) {
      if (nameNode is! YamlScalar) {
        continue;
      }

      var pluginName = nameNode.toString();
      if (pluginName == AnalysisOptionsFileKeys.dependencyOverrides) {
        if (pluginNode is YamlMap) {
          for (var (keyNode: overrideNameNode, valueNode: overrideNode)
              in pluginNode.nodeEntries) {
            if (overrideNameNode is! YamlScalar) {
              continue;
            }

            if (_parsePluginSource(overrideNode, file) case var source?) {
              (dependencyOverrides ??= {})[overrideNameNode.toString()] =
                  source;
            }

            if (overrideNameNode.value is String) {
              _validatePlugin(
                reporter,
                '${AnalysisOptionsFileKeys.plugins}/${AnalysisOptionsFileKeys.dependencyOverrides}',
                overrideNameNode.toString(),
                overrideNode,
              );
            }
          }
        } else {
          reporter.report(
            diag.invalidSectionFormat
                .withArguments(
                  sectionName:
                      '${AnalysisOptionsFileKeys.plugins}/${AnalysisOptionsFileKeys.dependencyOverrides}',
                )
                .atSourceSpan(pluginNode.span),
          );
        }
        continue;
      }

      if (_parsePluginSource(pluginNode, file) case var source?) {
        Map<String, RuleConfig> diagnosticConfigurations = const {};
        if (pluginNode is YamlMap) {
          var diagnostics = pluginNode.valueAt(
            AnalysisOptionsFileKeys.diagnostics,
          );
          if (diagnostics != null) {
            diagnosticConfigurations = parseDiagnosticsSection(diagnostics);
          }
        }

        configurations.add(
          PluginConfiguration(
            name: pluginName,
            source: source,
            diagnosticConfigs: diagnosticConfigurations,
            // TODO(srawlins): Implement `enabled: false`.
          ),
        );
      }

      if (nameNode.value is String) {
        _validatePlugin(
          reporter,
          AnalysisOptionsFileKeys.plugins,
          pluginName,
          pluginNode,
        );
      }
    }

    return _ParsedPluginsData._(
      configurations: configurations,
      dependencyOverrides: dependencyOverrides,
    );
  }

  _ParsedPluginsData._({
    this.clearsExisting = false,
    this.configurations = const [],
    this.dependencyOverrides,
  });

  static PluginSource? _parsePluginSource(YamlNode pluginNode, File file) {
    if (pluginNode case YamlScalar(:String value)) {
      return VersionedPluginSource(constraint: value);
    }

    if (pluginNode is! YamlMap) {
      return null;
    }

    // Grab either the source value from 'version', 'git', or 'path'. In the
    // erroneous case that multiple are specified, just take the first. A
    // warning should be reported by the options validation path.
    // TODO(srawlins): In addition to 'version' and 'path', try 'git'.
    var versionSource = pluginNode.valueAt(AnalysisOptionsFileKeys.version);
    var hostedUrlSource = pluginNode.valueAt(AnalysisOptionsFileKeys.hosted);

    if ((versionSource, hostedUrlSource) case (
      YamlScalar(value: String version),
      YamlScalar(value: String hostedUrl),
    )) {
      return VersionedPluginSource(constraint: version, hostedUrl: hostedUrl);
    } else if (versionSource case YamlScalar(value: String version)) {
      return VersionedPluginSource(constraint: version);
    }

    var gitSource = pluginNode.valueAt(AnalysisOptionsFileKeys.git);
    if (gitSource case YamlScalar(:String value)) {
      return GitPluginSource(url: value);
    } else if (gitSource is YamlMap) {
      var urlSource = gitSource.valueAt(AnalysisOptionsFileKeys.url);
      if (urlSource case YamlScalar(:String value)) {
        return GitPluginSource(
          url: value,
          path: gitSource.valueAt(AnalysisOptionsFileKeys.path).stringValue,
          ref: gitSource.valueAt(AnalysisOptionsFileKeys.ref).stringValue,
          tagPattern: gitSource
              .valueAt(AnalysisOptionsFileKeys.tagPattern)
              .stringValue,
        );
      }
    }

    var pathSource = pluginNode.valueAt(AnalysisOptionsFileKeys.path);
    if (pathSource case YamlScalar(value: String pathValue)) {
      var pathContext = file.provider.pathContext;
      if (pathContext.isRelative(pathValue)) {
        // The plugin source is later used in a synthetic pub package, so store
        // an absolute path before the source leaves options parsing.
        pathValue = pathContext.join(file.parent.path, pathValue);
        pathValue = pathContext.normalize(pathValue);
      }
      return PathPluginSource(path: pathValue);
    }
    return null;
  }

  static void _validateDiagnostics(
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

    for (var (keyNode: _, valueNode: severityNode)
        in diagnosticsValue.nodeEntries) {
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
      if (!_DiagnosticOptions.errorProcessorLegalValues.contains(severity)) {
        reporter.report(
          diag.unsupportedOptionWithLegalValues
              .withArguments(
                sectionName: sectionName,
                optionKey: severityNode.value.toString(),
                legalValues: _DiagnosticOptions
                    .errorProcessorLegalValues
                    .quotedAndCommaSeparatedWithAnd,
              )
              .atSourceSpan(severityNode.span),
        );
      }
    }
  }

  static void _validateGit(
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

    var unsupportedGitOption = _ErrorBuilder(
      AnalysisOptionsFileKeys.gitOptions,
    );
    for (var (:keyNode, :valueNode) in gitValue.nodeEntries) {
      if (keyNode case YamlScalar(value: String key)) {
        if (!AnalysisOptionsFileKeys.gitOptions.contains(key)) {
          unsupportedGitOption.reportError(reporter, sectionName, keyNode);
        } else if (valueNode is! YamlScalar || valueNode.value is! String) {
          reporter.report(
            diag.invalidSectionFormat
                .withArguments(sectionName: '$sectionName/$key')
                .atSourceSpan(valueNode.span),
          );
        }
      }
    }
  }

  static void _validatePlugin(
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

  static void _validatePluginMap(
    DiagnosticReporter reporter,
    String pluginPath,
    YamlMap pluginValue,
  ) {
    var unsupportedPluginOption = _ErrorBuilder(
      AnalysisOptionsFileKeys.pluginsOptions,
    );
    for (var (keyNode: pluginMapKeyNode, valueNode: pluginMapValueNode)
        in pluginValue.nodeEntries) {
      if (pluginMapKeyNode case YamlScalar(value: String pluginMapKey)) {
        if (pluginMapKey == AnalysisOptionsFileKeys.diagnostics) {
          _validateDiagnostics(reporter, pluginPath, pluginMapValueNode);
        } else if (pluginMapKey == AnalysisOptionsFileKeys.git) {
          _validateGit(reporter, pluginPath, pluginMapValueNode);
        } else if (!AnalysisOptionsFileKeys.pluginsOptions.contains(
          pluginMapKey,
        )) {
          unsupportedPluginOption.reportError(
            reporter,
            pluginPath,
            pluginMapKeyNode,
          );
        }
      }
      // TODO(srawlins): Validate 'path' is a YamlScalar.
    }
  }
}

/// Diagnostics for the deprecated `analyzer/strong-mode` section.
final class _ParsedStrongModeData {
  factory _ParsedStrongModeData.parse(
    YamlNode? strongMode,
    DiagnosticReporter reporter,
  ) {
    if (strongMode == null) {
      return _ParsedStrongModeData._();
    }

    if (strongMode is! YamlMap) {
      reporter.report(
        diag.invalidSectionFormat
            .withArguments(sectionName: AnalysisOptionsFileKeys.strongMode)
            .atSourceSpan(strongMode.span),
      );
      return _ParsedStrongModeData._();
    }

    bool? parseBool(String optionName, YamlNode valueNode) {
      if (valueNode is! YamlScalar) {
        reporter.report(
          diag.invalidSectionFormat
              .withArguments(sectionName: optionName)
              .atSourceSpan(valueNode.span),
        );
        return null;
      }

      if (valueNode.toBool() case var value?) {
        return value;
      } else {
        reporter.report(
          diag.unsupportedValue
              .withArguments(
                optionName: optionName,
                invalidValue: valueNode.value.toString(),
                legalValues: AnalysisOptionsFileKeys.trueOrFalseProposal,
              )
              .atSourceSpan(valueNode.span),
        );
      }
      return null;
    }

    for (var (:keyNode, :valueNode) in strongMode.nodeEntries) {
      if (keyNode is! YamlScalar) {
        continue;
      }

      var optionName = keyNode.value?.toString();
      switch (optionName) {
        case AnalysisOptionsFileKeys.implicitCasts:
          parseBool(AnalysisOptionsFileKeys.implicitCasts, valueNode);
        case AnalysisOptionsFileKeys.implicitDynamic:
          parseBool(AnalysisOptionsFileKeys.implicitDynamic, valueNode);
        default:
          reporter.report(
            diag.unsupportedOptionWithLegalValues
                .withArguments(
                  sectionName: AnalysisOptionsFileKeys.strongMode,
                  optionKey: keyNode.value.toString(),
                  legalValues: {
                    AnalysisOptionsFileKeys.implicitCasts,
                    AnalysisOptionsFileKeys.implicitDynamic,
                  }.quotedAndCommaSeparatedWithAnd,
                )
                .atSourceSpan(keyNode.span),
          );
      }
    }

    return _ParsedStrongModeData._();
  }

  _ParsedStrongModeData._();
}

final class _ParsedYamlFileContent extends _FileContent {
  @override
  final AnalysisOptionsFileContent content;

  _ParsedYamlFileContent({required super.file, required this.content});
}

final class _UnreadableFileContent extends _FileContent {
  final FileSystemException exception;

  _UnreadableFileContent({required super.file, required this.exception});

  @override
  AnalysisOptionsFileContent? get content => null;
}

/// A file node whose content could not be read.
final class _UnreadableFileNode extends _FileNode {
  final FileSystemException exception;

  _UnreadableFileNode({required super.file, required this.exception});

  @override
  AnalysisOptionsFileContent? get content => null;
}
