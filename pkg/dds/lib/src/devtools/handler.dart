// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:devtools_shared/devtools_deeplink_io.dart';
import 'package:devtools_shared/devtools_extensions_io.dart';
import 'package:devtools_shared/devtools_server.dart' hide Handler;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../constants.dart';
import '../dds_impl.dart';
import 'client.dart';
import 'utils.dart';

/// Returns a [Handler] which handles serving DevTools and the DevTools server
/// API.
///
/// [buildDir] is the path to the pre-compiled DevTools instance to be served.
///
/// [notFoundHandler] is a [Handler] to which requests that could not be handled
/// by the DevTools handler are forwarded (e.g., a proxy to the VM
/// service).
///
/// If [dds] is null, DevTools is not being served by a DDS instance and is
/// served by a standalone server (see `package:dds/devtools_server.dart`).
///
/// If [dtd] or [dtd.uri] is null, the Dart Tooling Daemon is not available for
/// this DevTools server connection.
///
/// If [dtd.uri] is non-null, but [dtd.secret] is null, then DTD was started by a
/// client that is not the DevTools server (e.g. an IDE).
FutureOr<Handler> defaultHandler({
  DartDevelopmentServiceImpl? dds,
  required String buildDir,
  ClientManager? clientManager,
  Analytics? analytics,
  Handler? notFoundHandler,
  DTDConnectionInfo? dtd,
}) {
  // When served through DDS, the app root is /devtools.
  // This variable is used in base href and must start and end with `/`
  var appRoot = dds != null ? '/devtools/' : '/';
  if (dds?.authCodesEnabled ?? false) {
    appRoot = '/${dds!.authCode}$appRoot';
  }

  const defaultDocument = 'index.html';
  final indexFile = File(path.join(buildDir, defaultDocument));

  // Serves the static web assets for DevTools.
  final devtoolsStaticAssetHandler = createStaticHandler(
    buildDir,
    defaultDocument: defaultDocument,
  );

  /// A wrapper around [devtoolsStaticAssetHandler] that handles serving
  /// index.html up for / and non-file requests like /memory, /inspector, etc.
  /// with the correct base href for the DevTools root.
  FutureOr<Response> devtoolsAssetHandler(Request request) {
    // To avoid hard-coding a set of page names here (or needing access to one
    // from DevTools, assume any single-segment path with no extension is a
    // DevTools page that needs to serve up index.html).
    final pathSegments = request.url.pathSegments;

    final isExtensionRequest = pathSegments.safeGet(0) == extensionRequestPath;
    if (isExtensionRequest) {
      final extensionName = pathSegments.safeGet(1);
      if (extensionName != null) {
        final extensionAssetPath = path.join(
          buildDir,
          path.joinAll(pathSegments),
        );
        final contentType = lookupMimeType(extensionAssetPath) ?? 'text/html';
        final baseHref = '$appRoot$extensionRequestPath/$extensionName/';
        return _serveStaticFile(
          request,
          File(extensionAssetPath),
          contentType,
          baseHref: baseHref,
        );
      }
    }

    final isValidRootPage = pathSegments.isEmpty ||
        (pathSegments.length == 1 && !pathSegments[0].contains('.'));

    if (isValidRootPage) {
      return _serveStaticFile(
        request,
        indexFile,
        'text/html',
        baseHref: appRoot,
      );
    }

    return devtoolsStaticAssetHandler(request);
  }

  // Support DevTools client-server interface via SSE.
  // Note: the handler path needs to match the full *original* path, not the
  // current request URL (we remove '/devtools' in the initial router but we
  // need to include it here).
  final devToolsSseHandlerPath = '${appRoot}api/sse';
  final devToolsApiHandler = SseHandler(
    Uri.parse(devToolsSseHandlerPath),
    keepAlive: sseKeepAlive,
  );

  clientManager ??= ClientManager(requestNotificationPermissions: false);

  devToolsApiHandler.connections.rest.listen(
    (sseConnection) => clientManager!.acceptClient(
      sseConnection,
      enableLogging: dds?.shouldLogRequests ?? false,
    ),
  );

  FutureOr<Response> devtoolsHandler(Request request) {
    // If the request isn't of the form api/<method> assume it's a request for
    // DevTools assets.
    final pathSegments = request.url.pathSegments;
    if (pathSegments.length < 2 || pathSegments.first != 'api') {
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
    return ServerApi.handle(
      request,
      extensionsManager: ExtensionsManager(buildDir: buildDir),
      deeplinkManager: DeeplinkManager(),
      dtd: dtd,
      analytics: analytics ?? NoOpAnalytics(),
    );
  }

  return (Request request) {
    if (notFoundHandler != null) {
      final pathSegments = request.url.pathSegments;
      if (pathSegments.isEmpty || pathSegments.first != 'devtools') {
        return notFoundHandler(request);
      }
      // Forward all requests to /devtools/* to the DevTools handler.
      request = request.change(path: 'devtools');
    }
    return devtoolsHandler(request);
  };
}

/// Serves [file] for all requests.
///
/// For files with [contentType] 'text/html' and a provided [baseHref] value,
/// any existing `<base href="">` tag will be rewritten with the provided path.
Future<Response> _serveStaticFile(
  Request request,
  File file,
  String contentType, {
  String? baseHref,
}) async {
  final headers = {HttpHeaders.contentTypeHeader: contentType};

  if (contentType != 'text/html') {
    late final Uint8List fileBytes;
    try {
      fileBytes = file.readAsBytesSync();
    } on PathNotFoundException catch (_) {
      // Wait a short delay, and then retry in case we have hit a race condition
      // between a static file being served and accessed. See
      // https://github.com/flutter/devtools/issues/6365.
      await Future.delayed(Duration(milliseconds: 500));
      try {
        fileBytes = file.readAsBytesSync();
      } catch (e) {
        return Response.notFound(
          'could not read file as bytes: ${file.path}',
        );
      }
    }
    return Response.ok(fileBytes, headers: headers);
  }

  late String contents;
  try {
    contents = file.readAsStringSync();
  } catch (e) {
    return Response.notFound(
      'could not read file as String: ${file.path}',
    );
  }

  if (baseHref != null) {
    assert(baseHref.startsWith('/'));
    assert(baseHref.endsWith('/'));
    // Replace the base href to match where the app is being served from.
    final baseHrefPattern = RegExp(r'<base href="\/"\s?\/?>');
    contents = contents.replaceFirst(
      baseHrefPattern,
      '<base href="${htmlEscape.convert(baseHref)}">',
    );
  }
  return Response.ok(contents, headers: headers);
}
