// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An entrypoint used to run portions of fasta and measure its performance.
library front_end.tool.fasta_perf;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/fasta/ast_builder.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;
import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;
import 'package:front_end/src/fasta/parser.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/fasta/scanner/io.dart' show readBytesFromFileSync;
import 'package:front_end/src/fasta/source/scope_listener.dart' show Scope;
import 'package:front_end/src/fasta/ticker.dart' show Ticker;
import 'package:front_end/src/fasta/translate_uri.dart' show TranslateUri;
import 'package:front_end/src/fasta/translate_uri.dart';

/// Cumulative total number of chars scanned.
int inputSize = 0;

/// Cumulative time spent scanning.
Stopwatch scanTimer = new Stopwatch();

main(List<String> args) async {
  // TODO(sigmund): provide sdk folder as well.
  if (args.length < 2) {
    print('usage: fasta_perf.dart <bench-id> <entry.dart>');
    exit(1);
  }
  var bench = args[0];
  var entryUri = Uri.base.resolve(args[1]);

  await setup(entryUri);

  Map<Uri, List<int>> files = await scanReachableFiles(entryUri);
  var handlers = {
    'scan': () async => scanFiles(files),
    // TODO(sigmund): enable when we can run the ast-builder standalone.
    // 'parse': () async => parseFiles(files),
    'kernel_gen_e2e': () async {
      await generateKernel(entryUri);
    },
    // TODO(sigmund): enable once we add a build step to create the
    // platform.dill files.
    // 'kernel_gen_e2e_sum': () async {
    //   await generateKernel(entryUri, compileSdk: false);
    // },
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

/// Translates `dart:*` and `package:*` URIs to resolved URIs.
TranslateUri uriResolver;

/// Preliminary set up to be able to correctly resolve URIs on the given
/// program.
Future setup(Uri entryUri) async {
  // TODO(sigmund): use `perf.dart::_findSdkPath` here when fasta can patch the
  // sdk directly.
  var sdkRoot =
      Uri.base.resolve(Platform.resolvedExecutable).resolve('patched_sdk/');
  uriResolver = await TranslateUri.parse(sdkRoot);
}

/// Scan [contents] and return the first token produced by the scanner.
Token tokenize(List<int> contents) {
  scanTimer.start();
  var token = scan(contents).tokens;
  scanTimer.stop();
  return token;
}

/// Scans every file in [files] and reports the time spent doing so.
void scanFiles(Map<Uri, List<int>> files) {
  scanTimer = new Stopwatch();
  for (var source in files.values) {
    tokenize(source);
  }
  report('scan', scanTimer.elapsedMicroseconds);
}

/// Load and scans all files we need to process: files reachable from the
/// entrypoint and all core libraries automatically included by the VM.
Future<Map<Uri, List<int>>> scanReachableFiles(Uri entryUri) async {
  var files = <Uri, List<int>>{};
  var loadTimer = new Stopwatch()..start();
  scanTimer = new Stopwatch();
  var entrypoints = [
    entryUri,
    // These extra libraries are added to match the same set of libraries
    // scanned by default by the VM and the other benchmarks.
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
    await collectSources(entry, files);
  }
  loadTimer.stop();

  inputSize = 0;
  // adjust size because there is a null-terminator on the contents.
  for (var source in files.values) inputSize += (source.length - 1);
  print('input size: $inputSize chars');
  var loadTime = loadTimer.elapsedMicroseconds - scanTimer.elapsedMicroseconds;
  report('load', loadTime);
  report('scan', scanTimer.elapsedMicroseconds);
  return files;
}

/// Add to [files] all sources reachable from [start].
Future<Null> collectSources(Uri start, Map<Uri, List<int>> files) async {
  helper(Uri uri) {
    uri = uriResolver.translate(uri) ?? uri;
    if (uri == null) return;
    if (files.containsKey(uri)) return;
    var contents = readBytesFromFileSync(uri);
    files[uri] = contents;
    for (var directiveUri in extractDirectiveUris(contents)) {
      helper(uri.resolve(directiveUri));
    }
  }

  helper(start);
}

/// Parse [contents] as a Dart program and return the URIs that appear in its
/// import, export, and part directives.
Set<String> extractDirectiveUris(List<int> contents) {
  var listener = new DirectiveListener();
  new DirectiveParser(listener).parseUnit(tokenize(contents));
  return listener.uris;
}

/// Diet parser that stops eagerly at the first sign that we have seen all the
/// import, export, and part directives.
class DirectiveParser extends ClassMemberParser {
  DirectiveParser(listener) : super(listener);

  static final _endToken = new SymbolToken.eof(-1);

  Token parseClassOrNamedMixinApplication(Token token) => _endToken;
  Token parseEnum(Token token) => _endToken;
  parseTypedef(token) => _endToken;
  parseTopLevelMember(Token token) => _endToken;
}

/// Listener that records the URIs from imports, exports, and part directives.
class DirectiveListener extends Listener {
  bool _inDirective = false;
  Set<String> uris = new Set<String>();

  void _enterDirective() {
    _inDirective = true;
  }

  void _exitDirective() {
    _inDirective = false;
  }

  beginImport(_) => _enterDirective();
  beginExport(_) => _enterDirective();
  beginPart(_) => _enterDirective();

  endExport(export, semicolon) => _exitDirective();
  endImport(import, deferred, asKeyword, semicolon) => _exitDirective();
  endPart(part, semicolon) => _exitDirective();

  void beginLiteralString(Token token) {
    if (_inDirective) {
      var quotedString = token.lexeme;
      uris.add(quotedString.substring(1, quotedString.length - 1));
    }
  }
}

/// Parses every file in [files] and reports the time spent doing so.
void parseFiles(Map<Uri, List<int>> files) {
  scanTimer = new Stopwatch();
  var parseTimer = new Stopwatch()..start();
  files.forEach((uri, source) {
    parseFull(uri, source);
  });
  parseTimer.stop();

  report('scan', scanTimer.elapsedMicroseconds);
  report(
      'parse', parseTimer.elapsedMicroseconds - scanTimer.elapsedMicroseconds);
}

/// Parse the full body of [source].
parseFull(Uri uri, List<int> source) {
  var tokens = tokenize(source);
  Parser parser = new Parser(new _PartialAstBuilder(uri));
  parser.parseUnit(tokens);
}

class _EmptyScope extends Scope {
  _EmptyScope() : super({}, null);
}

// Note: AstBuilder doesn't build compilation-units or classes, only method
// bodies. So this listener is not feature complete.
class _PartialAstBuilder extends AstBuilder {
  _PartialAstBuilder(Uri uri)
      : super(null, null, null, null, new _EmptyScope(), uri);

  // Note: this method converts the body to kernel, so we skip that here.
  @override
  finishFunction(formals, asyncModifier, body) {}
}

// Invoke the fasta kernel generator for the program starting in [entryUri]
// TODO(sigmund): update to uyse the frontend api once fasta is beind hit.
generateKernel(Uri entryUri, {bool compileSdk: true}) async {
  // TODO(sigmund): this is here only to compute the input size,
  // we should extract the input size from the frontend instead.
  scanReachableFiles(entryUri);

  var timer = new Stopwatch()..start();
  final Ticker ticker = new Ticker();
  final DillTarget dillTarget = new DillTarget(ticker, uriResolver);
  final KernelTarget kernelTarget = new KernelTarget(dillTarget, uriResolver);
  var entrypoints = [
    entryUri,
    // These extra libraries are added to match the same set of libraries
    // scanned by default by the VM and the other benchmarks.
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
  entrypoints.forEach(kernelTarget.read);

  if (!compileSdk) {
    dillTarget.read(
        Uri.base.resolve(Platform.resolvedExecutable).resolve('platform.dill'));
  }
  await dillTarget.writeOutline(null);
  var program = await kernelTarget.writeOutline(null);
  program = await kernelTarget.writeProgram(null);
  if (kernelTarget.errors.isNotEmpty) {
    throw kernelTarget.errors.first;
  }
  timer.stop();
  report('kernel_gen_e2e', timer.elapsedMicroseconds);
  return program;
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
