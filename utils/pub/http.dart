// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helpers for dealing with HTTP.
library pub.http;

import 'dart:async';
import 'dart:io';
import 'dart:json' as json;

// TODO(nweiz): Make this import better.
import '../../pkg/http/lib/http.dart' as http;
import 'curl_client.dart';
import 'io.dart';
import 'log.dart' as log;
import 'utils.dart';

// TODO(nweiz): make this configurable
/// The amount of time in milliseconds to allow HTTP requests before assuming
/// they've failed.
final HTTP_TIMEOUT = 30 * 1000;

/// An HTTP client that transforms 40* errors and socket exceptions into more
/// user-friendly error messages.
class PubHttpClient extends http.BaseClient {
  http.Client inner;

  PubHttpClient([http.Client inner])
    : this.inner = inner == null ? new http.Client() : inner;

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // TODO(rnystrom): Log request body when it's available and plaintext, but
    // not when it contains OAuth2 credentials.

    // TODO(nweiz): remove this when issue 4061 is fixed.
    var stackTrace;
    try {
      throw null;
    } catch (_, localStackTrace) {
      stackTrace = localStackTrace;
    }

    // TODO(nweiz): Ideally the timeout would extend to reading from the
    // response input stream, but until issue 3657 is fixed that's not feasible.
    return timeout(inner.send(request).then((streamedResponse) {
      log.fine("Got response ${streamedResponse.statusCode} "
               "${streamedResponse.reasonPhrase}.");

      var status = streamedResponse.statusCode;
      // 401 responses should be handled by the OAuth2 client. It's very
      // unlikely that they'll be returned by non-OAuth2 requests.
      if (status < 400 || status == 401) return streamedResponse;

      return http.Response.fromStream(streamedResponse).then((response) {
        throw new PubHttpException(response);
      });
    }).catchError((asyncError) {
      if (asyncError.error is SocketIOException &&
          asyncError.error.osError != null &&
          (asyncError.error.osError.errorCode == 8 ||
           asyncError.error.osError.errorCode == -2 ||
           asyncError.error.osError.errorCode == -5 ||
           asyncError.error.osError.errorCode == 11004)) {
        throw 'Could not resolve URL "${request.url.origin}".';
      }
      throw asyncError;
    }), HTTP_TIMEOUT, 'fetching URL "${request.url}"');
  }
}

/// The HTTP client to use for all HTTP requests.
final httpClient = new PubHttpClient();

final curlClient = new PubHttpClient(new CurlClient());

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
  throw errorMap['error']['message'];
}

/// Parses a response body, assuming it's JSON-formatted. Throws a user-friendly
/// error if the response body is invalid JSON, or if it's not a map.
Map parseJsonResponse(http.Response response) {
  var value;
  try {
    value = json.parse(response.body);
  } catch (e) {
    // TODO(nweiz): narrow this catch clause once issue 6775 is fixed.
    invalidServerResponse(response);
  }
  if (value is! Map) invalidServerResponse(response);
  return value;
}

/// Throws an error describing an invalid response from the server.
void invalidServerResponse(http.Response response) {
  throw 'Invalid server response:\n${response.body}';
}

/// Exception thrown when an HTTP operation fails.
class PubHttpException implements Exception {
  final http.Response response;

  const PubHttpException(this.response);

  String toString() => 'HTTP error ${response.statusCode}: '
      '${response.reasonPhrase}';
}
