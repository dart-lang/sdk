// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helpers for dealing with HTTP.
library pub.http;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_throttle/http_throttle.dart';

import 'io.dart';
import 'log.dart' as log;
import 'oauth2.dart' as oauth2;
import 'sdk.dart' as sdk;
import 'utils.dart';

// TODO(nweiz): make this configurable
/// The amount of time in milliseconds to allow HTTP requests before assuming
/// they've failed.
final HTTP_TIMEOUT = 30 * 1000;

/// Headers and field names that should be censored in the log output.
final _CENSORED_FIELDS = const ['refresh_token', 'authorization'];

/// Headers required for pub.dartlang.org API requests.
///
/// The Accept header tells pub.dartlang.org which version of the API we're
/// expecting, so it can either serve that version or give us a 406 error if
/// it's not supported.
final PUB_API_HEADERS = const {
  'Accept': 'application/vnd.pub.v2+json'
};

/// An HTTP client that transforms 40* errors and socket exceptions into more
/// user-friendly error messages.
///
/// This also adds a 30-second timeout to every request. This can be configured
/// on a per-request basis by setting the 'Pub-Request-Timeout' header to the
/// desired number of milliseconds, or to "None" to disable the timeout.
class _PubHttpClient extends http.BaseClient {
  final _requestStopwatches = new Map<http.BaseRequest, Stopwatch>();

  http.Client _inner;

  _PubHttpClient([http.Client inner])
      : this._inner = inner == null ? new http.Client() : inner;

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    _requestStopwatches[request] = new Stopwatch()..start();
    request.headers[HttpHeaders.USER_AGENT] = "Dart pub ${sdk.version}";
    _logRequest(request);

    // TODO(nweiz): remove this when issue 4061 is fixed.
    var stackTrace;
    try {
      throw null;
    } catch (_, localStackTrace) {
      stackTrace = localStackTrace;
    }

    var timeoutLength = HTTP_TIMEOUT;
    var timeoutString = request.headers.remove('Pub-Request-Timeout');
    if (timeoutString == 'None') {
      timeoutLength = null;
    } else if (timeoutString != null) {
      timeoutLength = int.parse(timeoutString);
    }

    var future = _inner.send(request).then((streamedResponse) {
      _logResponse(streamedResponse);

      var status = streamedResponse.statusCode;
      // 401 responses should be handled by the OAuth2 client. It's very
      // unlikely that they'll be returned by non-OAuth2 requests. We also want
      // to pass along 400 responses from the token endpoint.
      var tokenRequest =
          urisEqual(streamedResponse.request.url, oauth2.tokenEndpoint);
      if (status < 400 || status == 401 || (status == 400 && tokenRequest)) {
        return streamedResponse;
      }

      if (status == 406 &&
          request.headers['Accept'] == PUB_API_HEADERS['Accept']) {
        fail(
            "Pub ${sdk.version} is incompatible with the current version of "
                "${request.url.host}.\n" "Upgrade pub to the latest version and try again.");
      }

      if (status == 500 &&
          (request.url.host == "pub.dartlang.org" ||
              request.url.host == "storage.googleapis.com")) {
        var message =
            "HTTP error 500: Internal Server Error at " "${request.url}.";

        if (request.url.host == "pub.dartlang.org" ||
            request.url.host == "storage.googleapis.com") {
          message +=
              "\nThis is likely a transient error. Please try again " "later.";
        }

        fail(message);
      }

      return http.Response.fromStream(streamedResponse).then((response) {
        throw new PubHttpException(response);
      });
    }).catchError((error, stackTrace) {
      if (error is SocketException && error.osError != null) {
        if (error.osError.errorCode == 8 ||
            error.osError.errorCode == -2 ||
            error.osError.errorCode == -5 ||
            error.osError.errorCode == 11001 ||
            error.osError.errorCode == 11004) {
          fail(
              'Could not resolve URL "${request.url.origin}".',
              error,
              stackTrace);
        } else if (error.osError.errorCode == -12276) {
          fail(
              'Unable to validate SSL certificate for ' '"${request.url.origin}".',
              error,
              stackTrace);
        }
      }
      throw error;
    });

    if (timeoutLength == null) return future;
    return timeout(
        future,
        timeoutLength,
        request.url,
        'fetching URL "${request.url}"');
  }

  /// Logs the fact that [request] was sent, and information about it.
  void _logRequest(http.BaseRequest request) {
    var requestLog = new StringBuffer();
    requestLog.writeln("HTTP ${request.method} ${request.url}");
    request.headers.forEach(
        (name, value) => requestLog.writeln(_logField(name, value)));

    if (request.method == 'POST') {
      var contentTypeString = request.headers[HttpHeaders.CONTENT_TYPE];
      if (contentTypeString == null) contentTypeString = '';
      var contentType = ContentType.parse(contentTypeString);
      if (request is http.MultipartRequest) {
        requestLog.writeln();
        requestLog.writeln("Body fields:");
        request.fields.forEach(
            (name, value) => requestLog.writeln(_logField(name, value)));

        // TODO(nweiz): make MultipartRequest.files readable, and log them?
      } else if (request is http.Request) {
        if (contentType.value == 'application/x-www-form-urlencoded') {
          requestLog.writeln();
          requestLog.writeln("Body fields:");
          request.bodyFields.forEach(
              (name, value) => requestLog.writeln(_logField(name, value)));
        } else if (contentType.value == 'text/plain' ||
            contentType.value == 'application/json') {
          requestLog.write(request.body);
        }
      }
    }

    log.fine(requestLog.toString().trim());
  }

  /// Logs the fact that [response] was received, and information about it.
  void _logResponse(http.StreamedResponse response) {
    // TODO(nweiz): Fork the response stream and log the response body. Be
    // careful not to log OAuth2 private data, though.

    var responseLog = new StringBuffer();
    var request = response.request;
    var stopwatch = _requestStopwatches.remove(request)..stop();
    responseLog.writeln(
        "HTTP response ${response.statusCode} "
            "${response.reasonPhrase} for ${request.method} ${request.url}");
    responseLog.writeln("took ${stopwatch.elapsed}");
    response.headers.forEach(
        (name, value) => responseLog.writeln(_logField(name, value)));

    log.fine(responseLog.toString().trim());
  }

  /// Returns a log-formatted string for the HTTP field or header with the given
  /// [name] and [value].
  String _logField(String name, String value) {
    if (_CENSORED_FIELDS.contains(name.toLowerCase())) {
      return "$name: <censored>";
    } else {
      return "$name: $value";
    }
  }
}

/// The [_PubHttpClient] wrapped by [httpClient].
final _pubClient = new _PubHttpClient();

/// The HTTP client to use for all HTTP requests.
final httpClient = new ThrottleClient(16, _pubClient);

/// The underlying HTTP client wrapped by [httpClient].
http.Client get innerHttpClient => _pubClient._inner;
set innerHttpClient(http.Client client) => _pubClient._inner = client;

/// Handles a successful JSON-formatted response from pub.dartlang.org.
///
/// These responses are expected to be of the form `{"success": {"message":
/// "some message"}}`. If the format is correct, the message will be printed;
/// otherwise an error will be raised.
void handleJsonSuccess(http.Response response) {
  var parsed = parseJsonResponse(response);
  if (parsed['success'] is! Map ||
      !parsed['success'].containsKey('message') ||
      parsed['success']['message'] is! String) {
    invalidServerResponse(response);
  }
  log.message(parsed['success']['message']);
}

/// Handles an unsuccessful JSON-formatted response from pub.dartlang.org.
///
/// These responses are expected to be of the form `{"error": {"message": "some
/// message"}}`. If the format is correct, the message will be raised as an
/// error; otherwise an [invalidServerResponse] error will be raised.
void handleJsonError(http.Response response) {
  var errorMap = parseJsonResponse(response);
  if (errorMap['error'] is! Map ||
      !errorMap['error'].containsKey('message') ||
      errorMap['error']['message'] is! String) {
    invalidServerResponse(response);
  }
  fail(errorMap['error']['message']);
}

/// Parses a response body, assuming it's JSON-formatted.
///
/// Throws a user-friendly error if the response body is invalid JSON, or if
/// it's not a map.
Map parseJsonResponse(http.Response response) {
  var value;
  try {
    value = JSON.decode(response.body);
  } on FormatException catch (e) {
    invalidServerResponse(response);
  }
  if (value is! Map) invalidServerResponse(response);
  return value;
}

/// Throws an error describing an invalid response from the server.
void invalidServerResponse(http.Response response) =>
    fail('Invalid server response:\n${response.body}');

/// Exception thrown when an HTTP operation fails.
class PubHttpException implements Exception {
  final http.Response response;

  const PubHttpException(this.response);

  String toString() =>
      'HTTP error ${response.statusCode}: ' '${response.reasonPhrase}';
}
