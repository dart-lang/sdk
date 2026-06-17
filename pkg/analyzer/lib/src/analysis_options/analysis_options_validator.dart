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
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
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

YamlMap _parseOptionsFromString(String content, {Uri? sourceUrl}) {
  try {
    var doc = loadYamlNode(content, sourceUrl: sourceUrl);
    return doc is YamlMap ? doc : YamlMap();
  } on YamlException catch (e) {
    throw OptionsFormatException(e.message, e.span);
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

/// Cache of raw parsed analysis options files used during validation.
///
/// Unlike [AnalysisOptionsCache], this cache stores the unmerged YAML tree for
/// each physical options file. Validation walks include edges itself so that it
/// can report diagnostics against the file where they originate and summarize
/// included-file diagnostics at the including directive.
final class AnalysisOptionsValidationCache {
  final Map<File, _YamlFileParseResult> _map = {};
}

/// Validates analysis options files and produces user-visible diagnostics.
@Deprecated('Use AnalysisOptionsParseSession.parse instead.')
final class AnalysisOptionsValidator {
  final SourceFactory sourceFactory;
  final Folder contextRoot;
  final VersionConstraint? sdkVersionConstraint;
  final AnalysisOptionsValidationCache _validationCache;

  AnalysisOptionsValidator({
    required this.sourceFactory,
    required this.contextRoot,
    this.sdkVersionConstraint,
    required AnalysisOptionsValidationCache validationCache,
  }) : _validationCache = validationCache;

  List<Diagnostic> validate({required File file, required String content}) {
    var initialSource = FileSource(file);
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
      file: file,
      initialFile: file,
      sourceFactory: sourceFactory,
      contextRoot: contextRoot,
      sdkVersionConstraint: sdkVersionConstraint,
      validationCache: _validationCache,
    ).validate(content: content);
  }
}

/// Walks the initial options file and its includes for one validation request.
///
/// This class owns the mutable traversal state for the diagnostic validator:
/// the current file, reporter/listener pair, include chain, first include span,
/// and included legacy plugin state.
/// It deliberately delegates validation of a single already-parsed YAML map to
/// [_OptionsFileValidator]; its responsibility is parsing, include traversal,
/// source ownership, and converting diagnostics from included files into
/// diagnostics reported at the original `include` directive.
final class _AnalysisOptionsValidatorWalker {
  final RecordingDiagnosticListener initialDiagnosticListener;
  final DiagnosticReporter initialDiagnosticReporter;
  DiagnosticListener diagnosticListener;
  DiagnosticReporter diagnosticReporter;
  File file;
  final File initialFile;
  final SourceFactory sourceFactory;
  final Folder contextRoot;
  final VersionConstraint? sdkVersionConstraint;
  final AnalysisOptionsValidationCache validationCache;

  /// The span of the first `include` directive in the include chain currently
  /// being visited.
  SourceSpan? initialIncludeSpan;

  /// The first legacy plugin enabled by an included file while walking the
  /// current file's includes.
  String? firstPluginName;

  /// Map whose keys are files containing an `include` directive that is
  /// currently being visited, and whose values are the corresponding spans of
  /// those `include` directives.
  final Map<File, SourceSpan> includeChain = {};

  _AnalysisOptionsValidatorWalker({
    required this.initialDiagnosticListener,
    required this.initialDiagnosticReporter,
    required this.diagnosticListener,
    required this.diagnosticReporter,
    required this.file,
    required this.initialFile,
    required this.sourceFactory,
    required this.contextRoot,
    required this.sdkVersionConstraint,
    required this.validationCache,
  });

  Source get initialSource => initialDiagnosticReporter.source;

  /// Whether the file currently being visited is the initial file.
  bool get isPrimarySource => file == initialFile;

  Source get source => diagnosticReporter.source;

  List<Diagnostic> validate({required String content}) {
    try {
      YamlMap options = _parseOptionsFromString(
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
    // Make sure `initialIncludeSpan`, `file`, `source`, `includeChain`,
    // `diagnosticListener`, and `diagnosticReporter` have been restored to
    // their original states.
    assert(initialIncludeSpan == null);
    assert(file == initialFile);
    assert(identical(source, initialSource));
    assert(includeChain.isEmpty);
    assert(identical(diagnosticListener, initialDiagnosticListener));
    assert(identical(diagnosticReporter, initialDiagnosticReporter));
    return initialDiagnosticListener.diagnostics;
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

  YamlMap _parseIncludedOptions(FileSource source) {
    var file = source.file;
    var result = validationCache._map[file];
    if (result == null) {
      try {
        result = _ParsedYamlFile(
          _parseOptionsFromString(
            file.readAsStringSync(),
            sourceUrl: source.uri,
          ),
        );
      } on OptionsFormatException catch (exception) {
        result = _InvalidYamlFile(exception);
      }
      validationCache._map[file] = result;
    }

    return switch (result) {
      _ParsedYamlFile(:var map) => map,
      _InvalidYamlFile(:var exception) => throw exception,
    };
  }

  /// Validates the specified options and any included option files.
  _EffectiveLinterRules _validate(YamlMap options) {
    var validationResult = _OptionsFileValidator(
      file,
      sdkVersionConstraint: sdkVersionConstraint,
      contextRoot: contextRoot,
      isPrimarySource: isPrimarySource,
    ).validate(options, diagnosticReporter);

    var includeNode = options.valueAt(AnalysisOptionsFileKeys.include);
    if (includeNode == null) {
      // Validate the 'plugins' option in [options], understanding that no other
      // options are included.
      _validateLegacyPluginsOption(diagnosticReporter, options: options);
      return _EffectiveLinterRules.fromLocal(validationResult.linterRules);
    }

    var includes = switch (includeNode) {
      YamlScalar node => [node],
      YamlList(:var nodes) => nodes.whereType<YamlScalar>().toList(),
      _ => const <YamlScalar>[],
    };

    var includedLinterRules = <_IncludedLinterRules>[];
    for (var includeValue in includes) {
      var previousInitialIncludeSpan = initialIncludeSpan;
      try {
        var includeSpan = includeValue.span;
        initialIncludeSpan ??= includeSpan;
        var result = _validateInclude(includeValue);
        if (result != null) {
          includedLinterRules.add(result);
        }
      } finally {
        initialIncludeSpan = previousInitialIncludeSpan;
      }
    }

    _validateLegacyPluginsOption(
      diagnosticReporter,
      options: options,
      firstEnabledPluginName: firstPluginName,
    );

    _LinterRuleOptionsValidator.reportIncompatibleIncluded(
      reporter: diagnosticReporter,
      includedRules: includedLinterRules,
      disabledRules: validationResult.linterRules.disabled,
    );

    var includedEffectiveRules = _mergeIncludedLinterRules(includedLinterRules);
    _LinterRuleOptionsValidator.reportIncompatibleWithIncluded(
      reporter: diagnosticReporter,
      localRules: validationResult.linterRules,
      includedRules: includedEffectiveRules,
    );

    return includedEffectiveRules..applyLocal(validationResult.linterRules);
  }

  _IncludedLinterRules? _validateInclude(YamlScalar includeNode) {
    assert(initialIncludeSpan != null);
    Object? includeValue = includeNode.value;
    if (includeValue is! String) {
      return null;
    }

    var includeSpan = includeNode.span;
    var includeUri = includeValue;
    var includedSource = sourceFactory.resolveUri(source, includeUri);
    if (includedSource is! FileSource) {
      initialDiagnosticReporter.report(
        diag.includeFileNotFound
            .withArguments(
              includedUri: includeUri,
              includingFilePath: file.path,
              contextRootPath: contextRoot.path,
            )
            .atSourceSpan(initialIncludeSpan!),
      );
      return null;
    }

    var includedFile = includedSource.file;
    if (includedFile == initialFile) {
      initialDiagnosticReporter.report(
        diag.recursiveIncludeFile
            .withArguments(
              includedUri: includeUri,
              includingFilePath: file.path,
            )
            .atSourceSpan(initialIncludeSpan!),
      );
      return null;
    }

    if (!includedFile.exists) {
      initialDiagnosticReporter.report(
        diag.includeFileNotFound
            .withArguments(
              includedUri: includeUri,
              includingFilePath: file.path,
              contextRootPath: contextRoot.path,
            )
            .atSourceSpan(initialIncludeSpan!),
      );
      return null;
    }

    try {
      var includedOptions = _parseIncludedOptions(includedSource);
      var previousDiagnosticListener = diagnosticListener;
      var previousDiagnosticReporter = diagnosticReporter;
      var previousFile = file;
      late _EffectiveLinterRules includedLinterRules;
      try {
        assert(includeChain[file] == null);
        includeChain[file] = includeSpan;
        var spanInChain = includeChain[includedFile];
        if (spanInChain != null) {
          initialDiagnosticReporter.report(
            diag.includedFileWarning
                .withArguments(
                  includingFilePath: includedFile.path,
                  startOffset: spanInChain.start.offset,
                  endOffset: spanInChain.end.offset - 1,
                  warningMessage: 'The file includes itself recursively.',
                )
                .atSourceSpan(initialIncludeSpan!),
          );
          return null;
        }
        file = includedFile;
        diagnosticListener = _IncludedDiagnosticListener(
          source: includedSource,
          initialDiagnosticReporter: initialDiagnosticReporter,
          initialIncludeSpan: initialIncludeSpan!,
        );
        diagnosticReporter = DiagnosticReporter(
          diagnosticListener,
          includedSource,
        );
        includedLinterRules = _validate(includedOptions);
      } finally {
        file = previousFile;
        diagnosticListener = previousDiagnosticListener;
        diagnosticReporter = previousDiagnosticReporter;
        includeChain.remove(file);
      }
      firstPluginName ??= _firstPluginName(includedOptions);
      return _IncludedLinterRules(
        includeNode: includeNode,
        rules: includedLinterRules,
      );
    } on OptionsFormatException catch (e) {
      // Report diagnostics for included option files on the `include` directive
      // located in the initial options file.
      initialDiagnosticReporter.report(
        diag.includedFileParseError
            .withArguments(
              includingFilePath: includedFile.path,
              startOffset: e.span!.start.offset,
              endOffset: e.span!.end.offset,
              errorMessage: e.message,
            )
            .atSourceSpan(initialIncludeSpan!),
      );
      return null;
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

/// A YAML file that could be read but could not be parsed as options YAML.
///
/// The original exception keeps the source span from parsing so each including
/// file can report the same included-file parse error at its own include site.
final class _InvalidYamlFile extends _YamlFileParseResult {
  final OptionsFormatException exception;

  _InvalidYamlFile(this.exception);
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

/// A successfully parsed YAML file.
///
/// The map is the raw file contents, before include merging or interpretation
/// as an analysis options object.
final class _ParsedYamlFile extends _YamlFileParseResult {
  final YamlMap map;

  _ParsedYamlFile(this.map);
}

/// The cached outcome of parsing one YAML file.
///
/// Validation caches failures as well as successful parses because a broken
/// shared include should not be reread and reparsed for every options file
/// that includes it during a context rebuild.
sealed class _YamlFileParseResult {}
