// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
import 'package:analyzer/src/analysis_options/analysis_options_parser.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/src/expected_diagnostics.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../../util/diff.dart';
import '../dart/resolution/node_text_expectations.dart';

abstract class AbstractAnalysisOptionsTest
    with ResourceProviderMixin, LintRegistrationMixin {
  late File analysisOptionsFile = getFile(
    '$testPackageRootPath/analysis_options.yaml',
  );

  String get testPackageRootPath => '/home/test';

  void assertAnalysisOptionsText(AnalysisOptionsImpl options, String expected) {
    var actual = _AnalysisOptionsTextWriter().write(options);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  AnalysisOptionsParseResult parseAnalysisOptionsFile(
    File file, {
    AnalysisOptionsParseSession? parseSession,
    Map<String, Folder>? packageMap,
    VersionConstraint? sdkVersionConstraint,
  }) {
    parseSession ??= AnalysisOptionsParseSession();

    var sourceFactory = SourceFactoryImpl([
      ResourceUriResolver(resourceProvider),
      if (packageMap != null)
        PackageMapUriResolver(resourceProvider, packageMap),
    ]);

    return parseSession.parse(
      sourceFactory: sourceFactory,
      contextRoot: getFolder(testPackageRootPath),
      file: file,
      sdkVersionConstraint: sdkVersionConstraint,
    );
  }

  AnalysisOptionsImpl parseAnalysisOptionsFilesWithDiagnostics(
    Map<File, String> codeByFile, {
    AnalysisOptionsParseSession? parseSession,
    Map<String, Folder>? packageMap,
    VersionConstraint? sdkVersionConstraint,
  }) {
    if (codeByFile.isEmpty) {
      fail('Cannot parse analysis options: no content was provided.');
    }
    var cleanCodeByFile = _writeFilesWithoutDiagnosticExpectations(codeByFile);
    var initialFile = cleanCodeByFile.keys.first;

    var result = parseAnalysisOptionsFile(
      initialFile,
      parseSession: parseSession,
      packageMap: packageMap,
      sdkVersionConstraint: sdkVersionConstraint,
    );

    _assertDiagnosticMarkersInFiles(
      codeByFile: codeByFile,
      diagnostics: result.diagnostics,
    );

    return result.analysisOptions;
  }

  AnalysisOptionsImpl parseAnalysisOptionsWithDiagnostics(
    String code, {
    AnalysisOptionsParseSession? parseSession,
    Map<String, Folder>? packageMap,
    VersionConstraint? sdkVersionConstraint,
  }) {
    return parseAnalysisOptionsFilesWithDiagnostics(
      {analysisOptionsFile: code},
      parseSession: parseSession,
      packageMap: packageMap,
      sdkVersionConstraint: sdkVersionConstraint,
    );
  }

  @mustCallSuper
  void setUp() {}

  @mustCallSuper
  void tearDown() {
    unregisterLintRules();
  }

  void _assertDiagnosticMarkersInFiles({
    required Map<File, String> codeByFile,
    required List<Diagnostic> diagnostics,
  }) {
    var cleanCodeByFile = {
      for (var entry in codeByFile.entries)
        entry.key: removeDiagnosticExpectations(entry.value),
    };
    var actualCodeByFile = updateExpectedDiagnosticsForFiles(
      contentByFile: cleanCodeByFile,
      actualDiagnosticsByFile: _diagnosticsByFile(
        files: codeByFile.keys,
        diagnostics: diagnostics,
      ),
    );

    var hasMismatch = false;
    var index = 0;
    for (var entry in codeByFile.entries) {
      var actual = actualCodeByFile[entry.key]!;
      if (actual != entry.value) {
        NodeTextExpectationsCollector.add(actual, intraInvocationId: '$index');
        if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
          print('-------- ${entry.key.path} --------');
          printPrettyDiff(entry.value, actual);
        }
        hasMismatch = true;
      }
      index++;
    }

    if (hasMismatch) {
      fail('See the difference above.');
    }
  }

  Map<File, List<Diagnostic>> _diagnosticsByFile({
    required Iterable<File> files,
    required List<Diagnostic> diagnostics,
  }) {
    var fileByPath = {for (var file in files) file.path: file};
    var diagnosticsByFile = {for (var file in files) file: <Diagnostic>[]};

    for (var diagnostic in diagnostics) {
      var filePath = diagnostic.problemMessage.filePath;
      var file = fileByPath[filePath];
      if (file == null) {
        fail(
          'Cannot generate diagnostic expectations for $filePath: '
          'no content was provided.',
        );
      }
      diagnosticsByFile[file]!.add(diagnostic);
    }

    return diagnosticsByFile;
  }

  Map<File, String> _writeFilesWithoutDiagnosticExpectations(
    Map<File, String> codeByFile,
  ) {
    var cleanCodeByFile = {
      for (var entry in codeByFile.entries)
        entry.key: removeDiagnosticExpectations(entry.value),
    };
    for (var entry in cleanCodeByFile.entries) {
      entry.key.writeAsStringSync(entry.value);
    }
    return cleanCodeByFile;
  }
}

final class _AnalysisOptionsTextWriter {
  final StringBuffer _buffer = StringBuffer();
  late final TreeStringSink _sink = TreeStringSink(sink: _buffer, indent: '');

  late final AnalysisOptionsImpl _defaultOptions;

  String write(AnalysisOptionsImpl options) {
    _defaultOptions = AnalysisOptionsImpl(file: options.file);

    _sink.writelnWithIndent('AnalysisOptionsImpl');
    _sink.withIndent(() {
      _writeFeatureSet(
        'contextFeatures',
        options.contextFeatures,
        _defaultOptions.contextFeatures,
      );
      _writeFeatureSet(
        'nonPackageFeatureSet',
        options.nonPackageFeatureSet,
        _defaultOptions.nonPackageFeatureSet,
      );

      _writeErrorProcessors(options.errorProcessors);
      _writeStringSet(
        'unignorableDiagnosticCodeNames',
        options.unignorableDiagnosticCodeNames,
      );
      _writeStringList('excludePatterns', options.excludePatterns);

      _writeBool('lint', options.lint, _defaultOptions.lint);
      _writeLintRules(options.lintRules);
      _writeBool('warning', options.warning, _defaultOptions.warning);

      _writeBool(
        'strictCasts',
        options.strictCasts,
        _defaultOptions.strictCasts,
      );
      _writeBool(
        'strictInference',
        options.strictInference,
        _defaultOptions.strictInference,
      );
      _writeBool(
        'strictRawTypes',
        options.strictRawTypes,
        _defaultOptions.strictRawTypes,
      );
      _writeBool(
        'chromeOsManifestChecks',
        options.chromeOsManifestChecks,
        _defaultOptions.chromeOsManifestChecks,
      );
      _writeBool(
        'propagateLinterExceptions',
        options.propagateLinterExceptions,
        _defaultOptions.propagateLinterExceptions,
      );

      _writeCodeStyleOptions(options);
      _writeFormatterOptions(options);

      _writeStringList(
        'enabledLegacyPluginNames',
        options.enabledLegacyPluginNames,
      );
      _writePluginsOptions(options.pluginsOptions);
    });
    return _buffer.toString();
  }

  String _toPosixPath(String filePath) {
    if (filePath.startsWith(r'C:\')) {
      return filePath.substring(2).replaceAll(r'\', '/');
    }
    return filePath;
  }

  void _writeBool(String name, bool value, bool defaultValue) {
    if (value != defaultValue) {
      _sink.writelnWithIndent('$name: $value');
    }
  }

  void _writeCodeStyleOptions(AnalysisOptionsImpl options) {
    var codeStyleOptions = options.codeStyleOptions;
    var defaultCodeStyleOptions = _defaultOptions.codeStyleOptions;
    var properties = <String>[];

    void addBoolProperty(String name, bool value, bool defaultValue) {
      if (value != defaultValue) {
        properties.add('$name: $value');
      }
    }

    void addStringProperty(String name, String value, String defaultValue) {
      if (value != defaultValue) {
        properties.add('$name: $value');
      }
    }

    addBoolProperty(
      'addTrailingCommas',
      codeStyleOptions.addTrailingCommas,
      defaultCodeStyleOptions.addTrailingCommas,
    );
    addBoolProperty(
      'avoidAnnotatingWithDynamic',
      codeStyleOptions.avoidAnnotatingWithDynamic,
      defaultCodeStyleOptions.avoidAnnotatingWithDynamic,
    );
    addBoolProperty(
      'avoidRenamingMethodParameters',
      codeStyleOptions.avoidRenamingMethodParameters,
      defaultCodeStyleOptions.avoidRenamingMethodParameters,
    );
    addBoolProperty(
      'finalInForEach',
      codeStyleOptions.finalInForEach,
      defaultCodeStyleOptions.finalInForEach,
    );
    addBoolProperty(
      'makeLocalsFinal',
      codeStyleOptions.makeLocalsFinal,
      defaultCodeStyleOptions.makeLocalsFinal,
    );
    addBoolProperty(
      'preferConstDeclarations',
      codeStyleOptions.preferConstDeclarations,
      defaultCodeStyleOptions.preferConstDeclarations,
    );
    addBoolProperty(
      'preferIntLiterals',
      codeStyleOptions.preferIntLiterals,
      defaultCodeStyleOptions.preferIntLiterals,
    );
    addStringProperty(
      'preferredQuoteForStrings',
      codeStyleOptions.preferredQuoteForStrings,
      defaultCodeStyleOptions.preferredQuoteForStrings,
    );
    addBoolProperty(
      'requiredNamedParametersFirst',
      codeStyleOptions.requiredNamedParametersFirst,
      defaultCodeStyleOptions.requiredNamedParametersFirst,
    );
    addBoolProperty(
      'sortCombinators',
      codeStyleOptions.sortCombinators,
      defaultCodeStyleOptions.sortCombinators,
    );
    addBoolProperty(
      'sortConstructorsFirst',
      codeStyleOptions.sortConstructorsFirst,
      defaultCodeStyleOptions.sortConstructorsFirst,
    );
    addBoolProperty(
      'sortUnnamedConstructorsFirst',
      codeStyleOptions.sortUnnamedConstructorsFirst,
      defaultCodeStyleOptions.sortUnnamedConstructorsFirst,
    );
    addBoolProperty(
      'specifyReturnTypes',
      codeStyleOptions.specifyReturnTypes,
      defaultCodeStyleOptions.specifyReturnTypes,
    );
    addBoolProperty(
      'specifyTypes',
      codeStyleOptions.specifyTypes,
      defaultCodeStyleOptions.specifyTypes,
    );
    addBoolProperty(
      'useFormatter',
      codeStyleOptions.useFormatter,
      defaultCodeStyleOptions.useFormatter,
    );
    addBoolProperty(
      'usePackageUris',
      codeStyleOptions.usePackageUris,
      defaultCodeStyleOptions.usePackageUris,
    );
    addBoolProperty(
      'useRelativeUris',
      codeStyleOptions.useRelativeUris,
      defaultCodeStyleOptions.useRelativeUris,
    );

    _sink.writeElements('codeStyleOptions', properties, (property) {
      _sink.writelnWithIndent(property);
    });
  }

  void _writeErrorProcessors(List<ErrorProcessor> processors) {
    _sink.writeElements('errorProcessors', processors, (processor) {
      var severity = processor.severity?.name.toLowerCase() ?? 'ignore';
      _sink.writelnWithIndent('${processor.code}: $severity');
    });
  }

  void _writeFeatureSet(
    String name,
    FeatureSet featureSet,
    FeatureSet defaultFeatureSet,
  ) {
    var changedFeatures = <String>[];
    for (var entry in ExperimentStatus.knownFeatures.entries) {
      var featureName = entry.key;
      var feature = entry.value;
      var isEnabled = featureSet.isEnabled(feature);
      if (isEnabled != defaultFeatureSet.isEnabled(feature)) {
        changedFeatures.add('$featureName: $isEnabled');
      }
    }

    _sink.writeElements(name, changedFeatures, (feature) {
      _sink.writelnWithIndent(feature);
    });
  }

  void _writeFormatterOptions(AnalysisOptionsImpl options) {
    var formatterOptions = options.formatterOptions;
    var defaultFormatterOptions = _defaultOptions.formatterOptions;
    var properties = <String>[];

    if (formatterOptions.pageWidth != defaultFormatterOptions.pageWidth) {
      properties.add('pageWidth: ${formatterOptions.pageWidth}');
    }
    if (formatterOptions.trailingCommas !=
        defaultFormatterOptions.trailingCommas) {
      properties.add(
        'trailingCommas: ${formatterOptions.trailingCommas?.name}',
      );
    }

    _sink.writeElements('formatterOptions', properties, (property) {
      _sink.writelnWithIndent(property);
    });
  }

  void _writeGitPluginSource(GitPluginSource source) {
    _sink.writelnWithIndent('source: GitPluginSource');
    _sink.withIndent(() {
      _sink.writelnWithIndent('url: ${source.url}');
      if (source.ref case var ref?) {
        _sink.writelnWithIndent('ref: $ref');
      }
      if (source.path case var path?) {
        _sink.writelnWithIndent('path: $path');
      }
      if (source.tagPattern case var tagPattern?) {
        _sink.writelnWithIndent('tagPattern: $tagPattern');
      }
    });
  }

  void _writeLintRules(List<AbstractAnalysisRule> lintRules) {
    var ruleNames = lintRules.map((rule) => rule.name).toList();
    _sink.writeElements('lintRules', ruleNames, (ruleName) {
      _sink.writelnWithIndent(ruleName);
    });
  }

  void _writePathPluginSource(PathPluginSource source) {
    _sink.writelnWithIndent('source: PathPluginSource');
    _sink.withIndent(() {
      _sink.writelnWithIndent('path: ${_toPosixPath(source.path)}');
    });
  }

  void _writePluginsOptions(PluginsOptions options) {
    var dependencyOverrides = options.dependencyOverrides;
    if (options.configurations.isEmpty &&
        (dependencyOverrides == null || dependencyOverrides.isEmpty)) {
      return;
    }

    _sink.writelnWithIndent('pluginsOptions');
    _sink.withIndent(() {
      _sink.writeElements('configurations', options.configurations, (
        configuration,
      ) {
        _sink.writelnWithIndent(configuration.name);
        _sink.withIndent(() {
          if (!configuration.isEnabled) {
            _sink.writelnWithIndent('isEnabled: false');
          }
          _writePluginSource(configuration.source);
          _sink.writeElements(
            'diagnosticConfigs',
            configuration.diagnosticConfigs.values.toList(),
            (config) {
              _sink.writelnWithIndent(
                '${config.name}: ${config.severity.name}',
              );
            },
          );
        });
      });

      if (dependencyOverrides != null) {
        _sink.writeElements(
          'dependencyOverrides',
          dependencyOverrides.entries.toList(),
          (entry) {
            _sink.writelnWithIndent(entry.key);
            _sink.withIndent(() {
              _writePluginSource(entry.value);
            });
          },
        );
      }
    });
  }

  void _writePluginSource(PluginSource source) {
    switch (source) {
      case GitPluginSource():
        _writeGitPluginSource(source);
      case PathPluginSource():
        _writePathPluginSource(source);
      case VersionedPluginSource():
        _writeVersionedPluginSource(source);
    }
  }

  void _writeStringList(String name, List<String> values) {
    _sink.writeElements(name, values, (value) {
      _sink.writelnWithIndent(value);
    });
  }

  void _writeStringSet(String name, Set<String> values) {
    _sink.writeElements(name, values.sorted(), (value) {
      _sink.writelnWithIndent(value);
    });
  }

  void _writeVersionedPluginSource(VersionedPluginSource source) {
    _sink.writelnWithIndent('source: VersionedPluginSource');
    _sink.withIndent(() {
      _sink.writelnWithIndent('constraint: ${source.constraint}');
      if (source.hostedUrl case var hostedUrl?) {
        _sink.writelnWithIndent('hosted: $hostedUrl');
      }
    });
  }
}
