// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.server;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';

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
    _server.listen(_handleRequest, onError: (error) {
      _resultsController.addError(error);
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
    if (request.method != "GET" && request.method != "HEAD") {
      _methodNotAllowed(request);
      return;
    }

    var id = _getIdFromUri(request.uri);
    if (id == null) {
      _notFound(request, "Path ${request.uri.path} is not valid.");
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
        if (error is FileException) {
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

  /// Converts a request [uri] into an [AssetId] that can be requested from
  /// barback.
  AssetId _getIdFromUri(Uri uri) {
    var parts = path.url.split(uri.path);

    // Strip the leading "/" from the URL.
    parts.removeAt(0);

    var isSpecial = false;

    // Checks to see if [uri]'s path contains a special directory [name] that
    // identifies an asset within some package. If so, maps the package name
    // and path following that to be within [dir] inside that package.
    AssetId _trySpecialUrl(String name, String dir) {
      // Find the package name and the relative path in the package.
      var index = parts.indexOf(name);
      if (index == -1) return null;

      // If we got here, the path *did* contain the special directory, which
      // means we should not interpret it as a regular path, even if it's
      // missing the package name after it, which makes it invalid here.
      isSpecial = true;
      if (index + 1 >= parts.length) return null;

      var package = parts[index + 1];
      var assetPath = path.url.join(dir,
          path.url.joinAll(parts.skip(index + 2)));
      return new AssetId(package, assetPath);
    }

    // See if it's "packages" URL.
    var id = _trySpecialUrl("packages", "lib");
    if (id != null) return id;

    // See if it's an "assets" URL.
    id = _trySpecialUrl("assets", "asset");
    if (id != null) return id;

    // If we got here, we had a path like "/packages" which is a special
    // directory, but not a valid path since it lacks a following package name.
    if (isSpecial) return null;

    // Otherwise, it's a path in current package's web directory.
    return new AssetId(_rootPackage,
        path.url.join("web", path.url.joinAll(parts)));
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
