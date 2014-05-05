// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http.browser_client;

import 'dart:async';
import 'dart:html';

import 'package:stack_trace/stack_trace.dart';

import 'src/base_client.dart';
import 'src/base_request.dart';
import 'src/byte_stream.dart';
import 'src/exception.dart';
import 'src/streamed_response.dart';

// TODO(nweiz): Move this under src/, re-export from lib/http.dart, and use this
// automatically from [new Client] once we can create an HttpRequest using
// mirrors on dart2js (issue 18541) and dart2js doesn't crash on pkg/collection
// (issue 18535).

/// A `dart:html`-based HTTP client that runs in the browser and is backed by
/// XMLHttpRequests.
///
/// This client inherits some of the limitations of XMLHttpRequest. It ignores
/// the [BaseRequest.contentLength], [BaseRequest.persistentConnection],
/// [BaseRequest.followRedirects], and [BaseRequest.maxRedirects] fields. It is
/// also unable to stream requests or responses; a request will only be sent and
/// a response will only be returned once all the data is available.
class BrowserClient extends BaseClient {
  /// The currently active XHRs.
  ///
  /// These are aborted if the client is closed.
  final _xhrs = new Set<HttpRequest>();

  /// Creates a new HTTP client.
  BrowserClient();

  /// Sends an HTTP request and asynchronously returns the response.
  Future<StreamedResponse> send(BaseRequest request) {
    return request.finalize().toBytes().then((bytes) {
      var xhr = new HttpRequest();
      _xhrs.add(xhr);
      xhr.open(request.method, request.url.toString(), async: true);
      xhr.responseType = 'blob';
      request.headers.forEach(xhr.setRequestHeader);

      var completer = new Completer();
      xhr.onLoad.first.then((_) {
        // TODO(nweiz): Set the response type to "arraybuffer" when issue 18542
        // is fixed.
        var blob = xhr.response == null ? new Blob([]) : xhr.response;
        var reader = new FileReader();

        reader.onLoad.first.then((_) {
          var body = reader.result;
          completer.complete(new StreamedResponse(
              new ByteStream.fromBytes(body),
              xhr.status,
              contentLength: body.length,
              request: request,
              headers: xhr.responseHeaders,
              reasonPhrase: xhr.statusText));
        });

        reader.onError.first.then((error) {
          completer.completeError(
              new ClientException(error.toString(), request.url),
              new Chain.current());
        });

        reader.readAsArrayBuffer(blob);
      });

      xhr.onError.first.then((_) {
        // Unfortunately, the underlying XMLHttpRequest API doesn't expose any
        // specific information about the error itself.
        completer.completeError(
            new ClientException("XMLHttpRequest error.", request.url),
            new Chain.current());
      });

      xhr.send(bytes);
      return completer.future.whenComplete(() => _xhrs.remove(xhr));
    });
  }

  /// Closes the client.
  ///
  /// This terminates all active requests.
  void close() {
    for (var xhr in _xhrs) {
      xhr.abort();
    }
  }
}
