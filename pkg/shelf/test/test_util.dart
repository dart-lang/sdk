// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.test_util;

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf/src/util.dart';

/// A simple, synchronous handler for [Request].
///
/// By default, replies with a status code 200, empty headers, and
/// `Hello from ${request.url.path}`.
Response syncHandler(Request request, {int statusCode,
    Map<String, String> headers}) {
  if (statusCode == null) statusCode = 200;
  return new Response(statusCode, headers: headers,
      body: 'Hello from ${request.url.path}');
}

/// Calls [syncHandler] and wraps the response in a [Future].
Future<Response> asyncHandler(Request request) =>
    new Future(() => syncHandler(request));

/// Makes a simple GET request to [handler] and returns the result.
Future<Response> makeSimpleRequest(Handler handler) =>
    syncFuture(() => handler(_request));

final _request = new Request('GET', LOCALHOST_URI);

final LOCALHOST_URI = Uri.parse('http://localhost/');
