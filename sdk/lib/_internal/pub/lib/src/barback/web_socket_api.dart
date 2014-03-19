// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.web_socket_api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';

import '../utils.dart';
import 'build_environment.dart';

import '../log.dart' as log;

/// Implements the [WebSocket] API for communicating with a running pub serve
/// process, mainly for use by the Editor.
///
/// Requests must be string-encoded JSON maps. Each request is a command, and
/// the map must have a command key:
///
///     {
///       "command": "name"
///     }
///
/// The request may also have an "id" key with any value. If present in the
/// request, the response will include an "id" key with the same value. This
/// can be used by the client to match requests to responses when multiple
/// concurrent requests may be in flight.
///
///     {
///       "command": "name",
///       "id": "anything you want"
///     }
///
/// The request may have other keys for parameters to the command. It's an
/// error to invoke an unknown command.
///
/// All responses sent on the socket are string-encoded JSON maps. If an error
/// occurs while processing the request, an error response will be sent like:
///
///     {
///       "error": "Human-friendly error message."
///       "code": "UNIQUE_IDENTIFIER"
///     }
///
/// The code will be a short string that can be used to uniquely identify the
/// category of error.
///
/// No successful response map will contain a key named "error".
class WebSocketApi {
  final WebSocket _socket;
  final BuildEnvironment _environment;

  Map<String, _CommandHandler> _commands;

  WebSocketApi(this._socket, this._environment) {
    _commands = {
      "urlToAssetId": _urlToAssetId,
      "pathToUrls": _pathToUrls,
      "serveDirectory": _serveDirectory,
      "unserveDirectory": _unserveDirectory
    };
  }

  /// Listens on the socket.
  ///
  /// Returns a future that completes when the socket has closed. It will
  /// complete with an error if the socket had an error, otherwise it will
  /// complete to `null`.
  Future listen() {
    return _socket.listen((data) {
      var command;
      return syncFuture(() {
        try {
          command = JSON.decode(data);
        } on FormatException catch (ex) {
          throw new _WebSocketException(_ErrorCode.BAD_COMMAND,
              '"$data" is not valid JSON: ${ex.message}');
        }

        if (command is! Map) {
          throw new _WebSocketException(_ErrorCode.BAD_COMMAND,
              'Command must be a JSON map. Got $data.');
        }

        if (!command.containsKey("command")) {
          throw new _WebSocketException(_ErrorCode.BAD_COMMAND,
              'Missing command name. Got $data.');
        }

        var handler = _commands[command["command"]];
        if (handler == null) {
          throw new _WebSocketException(_ErrorCode.BAD_COMMAND,
              'Unknown command "${command["command"]}".');
        }

        return handler(command);
      }).then((response) {
        // If the command has an ID, include it in the response.
        if (command.containsKey("id")) {
          response["id"] = command["id"];
        }

        _socket.add(JSON.encode(response));
      }).catchError((error, [stackTrace]) {
        var response;
        if (error is _WebSocketException) {
          response = {
            "code": error.code,
            "error": error.message
          };
        } else {
          // Catch any other errors and pipe them through the web socket.
          response = {
            "code": _ErrorCode.UNEXPECTED_ERROR,
            "error": error.toString(),
            "stackTrace": new Chain.forTrace(stackTrace).toString()
          };
        }

        // If the command has an ID, include it in the response.
        if (command is Map && command.containsKey("id")) {
          response["id"] = command["id"];
        }

        _socket.add(JSON.encode(response));
      });
    }, cancelOnError: true).asFuture();
  }

  /// Given a URL to an asset that is served by pub, returns the ID of the
  /// asset that would be accessed by that URL.
  ///
  /// The command name is "urlToAssetId" and it takes a "url" key for the URL
  /// being mapped:
  ///
  ///     {
  ///       "command": "urlToAssetId",
  ///       "url": "http://localhost:8080/index.html"
  ///     }
  ///
  /// If successful, it returns a map containing the asset ID's package and
  /// path:
  ///
  ///     {
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
  Map _urlToAssetId(Map command) {
    var urlString = _validateString(command, "url");
    var url;
    try {
      url = Uri.parse(urlString);
    } on FormatException catch(ex) {
      print(ex);
      throw new _WebSocketException(_ErrorCode.BAD_ARGUMENT,
          '"$urlString" is not a valid URL.');
    }

    // If a line number was given, map it to the output line.
    var line = _validateOptionalInt(command, "line");

    var id = _environment.getAssetIdForUrl(url);
    if (id == null) {
      throw new _WebSocketException(_ErrorCode.NOT_SERVED,
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
  }

  /// Given a path on the filesystem, returns the URLs served by pub that can be
  /// used to access asset found at that path.
  ///
  /// The command name is "pathToUrls" and it takes a "path" key (a native OS
  /// path which may be absolute or relative to the root directory of the
  /// entrypoint package) for the path being mapped:
  ///
  ///     {
  ///       "command": "pathToUrls",
  ///       "path": "web/index.html"
  ///     }
  ///
  /// If successful, it returns a map containing the list of URLs that can be
  /// used to access that asset.
  ///
  ///     {
  ///       "urls": ["http://localhost:8080/index.html"]
  ///     }
  ///
  /// The "path" key may refer to a path in another package, either by referring
  /// to its location within the top-level "packages" directory or by referring
  /// to its location on disk. Only the "lib" and "asset" directories are
  /// visible in other packages:
  ///
  ///     {
  ///       "command": "assetIdToUrl",
  ///       "path": "packages/http/http.dart"
  ///     }
  ///
  /// Assets in the "lib" and "asset" directories will usually have one URL for
  /// each server:
  ///
  ///     {
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
  Map _pathToUrls(Map command) {
    var assetPath = _validateString(command, "path");
    var line = _validateOptionalInt(command, "line");

    var urls = _environment.getUrlsForAssetPath(assetPath);
    if (urls.isEmpty) {
      throw new _WebSocketException(_ErrorCode.NOT_SERVED,
          'Asset path "$assetPath" is not currently being served.');
    }

    var result = {"urls": urls.map((url) => url.toString()).toList()};

    // Map the line.
    // TODO(rnystrom): Right now, source maps are not supported and it just
    // passes through the original line. This lets the editor start using
    // this API before we've fully implemented it. See #12339 and #16061.
    if (line != null) result["line"] = line;

    return result;
  }

  /// Given a relative directory path within the entrypoint package, binds a
  /// new port to serve from that path and returns its URL.
  ///
  /// The command name is "serveDirectory" and it takes a "path" key (a native
  /// OS path relative to the root of the entrypoint package) for the directory
  /// being served:
  ///
  ///     {
  ///       "command": "serveDirectory",
  ///       "path": "example/awesome"
  ///     }
  ///
  /// If successful, it returns a map containing the URL that can be used to
  /// access the directory.
  ///
  ///     {
  ///       "url": "http://localhost:8083"
  ///     }
  ///
  /// If the directory is already being served, returns the previous URL.
  Future<Map> _serveDirectory(Map command) {
    var rootDirectory = _validateRelativePath(command, "path");
    return _environment.serveDirectory(rootDirectory).then((server) {
      return {
        "url": server.url.toString()
      };
    });
  }


  /// Given a relative directory path within the entrypoint package, unbinds
  /// the server previously bound to that directory and returns its (now
  /// unreachable) URL.
  ///
  /// The command name is "unserveDirectory" and it takes a "path" key (a
  /// native OS path relative to the root of the entrypoint package) for the
  /// directory being unserved:
  ///
  ///     {
  ///       "command": "unserveDirectory",
  ///       "path": "example/awesome"
  ///     }
  ///
  /// If successful, it returns a map containing the URL that used to be used
  /// to access the directory.
  ///
  ///     {
  ///       "url": "http://localhost:8083"
  ///     }
  ///
  /// If no server is bound to that directory, it returns a `NOT_SERVED` error.
  Future<Map> _unserveDirectory(Map command) {
    var rootDirectory = _validateRelativePath(command, "path");
    return _environment.unserveDirectory(rootDirectory).then((url) {
      if (url == null) {
        throw new _WebSocketException(_ErrorCode.NOT_SERVED,
            'Directory "$rootDirectory" is not bound to a server.');
      }

      return {"url": url.toString()};
    });
  }

  /// Validates that [command] has a field named [key] whose value is a string.
  ///
  /// Returns the string if found, or throws a [_WebSocketException] if
  /// validation failed.
  String _validateString(Map command, String key, {bool optional: false}) {
    if (!optional && !command.containsKey(key)) {
      throw new _WebSocketException(_ErrorCode.BAD_ARGUMENT,
          'Missing "$key" argument.');
    }

    var field = command[key];
    if (field is String) return field;
    if (field == null && optional) return null;

    throw new _WebSocketException(_ErrorCode.BAD_ARGUMENT,
        '"$key" must be a string. Got ${JSON.encode(field)}.');
  }

  /// Validates that [command] has a field named [key] whose value is a string
  /// containing a relative path that doesn't reach out of the entrypoint
  /// package's root directory.
  ///
  /// Returns the path if found, or throws a [_WebSocketException] if
  /// validation failed.
  String _validateRelativePath(Map command, String key) {
    var pathString = _validateString(command, key);

    if (!path.isRelative(pathString)) {
      throw new _WebSocketException(_ErrorCode.BAD_ARGUMENT,
          '"$key" must be a relative path. Got "$pathString".');
    }

    if (!path.isWithin(".", pathString)) {
      throw new _WebSocketException(_ErrorCode.BAD_ARGUMENT,
          '"$key" cannot reach out of its containing directory. '
          'Got "$pathString".');
    }

    return pathString;
  }

  /// Validates that if [command] has a field named [key], then its value is a
  /// number.
  ///
  /// Returns the number if found or `null` if not present. Throws an
  /// [_WebSocketException] if the key is there but the field is the wrong type.
  int _validateOptionalInt(Map command, String key) {
    if (!command.containsKey(key)) return null;

    var field = command[key];
    if (field is int) return field;

    throw new _WebSocketException(_ErrorCode.BAD_ARGUMENT,
        '"$key" must be an integer. Got ${JSON.encode(field)}.');
  }
}

/// Function for processing a single web socket command.
///
/// It can return a [Map] or a [Future] that completes to one.
typedef _CommandHandler(Map command);

/// Web socket API error codenames.
class _ErrorCode {
  /// An error of an unknown type has occurred.
  static const UNEXPECTED_ERROR = "UNEXPECTED_ERROR";

  /// The format or name of the command is not valid.
  static const BAD_COMMAND = "BAD_COMMAND";

  /// An argument to the commant is the wrong type or has an invalid value.
  static const BAD_ARGUMENT = "BAD_ARGUMENT";

  /// The path or URL requested is not currently covered by any of the running
  /// servers.
  static const NOT_SERVED = "NOT_SERVED";
}

/// Exception thrown when an error occurs while processing a WebSocket command.
///
/// The top-level WebSocket API code will catch this and translate it to an
/// appropriate error response.
class _WebSocketException implements Exception {
  final String code;
  final String message;

  _WebSocketException(this.code, this.message);
}
