// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/lint/config.dart';

/// A set of analysis options used to control the behavior of an analysis
/// context.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisOptions {
  /// A flag indicating whether to run checks on AndroidManifest.xml file to
  /// see if it is complaint with Chrome OS.
  bool get chromeOsManifestChecks;

  /// Return the options used to control the code that is generated.
  CodeStyleOptions get codeStyleOptions;

  /// The set of features that are globally enabled for this context.
  FeatureSet get contextFeatures;

  /// A list of the names of the packages for which, if they define a
  /// legacy plugin, the legacy plugin should be enabled.
  List<String> get enabledLegacyPluginNames;

  /// The list of error processors that are to be used when reporting errors in
  /// some analysis context.
  List<ErrorProcessor> get errorProcessors;

  /// The list of exclude patterns used to exclude some sources from analysis.
  List<String> get excludePatterns;

  /// The options used to control the formatter.
  FormatterOptions get formatterOptions;

  /// Whether analysis is to generate lint warnings.
  bool get lint;

  /// A list of the lint rules that are to be run in an analysis context if
  /// [lint] is `true`.
  // ignore: analyzer_public_api_bad_type
  List<AbstractAnalysisRule> get lintRules;

  /// The plugin configurations for each plugin which is configured in analysis
  /// options.
  ///
  /// These are distinct from the legacy plugins found at
  /// [enabledLegacyPluginNames].
  @Deprecated('This will be removed without replacement')
  List<PluginConfiguration> get pluginConfigurations;

  /// Whether implicit casts should be reported as potential problems.
  bool get strictCasts;

  /// Whether inference failures are allowed, off by default.
  bool get strictInference;

  /// Whether raw types (types without explicit type arguments, such as `List`)
  /// should be reported as potential problems.
  ///
  /// Raw types are a common source of `dynamic` being introduced implicitly.
  bool get strictRawTypes;

  /// Return `true` if analysis is to generate warning results (e.g. best
  /// practices and analysis based on certain annotations).
  bool get warning;

  /// Return `true` the lint with the given [name] is enabled.
  bool isLintEnabled(String name);
}

final class GitPluginSource implements PluginSource {
  final String _url;

  final String? _path;

  final String? _ref;

  GitPluginSource({required String url, String? path, String? ref})
    : _url = url,
      _path = path,
      _ref = ref;

  @override
  String toYaml({required String name}) {
    var buffer = StringBuffer()
      ..writeln('  $name:')
      ..writeln('    git:')
      ..writeln('      url: $_url');
    if (_ref != null) {
      buffer.writeln('      ref: $_ref');
    }
    if (_path != null) {
      buffer.writeln('      path: $_path');
    }
    return buffer.toString();
  }
}

final class PathPluginSource implements PluginSource {
  final String _path;

  PathPluginSource({required String path}) : _path = path;

  @override
  String toYaml({required String name}) =>
      '''
  $name:
    path: $_path
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
  // ignore: analyzer_public_api_bad_type
  final Map<String, DiagnosticConfig> diagnosticConfigs;

  /// Whether the plugin is enabled.
  final bool isEnabled;

  // ignore: analyzer_public_api_bad_type
  PluginConfiguration({
    required this.name,
    required this.source,
    this.diagnosticConfigs = const {},
    this.isEnabled = true,
  });

  String sourceYaml() => source.toYaml(name: name);
}

/// A description of the source of a plugin.

/// We support all of the source formats documented at
/// https://dart.dev/tools/pub/dependencies.
sealed class PluginSource {
  /// Returns the YAML-formatted source, using [name] as a key, for writing into
  /// a pubspec 'dependencies' section.
  String toYaml({required String name});
}

/// A plugin source using a version constraint, hosted either at pub.dev or
/// another host.
// TODO(srawlins): Support a different 'hosted' URL.
final class VersionedPluginSource implements PluginSource {
  /// The specified version constraint.
  final String _constraint;

  VersionedPluginSource({required String constraint})
    : _constraint = constraint;

  @override
  String toYaml({required String name}) => '  $name: $_constraint\n';
}
