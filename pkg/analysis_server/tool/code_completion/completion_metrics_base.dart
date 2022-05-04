// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show stdout;
import 'dart:math' as math;

import 'package:analysis_server/src/services/completion/dart/documentation_cache.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as err;
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:args/args.dart';
import 'package:cli_util/cli_logging.dart';

import 'visitors.dart';

final logger = Logger.standard(ansi: Ansi(Ansi.terminalSupportsAnsi));

/// This is the main metrics computer class for code completions. After the
/// object is constructed, [computeCompletionMetrics] is executed to do analysis
/// and print a summary of the metrics gathered from the completion tests.
abstract class CompletionMetricsComputer {
  final String rootPath;

  final CompletionMetricsOptions options;

  late ResolvedUnitResult resolvedUnitResult;

  final OverlayResourceProvider provider =
      OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);

  int overlayModificationStamp = 0;

  CompletionMetricsComputer(this.rootPath, this.options);

  /// Applies an overlay in [filePath] at [expectedCompletion].
  Future<void> applyOverlay(AnalysisContext context, String filePath,
      ExpectedCompletion expectedCompletion);

  /// Compute the metrics for the files in the context [root], creating a
  /// separate context collection to prevent accumulating memory. The metrics
  /// should be captured in the [collector].
  Future<void> computeInContext(ContextRoot root) async {
    // Create a new collection to avoid consuming large quantities of memory.
    final collection = AnalysisContextCollectionImpl(
      includedPaths: root.includedPaths.toList(),
      excludedPaths: root.excludedPaths.toList(),
      resourceProvider: provider,
    );

    var context = collection.contexts[0];

    setupForResolution(context);

    logger.write('Computing completions at root: ${root.root.path}\n');
    var documentationCache = DocumentationCache(DartdocDirectiveInfo());

    var results = await resolveAnalyzedFiles(
      context: context,
      documentationCache: documentationCache,
    );

    logger.write('Analyzing completion suggestions...\n');
    var progress = ProgressBar(logger, results.length);
    for (var result in results) {
      resolvedUnitResult = result;
      var filePath = result.path;
      // Use the ExpectedCompletionsVisitor to compute the set of expected
      // completions for this CompilationUnit.
      final visitor =
          ExpectedCompletionsVisitor(result, caretOffset: options.prefixLength);
      resolvedUnitResult.unit.accept(visitor);

      for (var expectedCompletion in visitor.expectedCompletions) {
        await applyOverlay(context, filePath, expectedCompletion);

        await computeSuggestionsAndMetrics(
          expectedCompletion,
          context,
          documentationCache,
        );

        removeOverlay(filePath);
      }
      progress.tick();
    }
    progress.complete();
  }

  Future<void> computeMetrics() async {
    final collection = AnalysisContextCollectionImpl(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    for (final context in collection.contexts) {
      await computeInContext(context.contextRoot);
    }
  }

  /// Computes suggestions for [expectedCompletion] and computes metrics from
  /// the resulting suggestions.
  Future<void> computeSuggestionsAndMetrics(
    ExpectedCompletion expectedCompletion,
    AnalysisContext context,
    DocumentationCache documentationCache,
  );

  /// Removes the overlay which has been applied to [filePath].
  void removeOverlay(String filePath);

  /// Resolves all analyzed files within [context].
  Future<List<ResolvedUnitResult>> resolveAnalyzedFiles({
    required AnalysisContext context,
    required DocumentationCache documentationCache,
  }) async {
    final analyzedFileCount = context.contextRoot.analyzedFiles().length;
    logger.write('Resolving $analyzedFileCount files...\n');

    final progress = ProgressBar(logger, analyzedFileCount);
    final results = <ResolvedUnitResult>[];
    final pathContext = context.contextRoot.resourceProvider.pathContext;
    for (final filePath in context.contextRoot.analyzedFiles()) {
      if (file_paths.isDart(pathContext, filePath)) {
        try {
          final result = await context.currentSession.getResolvedUnit(filePath)
              as ResolvedUnitResult;

          final analysisError = getFirstErrorOrNull(result);
          if (analysisError != null) {
            progress.clear();
            print('File $filePath skipped due to errors such as:');
            print('  ${analysisError.toString()}');
            print('');
            continue;
          } else {
            results.add(result);
            documentationCache.cacheFromResult(result);
          }
        } catch (exception, stackTrace) {
          progress.clear();
          print('Exception caught analyzing: $filePath');
          print(exception.toString());
          print(stackTrace);
        }
      }
      progress.tick();
    }
    progress.complete();
    return results;
  }

  /// Performs setup tasks with [context] before resolution.
  void setupForResolution(AnalysisContext context);

  /// Given some [ResolvedUnitResult] returns the first error of high severity
  /// if such an error exists, `null` otherwise.
  static err.AnalysisError? getFirstErrorOrNull(
      ResolvedUnitResult resolvedUnitResult) {
    for (final error in resolvedUnitResult.errors) {
      if (error.severity == Severity.error) {
        return error;
      }
    }
    return null;
  }

  /// Gets overlay contents for [contents], applying a change at
  /// [expectedCompletion] with [prefixLength], according to [overlay], one of
  /// the [CompletionMetricsOptions].
  static String getOverlayContents(
    String contents,
    ExpectedCompletion expectedCompletion,
    // TODO(srawlins): Replace this with an enum.
    String overlay,
    int prefixLength,
  ) {
    assert(contents.isNotEmpty);
    var offset = expectedCompletion.offset;
    final length = expectedCompletion.syntacticEntity.length;
    assert(offset >= 0);
    assert(length > 0);
    var tokenEndOffset = offset + length;
    if (length >= prefixLength) {
      // Rather than removing the whole token, remove the characters after
      // the given prefix length.
      offset += prefixLength;
    }
    if (overlay == CompletionMetricsOptions.OVERLAY_REMOVE_TOKEN) {
      return contents.substring(0, offset) + contents.substring(tokenEndOffset);
    } else if (overlay ==
        CompletionMetricsOptions.OVERLAY_REMOVE_REST_OF_FILE) {
      return contents.substring(0, offset);
    } else {
      final removeToken = CompletionMetricsOptions.OVERLAY_REMOVE_TOKEN;
      final removeRest = CompletionMetricsOptions.OVERLAY_REMOVE_REST_OF_FILE;
      throw Exception('\'getOverlayContents\' called with option other than'
          '$removeToken and $removeRest: $overlay');
    }
  }
}

/// The options specified on the command-line.
class CompletionMetricsOptions {
  /// An option to control whether and how overlays should be produced.
  static const String OVERLAY = 'overlay';

  /// A mode indicating that no overlays should be produced.
  /// TODO(srawlins): Replace this and the other two overlay values with enums.
  static const String OVERLAY_NONE = 'none';

  /// A mode indicating that everything from the completion offset to the end of
  /// the file should be removed.
  static const String OVERLAY_REMOVE_REST_OF_FILE = 'remove-rest-of-file';

  /// A mode indicating that the token whose offset is the same as the
  /// completion offset should be removed.
  static const String OVERLAY_REMOVE_TOKEN = 'remove-token';

  /// An option controlling how long of a prefix should be used.
  ///
  /// This affects the offset of the completion request, and how much content is
  /// removed in each of the overlay modes.
  static const String PREFIX_LENGTH = 'prefix-length';

  /// A flag that causes information to be printed about the completion requests
  /// that were the slowest to return suggestions.
  static const String PRINT_SLOWEST_RESULTS = 'print-slowest-results';

  /// The overlay mode that should be used.
  /// TODO(srawlins): Replace this with an enum.
  final String overlay;

  final int prefixLength;

  /// A flag indicating whether information should be printed about the
  /// completion requests that were the slowest to return suggestions.
  final bool printSlowestResults;

  CompletionMetricsOptions(ArgResults results)
      : overlay = results[OVERLAY] as String,
        prefixLength = int.parse(results[PREFIX_LENGTH] as String),
        printSlowestResults = results[PRINT_SLOWEST_RESULTS] as bool {
    assert(overlay == OVERLAY_NONE ||
        overlay == OVERLAY_REMOVE_TOKEN ||
        overlay == OVERLAY_REMOVE_REST_OF_FILE);
  }
}

/// A facility for drawing a progress bar in the terminal.
///
/// The bar is instantiated with the total number of "ticks" to be completed,
/// and progress is made by calling [tick]. The bar is drawn across one entire
/// line, like so:
///
///     [----------                                                   ]
///
/// The hyphens represent completed progress, and the whitespace represents
/// remaining progress.
///
/// If there is no terminal, the progress bar will not be drawn.
class ProgressBar {
  /// Whether the progress bar should be drawn.
  late bool _shouldDrawProgress;

  /// The width of the terminal, in terms of characters.
  late int _width;

  final Logger _logger;

  /// The inner width of the terminal, in terms of characters.
  ///
  /// This represents the number of characters available for drawing progress.
  late int _innerWidth;

  final int _totalTickCount;

  int _tickCount = 0;

  ProgressBar(this._logger, this._totalTickCount) {
    if (!stdout.hasTerminal) {
      _shouldDrawProgress = false;
    } else {
      _shouldDrawProgress = true;
      _width = stdout.terminalColumns;
      // Inclusion of the percent indicator assumes a terminal width of at least
      // 12 (2 brackets + 1 space + 2 parenthesis characters + 3 digits +
      // 1 period + 2 digits + 1 '%' character).
      _innerWidth = stdout.terminalColumns - 12;
      _logger.write('[${' ' * _innerWidth}]');
    }
  }

  /// Clears the progress bar from the terminal, allowing other logging to be
  /// printed.
  void clear() {
    if (!_shouldDrawProgress) {
      return;
    }
    _logger.write('\r${' ' * _width}\r');
  }

  /// Draws the progress bar as complete, and print two newlines.
  void complete() {
    if (!_shouldDrawProgress) {
      return;
    }
    _logger.write('\r[${'-' * _innerWidth}]\n\n');
  }

  /// Progresses the bar by one tick.
  void tick() {
    if (!_shouldDrawProgress) {
      return;
    }
    _tickCount++;
    final fractionComplete =
        math.max(0, _tickCount * _innerWidth ~/ _totalTickCount - 1);
    // The inner space consists of hyphens, one spinner character, spaces, and a
    // percentage (8 characters).
    final hyphens = '-' * fractionComplete;
    final trailingSpace = ' ' * (_innerWidth - fractionComplete - 1);
    final spinner = AnsiProgress.kAnimationItems[_tickCount % 4];
    final pctComplete = (_tickCount * 100 / _totalTickCount).toStringAsFixed(2);
    _logger.write('\r[$hyphens$spinner$trailingSpace] ($pctComplete%)');
  }
}
