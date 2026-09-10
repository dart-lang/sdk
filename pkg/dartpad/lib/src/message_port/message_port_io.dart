import 'dart:typed_data';

import 'package:stream_channel/stream_channel.dart';

import 'json_rpc_binary_channel.dart';

final class MessagePort {
  final StreamChannel<Uint8List> _channel;

  MessagePort.fromBinaryChannel(this._channel);

  StreamChannel<Uint8List> asBinaryChannel() => _channel;

  StreamChannel<Object?> _jsonRpcChannel() =>
      _channel.transform(binaryChannelToJsonRpcChannelTransformer);
}

extension MessagePortExt on MessagePort {
  StreamChannel<Object?> jsonRpcChannel() => _jsonRpcChannel();
}
