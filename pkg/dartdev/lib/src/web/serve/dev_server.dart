// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dartdev/src/web/project.dart';
import 'package:dartdev/src/web/serve/dart_sources.dart';
import 'package:dartdev/src/web/serve/ddc_assets.dart';
import 'package:dartdev/src/web/serve/ddc_compiler.dart';
import 'package:dartdev/src/web/serve/handler.dart';
import 'package:dartdev/src/web/serve/web_compiler.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Serves a [WebProject] over HTTP: compiles it and serves it until [close]
/// is called.
///
/// The browser asks the HTTP handler for files. The handler answers with the
/// generated files ([DdcAssets]: the scripts that start the app and the
/// modules that [WebCompiler] compiled) or the files in `web/`.
class DevServer {
  /// The project being served.
  final WebProject project;

  /// The errors of the first compile, or an empty list if there were none.
  ///
  /// The app is served even with errors (see [WebCompiler.compile]).
  final List<String> compileErrors;

  /// The host name [start] serves on by default.
  static const defaultHostname = 'localhost';

  /// The port [start] serves on by default.
  static const defaultPort = 8080;

  final String _hostname;
  final HttpServer _server;
  final WebCompiler _compiler;

  DevServer._(
    this.project,
    this.compileErrors,
    this._hostname,
    this._server,
    this._compiler,
  );

  /// The URL that serves the app, such as `http://localhost:8080`.
  ///
  /// Its host is `localhost` only if the server was started for `localhost`,
  /// which listens on both 127.0.0.1 and ::1. Otherwise it's the address the
  /// server listens on, such as `127.0.0.1` or `[::1]`, because a browser
  /// could resolve `localhost` to the other one.
  Uri get url => Uri(
    scheme: 'http',
    host: _hostname == 'localhost' ? _hostname : _server.address.host,
    port: _server.port,
  );

  /// Whether the server listens only on this machine's loopback addresses
  /// (such as `127.0.0.1` and `::1`), so other devices can't reach it.
  bool get isLoopback => _server.address.isLoopback;

  /// Starts serving [project] on [hostname]:[port], and completes once the
  /// app is compiled.
  ///
  /// [port] 0 picks a free port. [sdkRoot] is the SDK whose compiler and
  /// scripts are used, see [DdcCompiler.start].
  static Future<DevServer> start(
    WebProject project, {
    String hostname = defaultHostname,
    int port = defaultPort,
    String? sdkRoot,
  }) async {
    final compiler = await DdcCompiler.start(project, sdkRoot: sdkRoot);
    HttpServer? server;
    try {
      // The SDK scripts are read and the bootstrap scripts generated before
      // compiling, because they don't depend on the compile output.
      final assets = await DdcAssets.load(compiler);
      // Bind the port before compiling, so that a port that's in use fails
      // fast. The handler holds requests until [ready] completes, after the
      // first compile.
      final ready = Completer<void>();
      // For `localhost`, listen on both 127.0.0.1 and ::1. HttpServer.bind
      // only listens on the first address `localhost` resolves to, so
      // browsers that connect to the other one get no answer.
      server = await HttpMultiServer.bind(hostname, port);
      final dartSources = DartSources(
        webDirectory: project.webDirectory,
        packageConfig: project.packageConfig,
        sdkRoot: compiler.sdkRoot,
      );
      shelf_io.serveRequests(
        server,
        createAppHandler(
          lookupFile: assets.lookupFileByPath,
          webDirectory: project.webDirectory,
          dartSources: dartSources,
          hostname: hostname,
          ready: ready.future,
        ),
      );
      final compileErrors = await compiler.compile();
      ready.complete();
      return DevServer._(project, compileErrors, hostname, server, compiler);
    } catch (_) {
      await server?.close(force: true);
      await compiler.shutdown();
      rethrow;
    }
  }

  /// Stops the HTTP server and the compiler.
  Future<void> close() async {
    await _server.close(force: true);
    await _compiler.shutdown();
  }
}
