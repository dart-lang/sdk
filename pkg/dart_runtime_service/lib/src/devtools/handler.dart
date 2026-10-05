// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:devtools_shared/devtools_deeplink_io.dart';
import 'package:devtools_shared/devtools_extensions.dart';
import 'package:devtools_shared/devtools_extensions_io.dart';
import 'package:devtools_shared/devtools_server.dart';
import 'package:devtools_shared/devtools_shared.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:sse/server/sse_handler.dart';

import 'client.dart';

const sseKeepAlive = Duration(seconds: 30);

/// Returns a [Handler] which handles serving DevTools and the DevTools server
/// API.
///
/// [buildDir] is the path to the pre-compiled DevTools instance to be served.
///
/// [notFoundHandler] is a [Handler] to which requests that could not be handled
/// by the DevTools handler are forwarded (e.g., a proxy to the VM
/// service).
///
/// If [appRoot] is `/` (or null), DevTools is not being served by a DDS instance
/// and is served by a standalone server (see `package:dds/devtools_server.dart`).
///
/// If DTD or its URI is null, the Dart Tooling Daemon is not available for
/// this DevTools server connection.
///
/// If DTD URI is non-null, but secret is null, then DTD was started by a
/// client that is not the DevTools server (e.g. an IDE).
FutureOr<Handler> defaultHandler({
  String? buildDir,
  DevToolsClientManager? clientManager,
  Handler? notFoundHandler,
  DtdInfo? dtd,
  required ExtensionsManager devtoolsExtensionsManager,
  String? appRoot,
  bool enableLogging = false,
}) {
  appRoot ??= '/';
  if (!appRoot.endsWith('/')) {
    appRoot = '$appRoot/';
  }

  /// A wrapper around [devtoolsStaticAssetHandler] that handles serving
  /// index.html up for / and non-file requests like /memory, /inspector, etc.
  /// with the correct base href for the DevTools root.
  FutureOr<Response> devtoolsAssetHandler(Request request) {
    // To avoid hard-coding a set of page names here (or needing access to one
    // from DevTools), assume any single-segment path with no extension is a
    // DevTools page that needs to serve up index.html.
    final pathSegments = request.url.pathSegments;

    // Matches extension requests of the form
    // /devtools_extensions/<extension_identifier>/<asset_path> where
    // <extension_identifier> is the extension name and version
    // (e.g. foo_1.0.0).
    if (pathSegments case [
      extensionRequestPath,
      final extensionIdentifier,
      ...final rest,
    ]) {
      // This identifier should be the extension name appended with its version.
      final extensionAssetsLocation = devtoolsExtensionsManager
          .lookupLocationFor(extensionIdentifier);
      if (extensionAssetsLocation != null) {
        final relativePathToExtensionAsset = path.joinAll(rest);
        final assetPath = path.normalize(
          path.join(extensionAssetsLocation, relativePathToExtensionAsset),
        );
        // Ensure the normalized path is still within the expected
        // [extensionAssetsLocation] to protect against directory traversal.
        if (path.isWithin(extensionAssetsLocation, assetPath)) {
          final contentType = lookupMimeType(assetPath) ?? 'text/html';
          final baseHref =
              '$appRoot$extensionRequestPath/$extensionIdentifier/';
          return _serveStaticFile(
            request,
            File(assetPath),
            contentType,
            baseHref: baseHref,
          );
        }
        return Response.notFound(
          'Asset path is outside of extension assets location: $assetPath',
        );
      }
    }

    if (buildDir == null) {
      return Response.notFound('No build directory was specified.');
    }

    const defaultDocument = 'index.html';
    final indexFile = File(path.join(buildDir, defaultDocument));
    final isValidRootPage =
        pathSegments.isEmpty ||
        (pathSegments.length == 1 && !pathSegments[0].contains('.'));

    if (isValidRootPage) {
      return _serveStaticFile(
        request,
        indexFile,
        'text/html',
        baseHref: appRoot,
      );
    }

    // Serves the static web assets for DevTools.
    final devtoolsStaticAssetHandler = createStaticHandler(
      buildDir,
      defaultDocument: defaultDocument,
    );
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

  clientManager ??= DevToolsClientManager(
    requestNotificationPermissions: false,
  );

  devToolsApiHandler.connections.rest.listen((sseConnection) {
    clientManager!.acceptClient(sseConnection, enableLogging: enableLogging);
  });

  FutureOr<Response> devtoolsHandler(Request request) {
    // If the request isn't of the form api/<method> assume it's a request for
    // DevTools assets.
    if (request.url.pathSegments case ['api', final method, ...]) {
      if (method == 'ping') {
        // Note: we have an 'OK' body response, otherwise the response has an
        // incorrect status code (204 instead of 200).
        return Response.ok('OK');
      }
      if (method == 'sse') {
        print('DevTools server handling SSE request: ${request.url}');
        return devToolsApiHandler.handler(request);
      }
      if (!ServerApi.canHandle(request)) {
        return Response.notFound('$method is not a valid API');
      }
      return ServerApi.handle(
        request,
        extensionsManager: devtoolsExtensionsManager,
        deeplinkManager: DeeplinkManager(),
        dtd: dtd,
      );
    }
    return devtoolsAssetHandler(request);
  }

  return (Request request) {
    if (notFoundHandler != null) {
      if (request.url.pathSegments case ['devtools', ...]) {
        // Forward all requests to /devtools/* to the DevTools handler.
        request = request.change(path: 'devtools');
      } else {
        return notFoundHandler(request);
      }
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
      await Future<void>.delayed(const Duration(milliseconds: 500));
      try {
        fileBytes = file.readAsBytesSync();
      } catch (e) {
        return Response.notFound(
          'could not read file as bytes: ${request.url.path}',
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
      'could not read file as String: ${request.url.path}',
    );
  }

  if (baseHref != null) {
    assert(baseHref.startsWith('/'));
    assert(baseHref.endsWith('/'));

    // Always use a relative base href to support going through proxies that
    // rewrite paths. For example if the server thinks we are hosting at
    // `http://localhost/devtools/` but a frontend proxy means the client app
    // is at `http://localhost/proxy/1234/devtools/` then we need the base href
    // to effectively be `/proxy/1234/devtools/`, however we have no knowledge
    // of `/proxy/1234` because it was stripped by the proxy on its way to us.
    baseHref = computeRelativeBaseHref(baseHref, request.requestedUri);

    // Replace the base href to match where the app is being served from.
    final baseHrefPattern = RegExp(r'<base href="\/"\s?\/?>');
    contents = contents.replaceFirst(
      baseHrefPattern,
      '<base href="${htmlEscape.convert(baseHref)}">',
    );
  }
  return Response.ok(contents, headers: headers);
}

/// Computes a relative "base href" that can be used in place of
/// [absoluteBaseHref] for a request served at [requestUri].
String computeRelativeBaseHref(String absoluteBaseHref, Uri requestUri) {
  // path.relative will always treat `from` as if it's a directory, but for
  // URIs that's not correct. If the request is /foo/bar then `.` is `/foo` and
  // not `/foo/bar`. To handle this, trim the last segment if the request does
  // not end with a slash.
  final requestFolderPath = requestUri.path.endsWith('/')
      ? requestUri.path
      : path.posix.dirname(requestUri.path);
  return path.posix.relative(absoluteBaseHref, from: requestFolderPath);
}
