// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An entrypoint used to run portions of fasta and measure its performance.
library front_end.tool.fasta_perf;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/fasta/ast_builder.dart';
import 'package:args/args.dart';

import 'package:front_end/front_end.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/parser.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/fasta/scanner/io.dart' show readBytesFromFileSync;
import 'package:front_end/src/fasta/source/directive_listener.dart';
import 'package:front_end/src/fasta/uri_translator.dart' show UriTranslator;

import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:kernel/target/vm.dart' show VmTarget;

/// Cumulative total number of chars scanned.
int inputSize = 0;

/// Cumulative time spent scanning.
Stopwatch scanTimer = new Stopwatch();

main(List<String> args) async {
  // TODO(sigmund): provide sdk folder as well.
  var options = argParser.parse(args);
  if (options.rest.length != 2) {
    print('usage: fasta_perf.dart [options] <bench-id> <entry.dart>');
    print(argParser.usage);
    exit(1);
  }
  bool strongMode = !options['legacy'];
  var bench = options.rest[0];
  var entryUri = Uri.base.resolve(options.rest[1]);

  await setup(entryUri);

  Map<Uri, List<int>> files = await scanReachableFiles(entryUri);
  var handlers = {
    'scan': () async => scanFiles(files),
    // TODO(sigmund): enable when we can run the ast-builder standalone.
    // 'parse': () async => parseFiles(files),
    'kernel_gen_e2e': () async {
      await generateKernel(entryUri, strongMode: strongMode);
    },
    'kernel_gen_e2e_sum': () async {
      await generateKernel(entryUri, compileSdk: false, strongMode: strongMode);
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

// TODO(sigmund): use `perf.dart::_findSdkPath` here when fasta can patch the
// sdk directly.
Uri sdkRoot = Uri.base.resolve("sdk/");

/// Translates `dart:*` and `package:*` URIs to resolved URIs.
UriTranslator uriResolver;

/// Preliminary set up to be able to correctly resolve URIs on the given
/// program.
Future setup(Uri entryUri) async {
  var options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..compileSdk = true
    ..packagesFileUri = Uri.base.resolve('.packages');
  uriResolver = await new ProcessedOptions(options).getUriTranslator();
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
  var listener = new DirectiveListenerWithNative();
  new TopLevelParser(listener).parseUnit(tokenize(contents));
  return new Set<String>()
    ..addAll(listener.imports.map((directive) => directive.uri))
    ..addAll(listener.exports.map((directive) => directive.uri))
    ..addAll(listener.parts);
}

class DirectiveListenerWithNative extends DirectiveListener {
  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    // Always allow native functions.
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

// Note: AstBuilder doesn't build compilation-units or classes, only method
// bodies. So this listener is not feature complete.
class _PartialAstBuilder extends AstBuilder {
  _PartialAstBuilder(Uri uri) : super(null, null, null, null, true, uri);

  // Note: this method converts the body to kernel, so we skip that here.
  @override
  finishFunction(annotations, formals, asyncModifier, body) {}
}

// Invoke the fasta kernel generator for the program starting in [entryUri]
generateKernel(Uri entryUri,
    {bool compileSdk: true, bool strongMode: false}) async {
  // TODO(sigmund): this is here only to compute the input size,
  // we should extract the input size from the frontend instead.
  scanReachableFiles(entryUri);

  var timer = new Stopwatch()..start();
  var flags = new TargetFlags(strongMode: strongMode);
  var options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..strongMode = strongMode
    ..target = (strongMode ? new VmTarget(flags) : new LegacyVmTarget(flags))
    ..chaseDependencies = true
    ..packagesFileUri = Uri.base.resolve('.packages')
    ..compileSdk = compileSdk;
  if (!compileSdk) {
    // TODO(sigmund): fix this: this is broken since the change to move .dill
    // files out of the patched_sdk folder. It is not failing anywhere because
    // this codepath is not used right now in our performance bots.
    options.sdkSummary = sdkRoot.resolve('outline.dill');
  }

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
  var program = await kernelForBuildUnit(entrypoints, options);

  timer.stop();
  var name = 'kernel_gen_e2e${compileSdk ? "" : "_sum"}';
  report(name, timer.elapsedMicroseconds);
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

ArgParser argParser = new ArgParser()
  ..addFlag('legacy',
      help: 'run the compiler in legacy-mode',
      defaultsTo: false,
      negatable: false);

// TODO(sigmund): delete as soon as the disableTypeInference flag and the
// strongMode flag get merged.
class LegacyVmTarget extends VmTarget {
  LegacyVmTarget(TargetFlags flags) : super(flags);

  @override
  bool get disableTypeInference => true;
}
