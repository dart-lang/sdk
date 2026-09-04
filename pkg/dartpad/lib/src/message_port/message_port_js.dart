import 'dart:typed_data';

import 'package:stream_channel/stream_channel.dart';
import 'package:web/web.dart' as web;

import '../util/json_rpc_message_port_channel.dart';
import 'json_rpc_binary_channel.dart';

/// Wrapper for `MessagePort` allowing proxying over binary [StreamChannel].
abstract final class MessagePort {
  MessagePort._();

  /// Wrap a binary [StreamChannel] as a [MessagePort].
  factory MessagePort.fromBinaryChannel(StreamChannel<Uint8List> channel) =
      _StreamChannelMessagePort.fromBinaryChannel;

  /// Encode this [MessagePort] as a binary [StreamChannel] that can be decoded
  /// with [MessagePort.fromBinaryChannel].
  ///
  /// This encoding is not garenteed to be stable cross different versions of
  /// `package:dartpad`.
  StreamChannel<Uint8List> asBinaryChannel();

  StreamChannel<Object?> _jsonRpcChannel();
  web.MessagePort _asTransferableMessagePort();
}

/// This is internal API, not intended for consumers of `package:dartpad`.
extension MessagePortExt on MessagePort {
  /// Returns a [StreamChannel] adapter that communicates JSON-RPC 2.0 over a
  /// [MessagePort].
  ///
  /// This allows [Uint8List], but not [MessagePort] instances to be sent
  /// over the port.
  StreamChannel<Object?> jsonRpcChannel() => _jsonRpcChannel();

  /// Return the [web.MessageChannel] being wrapped by this [MessagePort] or
  /// create one and send message from this [MessagePort] over it.
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
  StreamChannel<Object?> _jsonRpcChannel() => jsonRpcMessagePortChannel(_port);

  @override
  StreamChannel<Uint8List> asBinaryChannel() =>
      _jsonRpcChannel().transform(jsonRpcChannelToBinaryChannelTransformer);

  @override
  web.MessagePort _asTransferableMessagePort() => _port;
}

final class _StreamChannelMessagePort extends MessagePort {
  final StreamChannel<Uint8List> _channel;

  _StreamChannelMessagePort.fromBinaryChannel(this._channel) : super._();

  @override
  StreamChannel<Object?> _jsonRpcChannel() =>
      _channel.transform(binaryChannelToJsonRpcChannelTransformer);

  @override
  StreamChannel<Uint8List> asBinaryChannel() => _channel;

  @override
  web.MessagePort _asTransferableMessagePort() {
    final c = web.MessageChannel();
    _jsonRpcChannel().pipe(jsonRpcMessagePortChannel(c.port1));
    return c.port2;
  }
}
