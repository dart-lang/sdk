// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:stream_channel/stream_channel.dart';

import 'message_port.dart';

/// Frame tags for the custom binary encoding of a [MessagePort] used by
/// [MessagePort.asBinaryChannel] and [MessagePort.fromBinaryChannel].
///
/// This binary encoding is not guaranteed to be stable across `package:dartpad`
/// releases, but allows proxying messages from a [MessagePort] across any
/// channel that transports binary data (`StreamChannel<Uint8List>`).
enum MessagePortFrameTag {
  /// JS object `{payload: String}` without `bytes`.
  ///
  /// Used by the Worker/Sandbox JSON-RPC 2.0 protocol when no binary payload
  /// is attached.
  objectWithoutBytes(0),

  /// JS object `{payload: String, bytes: Uint8Array}` with `bytes`.
  ///
  /// Used by the Worker/Sandbox JSON-RPC 2.0 protocol when a binary payload
  /// is attached.
  objectWithBytes(1),

  /// UTF-8 `String` message.
  ///
  /// Used by the VM Service protocol for JSON-RPC 2.0 text messages.
  string(2),

  /// Binary `Uint8List` / `Uint8Array` message.
  ///
  /// Used by the VM Service protocol for binary frames.
  bytes(3);

  final int tagByte;
  const MessagePortFrameTag(this.tagByte);

  static MessagePortFrameTag? fromTagByte(int tagByte) => switch (tagByte) {
    0 => objectWithoutBytes,
    1 => objectWithBytes,
    2 => string,
    3 => bytes,
    _ => null,
  };
}

/// Internal representation of a message sent over a [MessagePort].
sealed class MessagePortMessage {}

/// A UTF-8 string message (used by the VM Service protocol).
final class StringMessage extends MessagePortMessage {
  final String value;
  StringMessage(this.value);
}

/// A binary payload message (used by the VM Service protocol).
final class BytesMessage extends MessagePortMessage {
  final Uint8List bytes;
  BytesMessage(this.bytes);
}

/// A JSON-RPC 2.0 object message (`{payload: String, bytes?: Uint8Array,
/// port?: MessagePort}`) used by the Worker/Sandbox JSON-RPC 2.0 protocol.
final class RpcMessage extends MessagePortMessage {
  final String payload;
  final Uint8List? bytes;
  final MessagePort? port;

  RpcMessage(this.payload, {this.bytes, this.port});
}

/// Transforms a `StreamChannel<Uint8List>` (using [MessagePortFrameTag]
/// framing) into a `StreamChannel<MessagePortMessage>`.
final binaryToMessagePortChannelTransformer =
    StreamChannelTransformer<MessagePortMessage, Uint8List>(
      _decodeBinaryFrame,
      StreamSinkTransformer.fromStreamTransformer(_encodeBinaryFrame),
    );

/// Transforms a `StreamChannel<MessagePortMessage>` into a
/// `StreamChannel<Uint8List>` (using [MessagePortFrameTag] framing).
final messagePortToBinaryChannelTransformer =
    StreamChannelTransformer<Uint8List, MessagePortMessage>(
      _encodeBinaryFrame,
      StreamSinkTransformer.fromStreamTransformer(_decodeBinaryFrame),
    );

/// Transforms a `StreamChannel<MessagePortMessage>` into a
/// `StreamChannel<Object?>` of decoded JSON-RPC 2.0 message objects suitable
/// for `Peer.withoutJson` from `package:json_rpc_2`.
final jsonRpcChannelTransformer =
    StreamChannelTransformer<Object?, MessagePortMessage>(
      _decodeJsonRpcMessage,
      StreamSinkTransformer.fromStreamTransformer(_encodeJsonRpcMessage),
    );

/// Transforms a `StreamChannel<MessagePortMessage>` into a
/// `StreamChannel<Object?>` of Dart VM Service protocol messages ([String] for
/// JSON-RPC text or [Uint8List] for binary data).
final vmServiceChannelTransformer =
    StreamChannelTransformer<Object?, MessagePortMessage>(
      _decodeVmServiceMessage,
      StreamSinkTransformer.fromStreamTransformer(_encodeVmServiceMessage),
    );

/// Decodes tagged [Uint8List] frames into [MessagePortMessage]s:
///  * [MessagePortFrameTag.objectWithoutBytes] -> [RpcMessage] without `bytes`
///  * [MessagePortFrameTag.objectWithBytes] -> [RpcMessage] with `bytes`
///  * [MessagePortFrameTag.string] -> [StringMessage]
///  * [MessagePortFrameTag.bytes] -> [BytesMessage]
final _decodeBinaryFrame =
    StreamTransformer<Uint8List, MessagePortMessage>.fromHandlers(
      handleData: (Uint8List frame, EventSink<MessagePortMessage> sink) {
        if (frame.isEmpty) {
          sink.addError(const FormatException('Empty binary frame'));
          return;
        }
        try {
          switch (MessagePortFrameTag.fromTagByte(frame[0])) {
            case MessagePortFrameTag.objectWithoutBytes:
              final payload = utf8.decode(Uint8List.sublistView(frame, 1));
              sink.add(RpcMessage(payload));
            case MessagePortFrameTag.objectWithBytes:
              if (frame.length < 5) {
                sink.addError(
                  const FormatException('Invalid binary frame length'),
                );
                return;
              }
              final jsonSize = ByteData.sublistView(frame).getUint32(1);
              if (frame.length < 5 + jsonSize) {
                sink.addError(
                  const FormatException('Invalid binary frame length'),
                );
                return;
              }
              final payload = utf8.decode(
                Uint8List.sublistView(frame, 5, 5 + jsonSize),
              );
              final bytes = frame.sublist(5 + jsonSize);
              sink.add(RpcMessage(payload, bytes: bytes));
            case MessagePortFrameTag.string:
              final value = utf8.decode(Uint8List.sublistView(frame, 1));
              sink.add(StringMessage(value));
            case MessagePortFrameTag.bytes:
              final bytes = frame.sublist(1);
              sink.add(BytesMessage(bytes));
            case null:
              sink.addError(
                FormatException('Unknown binary frame tag byte: ${frame[0]}'),
              );
          }
        } on FormatException catch (e, st) {
          sink.addError(e, st);
        }
      },
    );

/// Encodes [MessagePortMessage]s into tagged [Uint8List] frames:
///  * [RpcMessage] without `bytes` -> [MessagePortFrameTag.objectWithoutBytes]
///  * [RpcMessage] with `bytes` -> [MessagePortFrameTag.objectWithBytes]
///  * [StringMessage] -> [MessagePortFrameTag.string]
///  * [BytesMessage] -> [MessagePortFrameTag.bytes]
final _encodeBinaryFrame =
    StreamTransformer<MessagePortMessage, Uint8List>.fromHandlers(
      handleData: (MessagePortMessage message, EventSink<Uint8List> sink) {
        switch (message) {
          case RpcMessage(:final payload, :final bytes, :final port):
            if (port != null) {
              port.close();
              sink.addError(
                const FormatException(
                  'Cannot encode MessagePort in binary channel',
                ),
              );
              return;
            }
            final jsonBytes = utf8.encode(payload);
            if (bytes == null) {
              final frame = Uint8List(1 + jsonBytes.length);
              frame[0] = MessagePortFrameTag.objectWithoutBytes.tagByte;
              frame.setAll(1, jsonBytes);
              sink.add(frame);
            } else {
              final jsonSize = jsonBytes.length;
              final frame = Uint8List(5 + jsonSize + bytes.length);
              frame[0] = MessagePortFrameTag.objectWithBytes.tagByte;
              ByteData.sublistView(frame).setUint32(1, jsonSize);
              frame.setAll(5, jsonBytes);
              frame.setAll(5 + jsonSize, bytes);
              sink.add(frame);
            }
          case StringMessage(:final value):
            final encoded = utf8.encode(value);
            final frame = Uint8List(1 + encoded.length);
            frame[0] = MessagePortFrameTag.string.tagByte;
            frame.setAll(1, encoded);
            sink.add(frame);
          case BytesMessage(:final bytes):
            final frame = Uint8List(1 + bytes.length);
            frame[0] = MessagePortFrameTag.bytes.tagByte;
            frame.setAll(1, bytes);
            sink.add(frame);
        }
      },
    );

/// Decodes [RpcMessage]s into parsed JSON-RPC 2.0 message objects:
///  * [RpcMessage] -> JSON-decoded `Object?` with optional `bytes` and `port`
///    injected into `params` or `result`
final _decodeJsonRpcMessage =
    StreamTransformer<MessagePortMessage, Object?>.fromHandlers(
      handleData: (MessagePortMessage message, EventSink<Object?> sink) {
        if (message is! RpcMessage) {
          sink.addError(
            FormatException('Unexpected JSON-RPC message: $message'),
          );
          return;
        }
        final Object? payload;
        try {
          payload = jsonDecode(message.payload);
        } on FormatException catch (e, st) {
          message.port?.close();
          sink.addError(e, st);
          return;
        }
        if (message.port != null || message.bytes != null) {
          final target = switch (payload) {
            {'params': final Map m} => m,
            {'result': final Map m} => m,
            _ => null,
          };
          if (target == null) {
            message.port?.close();
            sink.addError(
              const FormatException(
                'port and bytes require params or result to be a Map',
              ),
            );
            return;
          }
          if (message.port case final port?) {
            target['port'] = port;
          }
          if (message.bytes case final bytes?) {
            target['bytes'] = bytes;
          }
        }
        sink.add(payload);
      },
    );

/// Encodes JSON-RPC 2.0 message objects into [RpcMessage]s:
///  * `Object?` -> [RpcMessage] with `bytes` and `port` extracted from
///    `params` or `result`
final _encodeJsonRpcMessage =
    StreamTransformer<Object?, MessagePortMessage>.fromHandlers(
      handleData: (Object? m, EventSink<MessagePortMessage> sink) {
        MessagePort? port;
        Uint8List? bytes;
        if (m is Map) {
          for (final prop in ['params', 'result']) {
            if (m[prop] case final Map v) {
              if (v['port'] case final MessagePort p) {
                port = p;
                v.remove('port');
              }
              if (v['bytes'] case final Uint8List b) {
                bytes = b;
                v.remove('bytes');
              }
            }
          }

          // package:json_rpc_2 will automatically add error.data.request.params
          // to error messages; if they contain port or bytes we strip them.
          if (m['error'] case {
            'data': {'request': {'params': final Map params}},
          }) {
            if (params['port'] is MessagePort) {
              params.remove('port');
            }
            if (params['bytes'] is Uint8List) {
              params.remove('bytes');
            }
          }
        }

        sink.add(RpcMessage(jsonEncode(m), bytes: bytes, port: port));
      },
    );

/// Unwraps [MessagePortMessage]s into VM Service messages:
///  * [StringMessage] -> [String]
///  * [BytesMessage] -> [Uint8List]
final _decodeVmServiceMessage =
    StreamTransformer<MessagePortMessage, Object?>.fromHandlers(
      handleData: (MessagePortMessage message, EventSink<Object?> sink) {
        switch (message) {
          case StringMessage(:final value):
            sink.add(value);
          case BytesMessage(:final bytes):
            sink.add(bytes);
          case RpcMessage(:final port):
            port?.close();
            sink.addError(
              FormatException('Unexpected VM Service message: $message'),
            );
        }
      },
    );

/// Wraps VM Service messages into [MessagePortMessage]s:
///  * [String] -> [StringMessage]
///  * [Uint8List] -> [BytesMessage]
final _encodeVmServiceMessage =
    StreamTransformer<Object?, MessagePortMessage>.fromHandlers(
      handleData: (Object? message, EventSink<MessagePortMessage> sink) {
        switch (message) {
          case final String value:
            sink.add(StringMessage(value));
          case final Uint8List bytes:
            sink.add(BytesMessage(bytes));
          default:
            sink.addError(
              FormatException('Unexpected VM Service message: $message'),
            );
        }
      },
    );
