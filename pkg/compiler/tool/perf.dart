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
import 'package:compiler/src/elements/entities.dart' show LibraryEntity;
import 'package:compiler/src/common.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/messages.dart'
    show Message, MessageTemplate;
import 'package:compiler/src/enqueue.dart' show ResolutionEnqueuer;
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/options.dart';
import 'package:compiler/src/parser/element_listener.dart' show ScannerOptions;
import 'package:compiler/src/parser/node_listener.dart' show NodeListener;
import 'package:compiler/src/parser/diet_parser_task.dart' show PartialParser;
import 'package:compiler/src/platform_configuration.dart' as platform;
import 'package:compiler/src/source_file_provider.dart';
import 'package:compiler/src/universe/world_impact.dart'
    show WorldImpactBuilderImpl;
import 'package:front_end/src/fasta/parser.dart' show Listener, Parser;
import 'package:front_end/src/fasta/scanner.dart' show Token, scan;
import 'package:package_config/discovery.dart' show findPackages;
import 'package:package_config/packages.dart' show Packages;
import 'package:package_config/src/util.dart' show checkValidPackageUri;

/// Cumulative total number of chars scanned.
int inputSize = 0;

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
  var bench = args[0];
  var entryUri = Uri.base.resolve(args[1]);

  await setup(entryUri);

  Set<SourceFile> files = await scanReachableFiles(entryUri);
  var handlers = {
    'scan': () async => scanFiles(files),
    'parse': () async => parseFiles(files),
    'kernel_gen_e2e': () async {
      await generateKernel(entryUri);
    },
  };

  var handler = handlers[bench];
  if (handler == null) {
    // TODO(sigmund): implement the remaining benchmarks.
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
  scanTimer = new Stopwatch();
  var entrypoints = [
    entryUri,
    Uri.parse('dart:async'),
    Uri.parse('dart:collection'),
    Uri.parse('dart:convert'),
    Uri.parse('dart:core'),
    Uri.parse('dart:developer'),
    Uri.parse('dart:_internal'),
    Uri.parse('dart:io'),
    Uri.parse('dart:isolate'),
    Uri.parse('dart:math'),
    Uri.parse('dart:mirrors'),
    Uri.parse('dart:typed_data'),
  ];
  for (var entry in entrypoints) {
    await collectSources(await loader.loadFile(entry), files);
  }
  loadTimer.stop();

  inputSize = 0;
  for (var source in files) inputSize += source.length;
  print('input size: ${inputSize} chars');
  var loadTime = loadTimer.elapsedMicroseconds - scanTimer.elapsedMicroseconds;
  report('load', loadTime);
  report('scan', scanTimer.elapsedMicroseconds);
  return files;
}

/// Scans every file in [files] and reports the time spent doing so.
void scanFiles(Set<SourceFile> files) {
  scanTimer = new Stopwatch();
  for (var source in files) {
    tokenize(source);
  }
  report('scan', scanTimer.elapsedMicroseconds);
}

/// Parses every file in [files] and reports the time spent doing so.
void parseFiles(Set<SourceFile> files) {
  scanTimer = new Stopwatch();
  var parseTimer = new Stopwatch()..start();
  for (var source in files) {
    parseFull(source);
  }
  parseTimer.stop();

  report('scan', scanTimer.elapsedMicroseconds);
  report(
      'parse', parseTimer.elapsedMicroseconds - scanTimer.elapsedMicroseconds);
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
  var token = scan(source.slowUtf8ZeroTerminatedBytes()).tokens;
  scanTimer.stop();
  return token;
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
      var quotedString = token.lexeme;
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
Uri _platformConfigUri = _libraryRoot.resolve('lib/dart_server.platform');

class FakeReporter extends DiagnosticReporter {
  final hasReportedError = false;
  final options = new FakeReporterOptions();

  withCurrentElement(e, f) => f();
  log(m) => print(m);
  internalError(_, m) => print(m);
  spanFromSpannable(_) => null;
  spanFromToken(_) => null;

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

class FakeReporterOptions implements DiagnosticOptions {
  bool get suppressHints => false;
  bool get hidePackageWarnings => false;

  bool get fatalWarnings => false;
  bool get terseDiagnostics => false;
  bool get suppressWarnings => false;
  bool get showAllPackageWarnings => true;
  bool showPackageWarningsFor(Uri uri) => true;
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
    return await inputProvider.readFromUri(uri, inputKind: InputKind.utf8);
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
  // TODO(sigmund): this is here only to compute the input size,
  // we should extract the input size from the frontend instead.
  scanReachableFiles(entryUri);

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
  report('kernel_gen_e2e', timer.elapsedMicroseconds);
}

// We subclass compiler to skip phases and stop after creating kernel.
class MyCompiler extends CompilerImpl {
  MyCompiler(CompilerInput provider, CompilerDiagnostics handler,
      CompilerOptions options)
      : super(provider, null, handler, options) {}

  /// Performs the compilation when all libraries have been loaded.
  void compileLoadedLibraries(LibraryEntity rootLibrary) =>
      selfTask.measureSubtask('KernelCompiler.compileLoadedLibraries', () {
        ResolutionEnqueuer resolutionEnqueuer = startResolution();
        WorldImpactBuilderImpl mainImpact = new WorldImpactBuilderImpl();
        var mainFunction =
            frontendStrategy.computeMain(rootLibrary, mainImpact);
        mirrorUsageAnalyzerTask.analyzeUsage(rootLibrary);

        deferredLoadTask.beforeResolution(rootLibrary);
        impactStrategy = backend.createImpactStrategy(
            supportDeferredLoad: deferredLoadTask.isProgramSplit,
            supportDumpInfo: options.dumpInfo,
            supportSerialization: serialization.supportSerialization);

        phase = Compiler.PHASE_RESOLVING;
        resolutionEnqueuer.applyImpact(mainImpact);
        // Note: we enqueue everything in the program so we measure generating
        // kernel for the entire code, not just what's reachable from main.
        libraryLoader.libraries.forEach((LibraryEntity library) {
          resolutionEnqueuer.applyImpact(computeImpactForLibrary(library));
        });

        if (frontendStrategy.commonElements.mirrorsLibrary != null) {
          resolveLibraryMetadata();
        }
        reporter.log('Resolving...');
        processQueue(frontendStrategy.elementEnvironment, resolutionEnqueuer,
            mainFunction, libraryLoader.libraries);
        resolutionEnqueuer.logSummary(reporter.log);

        (reporter as CompilerDiagnosticReporter)
            .reportSuppressedMessagesSummary();

        if (compilationFailed) {
          // TODO(sigmund): more diagnostics?
          print('compilation failed!');
          exit(1);
        }

        backend.onResolutionEnd();
        closeResolution(mainFunction);
        var program = (backend as dynamic).kernelTask.program;
        print('total libraries: ${program.libraries.length}');
      });
}
