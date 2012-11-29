// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library base_request;

import 'dart:io';
import 'dart:isolate';
import 'dart:uri';

import 'client.dart';
import 'streamed_response.dart';

/// The base class for HTTP requests.
///
/// Subclasses of [BaseRequest] can be constructed manually and passed to
/// [BaseClient.send], which allows the user to provide fine-grained control
/// over the request properties. However, usually it's easier to use convenience
/// methods like [get] or [BaseClient.get].
abstract class BaseRequest {
  /// The HTTP method of the request. Most commonly "GET" or "POST", less
  /// commonly "HEAD", "PUT", or "DELETE". Non-standard method names are also
  /// supported.
  final String method;

  /// The URL to which the request will be sent.
  final Uri url;

  /// The size of the request body, in bytes. This defaults to -1, which
  /// indicates that the size of the request is not known in advance.
  int get contentLength => _contentLength;
  int _contentLength = -1;

  set contentLength(int value) {
    _checkFinalized();
    _contentLength = value;
  }

  /// Whether a persistent connection should be maintained with the server.
  /// Defaults to true.
  bool get persistentConnection => _persistentConnection;
  bool _persistentConnection = true;

  set persistentConnection(bool value) {
    _checkFinalized();
    _persistentConnection = value;
  }

  /// Whether the client should follow redirects while resolving this request.
  /// Defaults to true.
  bool get followRedirects => _followRedirects;
  bool _followRedirects = true;

  set followRedirects(bool value) {
    _checkFinalized();
    _followRedirects = value;
  }

  /// The maximum number of redirects to follow when [followRedirects] is true.
  /// If this number is exceeded the [BaseResponse] future will signal a
  /// [RedirectLimitExceeded] exception. Defaults to 5.
  int get maxRedirects => _maxRedirects;
  int _maxRedirects = 5;

  set maxRedirects(int value) {
    _checkFinalized();
    _maxRedirects = value;
  }

  // TODO(nweiz): automatically parse cookies from headers

  // TODO(nweiz): make this a HttpHeaders object
  /// The headers for this request.
  final Map<String, String> headers;

  /// Whether the request has been finalized.
  bool get finalized => _finalized;
  bool _finalized = false;

  /// Creates a new HTTP request.
  BaseRequest(this.method, this.url)
    : headers = <String>{};

  /// Finalizes the HTTP request in preparation for it being sent. This freezes
  /// all mutable fields and returns an [InputStream] that should emit the body
  /// of the request. The stream may be closed to indicate a request with no
  /// body.
  ///
  /// The base implementation of this returns null rather than an [InputStream];
  /// subclasses are responsible for creating the return value. They should also
  /// freeze any additional mutable fields they add that don't make sense to
  /// change after the request headers are sent.
  InputStream finalize() {
    // TODO(nweiz): freeze headers
    if (finalized) throw new StateError("Can't finalize a finalized Request.");
    _finalized = true;
    return null;
  }

  /// Sends this request.
  ///
  /// This automatically initializes a new [Client] and closes that client once
  /// the request is complete. If you're planning on making multiple requests to
  /// the same server, you should use a single [Client] for all of those
  /// requests.
  Future<StreamedResponse> send() {
    var client = new Client();
    return client.send(this).transform((response) {
      // TODO(nweiz): This makes me sick to my stomach, but it's currently the
      // best way to listen for the response stream being closed. Kill it with
      // fire once issue 4202 is fixed.
      new Timer.repeating(100, (timer) {
        if (response.stream.closed) {
          client.close();
          timer.cancel();
        }
      });

      return response;
    });
  }

  /// Throws an error if this request has been finalized.
  void _checkFinalized() {
    if (!finalized) return;
    throw new StateError("Can't modify a finalized Request.");
  }
}
