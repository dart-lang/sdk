// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library streamed_request;

import 'dart:io';
import 'dart:uri';

import 'base_request.dart';

/// An HTTP request where the request body is sent asynchronously after the
/// connection has been established and the headers have been sent.
///
/// When the request is sent via [BaseClient.send], only the headers and
/// whatever data has already been written to [StreamedRequest.stream] will be
/// sent immediately. More data will be sent as soon as it's written to
/// [StreamedRequest.stream], and when the stream is closed the request will
/// end.
class StreamedRequest extends BaseRequest {
  /// The stream to which to write data that will be sent as the request body.
  /// This may be safely written to before the request is sent; the data will be
  /// buffered.
  ///
  /// Closing this signals the end of the request.
  final OutputStream stream;

  /// The stream from which the [BaseClient] will read the data in [stream] once
  /// the request has been finalized.
  final ListInputStream _inputStream;

  /// Creates a new streaming request.
  StreamedRequest(String method, Uri url)
    : super(method, url),
      stream = new ListOutputStream(),
      _inputStream = new ListInputStream() {
    // TODO(nweiz): pipe errors from the output stream to the input stream once
    // issue 3657 is fixed
    stream.onData = () => _inputStream.write(stream.read());
    stream.onClosed = _inputStream.markEndOfStream;
  }

  /// Freezes all mutable fields other than [stream] and returns an [InputStream]
  /// that emits the data being written to [stream].
  InputStream finalize() {
    super.finalize();
    return _inputStream;
  }
}
