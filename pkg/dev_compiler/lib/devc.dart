// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line tool to run the checker on a Dart program.
library dev_compiler.devc;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/src/generated/error.dart' as analyzer;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, ChangeSet;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:logging/logging.dart' show Level, Logger, LogRecord;
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

import 'src/analysis_context.dart';
import 'src/checker/checker.dart';
import 'src/checker/rules.dart';
import 'src/codegen/code_generator.dart' show CodeGenerator;
import 'src/codegen/dart_codegen.dart';
import 'src/codegen/html_codegen.dart';
import 'src/codegen/js_codegen.dart';
import 'src/dependency_graph.dart';
import 'src/info.dart'
    show AnalyzerError, CheckerResults, LibraryInfo, LibraryUnit;
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

abstract class AbstractCompiler {
  CompilerOptions get options;
  AnalysisContext get context;
  TypeRules get rules;
  Uri get entryPointUri;
}

/// Encapsulates the logic to do a one-off compilation or a partial compilation
/// when the compiler is run as a development server.
class Compiler implements AbstractCompiler {
  final CompilerOptions options;
  final AnalysisContext context;
  final CheckerReporter _reporter;
  final TypeRules rules;
  final CodeChecker _checker;
  final SourceNode _entryNode;
  List<LibraryInfo> _libraries = <LibraryInfo>[];
  final _generators = <CodeGenerator>[];
  bool _hashing;
  bool _failure = false;

  factory Compiler(CompilerOptions options,
      {AnalysisContext context, CheckerReporter reporter}) {
    if (context == null) context = createAnalysisContext(options);

    if (reporter == null) {
      reporter = options.dumpInfo
          ? new SummaryReporter(context, options.logLevel)
          : new LogReporter(context, useColors: options.useColors);
    }
    var graph = new SourceGraph(context, reporter, options);
    var rules = new RestrictedRules(context.typeProvider, options: options);
    var checker = new CodeChecker(rules, reporter, options);

    var inputFile = options.entryPointFile;
    var inputUri = inputFile.startsWith('dart:') ||
            inputFile.startsWith('package:')
        ? Uri.parse(inputFile)
        : new Uri.file(path.absolute(options.useImplicitHtml
            ? ResolverOptions.implicitHtmlFile
            : inputFile));
    var entryNode = graph.nodeFromUri(inputUri);

    return new Compiler._(
        options, context, reporter, rules, checker, entryNode);
  }

  Compiler._(this.options, this.context, this._reporter, this.rules,
      this._checker, this._entryNode) {
    if (options.dumpSrcDir != null) {
      _generators.add(new EmptyDartGenerator(this));
    }
    if (options.outputDir != null) {
      _generators.add(
          options.outputDart ? new DartGenerator(this) : new JSGenerator(this));
    }
    // TODO(sigmund): refactor to support hashing of the dart output?
    _hashing =
        options.enableHashing && _generators.length == 1 && !options.outputDart;
  }

  Uri get entryPointUri => _entryNode.uri;

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
    if (options.outputDir == null) return;
    var uri = node.source.uri;
    _reporter.enterHtml(uri);
    var output = generateEntryHtml(node, options);
    if (output == null) {
      _failure = true;
      return;
    }
    _reporter.leaveHtml();
    var filename = path.basename(node.uri.path);
    String outputFile = path.join(options.outputDir, filename);
    new File(outputFile).writeAsStringSync(output);

    if (options.outputDart) return;
  }

  void _buildResourceFile(ResourceSourceNode node) {
    // ResourceSourceNodes files that just need to be copied over to the output
    // location. These can be external dependencies or pieces of the
    // dev_compiler runtime.
    if (options.outputDir == null || options.outputDart) return;
    var filepath = resourceOutputPath(node.uri, _entryNode.uri);
    assert(filepath != null);
    filepath = path.join(options.outputDir, filepath);
    var dir = path.dirname(filepath);
    new Directory(dir).createSync(recursive: true);
    new File.fromUri(node.source.uri).copySync(filepath);
    if (_hashing) node.cachingHash = computeHashFromFile(filepath);
  }

  bool _isEntry(DartSourceNode node) {
    if (_entryNode is DartSourceNode) return _entryNode == node;
    return (_entryNode as HtmlSourceNode).scripts.contains(node);
  }

  void _buildDartLibrary(DartSourceNode node) {
    var source = node.source;
    // TODO(sigmund): find out from analyzer team if there is a better way
    context.applyChanges(new ChangeSet()..changedSource(source));
    var entryUnit = context.resolveCompilationUnit2(source, source);
    var lib = entryUnit.element.enclosingElement;
    if (!options.checkSdk && lib.isInSdk) return;
    var current = node.info;
    if (current != null) {
      assert(current.library == lib);
    } else {
      node.info = current = new LibraryInfo(lib, _isEntry(node));
    }
    _reporter.enterLibrary(source.uri);
    _libraries.add(current);
    rules.currentLibraryInfo = current;

    var resolvedParts = node.parts
        .map((p) => context.resolveCompilationUnit2(p.source, source))
        .toList(growable: false);
    var libraryUnit = new LibraryUnit(entryUnit, resolvedParts);
    bool failureInLib = false;
    for (var unit in libraryUnit.libraryThenParts) {
      var unitSource = unit.element.source;
      _reporter.enterCompilationUnit(unit);
      // TODO(sigmund): integrate analyzer errors with static-info (issue #6).
      failureInLib = logErrors(unitSource) || failureInLib;
      _checker.visitCompilationUnit(unit);
      if (_checker.failure) failureInLib = true;
      _reporter.leaveCompilationUnit();
    }
    if (failureInLib) {
      _failure = true;
      if (!options.forceCompile) return;
    }

    for (var cg in _generators) {
      var hash = cg.generateLibrary(libraryUnit, current);
      if (_hashing) node.cachingHash = hash;
    }
    _reporter.leaveLibrary();
  }

  /// Log any errors encountered when resolving [source] and return whether any
  /// errors were found.
  bool logErrors(Source source) {
    List<analyzer.AnalysisError> errors = context.getErrors(source).errors;
    bool failure = false;
    if (errors.isNotEmpty) {
      for (var error in errors) {
        var message = new AnalyzerError.from(error);
        if (message.level == Level.SEVERE) failure = true;
        _reporter.log(message);
      }
    }
    return failure;
  }

  CheckerResults run() {
    var clock = new Stopwatch()..start();

    // TODO(sigmund): we are missing a couple failures here. The
    // dependency_graph now detects broken imports or unsupported features
    // like more than one script tag (see .severe messages in
    // dependency_graph.dart). Such failures should be reported back
    // here so we can mark failure=true in the CheckerResutls.
    rebuild(_entryNode, _buildSource);
    _dumpInfoIfRequested();
    clock.stop();
    var time = (clock.elapsedMilliseconds / 1000).toStringAsFixed(2);
    _log.fine('Compiled ${_libraries.length} libraries in ${time} s\n');
    return new CheckerResults(
        _libraries, rules, _failure || options.forceCompile);
  }

  void _runAgain() {
    var clock = new Stopwatch()..start();
    _libraries = <LibraryInfo>[];
    int changed = 0;

    // TODO(sigmund): propagate failures here (see TODO in run).
    rebuild(_entryNode, (n) {
      changed++;
      return _buildSource(n);
    });
    clock.stop();
    if (changed > 0) _dumpInfoIfRequested();
    var time = (clock.elapsedMilliseconds / 1000).toStringAsFixed(2);
    _log.fine("Compiled ${changed} libraries in ${time} s\n");
  }

  _dumpInfoIfRequested() {
    if (!options.dumpInfo || _reporter is! SummaryReporter) return;
    var result = (_reporter as SummaryReporter).result;
    if (!options.serverMode) print(summaryToString(result));
    var filepath = options.serverMode
        ? path.join(options.outputDir, 'messages.json')
        : options.dumpInfoFile;
    if (filepath == null) return;
    new File(filepath).writeAsStringSync(JSON.encode(result.toJsonMap()));
  }
}

class CompilerServer {
  final Compiler compiler;
  final String outDir;
  final String host;
  final int port;
  final String _entryPath;

  factory CompilerServer(CompilerOptions options) {
    var entryPath = path.basename(options.entryPointFile);
    var extension = path.extension(entryPath);
    if (extension != '.html' && !options.useImplicitHtml) {
      print('error: devc in server mode requires an HTML or Dart entry point.');
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
    var host = options.host;
    var compiler = new Compiler(options);
    return new CompilerServer._(compiler, outDir, host, port, entryPath);
  }

  CompilerServer._(
      Compiler compiler, this.outDir, this.host, this.port, String entryPath)
      : this.compiler = compiler,
        this._entryPath = compiler.options.useImplicitHtml
            ? ResolverOptions.implicitHtmlFile
            : entryPath;

  Future start() async {
    // Create output directory if needed. shelf_static will fail otherwise.
    var out = new Directory(outDir);
    if (!await out.exists()) await out.create(recursive: true);

    var handler = const shelf.Pipeline()
        .addMiddleware(rebuildAndCache)
        .addHandler(shelf_static.createStaticHandler(outDir,
            defaultDocument: _entryPath));
    await shelf.serve(handler, host, port);
    _log.fine('Serving $_entryPath at http://$host:$port/');
    compiler.run();
  }

  shelf.Handler rebuildAndCache(shelf.Handler handler) => (request) {
    _log.fine('requested $GREEN_COLOR${request.url}$NO_COLOR');
    // Trigger recompile only when requesting the HTML page.
    var segments = request.url.pathSegments;
    bool isEntryPage = segments.length == 0 || segments[0] == _entryPath;
    if (isEntryPage) compiler._runAgain();

    // To help browsers cache resources that don't change, we serve these
    // resources by adding a query parameter containing their hash:
    //    /{path-to-file.js}?____cached={hash}
    var hash = request.url.queryParameters['____cached'];
    var response = handler(request);
    var policy = hash != null ? 'max-age=${24 * 60 * 60}' : 'no-cache';
    var headers = {'cache-control': policy};
    if (hash != null) {
      // Note: the cache-control header should be enough, but this doesn't hurt
      // and can help renew the policy after it expires.
      headers['ETag'] = hash;
    }
    return response.change(headers: headers);
  };
}

final _log = new Logger('dev_compiler');
final _earlyErrorResult = new CheckerResults(const [], null, true);
