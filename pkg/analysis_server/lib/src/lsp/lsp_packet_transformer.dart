// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

/// Transforms a stream of LSP data in the form:
///
///     Content-Length: xxx\r\n
///     Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n
///     \r\n
///     { JSON payload }
///
/// into just the JSON payload, decoded with the specified encoding. Line endings
/// for headers must be \r\n on all platforms as defined in the LSP spec.
class LspPacketTransformer extends StreamTransformerBase<List<int>, String> {
  @override
  Stream<String> bind(Stream<List<int>> stream) {
    StreamSubscription<int> input;
    StreamController<String> _output;
    final buffer = <int>[];
    bool isParsingHeaders = true;
    int contentLength;
    _output = StreamController<String>(
      onListen: () {
        input = stream.expand((b) => b).listen(
          (codeUnit) {
            buffer.add(codeUnit);
            if (isParsingHeaders && _endsWithCrLfCrLf(buffer)) {
              contentLength = _parseContentLength(buffer);
              buffer.clear();
              isParsingHeaders = false;
            } else if (!isParsingHeaders && buffer.length >= contentLength) {
              // TODO(dantup): Use the encoding specified by the header!
              _output.add(utf8.decode(buffer));
              buffer.clear();
              isParsingHeaders = true;
            }
          },
          onError: _output.addError,
          onDone: _output.close,
        );
      },
      onPause: () => input.pause(),
      onResume: () => input.resume(),
      onCancel: () => input.cancel(),
    );
    return _output.stream;
  }

  /// Whether [buffer] ends in '\r\n\r\n'.
  static bool _endsWithCrLfCrLf(List<int> buffer) {
    var l = buffer.length;
    return l > 4 &&
        buffer[l - 1] == 10 &&
        buffer[l - 2] == 13 &&
        buffer[l - 3] == 10 &&
        buffer[l - 4] == 13;
  }

  /// Decodes [buffer] into a String and returns the 'Content-Length' header value.
  static int _parseContentLength(List<int> buffer) {
    var asString = ascii.decode(buffer);
    var headers = asString.split('\r\n');
    var lengthHeader =
        headers.firstWhere((h) => h.startsWith('Content-Length'));
    var length = lengthHeader.split(':').last.trim();
    return int.parse(length);
  }
}
