// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An entrypoint used to run portions of analyzer and measure its performance.
import 'dart:io' show exit;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart'
    show Folder, ResourceUriResolver;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart' show FolderBasedDartSdk;
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';

void main(List<String> args) async {
  // TODO(sigmund): provide sdk folder as well.
  if (args.length < 2) {
    print('usage: perf.dart <bench-id> <entry.dart>');
    exit(1);
  }
  var totalTimer = Stopwatch()..start();

  var bench = args[0];
  var entryUri = Uri.base.resolve(args[1]);

  await setup(args[1]);

  if (bench == 'scan') {
    var files = scanReachableFiles(entryUri);
    // TODO(sigmund): consider replacing the warmup with instrumented snapshots.
    for (var i = 0; i < 10; i++) {
      scanFiles(files);
    }
  } else if (bench == 'parse') {
    var files = scanReachableFiles(entryUri);
    // TODO(sigmund): consider replacing the warmup with instrumented snapshots.
    for (var i = 0; i < 10; i++) {
      parseFiles(files);
    }
  } else {
    print('unsupported bench-id: $bench. Please specify "scan" or "parse"');
    // TODO(sigmund): implement the remaining benchmarks.
    exit(1);
  }

  totalTimer.stop();
  report('total', totalTimer.elapsedMicroseconds);
}

/// Cumulative time spent scanning.
Stopwatch scanTimer = Stopwatch();

/// Cumulative total number of chars scanned.
int scanTotalChars = 0;

/// Factory to load and resolve app, packages, and sdk sources.
SourceFactory sources;

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
  var parser = Parser(
    source,
    AnalysisErrorListener.NULL_LISTENER,
    featureSet: FeatureSet.latestLanguageVersion(),
  );
  return parser.parseDirectives(token);
}

/// Parses every file in [files] and reports the time spent doing so.
void parseFiles(Set<Source> files) {
  // The code below will record again how many chars are scanned and how long it
  // takes to scan them, even though we already did so in [scanReachableFiles].
  // Recording and reporting this twice is unnecessary, but we do so for now to
  // validate that the results are consistent.
  scanTimer = Stopwatch();
  var old = scanTotalChars;
  scanTotalChars = 0;
  var parseTimer = Stopwatch()..start();
  for (var source in files) {
    parseFull(source);
  }
  parseTimer.stop();

  // Report size and scanning time again. See discussion above.
  if (old != scanTotalChars) print('input size changed? $old chars');
  report('scan', scanTimer.elapsedMicroseconds);

  var pTime = parseTimer.elapsedMicroseconds - scanTimer.elapsedMicroseconds;
  report('parse', pTime);
}

/// Parse the full body of [source] and return it's compilation unit.
CompilationUnit parseFull(Source source) {
  var token = tokenize(source);
  var parser = Parser(
    source,
    AnalysisErrorListener.NULL_LISTENER,
    featureSet: FeatureSet.latestLanguageVersion(),
  );
  return parser.parseCompilationUnit(token);
}

/// Report that metric [name] took [time] micro-seconds to process
/// [scanTotalChars] characters.
void report(String name, int time) {
  var sb = StringBuffer();
  sb.write('$name: $time us, ${time ~/ 1000} ms');
  sb.write(', ${scanTotalChars * 1000 ~/ time} chars/ms');
  print('$sb');
}

/// Scans every file in [files] and reports the time spent doing so.
void scanFiles(Set<Source> files) {
  // The code below will record again how many chars are scanned and how long it
  // takes to scan them, even though we already did so in [scanReachableFiles].
  // Recording and reporting this twice is unnecessary, but we do so for now to
  // validate that the results are consistent.
  scanTimer = Stopwatch();
  var old = scanTotalChars;
  scanTotalChars = 0;
  for (var source in files) {
    tokenize(source);
  }

  // Report size and scanning time again. See discussion above.
  if (old != scanTotalChars) print('input size changed? $old chars');
  report('scan', scanTimer.elapsedMicroseconds);
}

/// Load and scans all files we need to process: files reachable from the
/// entrypoint and all core libraries automatically included by the VM.
Set<Source> scanReachableFiles(Uri entryUri) {
  var files = <Source>{};
  var loadTimer = Stopwatch()..start();
  collectSources(sources.forUri2(entryUri), files);

  var libs = [
    'dart:async',
    'dart:cli',
    'dart:collection',
    'dart:convert',
    'dart:core',
    'dart:developer',
    'dart:_internal',
    'dart:isolate',
    'dart:math',
    'dart:mirrors',
    'dart:typed_data',
    'dart:io',
  ];

  for (var lib in libs) {
    collectSources(sources.forUri(lib), files);
  }

  loadTimer.stop();

  print('input size: $scanTotalChars chars');
  var loadTime = loadTimer.elapsedMicroseconds - scanTimer.elapsedMicroseconds;
  report('load', loadTime);
  report('scan', scanTimer.elapsedMicroseconds);
  return files;
}

/// Sets up analyzer to be able to load and resolve app, packages, and sdk
/// sources.
Future setup(String path) async {
  var provider = PhysicalResourceProvider.INSTANCE;

  var packages = findPackagesFrom(
    provider,
    provider.getResource(path),
  );

  var packageMap = <String, List<Folder>>{};
  for (var package in packages.packages) {
    packageMap[package.name] = [package.libFolder];
  }

  sources = SourceFactory([
    ResourceUriResolver(provider),
    PackageMapUriResolver(provider, packageMap),
    DartUriResolver(FolderBasedDartSdk(provider, provider.getFolder('sdk'))),
  ]);
}

/// Scan [source] and return the first token produced by the scanner.
Token tokenize(Source source) {
  scanTimer.start();
  var contents = source.contents.data;
  scanTotalChars += contents.length;
  // TODO(paulberry): figure out the appropriate featureSet to use here
  var featureSet = FeatureSet.latestLanguageVersion();
  // TODO(sigmund): is there a way to scan from a random-access-file without
  // first converting to String?
  var scanner = Scanner(
      source, CharSequenceReader(contents), AnalysisErrorListener.NULL_LISTENER)
    ..configureFeatures(
      featureSetForOverriding: featureSet,
      featureSet: featureSet,
    )
    ..preserveComments = false;
  var token = scanner.tokenize();
  scanTimer.stop();
  return token;
}
