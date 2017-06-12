// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An entrypoint used to run portions of analyzer and measure its performance.
library analyzer_cli.tool.perf;

import 'dart:async';
import 'dart:io' show exit;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart' show ResourceUriResolver;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart' show FolderBasedDartSdk;
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:package_config/discovery.dart';

/// Cumulative total number of chars scanned.
int scanTotalChars = 0;

/// Cumulative time spent scanning.
Stopwatch scanTimer = new Stopwatch();

/// Factory to load and resolve app, packages, and sdk sources.
SourceFactory sources;

main(List<String> args) async {
  // TODO(sigmund): provide sdk folder as well.
  if (args.length < 2) {
    print('usage: perf.dart <bench-id> <entry.dart>');
    exit(1);
  }
  var totalTimer = new Stopwatch()..start();

  var bench = args[0];
  var entryUri = Uri.base.resolve(args[1]);

  await setup(entryUri);

  if (bench == 'scan') {
    Set<Source> files = scanReachableFiles(entryUri);
    // TODO(sigmund): consider replacing the warmup with instrumented snapshots.
    for (int i = 0; i < 10; i++) scanFiles(files);
  } else if (bench == 'parse') {
    Set<Source> files = scanReachableFiles(entryUri);
    // TODO(sigmund): consider replacing the warmup with instrumented snapshots.
    for (int i = 0; i < 10; i++) parseFiles(files);
  } else {
    print('unsupported bench-id: $bench. Please specify "scan" or "parse"');
    // TODO(sigmund): implement the remaining benchmarks.
    exit(1);
  }

  totalTimer.stop();
  report("total", totalTimer.elapsedMicroseconds);
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
        new FolderBasedDartSdk(provider, provider.getFolder("sdk"))),
  ]);
}

/// Load and scans all files we need to process: files reachable from the
/// entrypoint and all core libraries automatically included by the VM.
Set<Source> scanReachableFiles(Uri entryUri) {
  var files = new Set<Source>();
  var loadTimer = new Stopwatch()..start();
  collectSources(sources.forUri2(entryUri), files);

  var libs = [
    "dart:async",
    "dart:collection",
    "dart:convert",
    "dart:core",
    "dart:developer",
    "dart:_internal",
    "dart:isolate",
    "dart:math",
    "dart:mirrors",
    "dart:typed_data",
    "dart:io"
  ];

  for (var lib in libs) {
    collectSources(sources.forUri(lib), files);
  }

  loadTimer.stop();

  print('input size: ${scanTotalChars} chars');
  var loadTime = loadTimer.elapsedMicroseconds - scanTimer.elapsedMicroseconds;
  report("load", loadTime);
  report("scan", scanTimer.elapsedMicroseconds);
  return files;
}

/// Scans every file in [files] and reports the time spent doing so.
void scanFiles(Set<Source> files) {
  // The code below will record again how many chars are scanned and how long it
  // takes to scan them, even though we already did so in [scanReachableFiles].
  // Recording and reporting this twice is unnecessary, but we do so for now to
  // validate that the results are consistent.
  scanTimer = new Stopwatch();
  var old = scanTotalChars;
  scanTotalChars = 0;
  for (var source in files) {
    tokenize(source);
  }

  // Report size and scanning time again. See discussion above.
  if (old != scanTotalChars) print('input size changed? ${old} chars');
  report("scan", scanTimer.elapsedMicroseconds);
}

/// Parses every file in [files] and reports the time spent doing so.
void parseFiles(Set<Source> files) {
  // The code below will record again how many chars are scanned and how long it
  // takes to scan them, even though we already did so in [scanReachableFiles].
  // Recording and reporting this twice is unnecessary, but we do so for now to
  // validate that the results are consistent.
  scanTimer = new Stopwatch();
  var old = scanTotalChars;
  scanTotalChars = 0;
  var parseTimer = new Stopwatch()..start();
  for (var source in files) {
    parseFull(source);
  }
  parseTimer.stop();

  // Report size and scanning time again. See discussion above.
  if (old != scanTotalChars) print('input size changed? ${old} chars');
  report("scan", scanTimer.elapsedMicroseconds);

  var pTime = parseTimer.elapsedMicroseconds - scanTimer.elapsedMicroseconds;
  report("parse", pTime);
}

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

/// Uses the diet-parser to parse only directives in [source].
CompilationUnit parseDirectives(Source source) {
  var token = tokenize(source);
  var parser = new Parser(source, AnalysisErrorListener.NULL_LISTENER);
  return parser.parseDirectives(token);
}

/// Parse the full body of [source] and return it's compilation unit.
CompilationUnit parseFull(Source source) {
  var token = tokenize(source);
  var parser = new Parser(source, AnalysisErrorListener.NULL_LISTENER);
  return parser.parseCompilationUnit(token);
}

/// Scan [source] and return the first token produced by the scanner.
Token tokenize(Source source) {
  scanTimer.start();
  var contents = source.contents.data;
  scanTotalChars += contents.length;
  // TODO(sigmund): is there a way to scan from a random-access-file without
  // first converting to String?
  var scanner = new Scanner(source, new CharSequenceReader(contents),
      AnalysisErrorListener.NULL_LISTENER)
    ..preserveComments = false;
  var token = scanner.tokenize();
  scanTimer.stop();
  return token;
}

/// Report that metric [name] took [time] micro-seconds to process
/// [scanTotalChars] characters.
void report(String name, int time) {
  var sb = new StringBuffer();
  sb.write('$name: $time us, ${time ~/ 1000} ms');
  sb.write(', ${scanTotalChars * 1000 ~/ time} chars/ms');
  print('$sb');
}
