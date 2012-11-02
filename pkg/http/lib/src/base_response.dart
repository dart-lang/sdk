// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library base_response;

import 'dart:io';

/// The base class for HTTP responses.
///
/// Subclasses of [BaseResponse] are usually not constructed manually; instead,
/// they're returned by [BaseClient.send] or other HTTP client methods.
abstract class BaseResponse {
  /// The status code of the response.
  final int statusCode;

  /// The reason phrase associated with the status code.
  final String reasonPhrase;

  /// The size of the response body, in bytes. If the size of the request is not
  /// known in advance, this is -1.
  final int contentLength;

  // TODO(nweiz): automatically parse cookies from headers

  // TODO(nweiz): make this a HttpHeaders object.
  /// The headers for this response.
  final Map<String, String> headers;

  /// Whether this response is a redirect.
  final bool isRedirect;

  /// Whether the server requested that a persistent connection be maintained.
  final bool persistentConnection;

  /// Creates a new HTTP response.
  BaseResponse(
      this.statusCode,
      this.contentLength,
      {this.headers: const <String>{},
       this.isRedirect: false,
       this.persistentConnection: true,
       this.reasonPhrase});
}
