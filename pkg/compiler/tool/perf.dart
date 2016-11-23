// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An entrypoint used to run portions of dart2js and measure its performance.
library compiler.tool.perf;

import 'dart:async';
import 'dart:io';

import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/apiimpl.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/kernel/task.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/messages.dart'
    show Message, MessageTemplate;
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/options.dart';
import 'package:compiler/src/parser/element_listener.dart' show ScannerOptions;
import 'package:compiler/src/parser/listener.dart';
import 'package:compiler/src/parser/node_listener.dart' show NodeListener;
import 'package:compiler/src/parser/parser.dart' show Parser;
import 'package:compiler/src/parser/partial_parser.dart';
import 'package:compiler/src/platform_configuration.dart' as platform;
import 'package:compiler/src/scanner/scanner.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:compiler/src/tokens/token.dart' show Token;
import 'package:package_config/discovery.dart' show findPackages;
import 'package:package_config/packages.dart' show Packages;
import 'package:package_config/src/util.dart' show checkValidPackageUri;

/// Cumulative total number of chars scanned.
int scanTotalChars = 0;

/// Cumulative time spent scanning.
Stopwatch scanTimer = new Stopwatch();

/// Helper class used to load source files using dart2js's internal APIs.
_Loader loader;

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
      Set<SourceFile> files = await scanReachableFiles(entryUri);
      // TODO(sigmund): replace the warmup with instrumented snapshots.
      for (int i = 0; i < 10; i++) scanFiles(files);
    },
    'parse': () async {
      Set<SourceFile> files = await scanReachableFiles(entryUri);
      // TODO(sigmund): replace the warmup with instrumented snapshots.
      for (int i = 0; i < 10; i++) parseFiles(files);
    },
    'kernel_gen_e2e': () async {
      // TODO(sigmund): remove. This is used to compute the input size, we
      // should extract input size from frontend instead.
      await scanReachableFiles(entryUri);
      // TODO(sigmund): replace this warmup. Note that for very large programs,
      // the GC pressure on the VM seems to make this worse with time (maybe we
      // are leaking memory?). That's why we run it twice and not 10 times.
      for (int i = 0; i < 2; i++) await generateKernel(entryUri);
    },
  };

  var handler = handlers[bench];
  if (handler == null) {
    // TODO(sigmund): implement the remaining benchmarks.
    print('unsupported bench-id: $bench. Please specify one of the following: '
        '${handler.keys.join(", ")}');
    exit(1);
  }
  await handler();
  totalTimer.stop();
  report("total", totalTimer.elapsedMicroseconds);
}

Future setup(Uri entryUri) async {
  var inputProvider = new CompilerSourceFileProvider();
  var sdkLibraries = await platform.load(_platformConfigUri, inputProvider);
  var packages = await findPackages(entryUri);
  loader = new _Loader(inputProvider, sdkLibraries, packages);
}

/// Load and scans all files we need to process: files reachable from the
/// entrypoint and all core libraries automatically included by the VM.
Future<Set<SourceFile>> scanReachableFiles(Uri entryUri) async {
  var files = new Set<SourceFile>();
  var loadTimer = new Stopwatch()..start();
  var entrypoints = [
    entryUri,
    Uri.parse("dart:async"),
    Uri.parse("dart:collection"),
    Uri.parse("dart:convert"),
    Uri.parse("dart:core"),
    Uri.parse("dart:developer"),
    Uri.parse("dart:_internal"),
    Uri.parse("dart:io"),
    Uri.parse("dart:isolate"),
    Uri.parse("dart:math"),
    Uri.parse("dart:mirrors"),
    Uri.parse("dart:typed_data"),
  ];
  for (var entry in entrypoints) {
    await collectSources(await loader.loadFile(entry), files);
  }
  loadTimer.stop();

  print('input size: ${scanTotalChars} chars');
  var loadTime = loadTimer.elapsedMicroseconds - scanTimer.elapsedMicroseconds;
  report("load", loadTime);
  report("scan", scanTimer.elapsedMicroseconds);
  return files;
}

/// Scans every file in [files] and reports the time spent doing so.
void scanFiles(Set<SourceFile> files) {
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
void parseFiles(Set<SourceFile> files) {
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

  report(
      "parse", parseTimer.elapsedMicroseconds - scanTimer.elapsedMicroseconds);
}

/// Add to [files] all sources reachable from [start].
Future collectSources(SourceFile start, Set<SourceFile> files) async {
  if (!files.add(start)) return;
  for (var directive in parseDirectives(start)) {
    var next = await loader.loadFile(start.uri.resolve(directive));
    await collectSources(next, files);
  }
}

/// Uses the diet-parser to parse only directives in [source], returns the
/// URIs seen in import/export/part directives in the file.
Set<String> parseDirectives(SourceFile source) {
  var tokens = tokenize(source);
  var listener = new DirectiveListener();
  new PartialParser(listener).parseUnit(tokens);
  return listener.targets;
}

/// Parse the full body of [source].
parseFull(SourceFile source) {
  var tokens = tokenize(source);
  NodeListener listener = new NodeListener(
      const ScannerOptions(canUseNative: true), new FakeReporter(), null);
  Parser parser = new Parser(listener);
  parser.parseUnit(tokens);
  return listener.popNode();
}

/// Scan [source] and return the first token produced by the scanner.
Token tokenize(SourceFile source) {
  scanTimer.start();
  scanTotalChars += source.length;
  var token = new Scanner(source).tokenize();
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

/// Listener that parses out just the uri in imports, exports, and part
/// directives.
class DirectiveListener extends Listener {
  Set<String> targets = new Set<String>();

  bool inDirective = false;
  void enterDirective() {
    inDirective = true;
  }

  void exitDirective() {
    inDirective = false;
  }

  void beginImport(Token importKeyword) => enterDirective();
  void beginExport(Token token) => enterDirective();
  void beginPart(Token token) => enterDirective();

  void beginLiteralString(Token token) {
    if (inDirective) {
      var quotedString = token.value;
      targets.add(quotedString.substring(1, quotedString.length - 1));
    }
  }

  void endExport(Token exportKeyword, Token semicolon) => exitDirective();
  void endImport(Token importKeyword, Token deferredKeyword, Token asKeyword,
          Token semicolon) =>
      exitDirective();
  void endPart(Token partKeyword, Token semicolon) => exitDirective();
}

Uri _libraryRoot = Platform.script.resolve('../../../sdk/');
Uri _platformConfigUri = _libraryRoot.resolve("lib/dart_server.platform");

class FakeReporter extends DiagnosticReporter {
  final hasReportedError = false;
  final options = new FakeReporterOptions();

  withCurrentElement(e, f) => f();
  log(m) => print(m);
  internalError(_, m) => print(m);
  spanFromSpannable(_) => null;

  void reportError(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    print('error: ${message.message}');
  }

  void reportWarning(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    print('warning: ${message.message}');
  }

  void reportHint(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    print('hint: ${message.message}');
  }

  void reportInfo(_, __, [Map arguments = const {}]) {}

  DiagnosticMessage createMessage(_, MessageKind kind,
      [Map arguments = const {}]) {
    MessageTemplate template = MessageTemplate.TEMPLATES[kind];
    Message message = template.message(arguments, false);
    return new DiagnosticMessage(null, null, message);
  }
}

class FakeReporterOptions {
  bool get suppressHints => false;
  bool get hidePackageWarnings => false;
}

class _Loader {
  CompilerInput inputProvider;

  /// Maps dart-URIs to a known location in the sdk.
  Map<String, Uri> sdkLibraries;
  Map<Uri, SourceFile> _cache = {};
  Packages packages;

  _Loader(this.inputProvider, this.sdkLibraries, this.packages);

  Future<SourceFile> loadFile(Uri uri) async {
    if (!uri.isAbsolute) throw 'Relative uri $uri provided to readScript.';
    Uri resourceUri = _translateUri(uri);
    if (resourceUri == null || resourceUri.scheme == 'dart-ext') {
      throw '$uri not resolved or unsupported.';
    }
    var file = _cache[resourceUri];
    if (file != null) return _cache[resourceUri];
    return _cache[resourceUri] = await _readFile(resourceUri);
  }

  Future<SourceFile> _readFile(Uri uri) async {
    var data = await inputProvider.readFromUri(uri);
    if (data is List<int>) return new Utf8BytesSourceFile(uri, data);
    if (data is String) return new StringSourceFile.fromUri(uri, data);
    // TODO(sigmund): properly handle errors, just report, return null, wrap
    // above and continue...
    throw "Expected a 'String' or a 'List<int>' from the input "
        "provider, but got: ${data.runtimeType}.";
  }

  Uri _translateUri(Uri uri) {
    if (uri.scheme == 'dart') return sdkLibraries[uri.path];
    if (uri.scheme == 'package') return _translatePackageUri(uri);
    return uri;
  }

  Uri _translatePackageUri(Uri uri) {
    checkValidPackageUri(uri);
    return packages.resolve(uri, notFound: (_) {
      print('$uri not found');
    });
  }
}

generateKernel(Uri entryUri) async {
  var timer = new Stopwatch()..start();
  var options = new CompilerOptions(
      entryPoint: entryUri,
      libraryRoot: _libraryRoot,
      packagesDiscoveryProvider: findPackages,
      platformConfigUri: _platformConfigUri,
      useKernel: true,
      verbose: false); // set to true to debug internal timings
  var inputProvider = new CompilerSourceFileProvider();
  var diagnosticHandler = new FormattingDiagnosticHandler(inputProvider)
    ..verbose = options.verbose;
  var compiler = new MyCompiler(inputProvider, diagnosticHandler, options);
  await compiler.run(entryUri);
  timer.stop();
  report("kernel_gen_e2e", timer.elapsedMicroseconds);
}

// We subclass compiler to skip phases and stop after creating kernel.
class MyCompiler extends CompilerImpl {
  MyCompiler(CompilerInput provider, CompilerDiagnostics handler,
      CompilerOptions options)
      : super(provider, null, handler, options) {}

  /// Performs the compilation when all libraries have been loaded.
  void compileLoadedLibraries() =>
      selfTask.measureSubtask("KernelCompiler.compileLoadedLibraries", () {
        computeMain();
        mirrorUsageAnalyzerTask.analyzeUsage(mainApp);

        deferredLoadTask.beforeResolution(this);
        impactStrategy = backend.createImpactStrategy(
            supportDeferredLoad: deferredLoadTask.isProgramSplit,
            supportDumpInfo: options.dumpInfo,
            supportSerialization: serialization.supportSerialization);

        phase = Compiler.PHASE_RESOLVING;

        // Note: we enqueue everything in the program so we measure generating
        // kernel for the entire code, not just what's reachable from main.
        libraryLoader.libraries.forEach((LibraryElement library) {
          fullyEnqueueLibrary(library, enqueuer.resolution);
        });

        backend.enqueueHelpers(enqueuer.resolution);
        resolveLibraryMetadata();
        reporter.log('Resolving...');
        processQueue(enqueuer.resolution, mainFunction);
        enqueuer.resolution.logSummary(reporter.log);

        (reporter as CompilerDiagnosticReporter)
            .reportSuppressedMessagesSummary();

        if (compilationFailed) {
          // TODO(sigmund): more diagnostics?
          print("compilation failed!");
          exit(1);
        }

        closeResolution();
        var program = (backend as dynamic).kernelTask.program;
        print('total libraries: ${program.libraries.length}');
      });
}
