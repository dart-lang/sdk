// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An entrypoint used to run portions of front_end and measure its performance.
library front_end.tool.perf;

import 'dart:async';
import 'dart:io' show exit, stderr;

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
import 'package:kernel/analyzer/loader.dart';
import 'package:kernel/kernel.dart';
import 'package:package_config/discovery.dart';

import 'package:front_end/compiler_options.dart';
import 'package:front_end/kernel_generator.dart';
import 'package:front_end/src/scanner/reader.dart';
import 'package:front_end/src/scanner/scanner.dart';
import 'package:front_end/src/scanner/token.dart';

/// Cumulative total number of chars scanned.
int scanTotalChars = 0;

/// Cumulative time spent scanning.
Stopwatch scanTimer = new Stopwatch();

/// Cumulative time spent parsing.
Stopwatch parseTimer = new Stopwatch();

/// Cumulative time spent building unlinked summaries.
Stopwatch unlinkedSummarizeTimer = new Stopwatch();

/// Cumulative time spent prelinking summaries.
Stopwatch prelinkSummaryTimer = new Stopwatch();

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

  var handlers = {
    'scan': () async {
      Set<Source> files = scanReachableFiles(entryUri);
      // TODO(sigmund): replace the warmup with instrumented snapshots.
      for (int i = 0; i < 10; i++) scanFiles(files);
    },
    'parse': () async {
      Set<Source> files = scanReachableFiles(entryUri);
      // TODO(sigmund): replace the warmup with instrumented snapshots.
      for (int i = 0; i < 10; i++) parseFiles(files);
    },
    'kernel_gen_e2e': () async {
      // TODO(sigmund): remove. This is used to compute the input size, we
      // should extract input size from frontend instead.
      scanReachableFiles(entryUri);
      // TODO(sigmund): replace this warmup. Note that for very large programs,
      // the GC pressure on the VM seems to make this worse with time (maybe we
      // are leaking memory?). That's why we run it twice and not 10 times.
      for (int i = 0; i < 2; i++) {
        await generateKernel(entryUri, useSdkSummary: false);
      }
    },
    'kernel_gen_e2e_sum': () async {
      // TODO(sigmund): remove. This is incorrect since it includes sizes for
      // files that will not be loaded when using summaries. We need to extract
      // input size from frontend instead.
      scanReachableFiles(entryUri);
      // TODO(sigmund): replace this warmup. Note that for very large programs,
      // the GC pressure on the VM seems to make this worse with time (maybe we
      // are leaking memory?). That's why we run it twice and not 10 times.
      for (int i = 0; i < 2; i++) {
        await generateKernel(entryUri, useSdkSummary: true, compileSdk: false);
      }
    },
    'unlinked_summarize': () async {
      Set<Source> files = scanReachableFiles(entryUri);
      // TODO(sigmund): replace the warmup with instrumented snapshots.
      for (int i = 0; i < 10; i++) unlinkedSummarizeFiles(files);
    },
    'prelinked_summarize': () async {
      Set<Source> files = scanReachableFiles(entryUri);
      // TODO(sigmund): replace the warmup with instrumented snapshots.
      for (int i = 0; i < 10; i++) prelinkedSummarizeFiles(files);
    },
    'linked_summarize': () async {
      Set<Source> files = scanReachableFiles(entryUri);
      // TODO(sigmund): replace the warmup with instrumented snapshots.
      for (int i = 0; i < 10; i++) linkedSummarizeFiles(files);
    }
  };

  var handler = handlers[bench];
  if (handler == null) {
    // TODO(sigmund): implement the remaining benchmarks.
    print('unsupported bench-id: $bench. Please specify one of the following: '
        '${handlers.keys.join(", ")}');
    exit(1);
  }
  await handler();

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
  parseTimer = new Stopwatch();
  for (var source in files) {
    parseFull(source);
  }

  // Report size and scanning time again. See discussion above.
  if (old != scanTotalChars) print('input size changed? ${old} chars');
  report("scan", scanTimer.elapsedMicroseconds);
  report("parse", parseTimer.elapsedMicroseconds);
}

/// Produces unlinked summaries for every file in [files] and reports the time
/// spent doing so.
void unlinkedSummarizeFiles(Set<Source> files) {
  // The code below will record again how many chars are scanned and how long it
  // takes to scan them, even though we already did so in [scanReachableFiles].
  // Recording and reporting this twice is unnecessary, but we do so for now to
  // validate that the results are consistent.
  scanTimer = new Stopwatch();
  var old = scanTotalChars;
  scanTotalChars = 0;
  parseTimer = new Stopwatch();
  unlinkedSummarizeTimer = new Stopwatch();
  generateUnlinkedSummaries(files);

  if (old != scanTotalChars) print('input size changed? ${old} chars');
  report("scan", scanTimer.elapsedMicroseconds);
  report("parse", parseTimer.elapsedMicroseconds);
  report('unlinked summarize', unlinkedSummarizeTimer.elapsedMicroseconds);
  report(
      'unlinked summarize + parse',
      unlinkedSummarizeTimer.elapsedMicroseconds +
          parseTimer.elapsedMicroseconds);
}

/// Simple container for a mapping from URI string to an unlinked summary.
class UnlinkedSummaries {
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

/// Generates unlinkmed summaries for all files in [files], and returns them in
/// an [UnlinkedSummaries] container.
UnlinkedSummaries generateUnlinkedSummaries(Set<Source> files) {
  var unlinkedSummaries = new UnlinkedSummaries();
  for (var source in files) {
    unlinkedSummaries.summariesByUri[source.uri.toString()] =
        unlinkedSummarize(source);
  }
  return unlinkedSummaries;
}

/// Produces prelinked summaries for every file in [files] and reports the time
/// spent doing so.
void prelinkedSummarizeFiles(Set<Source> files) {
  // The code below will record again how many chars are scanned and how long it
  // takes to scan them, even though we already did so in [scanReachableFiles].
  // Recording and reporting this twice is unnecessary, but we do so for now to
  // validate that the results are consistent.
  scanTimer = new Stopwatch();
  var old = scanTotalChars;
  scanTotalChars = 0;
  parseTimer = new Stopwatch();
  unlinkedSummarizeTimer = new Stopwatch();
  var unlinkedSummaries = generateUnlinkedSummaries(files);
  prelinkSummaryTimer = new Stopwatch();
  prelinkSummaries(files, unlinkedSummaries);

  if (old != scanTotalChars) print('input size changed? ${old} chars');
  report("scan", scanTimer.elapsedMicroseconds);
  report("parse", parseTimer.elapsedMicroseconds);
  report('unlinked summarize', unlinkedSummarizeTimer.elapsedMicroseconds);
  report(
      'unlinked summarize + parse',
      unlinkedSummarizeTimer.elapsedMicroseconds +
          parseTimer.elapsedMicroseconds);
  report('prelink', prelinkSummaryTimer.elapsedMicroseconds);
}

/// Produces linked summaries for every file in [files] and reports the time
/// spent doing so.
void linkedSummarizeFiles(Set<Source> files) {
  // The code below will record again how many chars are scanned and how long it
  // takes to scan them, even though we already did so in [scanReachableFiles].
  // Recording and reporting this twice is unnecessary, but we do so for now to
  // validate that the results are consistent.
  scanTimer = new Stopwatch();
  var old = scanTotalChars;
  scanTotalChars = 0;
  parseTimer = new Stopwatch();
  unlinkedSummarizeTimer = new Stopwatch();
  var unlinkedSummaries = generateUnlinkedSummaries(files);
  prelinkSummaryTimer = new Stopwatch();
  Map<String, LinkedLibraryBuilder> prelinkedLibraries =
      prelinkSummaries(files, unlinkedSummaries);
  var linkTimer = new Stopwatch()..start();
  LinkedLibrary getDependency(String uri) {
    // getDependency should never be called because all dependencies are present
    // in [prelinkedLibraries].
    print('Warning: getDependency called for: $uri');
    return null;
  }

  bool strong = true;
  relink(prelinkedLibraries, getDependency, unlinkedSummaries.getUnit, strong);
  linkTimer.stop();

  if (old != scanTotalChars) print('input size changed? ${old} chars');
  report("scan", scanTimer.elapsedMicroseconds);
  report("parse", parseTimer.elapsedMicroseconds);
  report('unlinked summarize', unlinkedSummarizeTimer.elapsedMicroseconds);
  report(
      'unlinked summarize + parse',
      unlinkedSummarizeTimer.elapsedMicroseconds +
          parseTimer.elapsedMicroseconds);
  report('prelink', prelinkSummaryTimer.elapsedMicroseconds);
  report('link', linkTimer.elapsedMicroseconds);
}

/// Prelinks all the summaries for [files], using [unlinkedSummaries] to obtain
/// their unlinked summaries.
///
/// The return value is suitable for passing to the summary linker.
Map<String, LinkedLibraryBuilder> prelinkSummaries(
    Set<Source> files, UnlinkedSummaries unlinkedSummaries) {
  prelinkSummaryTimer.start();
  Set<String> libraryUris =
      files.map((source) => source.uri.toString()).toSet();

  String getDeclaredVariable(String s) => null;
  var prelinkedLibraries =
      setupForLink(libraryUris, unlinkedSummaries.getUnit, getDeclaredVariable);
  prelinkSummaryTimer.stop();
  return prelinkedLibraries;
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
  parseTimer.start();
  var parser = new Parser(source, AnalysisErrorListener.NULL_LISTENER);
  var unit = parser.parseCompilationUnit(token);
  parseTimer.stop();
  return unit;
}

UnlinkedUnitBuilder unlinkedSummarize(Source source) {
  var unit = parseFull(source);
  unlinkedSummarizeTimer.start();
  var unlinkedUnit = serializeAstUnlinked(unit);
  unlinkedSummarizeTimer.stop();
  return unlinkedUnit;
}

/// Scan [source] and return the first token produced by the scanner.
Token tokenize(Source source) {
  scanTimer.start();
  var contents = source.contents.data;
  scanTotalChars += contents.length;
  // TODO(sigmund): is there a way to scan from a random-access-file without
  // first converting to String?
  var scanner = new _Scanner(contents);
  var token = scanner.tokenize();
  scanTimer.stop();
  return token;
}

class _Scanner extends Scanner {
  _Scanner(String contents) : super(new CharSequenceReader(contents)) {
    preserveComments = false;
  }

  @override
  void reportError(errorCode, int offset, List<Object> arguments) {
    // ignore errors.
  }
}

/// Report that metric [name] took [time] micro-seconds to process
/// [scanTotalChars] characters.
void report(String name, int time) {
  var sb = new StringBuffer();
  sb.write('$name: $time us, ${time ~/ 1000} ms');
  sb.write(', ${scanTotalChars * 1000 ~/ time} chars/ms');
  print('$sb');
}

Future<Program> generateKernel(Uri entryUri,
    {bool useSdkSummary: false, bool compileSdk: true}) async {
  var dartkTimer = new Stopwatch()..start();
  // TODO(sigmund): add a constructor with named args to compiler options.
  var options = new CompilerOptions()
    ..strongMode = false
    ..compileSdk = compileSdk
    ..packagesFilePath = '.packages'
    ..onError = ((e) => print('${e.message}'));
  if (useSdkSummary) {
    // TODO(sigmund): adjust path based on the benchmark runner architecture.
    // Possibly let the runner make the file available at an architecture
    // independent location.
    options.sdkSummary = 'out/ReleaseX64/dart-sdk/lib/_internal/spec.sum';
  } else {
    options.sdkPath = 'sdk';
  }
  Program program = await kernelForProgram(entryUri, options);
  dartkTimer.stop();
  var suffix = useSdkSummary ? "_sum" : "";
  report("kernel_gen_e2e${suffix}", dartkTimer.elapsedMicroseconds);
  return program;
}
