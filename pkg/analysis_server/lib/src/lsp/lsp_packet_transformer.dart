// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/src/utilities/stream.dart';
import 'package:collection/collection.dart';

class InvalidEncodingError {
  final String headers;
  InvalidEncodingError(this.headers);

  @override
  String toString() =>
      'Encoding in supplied headers is not supported.\n\nHeaders:\n$headers';
}

class LspHeaders {
  final String rawHeaders;
  final int contentLength;
  final String? encoding;
  LspHeaders(this.rawHeaders, this.contentLength, this.encoding);
}

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
    LspHeaders? headersState;
    final buffer = <int>[];
    var controller = MoreTypedStreamController<String,
        _LspPacketTransformerListenData, _LspPacketTransformerPauseData>(
      onListen: (controller) {
        var input = stream.expand((b) => b).listen(
          (codeUnit) {
            buffer.add(codeUnit);
            var headers = headersState;
            if (headers == null && _endsWithCrLfCrLf(buffer)) {
              headersState = _parseHeaders(buffer);
              buffer.clear();
            } else if (headers != null &&
                buffer.length >= headers.contentLength) {
              // UTF-8 is the default - and only supported - encoding for LSP.
              // The string 'utf8' is valid since it was published in the original spec.
              // Any other encodings should be rejected with an error.
              if ([null, 'utf-8', 'utf8']
                  .contains(headers.encoding?.toLowerCase())) {
                controller.add(utf8.decode(buffer));
              } else {
                controller.addError(InvalidEncodingError(headers.rawHeaders));
              }
              buffer.clear();
              headersState = null;
            }
          },
          onError: controller.addError,
          onDone: controller.close,
        );
        return _LspPacketTransformerListenData(input);
      },
      onPause: (listenData) {
        listenData.input.pause();
        return _LspPacketTransformerPauseData();
      },
      onResume: (listenData, pauseData) => listenData.input.resume(),
      onCancel: (listenData) => listenData.input.cancel(),
    );
    return controller.controller.stream;
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

  static String? _extractEncoding(String? header) {
    final charset = header
        ?.split(';')
        .map((s) => s.trim().toLowerCase())
        .firstWhereOrNull((s) => s.startsWith('charset='));

    return charset?.split('=')[1];
  }

  /// Decodes [buffer] into a String and returns the 'Content-Length' header value.
  static LspHeaders _parseHeaders(List<int> buffer) {
    // Headers are specified as always ASCII in LSP.
    final asString = ascii.decode(buffer);
    final headers = asString.split('\r\n');
    final lengthHeader =
        headers.firstWhere((h) => h.startsWith('Content-Length'));
    final length = lengthHeader.split(':').last.trim();
    final contentTypeHeader =
        headers.firstWhereOrNull((h) => h.startsWith('Content-Type'));
    final encoding = _extractEncoding(contentTypeHeader);
    return LspHeaders(asString, int.parse(length), encoding);
  }
}

/// The data class for [StreamController.onListen].
class _LspPacketTransformerListenData {
  final StreamSubscription<int> input;

  _LspPacketTransformerListenData(this.input);
}

/// The marker class for [StreamController.onPause].
class _LspPacketTransformerPauseData {}
