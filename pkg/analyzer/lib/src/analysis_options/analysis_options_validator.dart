// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/options_validator.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/source.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

part 'linter_rule_options_validator.dart';
part 'options_file_validator.dart';

/// Returns the name of the first legacy plugin, if one is specified in
/// [options], otherwise `null`.
String? _firstPluginName(YamlMap options) {
  var analyzerMap = options.valueAt(AnalysisOptionsFileKeys.analyzer);
  if (analyzerMap is! YamlMap) {
    return null;
  }
  var plugins = analyzerMap.valueAt(AnalysisOptionsFileKeys.plugins);
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

/// Validates analysis options files and produces user-visible diagnostics.
final class AnalysisOptionsValidator {
  final SourceFactory sourceFactory;
  final ResourceProvider resourceProvider;
  final String contextRoot;
  final VersionConstraint? sdkVersionConstraint;
  final AnalysisOptionsCache _analysisOptionsCache;

  AnalysisOptionsValidator({
    required this.sourceFactory,
    required this.resourceProvider,
    required this.contextRoot,
    this.sdkVersionConstraint,
    AnalysisOptionsCache? analysisOptionsCache,
  }) : _analysisOptionsCache = analysisOptionsCache ?? {};

  List<Diagnostic> validateContent({
    required File file,
    required String content,
  }) {
    var initialSource = sourceFactory.forUri2(file.toUri()) ?? FileSource(file);
    var initialDiagnosticListener = RecordingDiagnosticListener();
    var initialDiagnosticReporter = DiagnosticReporter(
      initialDiagnosticListener,
      initialSource,
    );
    return _AnalysisOptionsValidatorWalker(
      initialDiagnosticListener: initialDiagnosticListener,
      initialDiagnosticReporter: initialDiagnosticReporter,
      diagnosticListener: initialDiagnosticListener,
      diagnosticReporter: initialDiagnosticReporter,
      sourceFactory: sourceFactory,
      contextRoot: contextRoot,
      sdkVersionConstraint: sdkVersionConstraint,
      resourceProvider: resourceProvider,
      optionsProvider: AnalysisOptionsProvider(sourceFactory),
      analysisOptionsCache: _analysisOptionsCache,
    ).validate(content: content);
  }

  List<Diagnostic> validateFile(File file) {
    return validateContent(file: file, content: file.readAsStringSync());
  }
}

/// Walks the initial options file and its includes for one validation request.
///
/// This class owns the mutable traversal state that is awkward to keep on
/// [AnalysisOptionsValidator] itself: the current source, reporter/listener
/// pair, include chain, first include span, and included legacy plugin state.
/// It deliberately delegates validation of a single already-parsed YAML map to
/// [_OptionsFileValidator]; its responsibility is parsing, include traversal,
/// source ownership, and converting diagnostics from included files into
/// diagnostics reported at the original `include` directive.
final class _AnalysisOptionsValidatorWalker {
  final RecordingDiagnosticListener initialDiagnosticListener;
  final DiagnosticReporter initialDiagnosticReporter;
  DiagnosticListener diagnosticListener;
  DiagnosticReporter diagnosticReporter;
  final SourceFactory sourceFactory;
  final String contextRoot;
  final VersionConstraint? sdkVersionConstraint;
  final ResourceProvider resourceProvider;

  /// The span of the first `include` directive in the include chain currently
  /// being visited.
  SourceSpan? initialIncludeSpan;

  final AnalysisOptionsProvider optionsProvider;

  /// The first legacy plugin enabled by an included file while walking the
  /// current file's includes.
  String? firstPluginName;

  /// Map whose keys are source files containing an `include` directive that is
  /// currently being visited, and whose values are the corresponding
  /// [SourceSpan]s of those `include` directives.
  final Map<Source, SourceSpan> includeChain = {};

  final AnalysisOptionsCache _analysisOptionsCache;

  _AnalysisOptionsValidatorWalker({
    required this.initialDiagnosticListener,
    required this.initialDiagnosticReporter,
    required this.diagnosticListener,
    required this.diagnosticReporter,
    required this.sourceFactory,
    required this.contextRoot,
    required this.sdkVersionConstraint,
    required this.resourceProvider,
    required this.optionsProvider,
    required AnalysisOptionsCache analysisOptionsCache,
  }) : _analysisOptionsCache = analysisOptionsCache;

  Source get initialSource => initialDiagnosticReporter.source;

  /// Whether the source file currently being visited is the initial source
  /// file.
  bool get isPrimarySource => source == initialSource;

  Source get source => diagnosticReporter.source;

  List<Diagnostic> validate({required String content}) {
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
    _OptionsFileValidator(
      source,
      sdkVersionConstraint: sdkVersionConstraint,
      contextRoot: contextRoot,
      isPrimarySource: isPrimarySource,
      optionsProvider: optionsProvider,
      sourceFactory: sourceFactory,
      resourceProvider: resourceProvider,
      analysisOptionsCache: _analysisOptionsCache,
    ).validate(options, diagnosticReporter);

    var includeNode = options.valueAt(AnalysisOptionsFileKeys.include);
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

    try {
      var includedOptions = optionsProvider.getOptionsFromString(
        includedSource.stringContents,
      );
      var previousDiagnosticListener = diagnosticListener;
      var previousDiagnosticReporter = diagnosticReporter;
      try {
        assert(includeChain[source] == null);
        includeChain[source] = includeSpan;
        var spanInChain = includeChain[includedSource];
        if (spanInChain != null) {
          initialDiagnosticReporter.report(
            diag.includedFileWarning
                .withArguments(
                  includingFilePath: includedSource.fullName,
                  startOffset: spanInChain.start.offset,
                  endOffset: spanInChain.end.offset - 1,
                  warningMessage: 'The file includes itself recursively.',
                )
                .atSourceSpan(initialIncludeSpan!),
          );
          return;
        }
        diagnosticListener = _IncludedDiagnosticListener(
          source: includedSource,
          initialDiagnosticReporter: initialDiagnosticReporter,
          initialIncludeSpan: initialIncludeSpan!,
        );
        diagnosticReporter = DiagnosticReporter(
          diagnosticListener,
          includedSource,
        );
        _validate(includedOptions);
      } finally {
        diagnosticListener = previousDiagnosticListener;
        diagnosticReporter = previousDiagnosticReporter;
        includeChain.remove(source);
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

/// Implementation of [DiagnosticListener] that converts each reported
/// [Diagnostic] into a [diag.includedFileWarning] located at the site of an
/// `include` directive.
///
/// This is used by [_AnalysisOptionsValidatorWalker] to report diagnostics
/// that occur in included options files.
final class _IncludedDiagnosticListener implements DiagnosticListener {
  /// The [Source] file in which diagnostics are being reported.
  final Source source;

  /// The [DiagnosticReporter] for the initial source file (the one containing
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

/// Validates `analyzer` plugins configuration options.
final class _LegacyPluginsOptionValidator extends OptionsValidator {
  /// The name of the first included legacy plugin, if there is one.
  ///
  /// If there are no included legacy plugins, this is `null`.
  final String? _firstIncludedPluginName;

  _LegacyPluginsOptionValidator(this._firstIncludedPluginName);

  @override
  void validate(DiagnosticReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalysisOptionsFileKeys.analyzer);
    if (analyzer is! YamlMap) {
      return;
    }
    var plugins = analyzer.valueAt(AnalysisOptionsFileKeys.plugins);
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
