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
import 'src/utils.dart';

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
  final bool _hashing;
  bool _failure = false;

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
    var graph = new SourceGraph(resolver.context, reporter, options);
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
        entryNode, generators,
        // TODO(sigmund): refactor to support hashing of the dart output?
        options.serverMode && generators.length == 1 && !options.outputDart);
  }

  Compiler._(this._options, this._resolver, this._reporter, this._rules,
      this._checker, this._graph, this._entryNode, this._generators,
      this._hashing);

  bool _buildSource(SourceNode node) {
    if (node is HtmlSourceNode) {
      _buildHtmlFile(node);
    } else if (node is DartSourceNode) {
      _buildDartLibrary(node);
    } else if (node is ResourceSourceNode) {
      _buildResourceFile(node);
    } else {
      assert(false); // should not get a build request on PartSourceNode
    }

    // TODO(sigmund): don't always return true. Use summarization to better
    // determine when rebuilding is needed.
    return true;
  }

  void _buildHtmlFile(HtmlSourceNode node) {
    if (_options.outputDir == null) return;
    var uri = node.source.uri;
    _reporter.enterHtml(uri);
    var output = generateEntryHtml(node, _options);
    if (output == null) {
      _failure = true;
      return;
    }
    _reporter.leaveHtml();
    var filename = path.basename(node.uri.path);
    String outputFile = path.join(_options.outputDir, filename);
    new File(outputFile).writeAsStringSync(output);

    if (_options.outputDart) return;
  }

  void _buildResourceFile(ResourceSourceNode node) {
    // ResourceSourceNodes files that just need to be copied over to the output
    // location. These can be external dependencies or pieces of the
    // dev_compiler runtime.
    if (_options.outputDir == null || _options.outputDart) return;
    assert(node.uri.scheme == 'package');
    var filepath = path.join(_options.outputDir, resourceOutputPath(node.uri));
    var dir = path.dirname(filepath);
    new Directory(dir).createSync(recursive: true);
    var text = node.source.contents.data;
    new File(filepath).writeAsStringSync(text);
    if (_hashing) node.cachingHash = computeHash(text);
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
    _reporter.enterLibrary(source.uri);
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
      var hash = cg.generateLibrary(units, current, _reporter);
      if (_hashing) node.cachingHash = hash;
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
    _dumpInfoIfRequested();
    clock.stop();
    var time = (clock.elapsedMilliseconds / 1000).toStringAsFixed(2);
    _log.fine('Compiled ${_libraries.length} libraries in ${time} s\n');
    return new CheckerResults(
        _libraries, _rules, _failure || _options.forceCompile);
  }

  void _runAgain() {
    var clock = new Stopwatch()..start();
    _libraries = <LibraryInfo>[];
    int changed = 0;

    // TODO(sigmund): propagate failures here (see TODO in run).
    rebuild(_entryNode, _graph, (n) {
      changed++;
      return _buildSource(n);
    });
    clock.stop();
    if (changed > 0) _dumpInfoIfRequested();
    var time = (clock.elapsedMilliseconds / 1000).toStringAsFixed(2);
    _log.fine("Compiled ${changed} libraries in ${time} s\n");
  }

  _dumpInfoIfRequested() {
    if (!_options.dumpInfo || _reporter is! SummaryReporter) return;
    var result = (_reporter as SummaryReporter).result;
    if (!_options.serverMode) print(summaryToString(result));
    var filepath = _options.serverMode
        ? path.join(_options.outputDir, 'messages.json')
        : _options.dumpInfoFile;
    if (filepath == null) return;
    new File(filepath).writeAsStringSync(JSON.encode(result.toJsonMap()));
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
    _log.fine('Serving $entryPath at http://0.0.0.0:$port/');
    var compiler = new Compiler(options);
    return new CompilerServer._(compiler, outDir, port, entryPath);
  }

  CompilerServer._(this.compiler, this.outDir, this.port, this._entryPath);

  Future start() async {
    var handler = const shelf.Pipeline()
        .addMiddleware(rebuildAndCache)
        .addHandler(shelf_static.createStaticHandler(outDir,
            defaultDocument: _entryPath));
    await shelf.serve(handler, '0.0.0.0', port);
    compiler.run();
  }

  shelf.Handler rebuildAndCache(shelf.Handler handler) => (request) {
    _log.fine('requested $GREEN_COLOR${request.url}$NO_COLOR');
    // Trigger recompile only when requesting the HTML page.
    var segments = request.url.pathSegments;
    bool isEntryPage = segments.length == 0 || segments[0] == _entryPath;
    if (isEntryPage) compiler._runAgain();

    // To help browsers cache resources that don't change, we serve these
    // resources under a path containing their hash:
    //    /cached/{hash}/{path-to-file.js}
    bool isCached = segments.length > 1 && segments[0] == 'cached';
    if (isCached) {
      // Changing the request lets us record that the hash prefix is handled
      // here, and that the underlying handler should use the rest of the url to
      // determine where to find the resource in the file system.
      request = request.change(path: path.join('cached', segments[1]));
    }
    var response = handler(request);
    var policy = isCached ? 'max-age=${24 * 60 * 60}' : 'no-cache';
    var headers = {'cache-control': policy};
    if (isCached) {
      // Note: the cache-control header should be enough, but this doesn't hurt
      // and can help renew the policy after it expires.
      headers['ETag'] = segments[1];
    }
    return response.change(headers: headers);
  };
}

final _log = new Logger('dev_compiler');
final _earlyErrorResult = new CheckerResults(const [], null, true);
