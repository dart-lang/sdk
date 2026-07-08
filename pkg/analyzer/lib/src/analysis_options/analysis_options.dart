// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/code_style_options.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

/// A builder for [AnalysisOptionsImpl].
///
/// To be used when an [AnalysisOptionsImpl] needs to be constructed, but with
/// individually set options, rather than being built from YAML.
final class AnalysisOptionsBuilder {
  final File? file;

  ExperimentStatus _contextFeatures = ExperimentStatus();

  FeatureSet nonPackageFeatureSet = ExperimentStatus();

  List<String> enabledLegacyPluginNames = [];

  List<ErrorProcessor> errorProcessors = [];

  List<String> excludePatterns = [];

  bool lint = false;

  bool warning = true;

  List<AbstractAnalysisRule> lintRules = [];

  bool propagateLinterExceptions = false;

  bool strictCasts = false;

  bool strictInference = false;

  bool strictRawTypes = false;

  bool chromeOsManifestChecks = false;

  CodeStyleOptions codeStyleOptions = CodeStyleOptionsImpl(useFormatter: false);

  FormatterOptions formatterOptions = FormatterOptions();

  Set<String> unignorableDiagnosticCodeNames = {};

  PluginsOptions pluginsOptions = PluginsOptions(
    configurations: [],
    dependencyOverrides: null,
  );

  String? pluginDependencyOverrides;

  /// Creates a builder initialized with default options.
  AnalysisOptionsBuilder({this.file});

  /// Creates a builder initialized from an existing options object.
  AnalysisOptionsBuilder.from(AnalysisOptionsImpl options)
    : file = options.file {
    contextFeatures = options.contextFeatures;
    nonPackageFeatureSet = options.nonPackageFeatureSet;
    enabledLegacyPluginNames = options.enabledLegacyPluginNames.toList();
    pluginsOptions = PluginsOptions(
      configurations: options.pluginsOptions.configurations.toList(),
      dependencyOverrides: options.pluginsOptions.dependencyOverrides == null
          ? null
          : Map.of(options.pluginsOptions.dependencyOverrides!),
    );
    errorProcessors = options.errorProcessors.toList();
    excludePatterns = options.excludePatterns.toList();
    lint = options.lint;
    warning = options.warning;
    lintRules = options.lintRules.toList();
    propagateLinterExceptions = options.propagateLinterExceptions;
    strictCasts = options.strictCasts;
    strictInference = options.strictInference;
    strictRawTypes = options.strictRawTypes;
    chromeOsManifestChecks = options.chromeOsManifestChecks;
    codeStyleOptions = CodeStyleOptionsImpl(
      useFormatter: options.codeStyleOptions.useFormatter,
    );
    formatterOptions = FormatterOptions(
      pageWidth: options.formatterOptions.pageWidth,
      trailingCommas: options.formatterOptions.trailingCommas,
    );
    unignorableDiagnosticCodeNames = options.unignorableDiagnosticCodeNames
        .toSet();
  }

  FeatureSet get contextFeatures => _contextFeatures;

  set contextFeatures(FeatureSet featureSet) {
    _contextFeatures = featureSet as ExperimentStatus;
    nonPackageFeatureSet = featureSet;
  }

  AnalysisOptionsImpl build() {
    return AnalysisOptionsImpl._(
      file: file,
      contextFeatures: _contextFeatures,
      nonPackageFeatureSet: nonPackageFeatureSet,
      enabledLegacyPluginNames: enabledLegacyPluginNames.toList(),
      pluginsOptions: PluginsOptions(
        configurations: pluginsOptions.configurations.toList(),
        dependencyOverrides: pluginsOptions.dependencyOverrides == null
            ? null
            : Map.of(pluginsOptions.dependencyOverrides!),
      ),
      errorProcessors: errorProcessors.toList(),
      excludePatterns: excludePatterns.toList(),
      lint: lint,
      warning: warning,
      lintRules: lintRules.toList(),
      propagateLinterExceptions: propagateLinterExceptions,
      strictCasts: strictCasts,
      strictInference: strictInference,
      strictRawTypes: strictRawTypes,
      chromeOsManifestChecks: chromeOsManifestChecks,
      codeStyleOptions: CodeStyleOptionsImpl(
        useFormatter: codeStyleOptions.useFormatter,
      ),
      formatterOptions: FormatterOptions(
        pageWidth: formatterOptions.pageWidth,
        trailingCommas: formatterOptions.trailingCommas,
      ),
      unignorableDiagnosticCodeNames: unignorableDiagnosticCodeNames.toSet(),
    );
  }
}

/// A set of analysis options used to control the behavior of an analysis
/// context.
class AnalysisOptionsImpl implements AnalysisOptions {
  /// The cached [unlinkedSignature].
  Uint32List? _unlinkedSignature;

  /// The cached [signature].
  Uint32List? _signature;

  /// The cached [signatureForElements].
  Uint32List? _signatureForElements;

  /// The constraint on the language version for every Dart file.
  /// Violations will be reported as analysis errors.
  final VersionConstraint? sourceLanguageConstraint = VersionConstraint.parse(
    '>= 2.12.0',
  );

  ExperimentStatus _contextFeatures;

  /// The set of features to use for libraries that are not in a package.
  ///
  /// If a library is in a package, this feature set is *not* used, even if the
  /// package does not specify the language version. Instead [contextFeatures]
  /// is used.
  FeatureSet nonPackageFeatureSet;

  @override
  final List<String> enabledLegacyPluginNames;

  /// The options used to specify plugins.
  final PluginsOptions pluginsOptions;

  @override
  final List<ErrorProcessor> errorProcessors;

  @override
  final List<String> excludePatterns;

  /// The associated `analysis_options.yaml` file (or `null` if there is none).
  final File? file;

  bool _lint;

  bool _warning;

  List<AbstractAnalysisRule> _lintRules;

  /// Whether linter exceptions should be propagated to the caller (by
  /// rethrowing them).
  final bool propagateLinterExceptions;

  @override
  final bool strictCasts;

  @override
  final bool strictInference;

  @override
  final bool strictRawTypes;

  @override
  final bool chromeOsManifestChecks;

  @override
  final CodeStyleOptions codeStyleOptions;

  @override
  final FormatterOptions formatterOptions;

  /// The set of "un-ignorable" diagnostic names, as parsed from an analysis
  /// options file.
  ///
  /// All entries in this set are in `lower_snake_case` form.
  final Set<String> unignorableDiagnosticCodeNames;

  /// Returns a newly instantiated [AnalysisOptionsImpl].
  ///
  /// Optionally pass [file] as the file where the YAML can be found.
  factory AnalysisOptionsImpl({File? file}) {
    var builder = AnalysisOptionsBuilder(file: file);
    return builder.build();
  }

  AnalysisOptionsImpl._({
    required this.file,
    required ExperimentStatus contextFeatures,
    required this.nonPackageFeatureSet,
    required this.excludePatterns,
    required this.enabledLegacyPluginNames,
    required this.pluginsOptions,
    required this.errorProcessors,
    required bool lint,
    required bool warning,
    required List<AbstractAnalysisRule> lintRules,
    required this.propagateLinterExceptions,
    required this.strictCasts,
    required this.strictInference,
    required this.strictRawTypes,
    required this.chromeOsManifestChecks,
    required this.codeStyleOptions,
    required this.formatterOptions,
    required this.unignorableDiagnosticCodeNames,
  }) : _contextFeatures = contextFeatures,
       _lint = lint,
       _warning = warning,
       _lintRules = lintRules {
    assert(unignorableDiagnosticCodeNames.every((n) => n == n.toLowerCase()));
    (codeStyleOptions as CodeStyleOptionsImpl).options = this;
  }

  @override
  FeatureSet get contextFeatures => _contextFeatures;

  // TODO(scheglov): Remove these compatibility setters after clients migrate
  // to AnalysisOptionsBuilder.
  @Deprecated('Use AnalysisOptionsBuilder instead.')
  set contextFeatures(FeatureSet featureSet) {
    _contextFeatures = featureSet as ExperimentStatus;
    nonPackageFeatureSet = featureSet;
    _clearCachedSignatures();
  }

  @override
  bool get lint => _lint;

  @Deprecated('Use AnalysisOptionsBuilder instead.')
  set lint(bool value) {
    _lint = value;
    _clearCachedSignatures();
  }

  @override
  List<AbstractAnalysisRule> get lintRules => _lintRules;

  @Deprecated('Use AnalysisOptionsBuilder instead.')
  set lintRules(List<AbstractAnalysisRule> value) {
    _lintRules = value;
    _clearCachedSignatures();
  }

  /// The language version to use for libraries that are not in a package.
  ///
  /// If a library is in a package, this language version is *not* used,
  /// even if the package does not specify the language version.
  Version get nonPackageLanguageVersion => ExperimentStatus.currentVersion;

  List<PluginConfiguration> get pluginConfigurations =>
      pluginsOptions.configurations;

  Uint32List get signature {
    if (_signature == null) {
      ApiSignature buffer = ApiSignature();

      // Append boolean flags.
      buffer.addBool(propagateLinterExceptions);
      buffer.addBool(strictCasts);
      buffer.addBool(strictInference);
      buffer.addBool(strictRawTypes);

      // Append features.
      buffer.addInt(ExperimentStatus.knownFeatures.length);
      for (var feature in ExperimentStatus.knownFeatures.values) {
        buffer.addBool(contextFeatures.isEnabled(feature));
      }

      // Append error processors.
      buffer.addInt(errorProcessors.length);
      for (ErrorProcessor processor in errorProcessors.sortedBy(
        (processor) => processor.description,
      )) {
        buffer.addString(processor.description);
      }

      // Append lints.
      buffer.addInt(lintRules.length);
      for (var lintRule in lintRules.sortedBy((lintRule) => lintRule.name)) {
        buffer.addString(lintRule.name);
      }

      // Append legacy plugin names.
      buffer.addInt(enabledLegacyPluginNames.length);
      for (var enabledLegacyPluginName in enabledLegacyPluginNames.sorted()) {
        buffer.addString(enabledLegacyPluginName);
      }

      // Append plugin configurations.
      buffer.addInt(pluginConfigurations.length);
      for (var pluginConfiguration in pluginConfigurations.sortedBy(
        (pluginConfiguration) => pluginConfiguration.name,
      )) {
        buffer.addString(pluginConfiguration.name);
        buffer.addBool(pluginConfiguration.isEnabled);
        switch (pluginConfiguration.source) {
          case GitPluginSource source:
            buffer.addString(source.url);
            if (source.path case var path?) {
              buffer.addString(path);
            }
            if (source.ref case var ref?) {
              buffer.addString(ref);
            }
            if (source.tagPattern case var tagPattern?) {
              buffer.addString(tagPattern);
            }
          case PathPluginSource source:
            buffer.addString(source.path);
          case VersionedPluginSource source:
            buffer.addString(source.constraint);
            if (source.hostedUrl case var hostedUrl?) {
              buffer.addString(hostedUrl);
            }
        }
        buffer.addInt(pluginConfiguration.diagnosticConfigs.length);
        for (var diagnosticConfig
            in pluginConfiguration.diagnosticConfigs.values) {
          buffer.addString(diagnosticConfig.group ?? '');
          buffer.addString(diagnosticConfig.name);
          buffer.addInt(diagnosticConfig.severity.index);
        }
        if (pluginsOptions.dependencyOverrides case var dependencyOverrides?) {
          for (var pluginDependencyOverrideEntry
              in dependencyOverrides.entries.sortedBy((entry) => entry.key)) {
            buffer.addString(pluginDependencyOverrideEntry.key);
            switch (pluginDependencyOverrideEntry.value) {
              case GitPluginSource source:
                buffer.addString(source.url);
                if (source.path case var path?) {
                  buffer.addString(path);
                }
                if (source.ref case var ref?) {
                  buffer.addString(ref);
                }
                if (source.tagPattern case var tagPattern?) {
                  buffer.addString(tagPattern);
                }
              case PathPluginSource source:
                buffer.addString(source.path);
              case VersionedPluginSource source:
                buffer.addString(source.constraint);
            }
          }
        }
      }

      // Hash and convert to Uint32List.
      _signature = buffer.toUint32List();
    }
    return _signature!;
  }

  Uint32List get signatureForElements {
    if (_signatureForElements == null) {
      ApiSignature buffer = ApiSignature();

      // Append features.
      buffer.addInt(ExperimentStatus.knownFeatures.length);
      for (var feature in ExperimentStatus.knownFeatures.values) {
        buffer.addBool(contextFeatures.isEnabled(feature));
      }

      // Hash and convert to Uint32List.
      _signatureForElements = buffer.toUint32List();
    }
    return _signatureForElements!;
  }

  /// The opaque signature of the options that affect unlinked data.
  Uint32List get unlinkedSignature {
    if (_unlinkedSignature == null) {
      ApiSignature buffer = ApiSignature();

      // Append the current language version.
      buffer.addInt(ExperimentStatus.currentVersion.major);
      buffer.addInt(ExperimentStatus.currentVersion.minor);

      // Append features.
      buffer.addInt(ExperimentStatus.knownFeatures.length);
      for (var feature in ExperimentStatus.knownFeatures.values) {
        buffer.addBool(contextFeatures.isEnabled(feature));
      }

      // Hash and convert to Uint32List.
      return buffer.toUint32List();
    }
    return _unlinkedSignature!;
  }

  @override
  bool get warning => _warning;

  @Deprecated('Use AnalysisOptionsBuilder instead.')
  set warning(bool value) {
    _warning = value;
    _clearCachedSignatures();
  }

  @override
  bool isLintEnabled(String name) {
    return lintRules.any((rule) => rule.name == name);
  }

  /// Returns a "debug information" map of this set of analysis options.
  ///
  /// This map can be presented in different formats, like text in a
  /// terminal, or HTML.
  Map<String, Object> toDebugInfo() {
    return {
      'enable-experiment': contextFeatures,
      'diagnostic severities': {
        for (var processor in errorProcessors)
          processor.code: processor.severity,
      },
      'excludes': excludePatterns,
      'lint rules': lintRules.map(
        (e) => DebugLink(e.name, e.diagnosticCodes.first.url),
      ),
      'strict-casts': strictCasts,
      'strict-inference': strictInference,
      'strict-raw-types': strictRawTypes,
      'formatter': {
        'page_width': ?formatterOptions.pageWidth,
        'trailing_commas': ?formatterOptions.trailingCommas,
      },
      'chrome_os_manifest_checks': chromeOsManifestChecks,
      'legacy plugins': enabledLegacyPluginNames,
      for (var pluginConfiguration in pluginConfigurations)
        // TODO(srawlins): Having a top-level 'plugins' section, and then a Map
        // for each plugin is way too nested in the HTML table. This
        // interpolated "plugins/foo" section solves that, but is a bit hacky.
        // It'd be nice to have a general way in the Insights HTML to have a
        // cell with `colspan=2` and then each plugin Map inside that.
        'plugins/${pluginConfiguration.name}': {
          'enabled': pluginConfiguration.isEnabled,
          'diagnostics': [
            for (var MapEntry(key: ruleName, value: ruleConfig)
                in pluginConfiguration.diagnosticConfigs.entries)
              {ruleName: ruleConfig.severity.name},
          ],
          'source': DebugCodeBlock(
            pluginConfiguration.source
                .toYaml(name: pluginConfiguration.name)
                .trimRight(),
            lang: 'yaml',
          ),
        },
    };
  }

  void _clearCachedSignatures() {
    _unlinkedSignature = null;
    _signature = null;
    _signatureForElements = null;
  }
}

/// A code block for use as "debug information."
final class DebugCodeBlock {
  final String text;
  final String? lang;
  DebugCodeBlock(this.text, {this.lang});
}

/// A debug link object, to be rendered as a Markdown link or an HTML link.
///
/// If [url] is `null`, then the [text] is to be rendered as plain text.
final class DebugLink {
  final String text;
  final String? url;
  DebugLink(this.text, this.url);
}

final class GitPluginSource implements PluginSource {
  final String url;

  final String? path;

  final String? ref;

  final String? tagPattern;

  GitPluginSource({required this.url, this.path, this.ref, this.tagPattern});

  @override
  int get hashCode => Object.hash(url, path, ref, tagPattern);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitPluginSource &&
          url == other.url &&
          path == other.path &&
          ref == other.ref &&
          tagPattern == other.tagPattern;

  @override
  String toYaml({required String name}) {
    var buffer = StringBuffer()
      ..writeln('  $name:')
      ..writeln('    git:')
      ..writeln('      url: $url');
    if (ref != null) {
      buffer.writeln('      ref: $ref');
    }
    if (path != null) {
      buffer.writeln('      path: $path');
    }
    if (tagPattern != null) {
      buffer.writeln('      tag_pattern: $tagPattern');
    }
    return buffer.toString();
  }
}

final class PathPluginSource implements PluginSource {
  final String path;

  PathPluginSource({required this.path});

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PathPluginSource && path == other.path;

  @override
  String toYaml({required String name}) =>
      '''
  $name:
    path: $path
''';
}

/// The configuration of a Dart Analysis Server plugin, as specified by
/// analysis options.
final class PluginConfiguration {
  /// The name of the plugin being configured.
  final String name;

  /// The source of the plugin being configured.
  final PluginSource source;

  /// The list of specified [DiagnosticConfig]s.
  final Map<String, DiagnosticConfig> diagnosticConfigs;

  /// Whether the plugin is enabled.
  final bool isEnabled;

  PluginConfiguration({
    required this.name,
    required this.source,
    Map<String, DiagnosticConfig> diagnosticConfigs = const {},
    this.isEnabled = true,
  }) : diagnosticConfigs = LinkedHashMap(
         equals: _caseInsensitiveEquals,
         hashCode: _caseInsensitiveHash,
       )..addAll(diagnosticConfigs);

  String sourceYaml() => source.toYaml(name: name);

  static bool _caseInsensitiveEquals(String s1, String s2) =>
      s1.toLowerCase() == s2.toLowerCase();

  static int _caseInsensitiveHash(String s) => s.toLowerCase().hashCode;
}

/// The analysis options for plugins, as specified in the top-level `plugins`
/// section.
final class PluginsOptions {
  /// The list of each listed plugin's configuration.
  final List<PluginConfiguration> configurations;

  /// The dependency overrides, if specified.
  final Map<String, PluginSource>? dependencyOverrides;

  PluginsOptions({
    required this.configurations,
    required this.dependencyOverrides,
  });
}

/// A description of the source of a plugin.
///
/// We support all of the source formats documented at
/// https://dart.dev/tools/pub/dependencies.
sealed class PluginSource {
  /// Returns the YAML-formatted source, using [name] as a key, for writing into
  /// a pubspec 'dependencies' section.
  String toYaml({required String name});
}

/// A plugin source using a version constraint, hosted either at pub.dev or
/// another host.
final class VersionedPluginSource implements PluginSource {
  /// The specified version constraint.
  final String constraint;
  final String? hostedUrl;

  VersionedPluginSource({required this.constraint, this.hostedUrl});

  @override
  int get hashCode => Object.hash(constraint, hostedUrl);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersionedPluginSource &&
          constraint == other.constraint &&
          hostedUrl == other.hostedUrl;

  @override
  String toYaml({required String name}) {
    if (hostedUrl == null) {
      return '  $name: $constraint\n';
    }

    var buffer = StringBuffer()
      ..writeln('  $name:')
      ..writeln('    version: $constraint')
      ..writeln('    hosted: $hostedUrl');

    return buffer.toString();
  }
}
