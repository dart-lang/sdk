// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line tool to run the checker on a Dart program.
library dev_compiler.devc;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/src/generated/engine.dart' show ChangeSet;
import 'package:logging/logging.dart' show Level, Logger, LogRecord;
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

import 'src/checker/checker.dart';
import 'src/checker/dart_sdk.dart' show mockSdkSources;
import 'src/checker/resolver.dart';
import 'src/checker/rules.dart';
import 'src/codegen/code_generator.dart' show CodeGenerator;
import 'src/codegen/dart_codegen.dart';
import 'src/codegen/html_codegen.dart';
import 'src/codegen/js_codegen.dart';
import 'src/dependency_graph.dart';
import 'src/info.dart' show LibraryInfo, CheckerResults;
import 'src/options.dart';
import 'src/report.dart';

/// Sets up the type checker logger to print a span that highlights error
/// messages.
StreamSubscription setupLogger(Level level, printFn) {
  Logger.root.level = level;
  return Logger.root.onRecord.listen((LogRecord rec) {
    printFn('${rec.level.name.toLowerCase()}: ${rec.message}');
  });
}

/// Encapsulates the logic to do a one-off compilation or a partial compilation
/// when the compiler is run as a development server.
class Compiler {
  final CompilerOptions _options;
  final TypeResolver _resolver;
  final CheckerReporter _reporter;
  final TypeRules _rules;
  final CodeChecker _checker;
  final SourceGraph _graph;
  final SourceNode _entryNode;
  List<LibraryInfo> _libraries = <LibraryInfo>[];
  final List<CodeGenerator> _generators;
  bool _failure = false;
  bool _devCompilerRuntimeCopied = false;

  factory Compiler(CompilerOptions options,
      [TypeResolver resolver, CheckerReporter reporter]) {
    if (resolver == null) {
      resolver = options.useMockSdk
          ? new TypeResolver.fromMock(mockSdkSources, options)
          : new TypeResolver.fromDir(options.dartSdkPath, options);
    }

    if (reporter == null) {
      reporter = options.dumpInfo
          ? new SummaryReporter()
          : new LogReporter(options.useColors);
    }
    var graph = new SourceGraph(resolver.context, options);
    var rules = new RestrictedRules(resolver.context.typeProvider, reporter,
        options: options);
    var checker = new CodeChecker(rules, reporter, options);
    var inputFile = options.entryPointFile;
    var uri = inputFile.startsWith('dart:') || inputFile.startsWith('package:')
        ? Uri.parse(inputFile)
        : new Uri.file(path.absolute(inputFile));
    var entryNode = graph.nodeFromUri(uri);

    var outputDir = options.outputDir;
    var generators = <CodeGenerator>[];
    if (options.dumpSrcDir != null) {
      generators.add(new EmptyDartGenerator(
          options.dumpSrcDir, entryNode.uri, rules, options));
    }
    if (outputDir != null) {
      generators.add(options.outputDart
          ? new DartGenerator(outputDir, entryNode.uri, rules, options)
          : new JSGenerator(outputDir, entryNode.uri, rules, options));
    }
    return new Compiler._(options, resolver, reporter, rules, checker, graph,
        entryNode, generators);
  }

  Compiler._(this._options, this._resolver, this._reporter, this._rules,
      this._checker, this._graph, this._entryNode, this._generators);

  bool _buildSource(SourceNode node) {
    if (node is HtmlSourceNode) {
      _buildHtmlFile(node);
    } else if (node is DartSourceNode) {
      _buildDartLibrary(node);
    } else {
      assert(false); // should not get a build request on PartSourceNode
    }

    // TODO(sigmund): don't always return true. Use summarization to better
    // determine when rebuilding is needed.
    return true;
  }

  void _buildHtmlFile(HtmlSourceNode node) {
    if (_options.outputDir == null) return;
    var output = generateEntryHtml(node, _options);
    if (output == null) {
      _failure = true;
      return;
    }
    var filename = path.basename(node.uri.path);
    String outputFile = path.join(_options.outputDir, filename);
    new File(outputFile).writeAsStringSync(output);

    if (_options.outputDart || _devCompilerRuntimeCopied) return;
    // Copy the dev_compiler runtime (implicit dependency for js codegen)
    // TODO(sigmund): split this out as a separate node in our dependency graph
    // (https://github.com/dart-lang/dev_compiler/issues/85).
    var runtimeDir = path.join(
        path.dirname(path.dirname(Platform.script.path)), 'lib/runtime/');
    var runtimeOutput = path.join(_options.outputDir, 'dev_compiler/runtime/');
    new Directory(runtimeOutput).createSync(recursive: true);
    new File(path.join(runtimeDir, 'harmony_feature_check.js'))
        .copy(path.join(runtimeOutput, 'harmony_feature_check.js'));
    new File(path.join(runtimeDir, 'dart_runtime.js'))
        .copy(path.join(runtimeOutput, 'dart_runtime.js'));
    _devCompilerRuntimeCopied = true;
  }

  bool _isEntry(DartSourceNode node) {
    if (_entryNode is DartSourceNode) return _entryNode == node;
    return (_entryNode as HtmlSourceNode).scripts.contains(node);
  }

  void _buildDartLibrary(DartSourceNode node) {
    var source = node.source;
    // TODO(sigmund): find out from analyzer team if there is a better way
    _resolver.context.applyChanges(new ChangeSet()..changedSource(source));
    var entryUnit = _resolver.context.resolveCompilationUnit2(source, source);
    var lib = entryUnit.element.enclosingElement;
    if (!_options.checkSdk && lib.isInSdk) return;
    var current = node.info;
    if (current != null) {
      assert(current.library == lib);
    } else {
      node.info = current = new LibraryInfo(lib, _isEntry(node));
    }
    _reporter.enterLibrary(current);
    _libraries.add(current);
    _rules.currentLibraryInfo = current;

    var units = [entryUnit]
      ..addAll(node.parts.map(
          (p) => _resolver.context.resolveCompilationUnit2(p.source, source)));
    bool failureInLib = false;
    for (var unit in units) {
      var unitSource = unit.element.source;
      _reporter.enterSource(unitSource);
      // TODO(sigmund): integrate analyzer errors with static-info (issue #6).
      failureInLib = _resolver.logErrors(unitSource, _reporter) || failureInLib;
      unit.visitChildren(_checker);
      if (_checker.failure) failureInLib = true;
      _reporter.leaveSource();
    }
    if (failureInLib) {
      _failure = true;
      if (!_options.forceCompile) return;
    }
    for (var cg in _generators) {
      cg.generateLibrary(units, current, _reporter);
    }
    _reporter.leaveLibrary();
  }

  CheckerResults run() {
    var clock = new Stopwatch()..start();

    // TODO(sigmund): we are missing a couple failures here. The
    // dependendency_graph now detects broken imports or unsupported features
    // like more than one script tag (see .severe messages in
    // dependency_graph.dart). Such failures should be reported back
    // here so we can mark failure=true in the CheckerResutls.
    rebuild(_entryNode, _graph, _buildSource);
    if (_options.dumpInfo && _reporter is SummaryReporter) {
      var result = (_reporter as SummaryReporter).result;
      print(summaryToString(result));
      if (_options.dumpInfoFile != null) {
        new File(_options.dumpInfoFile)
            .writeAsStringSync(JSON.encode(result.toJsonMap()));
      }
    }
    clock.stop();
    if (_options.serverMode) {
      var time = (clock.elapsedMilliseconds / 1000).toStringAsFixed(2);
      print('Compiled ${_libraries.length} libraries in ${time} s\n');
    }
    return new CheckerResults(
        _libraries, _rules, _failure || _options.forceCompile);
  }

  void _runAgain() {
    var clock = new Stopwatch()..start();
    if (_reporter is SummaryReporter) (_reporter as SummaryReporter).clear();
    _libraries = <LibraryInfo>[];
    int changed = 0;

    // TODO(sigmund): propagate failures here (see TODO in run).
    rebuild(_entryNode, _graph, (n) {
      changed++;
      return _buildSource(n);
    });
    if (_reporter is SummaryReporter) {
      print(summaryToString((_reporter as SummaryReporter).result));
    }
    clock.stop();
    var time = (clock.elapsedMilliseconds / 1000).toStringAsFixed(2);
    print("Compiled ${changed} libraries in ${time} s\n");
  }
}

class CompilerServer {
  final Compiler compiler;
  final String outDir;
  final int port;
  final String _entryPath;

  factory CompilerServer(CompilerOptions options) {
    var entryPath = path.basename(options.entryPointFile);
    if (path.extension(entryPath) != '.html') {
      print('error: devc in server mode requires an HTML entry point.');
      exit(1);
    }

    // TODO(sigmund): allow running without a dir, but keep output in memory?
    var outDir = options.outputDir;
    if (outDir == null) {
      print('error: devc in server mode also requires specifying and '
          'output location for generated code.');
      exit(1);
    }
    var port = options.port;
    print('[dev_compiler]: Serving $entryPath at http://0.0.0.0:$port/');
    var compiler = new Compiler(options);
    return new CompilerServer._(compiler, outDir, port, entryPath);
  }

  CompilerServer._(this.compiler, this.outDir, this.port, this._entryPath);

  Future start() async {
    var handler = const shelf.Pipeline()
        .addMiddleware(shelf.createMiddleware(requestHandler: rebuildIfNeeded))
        .addHandler(shelf_static.createStaticHandler(outDir,
            defaultDocument: _entryPath));
    await shelf.serve(handler, '0.0.0.0', port);
    compiler.run();
  }

  rebuildIfNeeded(shelf.Request request) {
    var filepath = request.url.path;
    if (filepath == '/$_entryPath' || filepath == '/') compiler._runAgain();
  }
}

final _log = new Logger('dev_compiler');
final _earlyErrorResult = new CheckerResults(const [], null, true);
