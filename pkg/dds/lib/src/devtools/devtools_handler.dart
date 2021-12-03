// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dds/src/constants.dart';
import 'package:devtools_shared/devtools_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:sse/server/sse_handler.dart';

import '../dds_impl.dart';
import 'devtools_client.dart';

/// Returns a [Handler] which handles serving DevTools and the DevTools server
/// API under $DDS_URI/devtools/.
///
/// [buildDir] is the path to the pre-compiled DevTools instance to be served.
///
/// [notFoundHandler] is a [Handler] to which requests that could not be handled
/// by the DevTools handler are forwarded (e.g., a proxy to the VM service).
FutureOr<Handler> devtoolsHandler({
  required DartDevelopmentServiceImpl dds,
  required String buildDir,
  required Handler notFoundHandler,
}) {
  // Serves the web assets for DevTools.
  final devtoolsAssetHandler = createStaticHandler(
    buildDir,
    defaultDocument: 'index.html',
  );

  // Support DevTools client-server interface via SSE.
  // Note: the handler path needs to match the full *original* path, not the
  // current request URL (we remove '/devtools' in the initial router but we
  // need to include it here).
  const devToolsSseHandlerPath = '/devtools/api/sse';
  final devToolsApiHandler = SseHandler(
    dds.authCodesEnabled
        ? Uri.parse('/${dds.authCode}$devToolsSseHandlerPath')
        : Uri.parse(devToolsSseHandlerPath),
    keepAlive: sseKeepAlive,
  );

  devToolsApiHandler.connections.rest.listen(
    (sseConnection) => DevToolsClient.fromSSEConnection(
      sseConnection,
      dds.shouldLogRequests,
    ),
  );

  final devtoolsHandler = (Request request) {
    // If the request isn't of the form api/<method> assume it's a request for
    // DevTools assets.
    if (request.url.pathSegments.length < 2 ||
        request.url.pathSegments.first != 'api') {
      return devtoolsAssetHandler(request);
    }
    final method = request.url.pathSegments[1];
    if (method == 'ping') {
      // Note: we have an 'OK' body response, otherwise the response has an
      // incorrect status code (204 instead of 200).
      return Response.ok('OK');
    }
    if (method == 'sse') {
      return devToolsApiHandler.handler(request);
    }
    if (!ServerApi.canHandle(request)) {
      return Response.notFound('$method is not a valid API');
    }
    return ServerApi.handle(request);
  };

  return (request) {
    final pathSegments = request.url.pathSegments;
    if (pathSegments.isEmpty || pathSegments.first != 'devtools') {
      return notFoundHandler(request);
    }
    // Forward all requests to /devtools/* to the DevTools handler.
    request = request.change(path: 'devtools');
    return devtoolsHandler(request);
  };
}
