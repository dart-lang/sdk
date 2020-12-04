// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';
import 'dart:math' as math;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'src/error_listener.dart';
import 'src/histogram.dart';
import 'src/scrape_visitor.dart';

export 'src/histogram.dart';
export 'src/scrape_visitor.dart' hide bindVisitor;

class Scrape {
  final List<ScrapeVisitor Function()> _visitorFactories = [];

  /// What percent of files should be processed.
  int _percent;

  /// Process package test files.
  bool _includeTests = true;

  /// Process Dart SDK language tests.
  bool _includeLanguageTests = true;

  /// Process Dart files generated from protobufs.
  bool _includeProtobufs = false;

  /// Whether every file should be printed before being processed.
  bool _printFiles = true;

  /// Whether parse errors should be printed.
  bool _printErrors = true;

  /// The number of files that have been processed.
  int get scrapedFileCount => _scrapedFileCount;
  int _scrapedFileCount = 0;

  /// The number of lines of code that have been processed.
  int get scrapedLineCount => _scrapedLineCount;
  int _scrapedLineCount = 0;

  /// The number of files that could not be parsed.
  int get errorFileCount => _errorFileCount;
  int _errorFileCount = 0;

  final Map<String, Histogram> _histograms = {};

  /// Whether we're in the middle of writing the running file count and need a
  /// newline before any other output should be shown.
  bool _needClearLine = false;

  /// Register a new visitor factory.
  ///
  /// This function will be called for each scraped file and the resulting
  /// [ScrapeVisitor] will traverse the parsed file's AST.
  void addVisitor(ScrapeVisitor Function() createVisitor) {
    _visitorFactories.add(createVisitor);
  }

  /// Defines a new histogram with [name] to collect occurrences.
  ///
  /// After the scrape completes, each defined histogram's collected counts
  /// are shown, ordered by [order]. If [showBar] is not `false`, then shows an
  /// ASCII bar chart for the counts.
  ///
  /// If [showAll] is `true`, then every item that occurred is shown. Otherwise,
  /// only shows the first 100 items or occurrences that represent at least
  /// 0.1% of the total, whichever is longer.
  ///
  /// If [minCount] is passed, then only shows items that occurred at least
  /// that many times.
  void addHistogram(String name,
      {SortOrder order = SortOrder.descending,
      bool showBar,
      bool showAll,
      int minCount}) {
    _histograms.putIfAbsent(
        name,
        () => Histogram(
            order: order,
            showBar: showBar,
            showAll: showAll,
            minCount: minCount));
  }

  /// Add an occurrence of [item] to [histogram].
  void record(String histogram, Object item) {
    _histograms[histogram].add(item);
  }

  /// Run the scrape using the given set of command line arguments.
  void runCommandLine(List<String> arguments) {
    var parser = ArgParser(allowTrailingOptions: true);
    parser.addOption('percent',
        help: 'Only process a randomly selected percentage of files.');
    parser.addFlag('tests',
        defaultsTo: true, help: 'Process package test files.');
    parser.addFlag('language-tests',
        help: 'Process Dart SDK language test files.');
    parser.addFlag('protobufs',
        help: 'Process Dart files generated from protobufs.');
    parser.addFlag('print-files',
        defaultsTo: true, help: 'Print the path for each parsed file.');
    parser.addFlag('print-errors',
        defaultsTo: true, help: 'Print parse errors.');
    parser.addFlag('help', negatable: false, help: 'Print help text.');

    var results = parser.parse(arguments);

    if (results['help'] as bool) {
      var script = p.url.basename(Platform.script.toString());
      print('Usage: $script [options] <paths...>');
      print(parser.usage);
      return;
    }

    _includeTests = results['tests'] as bool;
    _includeLanguageTests = results['language-tests'] as bool;
    _includeProtobufs = results['protobufs'] as bool;
    _printFiles = results['print-files'] as bool;
    _printErrors = results['print-errors'] as bool;

    if (results.wasParsed('percent')) {
      _percent = int.tryParse(results['percent'] as String);
      if (_percent == null) {
        print("--percent must be an integer, was '${results["percent"]}'.");
        exit(1);
      }
    }

    if (results.rest.isEmpty) {
      print('Must pass at least one path to process.');
      exit(1);
    }

    var watch = Stopwatch()..start();
    for (var path in results.rest) {
      _processPath(path);
    }
    watch.stop();

    clearLine();
    _histograms.forEach((name, histogram) {
      histogram.printCounts(name);
    });

    String count(int n, String unit) {
      if (n == 1) return '1 $unit';
      return '$n ${unit}s';
    }

    var elapsed = _formatDuration(watch.elapsed);
    var lines = count(_scrapedLineCount, 'line');
    var files = count(_scrapedFileCount, 'file');
    var message = 'Took $elapsed to scrape $lines in $files.';

    if (_errorFileCount > 0) {
      var errors = count(_errorFileCount, 'file');
      message += ' ($errors could not be parsed.)';
    }

    print(message);
  }

  /// Display [message], clearing the line if necessary.
  void log(Object message) {
    // TODO(rnystrom): Consider using cli_util package.
    clearLine();
    print(message);
  }

  /// Clear the current line if it needs it.
  void clearLine() {
    if (!_needClearLine) return;
    stdout.write('\u001b[2K\r');
    _needClearLine = false;
  }

  String _formatDuration(Duration duration) {
    String pad(int width, int n) => n.toString().padLeft(width, '0');

    if (duration.inMinutes >= 1) {
      var minutes = duration.inMinutes;
      var seconds = duration.inSeconds % 60;
      var ms = duration.inMilliseconds % 1000;
      return '$minutes:${pad(2, seconds)}.${pad(3, ms)}';
    } else if (duration.inSeconds >= 1) {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(3)}s';
    } else {
      return '${duration.inMilliseconds}ms';
    }
  }

  void _processPath(String path) {
    var random = math.Random();

    if (File(path).existsSync()) {
      _parseFile(File(path), path);
      return;
    }

    for (var entry in Directory(path).listSync(recursive: true)) {
      if (entry is! File) continue;

      if (!entry.path.endsWith('.dart')) continue;

      // For unknown reasons, some READMEs have a ".dart" extension. They aren't
      // Dart files.
      if (entry.path.endsWith('README.dart')) continue;

      if (!_includeLanguageTests) {
        if (entry.path.contains('/sdk/tests/')) continue;
        if (entry.path.contains('/testcases/')) continue;
        if (entry.path.contains('/sdk/runtime/tests/')) continue;
        if (entry.path.contains('/linter/test/_data/')) continue;
        if (entry.path.contains('/analyzer/test/')) continue;
        if (entry.path.contains('/dev_compiler/test/')) continue;
        if (entry.path.contains('/analyzer_cli/test/')) continue;
        if (entry.path.contains('/analysis_server/test/')) continue;
        if (entry.path.contains('/kernel/test/')) continue;
      }

      if (!_includeTests) {
        if (entry.path.contains('/test/')) continue;
        if (entry.path.endsWith('_test.dart')) continue;
      }

      // Don't care about cached packages.
      if (entry.path.contains('sdk/third_party/pkg/')) continue;
      if (entry.path.contains('sdk/third_party/pkg_tested/')) continue;
      if (entry.path.contains('/.dart_tool/')) continue;

      // Don't care about generated protobuf code.
      if (!_includeProtobufs) {
        if (entry.path.endsWith('.pb.dart')) continue;
        if (entry.path.endsWith('.pbenum.dart')) continue;
      }

      if (_percent != null && random.nextInt(100) >= _percent) continue;

      var relative = p.relative(entry.path, from: path);
      _parseFile(entry as File, relative);
    }
  }

  void _parseFile(File file, String shortPath) {
    var source = file.readAsStringSync();

    var errorListener = ErrorListener(this, _printErrors);
    var featureSet = FeatureSet.latestLanguageVersion();

    // Tokenize the source.
    var reader = CharSequenceReader(source);
    var stringSource = StringSource(source, file.path);
    var scanner = Scanner(stringSource, reader, errorListener);
    scanner.configureFeatures(
        featureSet: featureSet, featureSetForOverriding: featureSet);
    var startToken = scanner.tokenize();

    // Parse it.
    var parser = Parser(stringSource, errorListener, featureSet: featureSet);
    parser.enableOptionalNewAndConst = true;
    parser.enableSetLiterals = true;

    if (_printFiles) {
      var line =
          '[$_scrapedFileCount files, $_scrapedLineCount lines] ' '$shortPath';
      if (Platform.isWindows) {
        // No ANSI escape codes on Windows.
        print(line);
      } else {
        // Overwrite the same line.
        stdout.write('\u001b[2K\r'
            '[$_scrapedFileCount files, $_scrapedLineCount lines] $shortPath');
        _needClearLine = true;
      }
    }

    AstNode node;
    try {
      node = parser.parseCompilationUnit(startToken);
    } catch (error) {
      print('Got exception parsing $shortPath:\n$error');
      return;
    }

    // Don't process files with syntax errors.
    if (errorListener.hadError) {
      _errorFileCount++;
      return;
    }

    var lineInfo = LineInfo(scanner.lineStarts);

    _scrapedFileCount++;
    _scrapedLineCount += lineInfo.lineCount;

    for (var visitorFactory in _visitorFactories) {
      var visitor = visitorFactory();
      bindVisitor(visitor, this, shortPath, source, lineInfo);
      node.accept(visitor);
    }
  }
}
