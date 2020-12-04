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

import 'dart:io' show Directory, File, Platform, exit;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart' show Folder;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart' show FolderBasedDartSdk;
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:path/path.dart' as path;

main(List<String> args) async {
  // TODO(sigmund): provide sdk folder as well.
  if (args.length < 2) {
    print('usage: perf.dart <bench-id> <entry.dart>');
    exit(1);
  }

  var bench = args[0];
  var entryUri = Uri.base.resolve(args[1]);

  await setup(path.fromUri(entryUri));

  Set<Source> files = scanReachableFiles(entryUri);
  var handlers = {
    'scan': () async => scanFiles(files),
    'parse': () async => parseFiles(files),
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

/// Cumulative time spent scanning.
Stopwatch scanTimer = new Stopwatch();

/// Size of all sources.
int inputSize = 0;

/// Factory to load and resolve app, packages, and sdk sources.
SourceFactory sources;

/// Path to the root of the built SDK that is being used to execute this script.
final _sdkPath = _findSdkPath();

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
  var parser = new Parser(
    source,
    AnalysisErrorListener.NULL_LISTENER,
    featureSet: FeatureSet.latestLanguageVersion(),
  );
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
  var parser = new Parser(
    source,
    AnalysisErrorListener.NULL_LISTENER,
    featureSet: FeatureSet.latestLanguageVersion(),
  );
  var unit = parser.parseCompilationUnit(token);
  parseTimer.stop();
  return unit;
}

/// Report that metric [name] took [time] micro-seconds to process
/// [inputSize] characters.
void report(String name, int time) {
  StringBuffer sb = new StringBuffer();
  String padding = ' ' * (20 - name.length);
  sb.write('$name:$padding $time us, ${time ~/ 1000} ms');
  String invSpeed = (time * 1000 / inputSize).toStringAsFixed(2);
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
  for (var s in files) {
    inputSize += s.contents.data.length;
  }
  print('input size: ${inputSize} chars');
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
  ScannerResult result =
      scanString(source.contents.data, includeComments: false);
  var token = result.tokens;
  if (result.hasErrors) {
    // Ignore errors.
    while (token is ErrorToken) {
      token = token.next;
    }
  }
  scanTimer.stop();
  return token;
}

String _findSdkPath() {
  var executable = Platform.resolvedExecutable;
  var executableDir = path.dirname(executable);
  for (var candidate in [
    path.dirname(executableDir),
    path.join(executableDir, 'dart-sdk')
  ]) {
    if (new File(path.join(candidate, 'lib', 'libraries.json')).existsSync()) {
      return candidate;
    }
  }
  // Not found; guess "sdk" relative to the current directory.
  return new Directory('sdk').absolute.path;
}
