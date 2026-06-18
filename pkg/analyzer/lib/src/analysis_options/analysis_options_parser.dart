// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/analysis_options/analysis_options_validator.dart';
import 'package:analyzer/src/analysis_options/analysis_options_yaml.dart';
import 'package:analyzer/src/analysis_options/code_style_options.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer/src/utilities/extensions/source.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

_MergedOptionsYamlCache _newMergedOptionsYamlCache() {
  return CanonicalizedMap(
    (key) {
      var (:containingUri, :uri) = key;
      if (uri.isScheme('package')) return uri;
      if (uri.isScheme('file') || uri.scheme.isEmpty) {
        if (uri.isAbsolute) return uri;
        if (containingUri != null) {
          return uriCache.resolveRelative(containingUri, uri);
        }
      }
      return uri;
    },
    isValidKey: (key) {
      // We can canonicalize a URI if it is a 'package:' URI (as this is per
      // SourceFactory), or if it is an absolute 'file:' URI, or if it is a
      // relative 'file:' URI and we have a "containing" URI which it is
      // relative to (via `UriCache.resolveRelative`).
      var (:containingUri, :uri) = key;
      if (uri.isScheme('package')) return true;
      if (uri.isScheme('file') || uri.scheme.isEmpty) {
        return uri.isAbsolute || containingUri != null;
      }
      return false;
    },
  );
}

/// Cache of merged analysis-options YAML maps.
///
/// Entries are keyed by the URI being resolved and, for relative include URIs,
/// the containing URI that makes the include unambiguous.
typedef _MergedOptionsYamlCache = Map<({Uri? containingUri, Uri uri}), YamlMap>;

/// The content of an analysis-options file.
final class AnalysisOptionsFileContent {
  /// The file text.
  final String text;

  /// Line information for [text].
  final LineInfo lineInfo;

  /// The parsed, unmerged YAML map from [text].
  ///
  /// This is `null` if [text] cannot be parsed as YAML, or is not a YAML map.
  final YamlMap? yamlMap;

  AnalysisOptionsFileContent({
    required this.text,
    required this.lineInfo,
    required this.yamlMap,
  });
}

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

/// Parses analysis options during one analysis-options parsing task.
///
/// The session owns the separate internal caches needed while parsing still
/// delegates to the legacy validation and merged-YAML builder paths.
final class AnalysisOptionsParseSession {
  final AnalysisOptionsValidationCache _validationCache =
      AnalysisOptionsValidationCache();

  final Map<SourceFactory, _MergedOptionsYamlCache> _mergedOptionsYamlCaches =
      {};

  /// Parses [file] and reports diagnostics for the same file graph.
  ///
  /// This is the production boundary for callers that need the effective
  /// [AnalysisOptionsImpl] and the diagnostics produced while interpreting the
  /// same initial options file. The implementation still delegates to the
  /// existing implementation pieces; keeping that delegation behind this
  /// session lets callers move to the combined contract before the internal
  /// include walks are collapsed.
  AnalysisOptionsParseResult parse({
    required SourceFactory sourceFactory,
    required Folder contextRoot,
    required File file,
    VersionConstraint? sdkVersionConstraint,
  }) {
    AnalysisOptionsFileContent? content;
    try {
      var text = file.readAsStringSync();
      content = AnalysisOptionsFileContent(
        text: text,
        lineInfo: LineInfo.fromContent(text),
        yamlMap: _parseYamlMap(text, sourceUrl: file.toUri()),
      );
    } catch (_) {}

    var diagnostics = const <Diagnostic>[];
    if (content != null) {
      try {
        // ignore: deprecated_member_use_from_same_package
        diagnostics = AnalysisOptionsValidator(
          sourceFactory: sourceFactory,
          contextRoot: contextRoot,
          sdkVersionConstraint: sdkVersionConstraint,
          validationCache: _validationCache,
        ).validate(file: file, content: content.text);
      } catch (_) {
        // Preserve best-effort behavior while clients migrate to the combined
        // parser API.
      }
    }

    AnalysisOptionsImpl analysisOptions;
    try {
      var mergedOptionsYaml = _MergedOptionsYamlBuilder(
        sourceFactory: sourceFactory,
        pathContext: file.provider.pathContext,
        cache: _mergedOptionsYamlCacheFor(sourceFactory),
      ).getOptionsFromFile(file);
      analysisOptions = _AnalysisOptionsYamlApplier(
        file: file,
        optionsMap: mergedOptionsYaml,
      ).build();
    } catch (_) {
      analysisOptions = AnalysisOptionsImpl(file: file);
    }

    return AnalysisOptionsParseResult(
      file: file,
      content: content,
      analysisOptions: analysisOptions,
      diagnostics: diagnostics,
    );
  }

  _MergedOptionsYamlCache _mergedOptionsYamlCacheFor(
    SourceFactory sourceFactory,
  ) {
    return _mergedOptionsYamlCaches.putIfAbsent(
      sourceFactory,
      _newMergedOptionsYamlCache,
    );
  }

  YamlMap? _parseYamlMap(String content, {required Uri sourceUrl}) {
    try {
      var node = loadYamlNode(content, sourceUrl: sourceUrl);
      return node.tryCast<YamlMap>();
    } on YamlException {
      return null;
    }
  }
}

/// Applies merged YAML to the runtime analysis options object.
///
/// Validation owns user-facing diagnostics. This class keeps the tolerant
/// YAML-to-runtime mapping private to the parser entry point.
final class _AnalysisOptionsYamlApplier {
  final File file;
  final YamlMap optionsMap;
  final AnalysisOptionsBuilder builder;

  _AnalysisOptionsYamlApplier({required this.file, required this.optionsMap})
    : builder = AnalysisOptionsBuilder()..file = file;

  AnalysisOptionsImpl build() {
    var analyzer = optionsMap.valueAt(AnalysisOptionsFileKeys.analyzer);
    if (analyzer is YamlMap) {
      var filters = analyzer.valueAt(AnalysisOptionsFileKeys.errors);
      builder.errorProcessors = ErrorConfig(filters).processors;

      var experimentNames = analyzer.valueAt(
        AnalysisOptionsFileKeys.enableExperiment,
      );
      if (experimentNames is YamlList) {
        var enabledExperiments = <String>[];
        for (var element in experimentNames.nodes) {
          var experimentName = element.stringValue;
          if (experimentName != null) {
            enabledExperiments.add(experimentName);
          }
        }
        builder.contextFeatures =
            FeatureSet.fromEnableFlags2(
                  sdkLanguageVersion: ExperimentStatus.currentVersion,
                  flags: enabledExperiments,
                )
                as ExperimentStatus;
        builder.nonPackageFeatureSet = builder.contextFeatures;
      }

      _applyOptionalChecks(
        analyzer.valueAt(AnalysisOptionsFileKeys.optionalChecks),
      );
      _applyLanguageOptions(analyzer.valueAt(AnalysisOptionsFileKeys.language));
      _applyExcludes(analyzer.valueAt(AnalysisOptionsFileKeys.exclude));
      _applyUnignorables(
        analyzer.valueAt(AnalysisOptionsFileKeys.cannotIgnore),
      );
      _applyLegacyPlugins(analyzer.valueAt(AnalysisOptionsFileKeys.plugins));
    }

    _applyFormatterOptions(
      optionsMap.valueAt(AnalysisOptionsFileKeys.formatter),
    );
    _applyPluginsOptions(optionsMap.valueAt(AnalysisOptionsFileKeys.plugins));

    var ruleConfigs = parseLinterSection(optionsMap);
    if (ruleConfigs != null) {
      var enabledRules = Registry.ruleRegistry.enabled(ruleConfigs);
      if (enabledRules.isNotEmpty) {
        builder.lint = true;
        builder.lintRules = enabledRules.toList();
      }
    }

    _applyCodeStyleOptions(
      optionsMap.valueAt(AnalysisOptionsFileKeys.codeStyle),
    );

    return builder.build();
  }

  void _applyCodeStyleOptions(YamlNode? codeStyle) {
    var useFormatter = false;
    if (codeStyle is YamlMap) {
      var formatNode = codeStyle.valueAt(AnalysisOptionsFileKeys.format);
      if (formatNode is YamlScalar) {
        var formatValue = formatNode.toBool();
        if (formatValue is bool) {
          useFormatter = formatValue;
        }
      }
    }
    builder.codeStyleOptions = CodeStyleOptionsImpl(useFormatter: useFormatter);
  }

  void _applyExcludes(YamlNode? excludes) {
    if (excludes is YamlList) {
      // TODO(srawlins): Report non-String items.
      builder.excludePatterns.addAll(excludes.whereType<String>());
    }
    // TODO(srawlins): Report non-List with
    // AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT.
  }

  void _applyFormatterOptions(YamlNode? formatter) {
    int? pageWidth;
    TrailingCommas? trailingCommas;
    if (formatter is YamlMap) {
      var pageWidthNode = formatter.valueAt(AnalysisOptionsFileKeys.pageWidth);
      var pageWidthValue = pageWidthNode?.value;
      if (pageWidthValue is int && pageWidthValue > 0) {
        pageWidth = pageWidthValue;
      }

      var trailingCommasNode = formatter.valueAt(
        AnalysisOptionsFileKeys.trailingCommas,
      );
      var trailingCommasValue = trailingCommasNode?.value;
      trailingCommas = TrailingCommas.values.firstWhereOrNull(
        (item) => item.name == trailingCommasValue,
      );
    }
    builder.formatterOptions = FormatterOptions(
      pageWidth: pageWidth,
      trailingCommas: trailingCommas,
    );
  }

  void _applyLanguageOptions(YamlNode? configs) {
    if (configs is! YamlMap) {
      return;
    }

    configs.nodes.forEach((key, value) {
      if (key is! YamlScalar || value is! YamlScalar) {
        return;
      }
      var feature = key.value?.toString();
      var boolValue = value.boolValue;
      if (boolValue == null) {
        return;
      }

      switch (feature) {
        case AnalysisOptionsFileKeys.strictCasts:
          builder.strictCasts = boolValue;
        case AnalysisOptionsFileKeys.strictInference:
          builder.strictInference = boolValue;
        case AnalysisOptionsFileKeys.strictRawTypes:
          builder.strictRawTypes = boolValue;
      }
    });
  }

  void _applyLegacyPlugins(YamlNode? plugins) {
    var pluginName = plugins.stringValue;
    if (pluginName != null) {
      builder.enabledLegacyPluginNames = [pluginName];
    } else if (plugins is YamlList) {
      for (var element in plugins.nodes) {
        var pluginName = element.stringValue;
        if (pluginName != null) {
          // Only the first legacy plugin is supported.
          builder.enabledLegacyPluginNames = [pluginName];
          return;
        }
      }
    } else if (plugins is YamlMap) {
      for (var key in plugins.nodes.keys.cast<YamlNode?>()) {
        var pluginName = key.stringValue;
        if (pluginName != null) {
          // Only the first legacy plugin is supported.
          builder.enabledLegacyPluginNames = [pluginName];
          return;
        }
      }
    }
  }

  void _applyOptionalChecks(YamlNode? config) {
    switch (config) {
      case YamlMap():
        for (var MapEntry(:key, :value) in config.nodes.entries) {
          if (key is YamlScalar && value is YamlScalar) {
            if (value.boolValue case var boolValue?) {
              switch ('${key.value}') {
                case AnalysisOptionsFileKeys.chromeOsManifestChecks:
                  builder.chromeOsManifestChecks = boolValue;
                case AnalysisOptionsFileKeys.propagateLinterExceptions:
                  builder.propagateLinterExceptions = boolValue;
              }
            }
          }
        }
      case YamlScalar():
        switch ('${config.value}') {
          case AnalysisOptionsFileKeys.chromeOsManifestChecks:
            builder.chromeOsManifestChecks = true;
          case AnalysisOptionsFileKeys.propagateLinterExceptions:
            builder.propagateLinterExceptions = true;
        }
    }
  }

  void _applyPluginsOptions(YamlNode? plugins) {
    if (plugins is! YamlMap) {
      return;
    }

    var configurations = <PluginConfiguration>[];
    Map<String, PluginSource>? dependencyOverrides;

    plugins.nodes.forEach((nameNode, pluginNode) {
      if (nameNode is! YamlScalar) {
        return;
      }

      var pluginName = nameNode.toString();
      if (pluginName == AnalysisOptionsFileKeys.dependencyOverrides) {
        // This is a magic key; not the name of a plugin.
        if (pluginNode is! YamlMap) return;
        pluginNode.nodes.forEach((nameNode, dependencyOverride) {
          if (nameNode is! YamlScalar) {
            return;
          }
          var source = _getSource(dependencyOverride);
          if (source == null) return;
          (dependencyOverrides ??= {})[nameNode.toString()] = source;
        });

        return;
      }

      var source = _getSource(pluginNode);
      if (source == null) return;

      if (pluginNode is! YamlMap) {
        configurations.add(
          PluginConfiguration(name: pluginName, source: source),
        );
        return;
      }

      var diagnostics = pluginNode.valueAt(AnalysisOptionsFileKeys.diagnostics);
      var diagnosticConfigurations = diagnostics == null
          ? const <String, RuleConfig>{}
          : parseDiagnosticsSection(diagnostics);

      configurations.add(
        PluginConfiguration(
          name: pluginName,
          source: source,
          diagnosticConfigs: diagnosticConfigurations,
          // TODO(srawlins): Implement `enabled: false`.
        ),
      );
    });

    builder.pluginsOptions = PluginsOptions(
      configurations: configurations,
      dependencyOverrides: dependencyOverrides,
    );
  }

  void _applyUnignorables(YamlNode? cannotIgnore) {
    if (cannotIgnore is! YamlList) {
      return;
    }
    for (var entry in cannotIgnore) {
      if (entry is! String) continue;
      if (severityMap[entry] case var severity?) {
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
        builder.unignorableDiagnosticCodeNames.add(entry.toLowerCase());
      }
    }
  }

  PluginSource? _getSource(YamlNode pluginNode) {
    if (pluginNode case YamlScalar(:String value)) {
      return VersionedPluginSource(constraint: value);
    }

    if (pluginNode is! YamlMap) {
      return null;
    }

    // Grab either the source value from 'version', 'git', or 'path'. In the
    // erroneous case that multiple are specified, just take the first. A
    // warning should be reported by the analysis-options validation path.
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
        // an absolute path before the source leaves analysis-options parsing.
        pathValue = pathContext.join(file.parent.path, pathValue);
        pathValue = pathContext.normalize(pathValue);
      }
      return PathPluginSource(path: pathValue);
    }
    return null;
  }
}

/// Builds the effective YAML map used to create [AnalysisOptionsImpl].
///
/// This is intentionally private to [AnalysisOptionsParseSession]. It preserves
/// the legacy merge semantics while keeping callers on the combined
/// parse-and-validate API.
final class _MergedOptionsYamlBuilder {
  final SourceFactory sourceFactory;
  final path.Context pathContext;
  final _MergedOptionsYamlCache cache;

  _MergedOptionsYamlBuilder({
    required this.sourceFactory,
    required this.pathContext,
    required this.cache,
  });

  YamlMap getOptionsFromFile(File file) {
    return _getOptionsFromSource(FileSource(file), handled: {});
  }

  YamlMap _getOptionsFromSource(Source source, {required Set<Source> handled}) {
    if (cache[(containingUri: null, uri: source.uri)] case var cached?) {
      return cached;
    }

    YamlMap options;
    try {
      options = parseAnalysisOptionsYaml(
        source.stringContents,
        sourceUrl: source.uri,
      );
    } on Exception {
      // A YAML-parsing exception is reported by the validation path.
      return YamlMap();
    }

    var includeValue = options.valueAt(AnalysisOptionsFileKeys.include);
    var includes = switch (includeValue) {
      YamlScalar(:String value) => [value],
      YamlList() =>
        includeValue.nodes
            .whereType<YamlScalar>()
            .map((e) => e.value)
            .whereType<String>()
            .toList(),
      _ => <String>[],
    };

    var includeOptions = includes.fold(YamlMap(), (currentOptions, uriString) {
      var uri = uriCache.parse(uriString);
      YamlMap includedOptions;
      if (cache[(containingUri: source.uri, uri: uri)] case var cached?) {
        includedOptions = cached;
      } else {
        var includeSource = sourceFactory.resolveUri(source, uriString);
        if (includeSource == null || !handled.add(includeSource)) {
          return currentOptions;
        }

        includedOptions = _getOptionsFromSource(
          includeSource,
          handled: handled,
        );

        includedOptions = _rewriteRelativePaths(
          includedOptions,
          pathContext.dirname(includeSource.fullName),
        );
        cache[(containingUri: source.uri, uri: uri)] = includedOptions;
      }
      return _merge(currentOptions, includedOptions);
    });

    options = _merge(includeOptions, options);
    cache[(containingUri: null, uri: source.uri)] = options;
    return options;
  }

  YamlMap _merge(YamlMap defaults, YamlMap overrides) {
    return Merger().mergeMap(defaults, overrides);
  }

  /// Rewrites relative paths in semantic locations whose meaning depends on the
  /// file where they were declared.
  YamlMap _rewriteRelativePaths(YamlMap options, String directory) {
    var pluginsSection = options.valueAt(AnalysisOptionsFileKeys.plugins);
    if (pluginsSection is! YamlMap) {
      return options;
    }

    var plugins = <String, Object>{};
    pluginsSection.nodes.forEach((key, value) {
      if (key is YamlScalar && value is YamlMap) {
        var pathValue = value.valueAt(AnalysisOptionsFileKeys.path)?.value;
        if (pathValue is String) {
          if (pathContext.isRelative(pathValue)) {
            // The plugin source is later used in a synthetic pub package, so
            // it must no longer depend on the included file's location.
            pathValue = pathContext.join(directory, pathValue);
            pathValue = pathContext.normalize(pathValue);
          }

          plugins[key.value as String] = {
            AnalysisOptionsFileKeys.path: pathValue,
          };
        }
      }
    });
    return _merge(
      options,
      YamlMap.wrap({AnalysisOptionsFileKeys.plugins: plugins}),
    );
  }
}

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
