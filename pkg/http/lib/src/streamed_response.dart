// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library streamed_response;

import 'dart:io';

import 'base_response.dart';

/// An HTTP response where the response body is received asynchronously after
/// the headers have been received.
class StreamedResponse extends BaseResponse {
  /// The stream from which the response body data can be read.
  final InputStream stream;

  /// Creates a new streaming response.
  StreamedResponse(
      this.stream,
      int statusCode,
      int contentLength,
      {Map<String, String> headers: const <String>{},
       bool isRedirect: false,
       bool persistentConnection: true,
       String reasonPhrase})
    : super(
        statusCode,
        contentLength,
        headers: headers,
        isRedirect: isRedirect,
        persistentConnection: persistentConnection,
        reasonPhrase: reasonPhrase);
}
