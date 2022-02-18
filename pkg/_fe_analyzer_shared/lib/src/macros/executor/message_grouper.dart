// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

/// Collects messages from an input stream of bytes.
///
/// Each message should start with a 32 bit big endian uint indicating its size,
/// followed by that many bytes.
class MessageGrouper {
  /// The input bytes stream subscription.
  late final StreamSubscription _inputStreamSubscription;

  /// The length of the current message to read, or `-1` if we are currently
  /// reading the length.
  int _length = -1;

  /// The buffer to store the length bytes in.
  BytesBuilder _lengthBuffer = new BytesBuilder();

  /// If reading raw data, buffer for the data.
  Uint8List _messageBuffer = new Uint8List(0);

  /// The position to write the next byte in [_messageBuffer].
  int _messagePos = 0;

  late StreamController<Uint8List> _messageStreamController =
      new StreamController<Uint8List>(onCancel: () {
    _inputStreamSubscription.cancel();
  });
  Stream<Uint8List> get messageStream => _messageStreamController.stream;

  MessageGrouper(Stream<List<int>> inputStream) {
    _inputStreamSubscription = inputStream.listen(_handleBytes, onDone: cancel);
  }

  void _handleBytes(List<int> bytes, [int offset = 0]) {
    if (_length == -1) {
      while (_lengthBuffer.length < 4 && offset < bytes.length) {
        _lengthBuffer.addByte(bytes[offset++]);
      }
      if (_lengthBuffer.length >= 4) {
        Uint8List lengthBytes = _lengthBuffer.takeBytes();
        _length = lengthBytes[0] << 24 |
            lengthBytes[1] << 16 |
            lengthBytes[2] << 8 |
            lengthBytes[3];
      }
    }

    // Just pass along `bytes` without a copy if we can, and reset our state
    if (offset == 0 && bytes.length == _length && bytes is Uint8List) {
      _length = -1;
      _messageStreamController.add(bytes);
      return;
    }

    // Initialize a new buffer.
    if (_messagePos == 0) {
      _messageBuffer = new Uint8List(_length);
    }

    // Read the data from `bytes`.
    int lenToRead = min(_length - _messagePos, bytes.length - offset);
    while (lenToRead-- > 0) {
      _messageBuffer[_messagePos++] = bytes[offset++];
    }

    // If we completed a message, add it to the output stream, reset our state,
    // and call ourselves again if we have more data to read.
    if (_messagePos >= _length) {
      _messageStreamController.add(_messageBuffer);
      _length = -1;
      _messagePos = 0;

      if (offset < bytes.length) {
        _handleBytes(bytes, offset);
      }
    }
  }

  /// Stop listening to the input stream for further updates, and close the
  /// output stream.
  void cancel() {
    _inputStreamSubscription.cancel();
    _messageStreamController.close();
  }
}
