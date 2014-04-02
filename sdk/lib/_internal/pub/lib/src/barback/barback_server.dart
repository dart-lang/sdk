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
import 'base_server.dart';
import 'build_environment.dart';
import 'old_web_socket_api.dart';

/// Callback for determining if an asset with [id] should be served or not.
typedef bool AllowAsset(AssetId id);

/// A server that serves assets transformed by barback.
class BarbackServer extends BaseServer<BarbackServerResult> {
  /// The directory in the root which will serve as the root of this server as
  /// a native platform path.
  ///
  /// This may be `null` in which case no files in the root package can be
  /// served and only assets in public directories ("packages" and "assets")
  /// are available.
  final String rootDirectory;

  /// Optional callback to determine if an asset should be served.
  ///
  /// This can be set to allow outside code to filter out assets. Pub serve
  /// uses this after plug-ins are loaded to avoid serving ".dart" files in
  /// release mode.
  ///
  /// If this is `null`, all assets may be served.
  AllowAsset allowAsset;

  // TODO(rnystrom): Remove this when the Editor is using the admin server.
  // port. See #17640.
  /// All currently open [WebSocket] connections.
  final _webSockets = new Set<WebSocket>();

  /// Creates a new server and binds it to [port] of [host].
  ///
  /// This server will serve assets from [barback], and use [rootDirectory] as
  /// the root directory.
  static Future<BarbackServer> bind(BuildEnvironment environment,
      String host, int port, String rootDirectory) {
    return Chain.track(HttpServer.bind(host, port)).then((server) {
      log.fine('Bound "$rootDirectory" to $host:$port.');
      return new BarbackServer._(environment, server, rootDirectory);
    });
  }

  BarbackServer._(BuildEnvironment environment, HttpServer server,
      this.rootDirectory)
      : super(environment, server);

  // TODO(rnystrom): Remove this when the Editor is using the admin server.
  // port. See #17640.
  /// Closes the server.
  Future close() {
    var futures = [super.close()];
    futures.addAll(_webSockets.map((socket) => socket.close()));
    return Future.wait(futures);
  }

  /// Converts a [url] served by this server into an [AssetId] that can be
  /// requested from barback.
  AssetId urlToId(Uri url) {
    // See if it's a URL to a public directory in a dependency.
    var id = specialUrlToId(url);
    if (id != null) return id;

    if (rootDirectory == null) {
      throw new FormatException(
          "This server cannot serve out of the root directory. Got $url.");
    }

    // Otherwise, it's a path in current package's [rootDirectory].
    var parts = path.url.split(url.path);

    // Strip the leading "/" from the URL.
    if (parts.isNotEmpty && parts.first == "/") parts = parts.skip(1);

    var relativePath = path.url.join(rootDirectory, path.url.joinAll(parts));
    return new AssetId(environment.rootPackage.name, relativePath);
  }

  /// Handles an HTTP request.
  void handleRequest(HttpRequest request) {
    // TODO(rnystrom): Remove this when the Editor is using the admin server.
    // port. See #17640.
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      _handleWebSocket(request);
      return;
    }

    if (request.method != "GET" && request.method != "HEAD") {
      methodNotAllowed(request);
      return;
    }

    var id;
    try {
      id = urlToId(request.uri);
    } on FormatException catch (ex) {
      // If we got here, we had a path like "/packages" which is a special
      // directory, but not a valid path since it lacks a following package name.
      notFound(request, error: ex.message);
      return;
    }

    // See if the asset should be blocked.
    if (allowAsset != null && !allowAsset(id)) {
      notFound(request,
          error: "Asset $id is not available in this configuration.",
          asset: id);
      return;
    }

    logRequest(request, "Loading $id");
    environment.barback.getAssetById(id).then((result) {
      logRequest(request, "getAssetById($id) returned");
      return result;
    }).then((asset) => _serveAsset(request, asset)).catchError((error, trace) {
      if (error is! AssetNotFoundException) throw error;
      return environment.barback.getAssetById(id.addExtension("/index.html"))
          .then((asset) {
        if (request.uri.path.endsWith('/')) return _serveAsset(request, asset);

        // We only want to serve index.html if the URL explicitly ends in a
        // slash. For other URLs, we redirect to one with the slash added to
        // implicitly support that too. This follows Apache's behavior.
        logRequest(request, "302 Redirect to ${request.uri}/");
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
        logRequest(request, "$error\n$trace");

        addError(error, trace);
        close();
        return;
      }

      addResult(new BarbackServerResult._failure(request.uri, id, error));
      notFound(request, asset: id);
    });
  }

  // TODO(rnystrom): Remove this when the Editor is using the admin server.
  // port. See #17640.
  /// Creates a web socket for [request] which should be an upgrade request.
  void _handleWebSocket(HttpRequest request) {
    Chain.track(WebSocketTransformer.upgrade(request)).then((socket) {
      _webSockets.add(socket);
      var api = new OldWebSocketApi(socket, environment);

      return api.listen().whenComplete(() {
        _webSockets.remove(api);
      });
    }).catchError(addError);
  }

  /// Serves the body of [asset] on [request]'s response stream.
  ///
  /// Returns a future that completes when the response has been succesfully
  /// written.
  Future _serveAsset(HttpRequest request, Asset asset) {
    return validateStream(asset.read()).then((stream) {
      addResult(new BarbackServerResult._success(request.uri, asset.id));
      var mimeType = lookupMimeType(asset.id.path);
      if (mimeType != null) {
        request.response.headers.add('content-type', mimeType);
      }
      // TODO(rnystrom): Set content-type based on asset type.
      return Chain.track(request.response.addStream(stream)).then((_) {
        // Log successful requests both so we can provide debugging
        // information and so scheduled_test knows we haven't timed out while
        // loading transformers.
        logRequest(request, "Served ${asset.id}");
        request.response.close();
      });
    }).catchError((error, trace) {
      addResult(new BarbackServerResult._failure(request.uri, asset.id, error));

      // If we couldn't read the asset, handle the error gracefully.
      if (error is FileSystemException) {
        // Assume this means the asset was a file-backed source asset
        // and we couldn't read it, so treat it like a missing asset.
        notFound(request, error: error.toString(), asset: asset.id);
        return;
      }

      trace = new Chain.forTrace(trace);
      logRequest(request, "$error\n$trace");

      // Otherwise, it's some internal error.
      request.response.statusCode = 500;
      request.response.reasonPhrase = "Internal Error";
      request.response.write(error);
      request.response.close();
    });
  }
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
