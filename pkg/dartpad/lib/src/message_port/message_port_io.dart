// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:stream_channel/stream_channel.dart';

import 'message_port_channel.dart';

final class MessagePort {
  final StreamChannel<Uint8List> _channel;

  MessagePort.fromBinaryChannel(this._channel);

  StreamChannel<Uint8List> asBinaryChannel() => _channel;

  StreamChannel<MessagePortMessage> _messageChannel() =>
      _channel.transform(binaryToMessagePortChannelTransformer);

  StreamChannel<Object?> _jsonRpcChannel() =>
      _messageChannel().transform(jsonRpcChannelTransformer);

  StreamChannel<Object?> _vmServiceChannel() =>
      _messageChannel().transform(vmServiceChannelTransformer);

  void _close() => unawaited(_channel.sink.close());
}

extension MessagePortExt on MessagePort {
  StreamChannel<Object?> jsonRpcChannel() => _jsonRpcChannel();
  StreamChannel<Object?> vmServiceChannel() => _vmServiceChannel();
  void close() => _close();

  static (MessagePort, MessagePort) createChannel() {
    final controller = StreamChannelController<Uint8List>();
    return (
      MessagePort.fromBinaryChannel(controller.local),
      MessagePort.fromBinaryChannel(controller.foreign),
    );
  }

  // Below are stubs only needed for compilation when running in the vm.

  Never asTransferableMessagePort() => throw UnsupportedError('Not supported');

  static MessagePort fromMessagePort(Object? port) =>
      throw UnsupportedError('Not supported');
}
