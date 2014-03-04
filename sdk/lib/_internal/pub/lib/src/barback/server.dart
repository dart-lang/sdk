// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.server;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';

import '../barback.dart';
import '../log.dart' as log;
import '../utils.dart';
import 'build_environment.dart';
import 'web_socket_api.dart';

/// Callback for determining if an asset with [id] should be served or not.
typedef bool AllowAsset(AssetId id);

/// A server that serves assets transformed by barback.
class BarbackServer {
  /// The [BuildEnvironment] being served.
  final BuildEnvironment _environment;

  /// The underlying HTTP server.
  final HttpServer _server;

  /// All currently open [WebSocket] connections.
  final _webSockets = new Set<WebSocket>();

  /// The directory in the root which will serve as the root of this server as
  /// a native platform path.
  final String rootDirectory;

  /// The root directory as an asset-style ("/") path.
  String get rootAssetPath => path.url.joinAll(path.split(rootDirectory));

  /// The server's port.
  final int port;

  /// The server's address.
  final InternetAddress address;

  /// Optional callback to determine if an asset should be served.
  ///
  /// This can be set to allow outside code to filter out assets. Pub serve
  /// uses this after plug-ins are loaded to avoid serving ".dart" files in
  /// release mode.
  ///
  /// If this is `null`, all assets may be served.
  AllowAsset allowAsset;

  /// The results of requests handled by the server.
  ///
  /// These can be used to provide visual feedback for the server's processing.
  /// This stream is also used to emit any programmatic errors that occur in the
  /// server.
  Stream<BarbackServerResult> get results => _resultsController.stream;
  final _resultsController =
      new StreamController<BarbackServerResult>.broadcast();

  /// Creates a new server and binds it to [port] of [host].
  ///
  /// This server will serve assets from [barback], and use [rootDirectory] as
  /// the root directory.
  static Future<BarbackServer> bind(BuildEnvironment environment,
      String host, int port, String rootDirectory) {
    return Chain.track(HttpServer.bind(host, port)).then((server) {
      return new BarbackServer._(environment, server, rootDirectory);
    });
  }

  BarbackServer._(this._environment, HttpServer server, this.rootDirectory)
      : _server = server,
        port = server.port,
        address = server.address {
    Chain.track(_server).listen(_handleRequest, onError: (error, stackTrace) {
      _resultsController.addError(error, stackTrace);
      close();
    });
  }

  /// Closes this server.
  Future close() {
    var futures = [_server.close(), _resultsController.close()];
    futures.addAll(_webSockets);
    return Future.wait(futures);
  }

  /// Converts a [url] served by this server into an [AssetId] that can be
  /// requested from barback.
  AssetId urlToId(Uri url) {
    // See if it's a URL to a public directory in a dependency.
    var id = specialUrlToId(url);
    if (id != null) return id;

    // Otherwise, it's a path in current package's [rootDirectory].
    var parts = path.url.split(url.path);

    // Strip the leading "/" from the URL.
    if (parts.isNotEmpty && parts.first == "/") parts = parts.skip(1);

    var relativePath = path.url.join(rootDirectory, path.url.joinAll(parts));
    return new AssetId(_environment.rootPackage.name, relativePath);
  }

  /// Handles an HTTP request.
  void _handleRequest(HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      _handleWebSocket(request);
      return;
    }

    if (request.method != "GET" && request.method != "HEAD") {
      _methodNotAllowed(request);
      return;
    }

    var id;
    try {
      id = urlToId(request.uri);
    } on FormatException catch (ex) {
      // If we got here, we had a path like "/packages" which is a special
      // directory, but not a valid path since it lacks a following package name.
      _notFound(request, ex.message);
      return;
    }

    // See if the asset should be blocked.
    if (allowAsset != null && !allowAsset(id)) {
      _notFound(request, "Asset $id is not available in this configuration.");
      return;
    }

    _logRequest(request, "Loading $id");
    _environment.barback.getAssetById(id)
        .then((asset) => _serveAsset(request, asset))
        .catchError((error, trace) {
      if (error is! AssetNotFoundException) throw error;
      return _environment.barback.getAssetById(id.addExtension("/index.html"))
          .then((asset) {
        if (request.uri.path.endsWith('/')) return _serveAsset(request, asset);

        // We only want to serve index.html if the URL explicitly ends in a
        // slash. For other URLs, we redirect to one with the slash added to
        // implicitly support that too. This follows Apache's behavior.
        _logRequest(request, "302 Redirect to ${request.uri}/");
        request.response.statusCode = 302;
        request.response.headers.add('location', '${request.uri}/');
        request.response.close();
      }).catchError((newError, newTrace) {
        // If we find neither the original file or the index, we should report
        // the error about the original to the user.
        throw newError is AssetNotFoundException ? error : newError;
      });
    }).catchError((error, trace) {
      if (error is! AssetNotFoundException) {
        trace = new Chain.forTrace(trace);
        _logRequest(request, "$error\n$trace");

        _resultsController.addError(error, trace);
        close();
        return;
      }

      _resultsController.add(
          new BarbackServerResult._failure(request.uri, id, error));
      _notFound(request, error);
    });
  }

  /// Serves the body of [asset] on [request]'s response stream.
  ///
  /// Returns a future that completes when the response has been succesfully
  /// written.
  Future _serveAsset(HttpRequest request, Asset asset) {
    return validateStream(asset.read()).then((stream) {
      _resultsController.add(
          new BarbackServerResult._success(request.uri, asset.id));
      var mimeType = lookupMimeType(asset.id.path);
      if (mimeType != null) {
        request.response.headers.add('content-type', mimeType);
      }
      // TODO(rnystrom): Set content-type based on asset type.
      return Chain.track(request.response.addStream(stream)).then((_) {
        // Log successful requests both so we can provide debugging
        // information and so scheduled_test knows we haven't timed out while
        // loading transformers.
        _logRequest(request, "Served ${asset.id}");
        request.response.close();
      });
    }).catchError((error, trace) {
      _resultsController.add(
          new BarbackServerResult._failure(request.uri, asset.id, error));

      // If we couldn't read the asset, handle the error gracefully.
      if (error is FileSystemException) {
        // Assume this means the asset was a file-backed source asset
        // and we couldn't read it, so treat it like a missing asset.
        _notFound(request, error);
        return;
      }

      trace = new Chain.forTrace(trace);
      _logRequest(request, "$error\n$trace");

      // Otherwise, it's some internal error.
      request.response.statusCode = 500;
      request.response.reasonPhrase = "Internal Error";
      request.response.write(error);
      request.response.close();
    });
  }

  /// Creates a web socket for [request] which should be an upgrade request.
  void _handleWebSocket(HttpRequest request) {
    Chain.track(WebSocketTransformer.upgrade(request)).then((socket) {
      _webSockets.add(socket);
      var api = new WebSocketApi(socket, _environment);

      return api.listen().whenComplete(() {
        _webSockets.remove(api);
      });
    }).catchError(_resultsController.addError);
  }

  /// Responds to [request] with a 405 response and closes it.
  void _methodNotAllowed(HttpRequest request) {
    _logRequest(request, "405 Method Not Allowed");
    request.response.statusCode = 405;
    request.response.reasonPhrase = "Method Not Allowed";
    request.response.headers.add('Allow', 'GET, HEAD');
    request.response.write(
        "The ${request.method} method is not allowed for ${request.uri}.");
    request.response.close();
  }

  /// Responds to [request] with a 404 response and closes it.
  void _notFound(HttpRequest request, message) {
    _logRequest(request, "404 Not Found");

    // Force a UTF-8 encoding so that error messages in non-English locales are
    // sent correctly.
    request.response.headers.contentType =
        ContentType.parse("text/plain; charset=utf-8");

    request.response.statusCode = 404;
    request.response.reasonPhrase = "Not Found";
    request.response.write(message);
    request.response.close();
  }

  /// Log [message] at [log.Level.FINE] with metadata about [request].
  void _logRequest(HttpRequest request, String message) =>
    log.fine("BarbackServer ${request.method} ${request.uri}\n$message");
}

/// The result of the server handling a URL.
///
/// Only requests for which an asset was requested from barback will emit a
/// result. Malformed requests will be handled internally.
class BarbackServerResult {
  /// The requested url.
  final Uri url;

  /// The id that [url] identifies.
  final AssetId id;

  /// The error thrown by barback.
  ///
  /// If the request was served successfully, this will be null.
  final error;

  /// Whether the request was served successfully.
  bool get isSuccess => error == null;

  /// Whether the request was served unsuccessfully.
  bool get isFailure => !isSuccess;

  BarbackServerResult._success(this.url, this.id)
      : error = null;

  BarbackServerResult._failure(this.url, this.id, this.error);
}
