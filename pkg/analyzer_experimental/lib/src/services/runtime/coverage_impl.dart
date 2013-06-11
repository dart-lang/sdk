// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for code coverage support for Dart.
library runtime.coverage_impl;

import "dart:io";

import "package:logging/logging.dart" as log;
import "package:pathos/path.dart" as po;

import 'package:analyzer_experimental/src/generated/source.dart' show Source;
import 'package:analyzer_experimental/src/generated/scanner.dart' show StringScanner;
import 'package:analyzer_experimental/src/generated/parser.dart' show Parser;
import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/engine.dart' show RecordingErrorListener;


log.Logger logger = log.Logger.root;

/// Abstract server that listens requests and serves files, may be rewriting them.
abstract class RewriteServer {
  String _basePath;
  RewriteServer(this._basePath);
  void start() {
    HttpServer.bind("127.0.0.1", 3445).then((HttpServer server) {
      logger.info('RewriteServer is listening at: ${server.port}.');
      server.listen((HttpRequest request) {
        var response = request.response;
        // Prepare path.
        var path = _basePath + '/' + request.uri.path;
        path = po.normalize(path);
        logger.info('[$path] Requested.');
        // May be serve using just path.
        {
          String content = rewritePathContent(path);
          if (content != null) {
            logger.info('[$path] Request served by path.');
            response.write(content);
            response.close();
            return;
          }
        }
        // Serve from file.
        logger.info('[$path] Serving file.');
        var file = new File(path);
        file.exists().then((bool found) {
          if (found) {
            logger.finest('[$path] Found file.');
            file.readAsString().then((String content) {
              logger.finest('[$path] Got file content.');
              var sw = new Stopwatch();
              sw.start();
              try {
                content = rewriteFileContent(path, content);
              } finally {
                sw.stop();
                logger.fine('[$path] Rewritten in ${sw.elapsedMilliseconds} ms.');
              }
              response.write(content);
              response.close();
            });
          } else {
            logger.severe('[$path] File not found.');
            response.statusCode = HttpStatus.NOT_FOUND;
            response.close();
          }
        });
      });
    });
  }

  /// Subclasses implement this method to rewrite the provided [code] of the file with [path].
  /// Returns some content or `null` if file content should be requested.
  String rewritePathContent(String path);

  /// Subclasses implement this method to rewrite the provided [code] of the file with [path].
  String rewriteFileContent(String path, String code);
}

/// Server that rewrites Dart code so that it reports execution of statements and other nodes.
class CoverageServer extends RewriteServer {
  CoverageServer(String basePath) : super(basePath);

  String rewritePathContent(String path) {
    if (path.endsWith('__coverage_impl.dart')) {
      String implPath = po.joinAll([
          po.dirname(new Options().script),
          '..', 'lib', 'src', 'services', 'runtime', 'coverage_lib.dart']);
      return new File(implPath).readAsStringSync();
    }
    return null;
  }

  String rewriteFileContent(String path, String code) {
    if (po.extension(path).toLowerCase() != '.dart') return code;
    if (path.contains('packages')) return code;
    var unit = _parseCode(code);
    var injector = new StringInjector(code);
    // Inject coverage library import.
    var directives = unit.directives;
    if (directives.isNotEmpty && directives[0] is LibraryDirective) {
      injector.inject(directives[0].end, 'import "__coverage_impl.dart" as __cc;');
    } else {
      throw new Exception('Only single library coverage is implemented.');
    }
    // Insert touch() invocations.
    unit.accept(new InsertTouchInvocationsVisitor(injector));
    // Done.
    code = injector.code;
    logger.finest('[$path] Rewritten content\n$code');
    return code;
  }

  CompilationUnit _parseCode(String code) {
    var source = null;
    var errorListener = new RecordingErrorListener();
    var parser = new Parser(source, errorListener);
    var scanner = new StringScanner(source, code, errorListener);
    var token = scanner.tokenize();
    return parser.parseCompilationUnit(token);
  }
}

/// The visitor that inserts `touch` method invocations.
class InsertTouchInvocationsVisitor extends GeneralizingASTVisitor {
  StringInjector injector;
  InsertTouchInvocationsVisitor(this.injector);
  visitStatement(Statement node) {
    super.visitStatement(node);
    var offset = node.end;
    if (node is Block) {
      offset--;
    }
    if (node is Block && node.parent is BlockFunctionBody) return null;
    injector.inject(offset, '__cc.touch(${node.offset});');
    return null;
  }
}

/// Helper for injecting fragments into some existing [String].
class StringInjector {
  String code;
  int _lastOffset = -1;
  int _delta = 0;
  StringInjector(this.code);
  void inject(int offset, String fragment) {
    if (offset < _lastOffset) {
      throw new ArgumentError('Only forward inserts are supported, was $_lastOffset given $offset');
    }
    _lastOffset = offset;
    offset += _delta;
    code = code.substring(0, offset) + fragment + code.substring(offset);
    _delta += fragment.length;
  }
}