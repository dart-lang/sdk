// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build_daemon/data/build_status.dart' as daemon;
import 'package:dwds/asset_reader.dart';
import 'package:dwds/dart_web_debug_service.dart';
import 'package:dwds/data/build_result.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/utilities/server.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

Logger _logger = Logger('TestServer');

Handler _interceptFavicon(Handler handler) {
  return (request) async {
    if (request.url.pathSegments.isNotEmpty &&
        request.url.pathSegments.last == 'favicon.ico') {
      return Response.ok('');
    }
    return handler(request);
  };
}

class TestServer {
  final HttpServer _server;
  final String target;
  final Dwds dwds;
  final Stream<BuildResult> buildResults;
  final AssetReader assetReader;

  TestServer._(
    this.target,
    this._server,
    this.dwds,
    this.buildResults,
    this.assetReader,
  );

  String get host => _server.address.host;
  int get port => _server.port;

  Future<void> stop() async {
    await dwds.stop();
    await _server.close(force: true);
  }

  static Future<TestServer> start({
    required DebugSettings debugSettings,
    required AppMetadata appMetadata,
    required Handler assetHandler,
    required AssetReader assetReader,
    required LoadStrategy strategy,
    required String target,
    required Stream<daemon.BuildResults> buildResults,
    required Future<ChromeConnection> Function() chromeConnection,
    int? port,
    HttpServer? httpServer,
  }) async {
    var pipeline = const Pipeline();

    pipeline = pipeline.addMiddleware(_interceptFavicon);

    final filteredBuildResults = buildResults.asyncMap<BuildResult>((results) {
      final result = results.results.firstWhere(
        (result) => result.target == target,
      );
      switch (result.status) {
        case daemon.BuildStatus.started:
          return BuildResult(status: BuildStatus.started);
        case daemon.BuildStatus.failed:
          return BuildResult(status: BuildStatus.failed);
        case daemon.BuildStatus.succeeded:
          return BuildResult(status: BuildStatus.succeeded);
        default:
          break;
      }
      throw StateError('Unexpected Daemon build result: $result');
    });

    final toolConfiguration = ToolConfiguration(
      loadStrategy: strategy,
      debugSettings: debugSettings,
      appMetadata: appMetadata,
    );

    final dwds = await Dwds.start(
      assetReader: assetReader,
      buildResults: filteredBuildResults,
      chromeConnection: chromeConnection,
      toolConfiguration: toolConfiguration,
    );

    final server = httpServer ?? await startHttpServer('localhost', port: port);
    var cascade = Cascade();

    cascade = cascade.add(dwds.handler).add(assetHandler);

    serveHttpRequests(
      server,
      pipeline
          .addMiddleware(_logRequests)
          .addMiddleware(dwds.middleware)
          .addHandler(cascade.handler),
      (e, s) {
        _logger.warning('Error handling requests', e, s);
      },
    );

    return TestServer._(
      target,
      server,
      dwds,
      filteredBuildResults,
      assetReader,
    );
  }

  /// [Middleware] that logs all requests, inspired by [logRequests].
  static Handler _logRequests(Handler innerHandler) {
    return (Request request) async {
      final watch = Stopwatch()..start();
      try {
        final response = await innerHandler(request);
        final logFn = response.statusCode >= 500
            ? _logger.warning
            : _logger.finest;
        final msg = _requestLabel(
          response.statusCode,
          request.requestedUri,
          request.method,
          watch.elapsed,
        );
        logFn(msg);
        return response;
      } catch (error, stackTrace) {
        if (error is HijackException) rethrow;
        final msg = _requestLabel(
          500,
          request.requestedUri,
          request.method,
          watch.elapsed,
        );
        _logger.severe(msg, error, stackTrace);
        rethrow;
      }
    };
  }

  static String _requestLabel(
    int statusCode,
    Uri requestedUri,
    String method,
    Duration elapsedTime,
  ) {
    return '$elapsedTime '
        '$method [$statusCode] '
        '${requestedUri.path}${_formatQuery(requestedUri.query)}';
  }

  static String _formatQuery(String query) {
    return query == '' ? '' : '?$query';
  }
}
