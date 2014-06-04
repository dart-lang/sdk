// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.web_socket_api;

import 'dart:async';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';
import 'asset_environment.dart';

/// Implements the [WebSocket] API for communicating with a running pub serve
/// process, mainly for use by the Editor.
///
/// This is a [JSON-RPC 2.0](http://www.jsonrpc.org/specification) server. Its
/// methods are described in the method-level documentation below.
class WebSocketApi {
  final AssetEnvironment _environment;
  final json_rpc.Server _server;

  /// Whether the application should exit when this connection closes.
  bool _exitOnClose = false;

  WebSocketApi(CompatibleWebSocket socket, this._environment)
      : _server = new json_rpc.Server(socket) {
    _server.registerMethod("urlToAssetId", _urlToAssetId);
    _server.registerMethod("pathToUrls", _pathToUrls);
    _server.registerMethod("serveDirectory", _serveDirectory);
    _server.registerMethod("unserveDirectory", _unserveDirectory);

    /// Tells the server to exit as soon as this WebSocket connection is closed.
    ///
    /// This takes no arguments and returns no results. It can safely be called
    /// as a JSON-RPC notification.
    _server.registerMethod("exitOnClose", () {
      _exitOnClose = true;
    });
  }

  /// Listens on the socket.
  ///
  /// Returns a future that completes when the socket has closed. It will
  /// complete with an error if the socket had an error, otherwise it will
  /// complete to `null`.
  Future listen() {
    return _server.listen().then((_) {
      if (!_exitOnClose) return;
      log.message("WebSocket connection closed, terminating.");
      flushThenExit(exit_codes.SUCCESS);
    });
  }

  /// Given a URL to an asset that is served by pub, returns the ID of the
  /// asset that would be accessed by that URL.
  ///
  /// The method name is "urlToAssetId" and it takes a "url" parameter for the
  /// URL being mapped:
  ///
  ///     "params": {
  ///       "url": "http://localhost:8080/index.html"
  ///     }
  ///
  /// If successful, it returns a map containing the asset ID's package and
  /// path:
  ///
  ///     "result": {
  ///       "package": "myapp",
  ///       "path": "web/index.html"
  ///     }
  ///
  /// The "path" key in the result is a URL path that's relative to the root
  /// directory of the package identified by "package". The location of this
  /// package may vary depending on which source it was installed from.
  ///
  /// An optional "line" key may be provided whose value must be an integer. If
  /// given, the result will also include a "line" key that maps the line in
  /// the served final file back to the corresponding source line in the asset
  /// that was used to generate that file.
  ///
  /// Examples (where "myapp" is the root package and pub serve is being run
  /// normally with "web" bound to port 8080 and "test" to 8081):
  ///
  ///     http://localhost:8080/index.html    -> myapp|web/index.html
  ///     http://localhost:8081/sub/main.dart -> myapp|test/sub/main.dart
  ///
  /// If the URL is not a domain being served by pub, this returns an error:
  ///
  ///     http://localhost:1234/index.html    -> NOT_SERVED error
  ///
  /// This does *not* currently support the implicit index.html behavior that
  /// pub serve provides for user-friendliness:
  ///
  ///     http://localhost:1234 -> NOT_SERVED error
  ///
  /// This does *not* currently check to ensure the asset actually exists. It
  /// only maps what the corresponding asset *should* be for that URL.
  Future<Map> _urlToAssetId(json_rpc.Parameters params) {
    var url = params["url"].asUri;

    // If a line number was given, map it to the output line.
    var line = params["line"].asIntOr(null);

    return _environment.getAssetIdForUrl(url).then((id) {
      if (id == null) {
        throw new json_rpc.RpcException(_Error.NOT_SERVED,
            '"${url.host}:${url.port}" is not being served by pub.');
      }

      // TODO(rnystrom): When this is hooked up to actually talk to barback to
      // see if assets exist, consider supporting implicit index.html at that
      // point.

      var result = {"package": id.package, "path": id.path};

      // Map the line.
      // TODO(rnystrom): Right now, source maps are not supported and it just
      // passes through the original line. This lets the editor start using
      // this API before we've fully implemented it. See #12339 and #16061.
      if (line != null) result["line"] = line;

      return result;
    });
  }

  /// Given a path on the filesystem, returns the URLs served by pub that can be
  /// used to access asset found at that path.
  ///
  /// The method name is "pathToUrls" and it takes a "path" key (a native OS
  /// path which may be absolute or relative to the root directory of the
  /// entrypoint package) for the path being mapped:
  ///
  ///     "params": {
  ///       "path": "web/index.html"
  ///     }
  ///
  /// If successful, it returns a map containing the list of URLs that can be
  /// used to access that asset.
  ///
  ///     "result": {
  ///       "urls": ["http://localhost:8080/index.html"]
  ///     }
  ///
  /// The "path" key may refer to a path in another package, either by referring
  /// to its location within the top-level "packages" directory or by referring
  /// to its location on disk. Only the "lib" directory is visible in other
  /// packages:
  ///
  ///     "params": {
  ///       "path": "packages/http/http.dart"
  ///     }
  ///
  /// Assets in the "lib" directory will usually have one URL for each server:
  ///
  ///     "result": {
  ///       "urls": [
  ///         "http://localhost:8080/packages/http/http.dart",
  ///         "http://localhost:8081/packages/http/http.dart"
  ///       ]
  ///     }
  ///
  /// An optional "line" key may be provided whose value must be an integer. If
  /// given, the result will also include a "line" key that maps the line in
  /// the source file to the corresponding output line in the resulting asset
  /// served at the URL.
  ///
  /// Examples (where "myapp" is the root package and pub serve is being run
  /// normally with "web" bound to port 8080 and "test" to 8081):
  ///
  ///     web/index.html      -> http://localhost:8080/index.html
  ///     test/sub/main.dart  -> http://localhost:8081/sub/main.dart
  ///
  /// If the asset is not in a directory being served by pub, returns an error:
  ///
  ///     example/index.html  -> NOT_SERVED error
  Future<Map> _pathToUrls(json_rpc.Parameters params) {
    var assetPath = params["path"].asString;
    var line = params["line"].asIntOr(null);

    return _environment.getUrlsForAssetPath(assetPath).then((urls) {
      if (urls.isEmpty) {
        throw new json_rpc.RpcException(_Error.NOT_SERVED,
            'Asset path "$assetPath" is not currently being served.');
      }

      var result = {"urls": urls.map((url) => url.toString()).toList()};

      // Map the line.
      // TODO(rnystrom): Right now, source maps are not supported and it just
      // passes through the original line. This lets the editor start using
      // this API before we've fully implemented it. See #12339 and #16061.
      if (line != null) result["line"] = line;

      return result;
    });
  }

  /// Given a relative directory path within the entrypoint package, binds a
  /// new port to serve from that path and returns its URL.
  ///
  /// The method name is "serveDirectory" and it takes a "path" key (a native
  /// OS path relative to the root of the entrypoint package) for the directory
  /// being served:
  ///
  ///     "params": {
  ///       "path": "example/awesome"
  ///     }
  ///
  /// If successful, it returns a map containing the URL that can be used to
  /// access the directory.
  ///
  ///     "result": {
  ///       "url": "http://localhost:8083"
  ///     }
  ///
  /// If the directory is already being served, returns the previous URL.
  Future<Map> _serveDirectory(json_rpc.Parameters params) {
    var rootDirectory = _validateRelativePath(params, "path");
    return _environment.serveDirectory(rootDirectory).then((server) {
      return {
        "url": server.url.toString()
      };
    }).catchError((error) {
      if (error is! OverlappingSourceDirectoryException) throw error;

      var dir = pluralize("directory", error.overlappingDirectories.length,
          plural: "directories");
      var overlapping = toSentence(error.overlappingDirectories.map(
          (dir) => '"$dir"'));
      print("data: ${error.overlappingDirectories}");
      throw new json_rpc.RpcException(_Error.OVERLAPPING,
          'Path "$rootDirectory" overlaps already served $dir $overlapping.',
          data: {
            "directories": error.overlappingDirectories
          });
    });
  }

  /// Given a relative directory path within the entrypoint package, unbinds
  /// the server previously bound to that directory and returns its (now
  /// unreachable) URL.
  ///
  /// The method name is "unserveDirectory" and it takes a "path" key (a
  /// native OS path relative to the root of the entrypoint package) for the
  /// directory being unserved:
  ///
  ///     "params": {
  ///       "path": "example/awesome"
  ///     }
  ///
  /// If successful, it returns a map containing the URL that used to be used
  /// to access the directory.
  ///
  ///     "result": {
  ///       "url": "http://localhost:8083"
  ///     }
  ///
  /// If no server is bound to that directory, it returns a `NOT_SERVED` error.
  Future<Map> _unserveDirectory(json_rpc.Parameters params) {
    var rootDirectory = _validateRelativePath(params, "path");
    return _environment.unserveDirectory(rootDirectory).then((url) {
      if (url == null) {
        throw new json_rpc.RpcException(_Error.NOT_SERVED,
            'Directory "$rootDirectory" is not bound to a server.');
      }

      return {"url": url.toString()};
    });
  }

  /// Validates that [command] has a field named [key] whose value is a string
  /// containing a relative path that doesn't reach out of the entrypoint
  /// package's root directory.
  ///
  /// Returns the path if found, or throws a [_WebSocketException] if
  /// validation failed.
  String _validateRelativePath(json_rpc.Parameters params, String key) {
    var pathString = params[key].asString;

    if (!path.isRelative(pathString)) {
      throw new json_rpc.RpcException.invalidParams(
          '"$key" must be a relative path. Got "$pathString".');
    }

    if (!path.isWithin(".", pathString)) {
      throw new json_rpc.RpcException.invalidParams(
          '"$key" cannot reach out of its containing directory. '
          'Got "$pathString".');
    }

    return pathString;
  }
}


/// The pub-specific JSON RPC error codes.
class _Error {
  /// The specified directory is not being served.
  static const NOT_SERVED = 1;

  /// The specified directory overlaps one or more ones already being served.
  static const OVERLAPPING = 2;
}
