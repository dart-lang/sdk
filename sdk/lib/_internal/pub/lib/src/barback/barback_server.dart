// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.server;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:stack_trace/stack_trace.dart';

import '../barback.dart';
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';
import 'base_server.dart';
import 'asset_environment.dart';

/// Callback for determining if an asset with [id] should be served or not.
typedef bool AllowAsset(AssetId id);

/// A server that serves assets transformed by barback.
class BarbackServer extends BaseServer<BarbackServerResult> {
  /// The directory in the root which will serve as the root of this server as
  /// a native platform path.
  ///
  /// This may be `null` in which case no files in the root package can be
  /// served and only assets in "lib" directories are available.
  final String rootDirectory;

  /// Optional callback to determine if an asset should be served.
  ///
  /// This can be set to allow outside code to filter out assets. Pub serve
  /// uses this after plug-ins are loaded to avoid serving ".dart" files in
  /// release mode.
  ///
  /// If this is `null`, all assets may be served.
  AllowAsset allowAsset;

  /// Creates a new server and binds it to [port] of [host].
  ///
  /// This server will serve assets from [barback], and use [rootDirectory] as
  /// the root directory.
  static Future<BarbackServer> bind(AssetEnvironment environment,
      String host, int port, String rootDirectory) {
    return Chain.track(bindServer(host, port)).then((server) {
      log.fine('Bound "$rootDirectory" to $host:$port.');
      return new BarbackServer._(environment, server, rootDirectory);
    });
  }

  BarbackServer._(AssetEnvironment environment, HttpServer server,
      this.rootDirectory)
      : super(environment, server);

  /// Converts a [url] served by this server into an [AssetId] that can be
  /// requested from barback.
  AssetId urlToId(Uri url) {
    // See if it's a URL to a public directory in a dependency.
    var id = packagesUrlToId(url);
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
  handleRequest(shelf.Request request) {
    if (request.method != "GET" && request.method != "HEAD") {
      return methodNotAllowed(request);
    }

    var id;
    try {
      id = urlToId(request.url);
    } on FormatException catch (ex) {
      // If we got here, we had a path like "/packages" which is a special
      // directory, but not a valid path since it lacks a following package
      // name.
      return notFound(request, error: ex.message);
    }

    // See if the asset should be blocked.
    if (allowAsset != null && !allowAsset(id)) {
      return notFound(request,
          error: "Asset $id is not available in this configuration.",
          asset: id);
    }

    logRequest(request, "Loading $id");
    return environment.barback.getAssetById(id).then((result) {
      logRequest(request, "getAssetById($id) returned");
      return result;
    }).then((asset) => _serveAsset(request, asset)).catchError((error, trace) {
      if (error is! AssetNotFoundException) throw error;
      return environment.barback.getAssetById(id.addExtension("/index.html"))
          .then((asset) {
        if (request.url.path.endsWith('/')) return _serveAsset(request, asset);

        // We only want to serve index.html if the URL explicitly ends in a
        // slash. For other URLs, we redirect to one with the slash added to
        // implicitly support that too. This follows Apache's behavior.
        logRequest(request, "302 Redirect to ${request.url}/");
        return new shelf.Response.found('${request.url}/');
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
        return new shelf.Response.internalServerError();
      }

      addResult(new BarbackServerResult._failure(request.url, id, error));
      return notFound(request, asset: id);
    });
  }

  /// Returns the body of [asset] as a response to [request].
  Future<shelf.Response> _serveAsset(shelf.Request request, Asset asset) {
    return validateStream(asset.read()).then((stream) {
      addResult(new BarbackServerResult._success(request.url, asset.id));
      var headers = {};
      var mimeType = lookupMimeType(asset.id.path);
      if (mimeType != null) headers['Content-Type'] = mimeType;
      return new shelf.Response.ok(stream, headers: headers);
    }).catchError((error, trace) {
      addResult(new BarbackServerResult._failure(request.url, asset.id, error));

      // If we couldn't read the asset, handle the error gracefully.
      if (error is FileSystemException) {
        // Assume this means the asset was a file-backed source asset
        // and we couldn't read it, so treat it like a missing asset.
        return notFound(request, error: error.toString(), asset: asset.id);
      }

      trace = new Chain.forTrace(trace);
      logRequest(request, "$error\n$trace");

      // Otherwise, it's some internal error.
      return new shelf.Response.internalServerError(body: error.toString());
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
