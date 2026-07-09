// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/analysis_options/code_style_options.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

part 'analysis_options_include_walker.dart';
part 'analysis_options_parse_model.dart';
part 'linter_rule_options_validator.dart';

/// The result of parsing an analysis options file at a user-visible boundary.
///
/// Analysis options are configuration, so parsing is best-effort: callers get
/// the effective options object along with diagnostics for parts of the file
/// graph that were ignored, malformed, unsupported, or inconsistent.
final class AnalysisOptionsParseResult {
  /// The initial options file passed to [AnalysisOptionsParseSession.parse].
  final File file;

  /// The content read from [file], or `null` if it could not be read.
  final AnalysisOptionsFileContent? content;

  final AnalysisOptionsImpl analysisOptions;
  final List<Diagnostic> diagnostics;

  AnalysisOptionsParseResult({
    required this.file,
    required this.content,
    required this.analysisOptions,
    required this.diagnostics,
  });
}

/// Parses analysis options and owns caches reused by parse requests.
final class AnalysisOptionsParseSession {
  /// File contents are independent of [SourceFactory].
  final Map<File, _FileContent> _fileContents = {};

  /// Parsed file nodes with resolved includes.
  ///
  /// Include resolution depends on [SourceFactory], so the same [File] can have
  /// more than one file node in this cache.
  final Map<({SourceFactory sourceFactory, File file}), _FileNode> _fileNodes =
      {};

  /// Parses [file] and reports diagnostics for the same file graph.
  ///
  /// This is the production boundary for callers that need the effective
  /// [AnalysisOptionsImpl] and the diagnostics produced while interpreting the
  /// same initial options file.
  AnalysisOptionsParseResult parse({
    required SourceFactory sourceFactory,
    required Folder contextRoot,
    required File file,
    VersionConstraint? sdkVersionConstraint,
  }) {
    return _ParseRequest(
      session: this,
      sourceFactory: sourceFactory,
      contextRoot: contextRoot,
      sdkVersionConstraint: sdkVersionConstraint,
    ).parse(file);
  }

  _FileContent _fileContentFor(File file) {
    if (_fileContents[file] case var result?) {
      return result;
    }

    String text;
    try {
      text = file.readAsStringSync();
    } on FileSystemException catch (exception) {
      return _fileContents[file] = _UnreadableFileContent(
        file: file,
        exception: exception,
      );
    }

    var lineInfo = LineInfo.fromContent(text);
    YamlNode yaml;
    try {
      yaml = loadYamlNode(text);
    } on YamlException catch (e) {
      return _fileContents[file] = _MalformedYamlFileContent(
        file: file,
        content: AnalysisOptionsFileContent(
          text: text,
          lineInfo: lineInfo,
          yaml: null,
        ),
        failure: _FileParseFailure(message: e.message, span: e.span),
      );
    }

    return _fileContents[file] = _ParsedYamlFileContent(
      file: file,
      content: AnalysisOptionsFileContent(
        text: text,
        lineInfo: lineInfo,
        yaml: yaml,
      ),
    );
  }
}

/// Mutable state used while applying the parsed include graph to options.
final class _ApplyState {
  final AnalysisOptionsBuilder builder;
  final Map<String, RuleConfig> _linterRuleConfigs = {};

  bool _hasLinterSection = false;
  YamlNode? _legacyPluginsNode;

  _ApplyState(File file) : builder = AnalysisOptionsBuilder(file: file);

  void apply(_ParsedFileData fileData) {
    _applyAnalyzer(fileData.analyzer);
    _applyCodeStyle(fileData.codeStyle);
    _applyFormatter(fileData.formatter);
    _applyPlugins(fileData.plugins);
    _applyLegacyPlugins(fileData.analyzer.legacyPlugins);
    _applyLinterSection(fileData.linter);
  }

  AnalysisOptionsImpl build() {
    if (_hasLinterSection) {
      var lintRules = Registry.ruleRegistry.enabled(_linterRuleConfigs);
      if (lintRules.isNotEmpty) {
        builder.lint = true;
        builder.lintRules = lintRules.toList();
      }
    }

    return builder.build();
  }

  void _applyAnalyzer(_ParsedAnalyzerData analyzer) {
    _applyEnableExperiments(analyzer.enableExperiments);
    _applyErrorProcessors(analyzer.errorProcessors);
    _applyCannotIgnore(analyzer.cannotIgnore);
    _applyExcludes(analyzer.excludes);
    _applyLanguage(analyzer.language);
    _applyOptionalChecks(analyzer.optionalChecks);
  }

  void _applyCannotIgnore(_ParsedCannotIgnoreData cannotIgnore) {
    if (cannotIgnore.names case var names?) {
      for (var name in names) {
        if (severityMap[name] case var severity?) {
          for (var diagnostic in diagnosticCodeValues) {
            // If the severity of [error] is also changed in this options file,
            // use the changed severity.
            var processors = builder.errorProcessors.where(
              (processor) => processor.code == diagnostic.lowerCaseName,
            );
            DiagnosticSeverity? diagnosticSeverity = processors.isNotEmpty
                ? processors.first.severity
                : diagnostic.severity;
            if (diagnosticSeverity == severity) {
              builder.unignorableDiagnosticCodeNames.add(
                diagnostic.lowerCaseName,
              );
            }
          }
        } else {
          builder.unignorableDiagnosticCodeNames.add(name.toLowerCase());
        }
      }
    }
  }

  void _applyCodeStyle(_ParsedCodeStyleData codeStyle) {
    if (codeStyle.useFormatter case var useFormatter?) {
      builder.codeStyleOptions = CodeStyleOptionsImpl(
        useFormatter: useFormatter,
      );
    }
  }

  void _applyEnableExperiments(_ParsedEnableExperimentsData enableExperiments) {
    if (enableExperiments.flags case var flags?) {
      builder.contextFeatures =
          FeatureSet.fromEnableFlags2(
                sdkLanguageVersion: ExperimentStatus.currentVersion,
                flags: flags,
              )
              as ExperimentStatus;
      builder.nonPackageFeatureSet = builder.contextFeatures;
    }
  }

  void _applyErrorProcessors(_ParsedErrorProcessorsData errorProcessors) {
    if (errorProcessors.processors case var processors?) {
      var processorsByCode = {
        for (var processor in builder.errorProcessors)
          processor.code: processor,
      };
      for (var processor in processors) {
        processorsByCode[processor.code] = processor;
      }
      builder.errorProcessors = processorsByCode.values.toList();
    }
  }

  void _applyExcludes(_ParsedExcludesData excludes) {
    if (excludes.patterns case var patterns?) {
      for (var pattern in patterns) {
        if (!builder.excludePatterns.contains(pattern)) {
          builder.excludePatterns.add(pattern);
        }
      }
    }
  }

  void _applyFormatter(_ParsedFormatterData formatter) {
    builder.formatterOptions = FormatterOptions(
      pageWidth: formatter.pageWidth ?? builder.formatterOptions.pageWidth,
      trailingCommas:
          formatter.trailingCommas ?? builder.formatterOptions.trailingCommas,
    );
  }

  void _applyLanguage(_ParsedLanguageData language) {
    if (language.strictCasts case var value?) {
      builder.strictCasts = value;
    }
    if (language.strictInference case var value?) {
      builder.strictInference = value;
    }
    if (language.strictRawTypes case var value?) {
      builder.strictRawTypes = value;
    }
  }

  void _applyLegacyPlugins(_ParsedLegacyPluginsData plugins) {
    var localNode = plugins.node;
    if (localNode == null) {
      return;
    }

    _legacyPluginsNode = _legacyPluginsNode == null
        ? localNode
        : Merger().merge(_legacyPluginsNode!, localNode);

    var pluginName = _ParsedLegacyPluginsData.parse(
      _legacyPluginsNode,
    ).firstPluginName;
    builder.enabledLegacyPluginNames = [?pluginName];
  }

  void _applyLinterSection(_ParsedLinterData linter) {
    switch (linter.kind) {
      case _ParsedLinterDataKind.absent:
        return;
      case _ParsedLinterDataKind.invalid:
        _hasLinterSection = false;
        _linterRuleConfigs.clear();
      case _ParsedLinterDataKind.valid:
        _hasLinterSection = true;
        _linterRuleConfigs.addAll(linter.ruleConfigs);
    }
  }

  void _applyOptionalChecks(_ParsedOptionalChecksData optionalChecks) {
    if (optionalChecks.chromeOsManifestChecks case var value?) {
      builder.chromeOsManifestChecks = value;
    }
    if (optionalChecks.propagateLinterExceptions case var value?) {
      builder.propagateLinterExceptions = value;
    }
  }

  void _applyPlugins(_ParsedPluginsData plugins) {
    if (plugins.clearsExisting) {
      builder.pluginsOptions = PluginsOptions(
        configurations: [],
        dependencyOverrides: null,
      );
      return;
    }

    var configurations = {
      for (var configuration in builder.pluginsOptions.configurations)
        configuration.name: configuration,
    };
    var dependencyOverrides = builder.pluginsOptions.dependencyOverrides == null
        ? null
        : Map.of(builder.pluginsOptions.dependencyOverrides!);

    for (var configuration in plugins.configurations) {
      configurations[configuration.name] = configuration;
    }
    if (plugins.dependencyOverrides case var overrides?) {
      (dependencyOverrides ??= {}).addAll(overrides);
    }

    builder.pluginsOptions = PluginsOptions(
      configurations: configurations.values.toList(),
      dependencyOverrides: dependencyOverrides,
    );
  }
}

/// Request-specific state and operations for one call to [parse].
final class _ParseRequest {
  final AnalysisOptionsParseSession session;
  final SourceFactory sourceFactory;
  final Folder contextRoot;
  final VersionConstraint? sdkVersionConstraint;
  final Map<_ParsedFileNode, _ParsedFileData> fileDataCache = {};

  _ParseRequest({
    required this.session,
    required this.sourceFactory,
    required this.contextRoot,
    required this.sdkVersionConstraint,
  });

  AnalysisOptionsParseResult parse(File file) {
    var initialFileNode = _fileNodeFor(file: file);

    var diagnostics = const <Diagnostic>[];
    switch (initialFileNode) {
      case _ParsedFileNode():
        diagnostics = _diagnosticsForParsedFileNode(file: initialFileNode);
      case _MalformedYamlFileNode(:var failure):
        diagnostics = _diagnosticsForMalformedFile(
          file: file,
          failure: failure,
        );
      case _UnreadableFileNode():
        break;
    }

    AnalysisOptionsImpl analysisOptions;
    if (initialFileNode case _ParsedFileNode initialParsedFileNode) {
      var applyState = _ApplyState(initialParsedFileNode.file);
      _applyParsedFiles(
        applyState: applyState,
        file: initialParsedFileNode,
        isInitialFile: true,
        handled: {},
      );
      analysisOptions = applyState.build();
    } else {
      analysisOptions = AnalysisOptionsImpl(file: file);
    }

    return AnalysisOptionsParseResult(
      file: file,
      content: initialFileNode.content,
      analysisOptions: analysisOptions,
      diagnostics: diagnostics,
    );
  }

  void _applyParsedFiles({
    required _ApplyState applyState,
    required _ParsedFileNode file,
    required bool isInitialFile,
    required Set<File> handled,
  }) {
    for (var include in file.includeResolutions) {
      switch (include) {
        case _MissingInclude() || _MalformedInclude():
          break;
        case _ParsedInclude(file: var includedFile):
          if (handled.add(includedFile.file)) {
            _applyParsedFiles(
              applyState: applyState,
              file: includedFile,
              isInitialFile: false,
              handled: handled,
            );
          }
      }
    }

    var data = _parsedFileDataFor(file: file, isInitialFile: isInitialFile);
    applyState.apply(data);
  }

  List<Diagnostic> _diagnosticsForMalformedFile({
    required File file,
    required _FileParseFailure failure,
  }) {
    var diagnosticListener = RecordingDiagnosticListener();
    var diagnosticReporter = DiagnosticReporter(
      diagnosticListener,
      FileSource(file),
    );
    if (failure.span case var span?) {
      diagnosticReporter.report(
        diag.parseError
            .withArguments(errorMessage: failure.message)
            .atSourceSpan(span),
      );
    }
    return diagnosticListener.diagnostics;
  }

  List<Diagnostic> _diagnosticsForParsedFileNode({
    required _ParsedFileNode file,
  }) {
    var diagnosticListener = RecordingDiagnosticListener();
    var diagnosticReporter = DiagnosticReporter(
      diagnosticListener,
      FileSource(file.file),
    );

    _ParsedFileSemantics computeFileSemantics(
      _ParsedFileNode fileNode, {
      required bool isInitialFile,
      required Set<File> includeChainFiles,
    }) {
      return _fileSemanticsFor(
        file: fileNode,
        isInitialFile: isInitialFile,
        includeChainFiles: includeChainFiles,
      );
    }

    return _AnalysisOptionsIncludeWalker(
      initialDiagnosticListener: diagnosticListener,
      initialDiagnosticReporter: diagnosticReporter,
      initialParsedFileNode: file,
      contextRoot: contextRoot,
      fileSemantics: computeFileSemantics,
    ).walk();
  }

  _FileNode _fileNodeFor({required File file}) {
    var key = (sourceFactory: sourceFactory, file: file);
    if (session._fileNodes[key] case var result?) {
      return result;
    }

    var content = session._fileContentFor(file);
    switch (content) {
      case _ParsedYamlFileContent():
        var result = _ParsedFileNode(file: file, content: content.content);
        session._fileNodes[key] = result;

        result.includeResolutions = _resolvedIncludesFor(
          parsedFileNode: result,
        );
        return result;
      case _MalformedYamlFileContent():
        return session._fileNodes[key] = _MalformedYamlFileNode(
          file: file,
          content: content.content,
          failure: content.failure,
        );
      case _UnreadableFileContent():
        return session._fileNodes[key] = _UnreadableFileNode(
          file: file,
          exception: content.exception,
        );
    }
  }

  _ParsedFileSemantics _fileSemanticsFor({
    required _ParsedFileNode file,
    required bool isInitialFile,
    required Set<File> includeChainFiles,
  }) {
    var initialFile = file.file;

    _ParsedFileSemantics compute({
      required _ParsedFileNode file,
      required bool isInitialFile,
      required Set<File> includeChainFiles,
    }) {
      var localData = _parsedFileDataFor(
        file: file,
        isInitialFile: isInitialFile,
      );

      var nextIncludeChainFiles = {...includeChainFiles, file.file};
      var includedLinterRules = <_IncludedLinterRules>[];
      YamlNode? includedLegacyPluginsNode;
      for (var include in file.includeResolutions) {
        switch (include) {
          case _MissingInclude() || _MalformedInclude():
            break;
          case _ParsedInclude(file: var includedParsedFile):
            var includedFile = includedParsedFile.file;
            if (includedFile == initialFile ||
                includeChainFiles.contains(includedFile)) {
              break;
            }

            var includedSemantics = compute(
              file: includedParsedFile,
              isInitialFile: false,
              includeChainFiles: nextIncludeChainFiles,
            );
            includedLinterRules.add(
              _IncludedLinterRules(
                includeNode: include.include.node,
                rules: includedSemantics.effectiveLinterRules,
              ),
            );
            var includedNode = includedSemantics.effectiveLegacyPluginsNode;
            if (includedNode != null) {
              includedLegacyPluginsNode = includedLegacyPluginsNode == null
                  ? includedNode
                  : Merger().merge(includedLegacyPluginsNode, includedNode);
            }
        }
      }

      var includedEffectiveLinterRules = _mergeIncludedLinterRules(
        includedLinterRules,
      );
      var effectiveLinterRules = includedEffectiveLinterRules.copy()
        ..applyLocal(localData.localLinterRules);

      return _ParsedFileSemantics(
        localData: localData,
        includedLinterRules: includedLinterRules,
        includedEffectiveLinterRules: includedEffectiveLinterRules,
        effectiveLinterRules: effectiveLinterRules,
        includedLegacyPluginsNode: includedLegacyPluginsNode,
      );
    }

    return compute(
      file: file,
      isInitialFile: isInitialFile,
      includeChainFiles: includeChainFiles,
    );
  }

  _EffectiveLinterRules _mergeIncludedLinterRules(
    List<_IncludedLinterRules> includedRules,
  ) {
    var result = _EffectiveLinterRules();
    for (var included in includedRules) {
      result.apply(included.rules);
    }
    return result;
  }

  _ParsedFileData _parsedFileDataFor({
    required _ParsedFileNode file,
    required bool isInitialFile,
  }) {
    return fileDataCache.putIfAbsent(
      file,
      () => _ParsedFileData.parse(
        file,
        contextRoot: contextRoot,
        sdkVersionConstraint: sdkVersionConstraint,
        isInitialFile: isInitialFile,
      ),
    );
  }

  List<_IncludeResolution> _resolvedIncludesFor({
    required _ParsedFileNode parsedFileNode,
  }) {
    List<_IncludeDirective> includeNodes(YamlMap? yamlMap) {
      var includeNode = yamlMap?.valueAt(AnalysisOptionsFileKeys.include);
      return switch (includeNode) {
        YamlScalar(value: String uri) => [
          _IncludeDirective(node: includeNode, uri: uri),
        ],
        YamlList(:var nodes) => [
          for (var node in nodes.whereType<YamlScalar>())
            if (node.value case String uri)
              _IncludeDirective(node: node, uri: uri),
        ],
        _ => const <_IncludeDirective>[],
      };
    }

    _IncludeResolution resolveInclude(_IncludeDirective include) {
      var includeSource = sourceFactory.resolveUri(
        FileSource(parsedFileNode.file),
        include.uri,
      );
      if (includeSource is! FileSource) {
        return _MissingInclude(include: include);
      }

      var includedFile = includeSource.file;
      var includedFileNode = _fileNodeFor(file: includedFile);
      switch (includedFileNode) {
        case _ParsedFileNode():
          return _ParsedInclude(include: include, file: includedFileNode);
        case _MalformedYamlFileNode():
          return _MalformedInclude(include: include, file: includedFileNode);
        case _UnreadableFileNode():
          return _MissingInclude(include: include);
      }
    }

    var yamlMap = parsedFileNode.content.yaml.tryCast<YamlMap>();
    return [for (var include in includeNodes(yamlMap)) resolveInclude(include)];
  }
}

extension on YamlNode? {
  bool get isNullScalar {
    var self = this;
    return self is YamlScalar && self.value == null;
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
