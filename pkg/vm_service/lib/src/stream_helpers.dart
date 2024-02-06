// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Copied from package:stream_transform.

/// Starts emitting values from [next] after the original stream is complete.
///
/// If the initial stream never finishes, the [next] stream will never be
/// listened to.
///
/// If a single-subscription follows the a broadcast stream it may be listened
/// to and never canceled.
///
/// If a broadcast stream follows any other stream it will miss any events which
/// occur before the first stream is done. If a broadcast stream follows a
/// single-subscription stream, pausing the stream while it is listening to the
/// second stream will cause events to be dropped rather than buffered.
StreamTransformer<T, T> followedBy<T>(Stream<T> next) => _FollowedBy<T>(next);

class _FollowedBy<T> extends StreamTransformerBase<T, T> {
  final Stream<T> _next;

  _FollowedBy(this._next);

  @override
  Stream<T> bind(Stream<T> first) {
    var controller = first.isBroadcast
        ? StreamController<T>.broadcast(sync: true)
        : StreamController<T>(sync: true);

    var next = first.isBroadcast && !_next.isBroadcast
        ? _next.asBroadcastStream()
        : _next;

    StreamSubscription<T>? subscription;
    var currentStream = first;
    var firstDone = false;
    var secondDone = false;

    late Function currentDoneHandler;

    listen() {
      subscription = currentStream.listen(controller.add,
          onError: controller.addError, onDone: () => currentDoneHandler());
    }

    onSecondDone() {
      secondDone = true;
      controller.close();
    }

    onFirstDone() {
      firstDone = true;
      currentStream = next;
      currentDoneHandler = onSecondDone;
      listen();
    }

    currentDoneHandler = onFirstDone;

    controller.onListen = () {
      assert(subscription == null);
      listen();
      final sub = subscription!;
      if (!first.isBroadcast) {
        controller
          ..onPause = () {
            if (!firstDone || !next.isBroadcast) return sub.pause();
            sub.cancel();
            subscription = null;
          }
          ..onResume = () {
            if (!firstDone || !next.isBroadcast) return sub.resume();
            listen();
          };
      }
      controller.onCancel = () {
        if (secondDone) return null;
        var toCancel = subscription!;
        subscription = null;
        return toCancel.cancel();
      };
    };
    return controller.stream;
  }
}

StreamTransformer<T, T> startWithMany<T>(Iterable<T> initial) =>
    startWithStream<T>(Stream.fromIterable(initial));

StreamTransformer<T, T> startWithStream<T>(Stream<T> initial) =>
    StreamTransformer.fromBind((values) {
      if (values.isBroadcast && !initial.isBroadcast) {
        initial = initial.asBroadcastStream();
      }
      return initial.transform(followedBy(values));
    });

class WriteStream {
  WriteStream({this.chunkSizeBytes = _defaultChunkSizeBytes})
      : assert(chunkSizeBytes > 0);

  final int chunkSizeBytes;

  /// The size copied from chunk size produced by VM for Mac.
  static const int _defaultChunkSizeBytes = 1048055;

  final List<ByteData> chunks = [];
  int _cursor = 0;

  void _writeByte(int value) {
    assert(value >= 0 && value <= 0xFF, value);
    _ensureCapacity();
    final chunk = chunks.last;
    chunk.setUint8(_cursor, value);
    _cursor = _cursor + 1;
  }

  void writeByte(int value) {
    _writeByte(value);
  }

  /// Write one ULEB128 number.
  void writeInteger(int value) {
    // First bit in every byte is a signal if there is more data.
    // So, we split the number into 7-bit parts and write them smaller to larger,
    // prefixing with the signal.

    int bytes = 0;
    for (;;) {
      int part = 0x7F & value;
      value >>= 7;

      if (value != 0) {
        // Signal that there is more data.
        part |= 0x80;
      }
      bytes++;
      _writeByte(part);

      if (value == 0) {
        break;
      }

      if (value == -1) {
        for (var i = 0; i < 9 - bytes; i++) {
          _writeByte(0xFF);
        }
        _writeByte(1);
        break;
      }
    }
  }

  void writeUtf8(String value) {
    final bytes = Utf8Codec(allowMalformed: true).encode(value);
    writeInteger(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      _writeByte(bytes[i]);
    }
  }

  void writeFloat64(double value) {
    var buffer = Float64List(1);
    buffer[0] = value;
    Uint8List bytes = buffer.buffer.asUint8List();
    for (int i = 0; i < 8; i++) {
      _writeByte(bytes[i]);
    }
  }

  /// Verifies there is space for one more byte.
  void _ensureCapacity() {
    if (chunks.isEmpty) {
      chunks.add(ByteData(chunkSizeBytes));
      return;
    }
    if (_cursor >= chunkSizeBytes) {
      chunks.add(ByteData(chunkSizeBytes));
      _cursor = 0;
    }
  }
}

class ReadStream {
  final List<ByteData> _chunks;
  int _chunkIndex = 0;
  int _byteIndex = 0;

  ReadStream(this._chunks) {
    for (int i = 0; i < _chunks.length; ++i) {
      _chunks[i].lengthInBytes;
    }
  }

  bool get atEnd => ((_byteIndex >= _chunks[_chunkIndex].lengthInBytes) &&
      (_chunkIndex + 1 >= _chunks.length));

  int _readByte() {
    while (_byteIndex >= _chunks[_chunkIndex].lengthInBytes) {
      _chunkIndex++;
      _byteIndex = 0;
    }
    return _chunks[_chunkIndex].getUint8(_byteIndex++);
  }

  int readByte() {
    return _readByte();
  }

  /// Read one ULEB128 number.
  ///
  /// The result can be negative.
  int readInteger() {
    int result = 0;
    int shift = 0;
    for (;;) {
      int part = _readByte();
      result |= (part & 0x7F) << shift;
      if ((part & 0x80) == 0) {
        break;
      }
      shift += 7;
    }
    return result;
  }

  /// Read one SLEB128 number.
  int readSigned() {
    int result = 0;
    int shift = 0;
    for (;;) {
      int part = _readByte();
      result |= (part & 0x7F) << shift;
      shift += 7;
      if ((part & 0x80) == 0) {
        if ((part & 0x40) != 0) {
          result |= (-1 << shift);
        }
        break;
      }
    }
    return result;
  }

  double readFloat64() {
    final bytes = Uint8List(8);
    for (int i = 0; i < 8; i++) {
      bytes[i] = _readByte();
    }
    return Float64List.view(bytes.buffer)[0];
  }

  String readUtf8() {
    int len = readInteger();
    final bytes = Uint8List(len);
    for (int i = 0; i < len; i++) {
      bytes[i] = _readByte();
    }
    return Utf8Codec(allowMalformed: true).decode(bytes);
  }

  String readLatin1() {
    int len = readInteger();
    final codeUnits = Uint8List(len);
    for (int i = 0; i < len; i++) {
      codeUnits[i] = _readByte();
    }
    return String.fromCharCodes(codeUnits);
  }

  String readUtf16() {
    int len = readInteger();
    final codeUnits = Uint16List(len);
    for (int i = 0; i < len; i++) {
      codeUnits[i] = _readByte() | (_readByte() << 8);
    }
    return String.fromCharCodes(codeUnits);
  }
}
