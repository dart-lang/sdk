// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.web_socket_api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';

import 'build_environment.dart';

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
      "assetIdToUrls": _assetIdToUrls
    };
  }

  /// Listens on the socket.
  ///
  /// Returns a future that completes when the socket has closed. It will
  /// complete with an error if the socket had an error, otherwise it will
  /// complete to `null`.
  Future listen() {
    return _socket.listen((data) {
      try {
        var command;
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

        var response = handler(command);

        // If the command has an ID, include it in the response.
        if (command.containsKey("id")) {
          response["id"] = command["id"];
        }

        _socket.add(JSON.encode(response));
      } on _WebSocketException catch(ex) {
        _socket.add(JSON.encode({"code": ex.code, "error": ex.message}));
      } catch (ex, stack) {
        // Catch any other errors and pipe them through the web socket.
        _socket.add(JSON.encode({
          "code": _ErrorCode.UNEXPECTED_ERROR,
          "error": ex.toString(),
          "stackTrace": new Chain.forTrace(stack).toString()
        }));
      }
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

    // Find the server.
    var server = _environment.servers.firstWhere(
        (server) => server.address.host == url.host && server.port == url.port,
        orElse: () => throw new _WebSocketException(_ErrorCode.NOT_SERVED,
            '"${url.host}:${url.port}" is not being served by pub.'));

    var id = server.urlToId(url);

    // TODO(rnystrom): When this is hooked up to actually talk to barback to
    // see if assets exist, consider supporting implicit index.html at that
    // point.

    var result = {"package": id.package, "path": id.path};

    // Map the line.
    // TODO(rnystrom): Right now, source maps are not supported and it just
    // passes through the original line. This lets the editor start using this
    // API before we've fully implemented it. See #12339 and #16061.
    if (line != null) result["line"] = line;

    return result;
  }

  /// Given an asset ID in the root package, returns the URLs served by pub
  /// that can be used to access that asset.
  ///
  /// The command name is "assetIdToUrl" and it takes a "path" key for the
  /// asset path being mapped:
  ///
  ///     {
  ///       "command": "assetIdToUrl",
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
  ///
  /// This cannot currently be used to access assets in other packages aside
  /// from the root. Nor can it be used to access assets in the root package's
  /// "lib" or "asset" directories.
  ///
  ///     lib/myapp.dart  -> BAD_ARGUMENT error
  Map _assetIdToUrls(Map command) {
    // TODO(rnystrom): Support assets in other packages. See #17146.
    var assetPath = _validateString(command, "path");

    if (!path.url.isRelative(assetPath)) {
      throw new _WebSocketException(_ErrorCode.BAD_ARGUMENT,
          '"path" must be a relative path. Got "$assetPath".');
    }

    if (!path.url.isWithin(".", assetPath)) {
      throw new _WebSocketException(_ErrorCode.BAD_ARGUMENT,
          '"path" cannot reach out of its containing directory. '
          'Got "$assetPath".');
    }

    var line = _validateOptionalInt(command, "line");

    // Find all of the servers whose root directories contain the asset and
    // generate appropriate URLs for each.
    var urls = _environment.servers
        .where((server) => path.url.isWithin(server.rootAssetPath, assetPath))
        .map((server) =>
            "http://${server.address.host}:${server.port}/" +
            path.url.relative(assetPath, from: server.rootAssetPath))
        .toList();

    if (urls.isEmpty) {
      throw new _WebSocketException(_ErrorCode.NOT_SERVED,
          'Asset path "$assetPath" is not currently being served.');
    }

    var result = {"urls": urls};

    // Map the line.
    // TODO(rnystrom): Right now, source maps are not supported and it just
    // passes through the original line. This lets the editor start using this
    // API before we've fully implemented it. See #12339 and #16061.
    if (line != null) result["line"] = line;

    return result;
  }

  /// Validates that [command] has a field named [key] whose value is a string.
  ///
  /// Returns the string if found, or throws a [_WebSocketException] if
  /// validation failed.
  String _validateString(Map command, String key) {
    if (!command.containsKey(key)) {
      throw new _WebSocketException(_ErrorCode.BAD_ARGUMENT,
          'Missing "$key" argument.');
    }

    var field = command[key];
    if (field is String) return field;

    throw new _WebSocketException(_ErrorCode.BAD_ARGUMENT,
        '"$key" must be a string. Got ${JSON.encode(field)}.');
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
typedef Map _CommandHandler(Map command);

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
