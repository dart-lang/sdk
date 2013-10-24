// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';

import '../barback.dart';
import '../log.dart' as log;
import '../utils.dart';

/// A server that serves assets transformed by barback.
class BarbackServer {
  /// The underlying HTTP server.
  final HttpServer _server;

  /// The name of the root package, from whose `web` directory root assets will
  /// be served.
  final String _rootPackage;

  /// The barback instance from which this serves assets.
  final Barback barback;

  /// The server's port.
  final int port;

  /// The server's address.
  final InternetAddress address;

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
  /// This server will serve assets from [barback], and use [rootPackage] as the
  /// root package.
  static Future<BarbackServer> bind(String host, int port, Barback barback,
      String rootPackage) {
    return HttpServer.bind(host, port)
        .then((server) => new BarbackServer._(server, barback, rootPackage));
  }

  BarbackServer._(HttpServer server, this.barback, this._rootPackage)
      : _server = server,
        port = server.port,
        address = server.address {
    _server.listen(_handleRequest, onError: (error, stackTrace) {
      _resultsController.addError(error, stackTrace);
      close();
    });
  }

  /// Closes this server.
  Future close() {
    _server.close();
    _resultsController.close();
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
      id = _urlToId(request.uri);
    } on FormatException catch (ex) {
      // If we got here, we had a path like "/packages" which is a special
      // directory, but not a valid path since it lacks a following package name.
      _notFound(request, ex.message);
      return;
    }

    _logRequest(request, "Loading $id");
    barback.getAssetById(id).then((asset) {
      return validateStream(asset.read()).then((stream) {
        _resultsController.add(
            new BarbackServerResult._success(request.uri, id));
        // TODO(rnystrom): Set content-type based on asset type.
        return request.response.addStream(stream).then((_) {
          // Log successful requests both so we can provide debugging
          // information and so scheduled_test knows we haven't timed out while
          // loading transformers.
          _logRequest(request, "Served $id");
          request.response.close();
        });
      }).catchError((error) {
        _resultsController.add(
            new BarbackServerResult._failure(request.uri, id, error));

        // If we couldn't read the asset, handle the error gracefully.
        if (error is FileSystemException) {
          // Assume this means the asset was a file-backed source asset
          // and we couldn't read it, so treat it like a missing asset.
          _notFound(request, error);
          return;
        }

        var trace = new Trace.from(getAttachedStackTrace(error));
        _logRequest(request, "$error\n$trace");

        // Otherwise, it's some internal error.
        request.response.statusCode = 500;
        request.response.reasonPhrase = "Internal Error";
        request.response.write(error);
        request.response.close();
      });
    }).catchError((error) {
      if (error is! AssetNotFoundException) {
        var trace = new Trace.from(getAttachedStackTrace(error));
        _logRequest(request, "$error\n$trace");

        _resultsController.addError(error);
        close();
        return;
      }

      _resultsController.add(
          new BarbackServerResult._failure(request.uri, id, error));
      _notFound(request, error);
    });
  }

  /// Creates a web socket for [request] which should be an upgrade request.
  void _handleWebSocket(HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((socket) {
      socket.listen((data) {
        var command;
        try {
          command = JSON.decode(data);
        } on FormatException catch (ex) {
          _webSocketError(socket, '"$data" is not valid JSON: ${ex.message}');
          return;
        }

        if (command is! Map) {
          _webSocketError(socket, "Command must be a JSON map. Got: $data.");
          return;
        }

        if (!command.containsKey("command")) {
          _webSocketError(socket, "Missing command name. Got: $data.");
          return;
        }

        switch (command["command"]) {
          case "urlToAsset":
            var urlPath = command["path"];
            if (urlPath is! String) {
              _webSocketError(socket, '"path" must be a string. Got: '
                  '${JSON.encode(urlPath)}.');
              return;
            }

            var url = new Uri(path: urlPath);
            var id = _urlToId(url);
            socket.add(JSON.encode({
              "package": id.package,
              "path": id.path
            }));
            break;

          case "assetToUrl":
            var packageName = command["package"];
            if (packageName is! String) {
              _webSocketError(socket, '"package" must be a string. Got: '
                  '${JSON.encode(packageName)}.');
              return;
            }

            var packagePath = command["path"];
            if (packagePath is! String) {
              _webSocketError(socket, '"path" must be a string. Got: '
                  '${JSON.encode(packagePath)}.');
              return;
            }

            var id = new AssetId(packageName, packagePath);
            try {
              var urlPath = idtoUrlPath(_rootPackage, id);
              socket.add(JSON.encode({"path": urlPath}));
            } on FormatException catch (ex) {
              _webSocketError(socket, ex.message);
            }
            break;

          default:
            _webSocketError(socket, 'Unknown command "${command["command"]}".');
            break;
        }
      }, onError: (error) {
        _resultsController.addError(error);
      }, cancelOnError: true);
    }).catchError((error) {
      _resultsController.addError(error);
    });
  }

  /// Converts a [url] served by pub serve into an [AssetId] that can be
  /// requested from barback.
  AssetId _urlToId(Uri url) {
    var id = specialUrlToId(url);
    if (id != null) return id;

    // Otherwise, it's a path in current package's web directory.
    var parts = path.url.split(url.path);

    // Strip the leading "/" from the URL.
    if (parts.isNotEmpty && parts.first == "/") parts = parts.skip(1);

    var relativePath = path.url.join("web", path.url.joinAll(parts));
    return new AssetId(_rootPackage, relativePath);
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
    request.response.statusCode = 404;
    request.response.reasonPhrase = "Not Found";
    request.response.write(message);
    request.response.close();
  }

  /// Log [message] at [log.Level.FINE] with metadata about [request].
  void _logRequest(HttpRequest request, String message) =>
    log.fine("BarbackServer ${request.method} ${request.uri}\n$message");

  void _webSocketError(WebSocket socket, String message) {
    socket.add(JSON.encode({"error": message}));
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
