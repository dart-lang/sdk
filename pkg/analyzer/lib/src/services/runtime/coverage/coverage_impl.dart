// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for code coverage support for Dart.
library runtime.coverage.impl;

import 'dart:async';
import 'dart:collection' show SplayTreeMap;
import 'dart:io';

import 'package:path/path.dart' as pathos;

import 'package:analyzer/src/generated/scanner.dart' show CharSequenceReader, Scanner;
import 'package:analyzer/src/generated/parser.dart' show Parser;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart' show RecordingErrorListener;

import '../log.dart' as log;
import 'models.dart';

/// Run the [targetPath] with code coverage rewriting.
/// Redirects stdandard process streams.
/// On process exit dumps coverage statistics into the [outPath].
void runServerApplication(String targetPath, String outPath) {
  var targetFolder = pathos.dirname(targetPath);
  var targetName = pathos.basename(targetPath);
  var server = new CoverageServer(targetFolder, targetPath, outPath);
  server.start().then((port) {
    var targetArgs = ['http://127.0.0.1:$port/$targetName'];
    var dartExecutable = Platform.executable;
    return Process.start(dartExecutable, targetArgs);
  }).then((process) {
    stdin.pipe(process.stdin);
    process.stdout.pipe(stdout);
    process.stderr.pipe(stderr);
    return process.exitCode;
  }).then(exit).catchError((e) {
    log.severe('Error starting $targetPath. $e');
  });
}


/// Abstract server to listen requests and serve files, may be rewriting them.
abstract class RewriteServer {
  final String basePath;
  int port;

  RewriteServer(this.basePath);

  /// Runs the HTTP server on the ephemeral port and returns [Future] with it.
  Future<int> start() {
    return HttpServer.bind('127.0.0.1', 0).then((server) {
      port = server.port;
      log.info('RewriteServer is listening at: $port.');
      server.listen((request) {
        if (request.method == 'GET') {
          handleGetRequest(request);
        }
        if (request.method == 'POST') {
          handlePostRequest(request);
        }
      });
      return port;
    });
  }

  void handlePostRequest(HttpRequest request);

  void handleGetRequest(HttpRequest request) {
    var response = request.response;
    // Prepare path.
    var path = getFilePath(request.uri);
    log.info('[$path] Requested.');
    // May be serve using just path.
    {
      var content = rewritePathContent(path);
      if (content != null) {
        log.info('[$path] Request served by path.');
        response.write(content);
        response.close();
        return;
      }
    }
    // Serve from file.
    log.info('[$path] Serving file.');
    var file = new File(path);
    file.exists().then((found) {
      if (found) {
        // May be this files should be sent as is.
        if (!shouldRewriteFile(path)) {
          return sendFile(request, file);
        }
        // Rewrite content of the file.
        return file.readAsString().then((content) {
          log.finest('[$path] Done reading ${content.length} characters.');
          content = rewriteFileContent(path, content);
          log.fine('[$path] Rewritten.');
          response.write(content);
          return response.close();
        });
      } else {
        log.severe('[$path] File not found.');
        response.statusCode = HttpStatus.NOT_FOUND;
        return response.close();
      }
    }).catchError((e) {
      log.severe('[$path] $e.');
      response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
      return response.close();
    });
  }

  String getFilePath(Uri uri) {
    var path = uri.path;
    path = pathos.joinAll(uri.pathSegments);
    path = pathos.join(basePath, path);
    return pathos.normalize(path);
  }

  Future sendFile(HttpRequest request, File file) {
    return file.resolveSymbolicLinks().then((fullPath) {
      return file.openRead().pipe(request.response);
    });
  }

  bool shouldRewriteFile(String path);

  /// Subclasses implement this method to rewrite the provided [code] of the
  /// file with [path]. Returns some content or `null` if file content
  /// should be requested.
  String rewritePathContent(String path);

  /// Subclasses implement this method to rewrite the provided [code] of the
  /// file with [path].
  String rewriteFileContent(String path, String code);
}


/// Here `CCC` means 'code coverage configuration'.
const TEST_UNIT_CCC = '''
class __CCC extends __cc_ut.Configuration {
  void onDone(bool success) {
    __cc.postStatistics();
    super.onDone(success);
  }
}''';

const TEST_UNIT_CCC_SET = '__cc_ut.unittestConfiguration = new __CCC();';


/// Server that rewrites Dart code so that it reports execution of statements
/// and other nodes.
class CoverageServer extends RewriteServer {
  final appInfo = new AppInfo();
  final String targetPath;
  final String outPath;

  CoverageServer(String basePath, this.targetPath, this.outPath)
      : super(basePath);

  void handlePostRequest(HttpRequest request) {
    var id = 0;
    var executedIds = new Set<int>();
    request.listen((data) {
      log.fine('Received statistics, ${data.length} bytes.');
      while (true) {
        var listIndex = id ~/ 8;
        if (listIndex >= data.length) break;
        var bitIndex = id % 8;
        if ((data[listIndex] & (1 << bitIndex)) != 0) {
          executedIds.add(id);
        }
        id++;
      }
    }).onDone(() {
      log.fine('Received all statistics.');
      var buffer = new StringBuffer();
      appInfo.write(buffer, executedIds);
      new File(outPath).writeAsString(buffer.toString()).then((_) {
        return request.response.close();
      }).catchError((e) {
        log.severe('Error in receiving statistics $e.');
        return request.response.close();
      });
    });
  }

  String rewritePathContent(String path) {
    if (path.endsWith('__coverage_lib.dart')) {
      String implPath = pathos.joinAll([
          pathos.dirname(Platform.script.toFilePath()),
          '..', 'lib', 'src', 'services', 'runtime', 'coverage',
          'coverage_lib.dart']);
      var content = new File(implPath).readAsStringSync();
      return content.replaceAll('0; // replaced during rewrite', '$port;');
    }
    return null;
  }

  bool shouldRewriteFile(String path) {
    if (pathos.extension(path).toLowerCase() != '.dart') return false;
    // Rewrite target itself, only to send statistics.
    if (path == targetPath) {
      return true;
    }
    // TODO(scheglov) use configuration
    return path.contains('/packages/analyzer/');
  }

  String rewriteFileContent(String path, String code) {
    var unit = _parseCode(code);
    log.finest('[$path] Parsed.');
    var injector = new CodeInjector(code);
    // Inject imports.
    var directives = unit.directives;
    if (directives.isNotEmpty && directives[0] is LibraryDirective) {
      injector.inject(directives[0].end,
          'import "package:unittest/unittest.dart" as __cc_ut;'
          'import "http://127.0.0.1:$port/__coverage_lib.dart" as __cc;');
    }
    // Inject statistics sender.
    var isTargetScript = path == targetPath;
    if (isTargetScript) {
      for (var node in unit.declarations) {
        if (node is FunctionDeclaration) {
          var body = node.functionExpression.body;
          if (node.name.name == 'main' && body is BlockFunctionBody) {
            injector.inject(node.offset, TEST_UNIT_CCC);
            injector.inject(body.offset + 1, TEST_UNIT_CCC_SET);
          }
        }
      }
    }
    // Inject touch() invocations.
    if (!isTargetScript) {
      appInfo.enterUnit(path, code);
      unit.accept(new InsertTouchInvocationsVisitor(appInfo, injector));
    }
    // Done.
    return injector.getResult();
  }

  CompilationUnit _parseCode(String code) {
    var source = null;
    var errorListener = new RecordingErrorListener();
    var parser = new Parser(source, errorListener);
    var reader = new CharSequenceReader(code);
    var scanner = new Scanner(null, reader, errorListener);
    var token = scanner.tokenize();
    return parser.parseCompilationUnit(token);
  }
}


/// The visitor that inserts `touch` method invocations.
class InsertTouchInvocationsVisitor extends GeneralizingAstVisitor {
  final AppInfo appInfo;
  final CodeInjector injector;

  InsertTouchInvocationsVisitor(this.appInfo, this.injector);

  visitClassDeclaration(ClassDeclaration node) {
    appInfo.enter('class', node.name.name);
    super.visitClassDeclaration(node);
    appInfo.leave();
  }

  visitConstructorDeclaration(ConstructorDeclaration node) {
    var className = (node.parent as ClassDeclaration).name.name;
    var constructorName;
    if (node.name == null) {
      constructorName = className;
    } else {
      constructorName = className + '.' + node.name.name;
    }
    appInfo.enter('constructor', constructorName);
    super.visitConstructorDeclaration(node);
    appInfo.leave();
  }

  visitMethodDeclaration(MethodDeclaration node) {
    if (node.isAbstract) {
      super.visitMethodDeclaration(node);
    } else {
      var kind;
      if (node.isGetter) {
        kind = 'getter';
      } else if (node.isSetter) {
        kind = 'setter';
      } else {
        kind = 'method';
      }
      appInfo.enter(kind, node.name.name);
      super.visitMethodDeclaration(node);
      appInfo.leave();
    }
  }

  visitStatement(Statement node) {
    insertTouch(node);
    super.visitStatement(node);
  }

  void insertTouch(Statement node) {
    if (node is Block) return;
    if (node.parent is LabeledStatement) return;
    if (node.parent is! Block) return;
    // Inject 'touch' invocation.
    var offset = node.offset;
    var id = appInfo.addNode(node);
    injector.inject(offset, '__cc.touch($id);');
  }
}


/// Helper for injecting fragments into some existing code.
class CodeInjector {
  final String _code;
  final offsetFragmentMap = new SplayTreeMap<int, String>();

  CodeInjector(this._code);

  void inject(int offset, String fragment) {
    offsetFragmentMap[offset] = fragment;
  }

  String getResult() {
    var sb = new StringBuffer();
    var lastOffset = 0;
    offsetFragmentMap.forEach((offset, fragment) {
      sb.write(_code.substring(lastOffset, offset));
      sb.write(fragment);
      lastOffset = offset;
    });
    sb.write(_code.substring(lastOffset, _code.length));
    return sb.toString();
  }
}
