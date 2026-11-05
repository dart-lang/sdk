// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:stream_channel/stream_channel.dart';
import 'package:web/web.dart' as web;

import '../util/environment.dart';
import 'message_port_channel.dart';

/// Wrapper for `MessagePort` allowing proxying over binary [StreamChannel].
abstract final class MessagePort {
  MessagePort._();

  /// Wrap a binary [StreamChannel] as a [MessagePort].
  factory MessagePort.fromBinaryChannel(StreamChannel<Uint8List> channel) =
      _StreamChannelMessagePort.fromBinaryChannel;

  /// Encode this [MessagePort] as a binary [StreamChannel] that can be decoded
  /// with [MessagePort.fromBinaryChannel].
  ///
  /// This encoding is not guaranteed to be stable across different versions of
  /// `package:dartpad`.
  StreamChannel<Uint8List> asBinaryChannel();

  StreamChannel<MessagePortMessage> _messageChannel();

  StreamChannel<Object?> _jsonRpcChannel() =>
      _messageChannel().transform(jsonRpcChannelTransformer);

  StreamChannel<Object?> _vmServiceChannel() =>
      _messageChannel().transform(vmServiceChannelTransformer);

  web.MessagePort _asTransferableMessagePort();
  void _close();
}

/// This is internal API, not intended for consumers of `package:dartpad`.
extension MessagePortExt on MessagePort {
  /// Returns a [StreamChannel] adapter that communicates JSON-RPC 2.0 over a
  /// [MessagePort].
  ///
  /// When backed by a browser [web.MessagePort], this encodes messages as:
  /// ```js
  /// {
  ///   "payload": JSON.stringify(message),
  ///   "port": port, /* [Optional] MessagePort instance */
  ///   "bytes": bytes, /* [Optional] Uint8Array instance */
  /// }
  /// ```
  ///
  /// Extracting `port` and `bytes` from `params` and `result`, ensuring that
  /// they do not get encoded as JSON, and instead are sent separately.
  /// When reconstituting messages `port` and `bytes` will be inserted into
  /// `params` and `result`.
  ///
  /// When a [web.MessagePort] appears in `'port'` it will be wrapped in a
  /// [MessagePort] before being injected into `params` or `result`.
  /// Similarly, when sending a [web.MessagePort], it is expected that it is
  /// wrapped in a [MessagePort] wrapper.
  ///
  /// This is an implementation of the "JSON-RPC 2.0 over MessagePort" as
  /// specified in `doc/worker-protocol.md`.
  StreamChannel<Object?> jsonRpcChannel() => _jsonRpcChannel();

  /// Returns a [StreamChannel] adapter that communicates Dart VM Service
  /// protocol messages ([String] or [Uint8List]) over a [MessagePort].
  StreamChannel<Object?> vmServiceChannel() => _vmServiceChannel();

  /// Closes this [MessagePort].
  void close() => _close();

  /// Creates a connected pair of [MessagePort]s.
  static (MessagePort, MessagePort) createChannel() {
    final channel = web.MessageChannel();
    return (fromMessagePort(channel.port1), fromMessagePort(channel.port2));
  }

  /// Return the [web.MessagePort] being wrapped by this [MessagePort] or
  /// create one and send messages from this [MessagePort] over it.
  ///
  /// > [!NOTICE]
  /// > This method is only available when building for web.
  web.MessagePort asTransferableMessagePort() => _asTransferableMessagePort();

  /// Wrap a [web.MessagePort] as a [MessagePort].
  ///
  /// > [!NOTICE]
  /// > This method is only available when building for web.
  static MessagePort fromMessagePort(web.MessagePort port) =>
      _BrowserMessagePort(port);
}

final class _BrowserMessagePort extends MessagePort {
  final web.MessagePort _port;

  _BrowserMessagePort(this._port) : super._();

  @override
  StreamChannel<MessagePortMessage> _messageChannel() =>
      _webMessagePortChannel(_port);

  @override
  StreamChannel<Uint8List> asBinaryChannel() =>
      _messageChannel().transform(messagePortToBinaryChannelTransformer);

  @override
  web.MessagePort _asTransferableMessagePort() => _port;

  @override
  void _close() {
    _port
      ..postMessage(null)
      ..onmessage = null
      ..onmessageerror = null
      ..close();
  }
}

final class _StreamChannelMessagePort extends MessagePort {
  final StreamChannel<Uint8List> _channel;

  _StreamChannelMessagePort.fromBinaryChannel(this._channel) : super._();

  @override
  StreamChannel<MessagePortMessage> _messageChannel() =>
      _channel.transform(binaryToMessagePortChannelTransformer);

  @override
  StreamChannel<Uint8List> asBinaryChannel() => _channel;

  @override
  web.MessagePort _asTransferableMessagePort() {
    final c = web.MessageChannel();
    _messageChannel().pipe(_webMessagePortChannel(c.port1));
    return c.port2;
  }

  @override
  void _close() => unawaited(_channel.sink.close());
}

final _nativeUint8ListType = Uint8List(0).runtimeType;

extension on JSUint8Array {
  external JSArrayBuffer get buffer;
}

extension type _RpcMessage._(JSObject _) implements JSObject {
  external factory _RpcMessage({
    required JSString payload,
    web.MessagePort? port,
    JSUint8Array? bytes,
  });

  external JSAny? get payload;
  external JSAny? get port;
  external JSAny? get bytes;
}

/// Wraps a browser [web.MessagePort] as a `StreamChannel<MessagePortMessage>`.
///
/// **Incoming** (`port.onmessage` -> `stream`), converts JS messages from
/// [port] into [MessagePortMessage]s:
///  * `JSString` -> [StringMessage]
///  * `JSUint8Array` -> [BytesMessage]
///  * `{payload: JSString, bytes?: JSUint8Array, port?: web.MessagePort}` ->
///    [RpcMessage]
///  * `null` -> closes `stream` and [port]
///
/// **Outgoing** (`sink` -> `port.postMessage`), converts [MessagePortMessage]s
/// into JS values and posts them on [port]:
///  * [StringMessage] -> `JSString`
///  * [BytesMessage] -> `JSUint8Array`
///  * [RpcMessage] -> `{payload: JSString, bytes?: JSUint8Array,
///    port?: web.MessagePort}`
///  * closing `sink` -> posts `null` and closes [port]
StreamChannel<MessagePortMessage> _webMessagePortChannel(web.MessagePort port) {
  final input = StreamController<MessagePortMessage>();
  final output = StreamController<MessagePortMessage>();

  void closeTransferredPorts(web.MessageEvent event) {
    for (final p in event.ports.toDart) {
      p.close();
    }
  }

  port.onmessage = (web.MessageEvent event) {
    if (input.isClosed) {
      closeTransferredPorts(event);
      return;
    }
    final data = event.data;
    if (data == null) {
      closeTransferredPorts(event);
      port
        ..onmessage = null
        ..onmessageerror = null
        ..close();
      unawaited(input.sink.close());
      return;
    }
    if (data.isA<JSString>()) {
      closeTransferredPorts(event);
      input.sink.add(StringMessage((data as JSString).toDart));
      return;
    }
    if (data.isA<JSUint8Array>()) {
      closeTransferredPorts(event);
      final dartBytes = (data as JSUint8Array).toDart;
      final bytes = isDart2Wasm ? Uint8List.fromList(dartBytes) : dartBytes;
      input.sink.add(BytesMessage(bytes));
      return;
    }
    if (data.isA<JSObject>()) {
      final msg = _RpcMessage._(data as JSObject);
      final rawPayload = msg.payload;
      final rawBytes = msg.bytes;
      final rawPort = msg.port;
      if (!rawPayload.isA<JSString>() ||
          (rawBytes != null && !rawBytes.isA<JSUint8Array>()) ||
          (rawPort != null && !rawPort.isA<web.MessagePort>())) {
        closeTransferredPorts(event);
        input.sink.addError(
          const FormatException('Unexpected MessagePort object payload'),
        );
        return;
      }
      MessagePort? attachedPort;
      if (rawPort != null) {
        attachedPort = MessagePortExt.fromMessagePort(
          rawPort as web.MessagePort,
        );
      }
      Uint8List? bytes;
      if (rawBytes != null) {
        // On dart2wasm, `.toDart` returns JSUint8ArrayImpl (a JS DataView
        // view). Materializing a native WasmGC U8List once at ingress prevents
        // storing JSUint8ArrayImpl in MemoryResourceProvider or slicing it in
        // TarReader.
        final dartBytes = (rawBytes as JSUint8Array).toDart;
        bytes = isDart2Wasm ? Uint8List.fromList(dartBytes) : dartBytes;
      }
      input.sink.add(
        RpcMessage(
          (rawPayload as JSString).toDart,
          bytes: bytes,
          port: attachedPort,
        ),
      );
      return;
    }
    closeTransferredPorts(event);
    input.sink.addError(
      const FormatException('Unexpected MessagePort message'),
    );
  }.toJS;

  // This happens if message can't be deserialized on this side of the port,
  // usually a browser bug, or something like SharedArrayBuffer or other corner
  // cases; not likely to happen in our code.
  port.onmessageerror = (web.MessageEvent event) {
    closeTransferredPorts(event);
    if (input.isClosed) return;
    final originStr = event.origin.isNotEmpty
        ? ' (Origin: ${event.origin})'
        : '';
    input.sink.addError(
      FormatException(
        'MessagePort dropped a message due to '
        'deserialization failure$originStr',
      ),
    );
  }.toJS;

  port.start();

  output.stream.listen(
    (message) {
      switch (message) {
        case StringMessage(:final value):
          port.postMessage(value.toJS);
        case BytesMessage(:final bytes):
          final jsBytes = bytes.toJS;
          if (isDart2Wasm && bytes.runtimeType == _nativeUint8ListType) {
            port.postMessage(jsBytes, <JSObject>[jsBytes.buffer].toJS);
          } else {
            port.postMessage(jsBytes);
          }
        case RpcMessage(:final payload, :final bytes, port: final attachedPort):
          final transferables = <JSObject>[];
          final jsPayload = payload.toJS;
          final webPort = attachedPort?.asTransferableMessagePort();
          if (webPort != null) {
            transferables.add(webPort);
          }
          final jsBytes = bytes?.toJS;
          if (isDart2Wasm &&
              jsBytes != null &&
              bytes.runtimeType == _nativeUint8ListType) {
            // On dart2wasm, `bytes.toJS` on a native WasmGC U8List allocates a
            // fresh JSArrayBuffer copy; transferring it avoids a second
            // structured-clone copy across MessagePort without detaching
            // caller-owned JS buffers.
            transferables.add(jsBytes.buffer);
          }
          final rpcMessage = switch ((webPort, jsBytes)) {
            (null, null) => _RpcMessage(payload: jsPayload),
            (final p?, null) => _RpcMessage(payload: jsPayload, port: p),
            (null, final b?) => _RpcMessage(payload: jsPayload, bytes: b),
            (final p?, final b?) => _RpcMessage(
              payload: jsPayload,
              port: p,
              bytes: b,
            ),
          };
          port.postMessage(rpcMessage, transferables.toJS);
      }
    },
    onDone: () {
      port
        ..postMessage(null)
        ..onmessage = null
        ..onmessageerror = null
        ..close();
      unawaited(input.sink.close());
    },
  );

  return StreamChannel(input.stream, output.sink);
}
