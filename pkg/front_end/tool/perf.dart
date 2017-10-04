// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An entrypoint used to run portions of analyzer and measure its performance.
///
/// TODO(sigmund): rename to 'analyzer_perf.dart' in sync with changes to the
/// perf bots.
///
/// This file was started to measure the implementation of the front-end when it
/// was based on the analyzer codebase.  Now that we are using fasta as the
/// implementation (which is measured in fasta_perf.dart), we still want to
/// measure the analyzer to ensure that there are no regressions when replacing
/// features (e.g. there is no regression from replacing summaries with kernel
/// outlines).
library front_end.tool.perf;

import 'dart:async';
import 'dart:io' show Directory, File, Platform, exit;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart' show ResourceUriResolver;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart' show FolderBasedDartSdk;
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:front_end/src/scanner/reader.dart';
import 'package:front_end/src/scanner/scanner.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:package_config/discovery.dart';
import 'package:path/path.dart' as path;

main(List<String> args) async {
  // TODO(sigmund): provide sdk folder as well.
  if (args.length < 2) {
    print('usage: perf.dart <bench-id> <entry.dart>');
    exit(1);
  }

  var bench = args[0];
  var entryUri = Uri.base.resolve(args[1]);

  await setup(entryUri);

  Set<Source> files = scanReachableFiles(entryUri);
  var handlers = {
    'scan': () async => scanFiles(files),
    'parse': () async => parseFiles(files),
    'unlinked_summarize': () async => summarize(files),
    'unlinked_summarize_from_sources': () async => summarize(files),
    'prelinked_summarize': () async => summarize(files, prelink: true),
    'linked_summarize': () async => summarize(files, link: true),
  };

  var handler = handlers[bench];
  if (handler == null) {
    print('unsupported bench-id: $bench. Please specify one of the following: '
        '${handlers.keys.join(", ")}');
    exit(1);
  }

  // TODO(sigmund): replace the warmup with instrumented snapshots.
  int iterations = bench.contains('kernel_gen') ? 2 : 10;
  for (int i = 0; i < iterations; i++) {
    var totalTimer = new Stopwatch()..start();
    print('== iteration $i');
    await handler();
    totalTimer.stop();
    report('total', totalTimer.elapsedMicroseconds);
  }
}

/// Cumulative time spent parsing.
Stopwatch parseTimer = new Stopwatch();

/// Cumulative time spent building unlinked summaries.
Stopwatch unlinkedSummarizeTimer = new Stopwatch();

/// Cumulative time spent scanning.
Stopwatch scanTimer = new Stopwatch();

/// Size of all sources.
int inputSize = 0;

/// Factory to load and resolve app, packages, and sdk sources.
SourceFactory sources;

/// File URI of the root of the SDK source tree.
final _repoUri = Platform.script.resolve('../../../');

/// Path to the root of the built SDK that is being used to execute this script.
final _sdkPath = _findSdkPath();

/// File URI to the root of the built SDK that is being used to execute this
/// script.
final _sdkUri = new Uri.directory(_sdkPath);

/// Add to [files] all sources reachable from [start].
void collectSources(Source start, Set<Source> files) {
  if (!files.add(start)) return;
  var unit = parseDirectives(start);
  for (var directive in unit.directives) {
    if (directive is UriBasedDirective) {
      var next = sources.resolveUri(start, directive.uri.stringValue);
      collectSources(next, files);
    }
  }
}

/// Generates unlinkmed summaries for all files in [files], and returns them in
/// an [_UnlinkedSummaries] container.
_UnlinkedSummaries generateUnlinkedSummaries(Set<Source> files) {
  var unlinkedSummaries = new _UnlinkedSummaries();
  for (var source in files) {
    unlinkedSummaries.summariesByUri[source.uri.toString()] =
        unlinkedSummarize(source);
  }
  return unlinkedSummaries;
}

/// Generates unlinked summaries for every file in [files] and, if requested via
/// [prelink] or [link], generates the pre-linked and linked summaries as well.
///
/// This function also prints a report of the time spent on each action.
void summarize(Set<Source> files, {bool prelink: false, bool link: false}) {
  scanTimer = new Stopwatch();
  parseTimer = new Stopwatch();
  unlinkedSummarizeTimer = new Stopwatch();
  var unlinkedSummaries = generateUnlinkedSummaries(files);
  report('scan', scanTimer.elapsedMicroseconds);
  report('parse', parseTimer.elapsedMicroseconds);
  report('unlinked_summarize', unlinkedSummarizeTimer.elapsedMicroseconds);
  report(
      'unlinked_summarize_from_sources',
      unlinkedSummarizeTimer.elapsedMicroseconds +
          parseTimer.elapsedMicroseconds +
          scanTimer.elapsedMicroseconds);

  if (prelink || link) {
    var prelinkTimer = new Stopwatch()..start();
    var prelinkedLibraries = prelinkSummaries(files, unlinkedSummaries);
    prelinkTimer.stop();
    report('prelinked_summarize', prelinkTimer.elapsedMicroseconds);

    if (link) {
      var linkTimer = new Stopwatch()..start();
      LinkedLibrary getDependency(String uri) {
        // getDependency should never be called because all dependencies are
        // present in [prelinkedLibraries].
        print('Warning: getDependency called for: $uri');
        return null;
      }

      relink(prelinkedLibraries, getDependency, unlinkedSummaries.getUnit,
          true /*strong*/);
      linkTimer.stop();
      report('linked_summarize', linkTimer.elapsedMicroseconds);
    }
  }
}

/// Uses the diet-parser to parse only directives in [source].
CompilationUnit parseDirectives(Source source) {
  var token = tokenize(source);
  var parser = new Parser(source, AnalysisErrorListener.NULL_LISTENER);
  return parser.parseDirectives(token);
}

/// Parses every file in [files] and reports the time spent doing so.
void parseFiles(Set<Source> files) {
  scanTimer = new Stopwatch();
  parseTimer = new Stopwatch();
  for (var source in files) {
    parseFull(source);
  }

  report('scan', scanTimer.elapsedMicroseconds);
  report('parse', parseTimer.elapsedMicroseconds);
}

/// Parse the full body of [source] and return it's compilation unit.
CompilationUnit parseFull(Source source) {
  var token = tokenize(source);
  parseTimer.start();
  var parser = new Parser(source, AnalysisErrorListener.NULL_LISTENER);
  var unit = parser.parseCompilationUnit(token);
  parseTimer.stop();
  return unit;
}

/// Prelinks all the summaries for [files], using [unlinkedSummaries] to obtain
/// their unlinked summaries.
///
/// The return value is suitable for passing to the summary linker.
Map<String, LinkedLibraryBuilder> prelinkSummaries(
    Set<Source> files, _UnlinkedSummaries unlinkedSummaries) {
  Set<String> libraryUris = files.map((source) => '${source.uri}').toSet();

  String getDeclaredVariable(String s) => null;
  var prelinkedLibraries =
      setupForLink(libraryUris, unlinkedSummaries.getUnit, getDeclaredVariable);
  return prelinkedLibraries;
}

/// Report that metric [name] took [time] micro-seconds to process
/// [inputSize] characters.
void report(String name, int time) {
  var sb = new StringBuffer();
  var padding = ' ' * (20 - name.length);
  sb.write('$name:$padding $time us, ${time ~/ 1000} ms');
  var invSpeed = (time * 1000 / inputSize).toStringAsFixed(2);
  sb.write(', $invSpeed ns/char');
  print('$sb');
}

/// Scans every file in [files] and reports the time spent doing so.
void scanFiles(Set<Source> files) {
  // `tokenize` records how many chars are scanned and how long it takes to scan
  // them. As this function is called repeatedly when running as a benchmark, we
  // make sure to clear the data and compute it again every time.
  scanTimer = new Stopwatch();
  for (var source in files) {
    tokenize(source);
  }

  report('scan', scanTimer.elapsedMicroseconds);
}

/// Load and scans all files we need to process: files reachable from the
/// entrypoint and all core libraries automatically included by the VM.
Set<Source> scanReachableFiles(Uri entryUri) {
  var files = new Set<Source>();
  var loadTimer = new Stopwatch()..start();
  scanTimer = new Stopwatch();
  collectSources(sources.forUri2(entryUri), files);

  var libs = [
    'dart:async',
    'dart:collection',
    'dart:convert',
    'dart:core',
    'dart:developer',
    'dart:_internal',
    'dart:isolate',
    'dart:math',
    'dart:mirrors',
    'dart:typed_data',
    'dart:io'
  ];

  for (var lib in libs) {
    collectSources(sources.forUri(lib), files);
  }

  loadTimer.stop();

  inputSize = 0;
  for (var s in files) inputSize += s.contents.data.length;
  print('input size: ${inputSize} chars');
  var loadTime = loadTimer.elapsedMicroseconds - scanTimer.elapsedMicroseconds;
  report('load', loadTime);
  report('scan', scanTimer.elapsedMicroseconds);
  return files;
}

/// Sets up analyzer to be able to load and resolve app, packages, and sdk
/// sources.
Future setup(Uri entryUri) async {
  var provider = PhysicalResourceProvider.INSTANCE;
  var packageMap = new ContextBuilder(provider, null, null)
      .convertPackagesToMap(await findPackages(entryUri));
  sources = new SourceFactory([
    new ResourceUriResolver(provider),
    new PackageMapUriResolver(provider, packageMap),
    new DartUriResolver(
        new FolderBasedDartSdk(provider, provider.getFolder(_sdkPath))),
  ]);
}

/// Scan [source] and return the first token produced by the scanner.
Token tokenize(Source source) {
  scanTimer.start();
  // TODO(sigmund): is there a way to scan from a random-access-file without
  // first converting to String?
  var scanner = new _Scanner(source.contents.data);
  var token = scanner.tokenize();
  scanTimer.stop();
  return token;
}

UnlinkedUnitBuilder unlinkedSummarize(Source source) {
  var unit = parseFull(source);
  unlinkedSummarizeTimer.start();
  var unlinkedUnit = serializeAstUnlinked(unit);
  unlinkedSummarizeTimer.stop();
  return unlinkedUnit;
}

String _findSdkPath() {
  var executable = Platform.resolvedExecutable;
  var executableDir = path.dirname(executable);
  for (var candidate in [
    path.dirname(executableDir),
    path.join(executableDir, 'dart-sdk')
  ]) {
    if (new File(path.join(candidate, 'lib', 'dart_server.platform'))
        .existsSync()) {
      return candidate;
    }
  }
  // Not found; guess "sdk" relative to the current directory.
  return new Directory('sdk').absolute.path;
}

/// Simple container for a mapping from URI string to an unlinked summary.
class _UnlinkedSummaries {
  final summariesByUri = <String, UnlinkedUnit>{};

  /// Get the unlinked summary for the given URI, and report a warning if it
  /// can't be found.
  UnlinkedUnit getUnit(String uri) {
    var result = summariesByUri[uri];
    if (result == null) {
      print('Warning: no summary found for: $uri');
    }
    return result;
  }
}

class _Scanner extends Scanner {
  _Scanner(String contents) : super.create(new CharSequenceReader(contents)) {
    preserveComments = false;
  }

  @override
  void reportError(errorCode, int offset, List<Object> arguments) {
    // ignore errors.
  }
}
