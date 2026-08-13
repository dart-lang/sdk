// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'analysis_options_parser.dart';

/// Walks the initial options file and its includes for one parse request.
///
/// This class owns the fixed dependencies for include traversal. Recursive
/// state is passed through [_IncludeWalkState], so each call receives the file,
/// reporter/listener pair, include chain, and first include span that apply to
/// that point in the include graph.
final class _AnalysisOptionsIncludeWalker {
  final RecordingDiagnosticListener initialDiagnosticListener;
  final DiagnosticReporter initialDiagnosticReporter;
  final _ParsedFileNode initialParsedFileNode;
  final Folder contextRoot;
  final _ParsedFileSemantics Function(
    _ParsedFileNode fileNode, {
    required bool isInitialFile,
    required Set<File> includeChainFiles,
  })
  fileSemantics;

  _AnalysisOptionsIncludeWalker({
    required this.initialDiagnosticListener,
    required this.initialDiagnosticReporter,
    required this.initialParsedFileNode,
    required this.contextRoot,
    required this.fileSemantics,
  });

  File get initialFile => initialParsedFileNode.file;

  List<Diagnostic> walk() {
    _walk(
      _IncludeWalkState(
        parsedFileNode: initialParsedFileNode,
        diagnosticListener: initialDiagnosticListener,
        diagnosticReporter: initialDiagnosticReporter,
        initialIncludeSpan: null,
        includeChain: const {},
      ),
    );
    return initialDiagnosticListener.diagnostics;
  }

  void _reportIncludedFileParseError({
    required _MalformedYamlFileNode file,
    required SourceSpan initialIncludeSpan,
  }) {
    // Report diagnostics for included option files on the `include` directive
    // located in the initial options file.
    var failure = file.failure;
    var span = failure.span!;
    initialDiagnosticReporter.report(
      diag.includedFileParseError
          .withArguments(
            includingFilePath: file.file.path,
            startOffset: span.start.offset,
            endOffset: span.end.offset,
            errorMessage: failure.message,
          )
          .atSourceSpan(initialIncludeSpan),
    );
  }

  void _walk(_IncludeWalkState state) {
    var semantics = fileSemantics(
      state.parsedFileNode,
      isInitialFile: state.file == initialFile,
      includeChainFiles: state.includeChain.keys.toSet(),
    );
    for (var diagnostic in semantics.localData.diagnostics) {
      state.diagnosticListener.onDiagnostic(diagnostic);
    }

    var legacyPlugins = semantics.localData.analyzer.legacyPlugins;
    var includes = state.parsedFileNode.includeResolutions;
    if (includes.isEmpty) {
      legacyPlugins.reportLocalMultiplePlugins(state.diagnosticReporter);
      return;
    }

    for (var include in includes) {
      var includeSpan = include.include.node.span;
      _walkInclude(
        state: state,
        include: include,
        initialIncludeSpan: state.initialIncludeSpan ?? includeSpan,
      );
    }

    if (semantics.includedLegacyPluginName case var includedPluginName?) {
      legacyPlugins.reportMultiplePluginsWithIncluded(
        state.diagnosticReporter,
        includedPluginName: includedPluginName,
      );
    } else {
      legacyPlugins.reportLocalMultiplePlugins(state.diagnosticReporter);
    }

    _LinterRuleDiagnostics.reportIncompatibleIncluded(
      reporter: state.diagnosticReporter,
      includedRules: semantics.includedLinterRules,
      disabledRules: semantics.localData.localLinterRules.disabled,
    );

    _LinterRuleDiagnostics.reportIncompatibleWithIncluded(
      reporter: state.diagnosticReporter,
      localRules: semantics.localData.localLinterRules,
      includedRules: semantics.includedEffectiveLinterRules,
    );
  }

  void _walkInclude({
    required _IncludeWalkState state,
    required _IncludeResolution include,
    required SourceSpan initialIncludeSpan,
  }) {
    var includeSpan = include.include.node.span;
    var includeUri = include.include.uri;
    switch (include) {
      case _MissingInclude():
        initialDiagnosticReporter.report(
          diag.includeFileNotFound
              .withArguments(
                includedUri: includeUri,
                includingFilePath: state.file.path,
                contextRootPath: contextRoot.path,
              )
              .atSourceSpan(initialIncludeSpan),
        );
        return;
      case _MalformedInclude(:var file):
        _reportIncludedFileParseError(
          file: file,
          initialIncludeSpan: initialIncludeSpan,
        );
        return;
      case _ParsedInclude(:var file):
        _walkParsedInclude(
          state: state,
          includeSpan: includeSpan,
          initialIncludeSpan: initialIncludeSpan,
          includeUri: includeUri,
          parsedIncludedFileNode: file,
        );
        return;
    }
  }

  void _walkParsedInclude({
    required _IncludeWalkState state,
    required SourceSpan includeSpan,
    required SourceSpan initialIncludeSpan,
    required String includeUri,
    required _ParsedFileNode parsedIncludedFileNode,
  }) {
    var includedFile = parsedIncludedFileNode.file;
    if (includedFile == initialFile) {
      initialDiagnosticReporter.report(
        diag.recursiveIncludeFile
            .withArguments(
              includedUri: includeUri,
              includingFilePath: state.file.path,
            )
            .atSourceSpan(initialIncludeSpan),
      );
      return;
    }

    assert(!state.includeChain.containsKey(state.file));
    var nextIncludeChain = {...state.includeChain, state.file: includeSpan};
    var spanInChain = nextIncludeChain[includedFile];
    if (spanInChain != null) {
      initialDiagnosticReporter.report(
        diag.includedFileWarning
            .withArguments(
              includingFilePath: includedFile.path,
              startOffset: spanInChain.start.offset,
              endOffset: spanInChain.end.offset - 1,
              warningMessage: 'The file includes itself recursively.',
            )
            .atSourceSpan(initialIncludeSpan),
      );
      return;
    }

    var diagnosticListener = _IncludedDiagnosticListener(
      includedFile: includedFile,
      initialDiagnosticReporter: initialDiagnosticReporter,
      initialIncludeSpan: initialIncludeSpan,
    );
    _walk(
      _IncludeWalkState(
        parsedFileNode: parsedIncludedFileNode,
        diagnosticListener: diagnosticListener,
        diagnosticReporter: DiagnosticReporter(
          diagnosticListener,
          FileSource(includedFile),
        ),
        initialIncludeSpan: initialIncludeSpan,
        includeChain: nextIncludeChain,
      ),
    );
  }
}

/// Implementation of [DiagnosticListener] that converts each reported
/// [Diagnostic] into a [diag.includedFileWarning] located at the site of an
/// `include` directive.
///
/// This is used by [_AnalysisOptionsIncludeWalker] to report diagnostics
/// that occur in included options files.
final class _IncludedDiagnosticListener implements DiagnosticListener {
  /// The included options file whose diagnostics are being translated.
  final File includedFile;

  /// The [DiagnosticReporter] for the initial source file (the one containing
  /// the first `include` in the chain of `include`s that's currently being
  /// processed).
  final DiagnosticReporter initialDiagnosticReporter;

  /// The [SourceSpan] of the first `include` in the chain of `include`s that's
  /// currently being processed.
  final SourceSpan initialIncludeSpan;

  _IncludedDiagnosticListener({
    required this.includedFile,
    required this.initialDiagnosticReporter,
    required this.initialIncludeSpan,
  });

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    initialDiagnosticReporter.report(
      diag.includedFileWarning
          .withArguments(
            includingFilePath: includedFile.path,
            startOffset: diagnostic.offset,
            endOffset: diagnostic.offset + diagnostic.length - 1,
            warningMessage: diagnostic.message,
          )
          .atSourceSpan(initialIncludeSpan),
    );
  }
}

/// State for one recursive include-walk call.
final class _IncludeWalkState {
  final _ParsedFileNode parsedFileNode;
  final DiagnosticListener diagnosticListener;
  final DiagnosticReporter diagnosticReporter;
  final SourceSpan? initialIncludeSpan;
  final Map<File, SourceSpan> includeChain;

  _IncludeWalkState({
    required this.parsedFileNode,
    required this.diagnosticListener,
    required this.diagnosticReporter,
    required this.initialIncludeSpan,
    required this.includeChain,
  });

  File get file => parsedFileNode.file;
}
