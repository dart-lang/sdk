// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dds;

/// Adds support for binary events send from the VM service, which are not part
/// of the official JSON RPC 2.0 specification.
///
/// A binary event from the VM service has the form:
/// ```
/// type BinaryEvent {
///  dataOffset : uint32,
///  metadata : uint8[dataOffset-4],
///  data : uint8[],
/// }
/// ```
/// where `metadata` is the JSON body of the event.
///
/// [_BinaryCompatiblePeer] assumes that only stream events can contain a
/// binary payload (e.g., clients cannot send a `BinaryEvent` to the VM service).
class _BinaryCompatiblePeer extends json_rpc.Peer {
  _BinaryCompatiblePeer(WebSocketChannel ws, _StreamManager streamManager)
      : super(
          ws.transform<String>(
            StreamChannelTransformer(
              StreamTransformer<dynamic, String>.fromHandlers(
                  handleData: (data, EventSink<String> sink) =>
                      _transformStream(streamManager, data, sink)),
              StreamSinkTransformer<String, dynamic>.fromHandlers(
                handleData: (String data, EventSink<dynamic> sink) {
                  sink.add(data);
                },
              ),
            ),
          ),
          // Allow for requests without the jsonrpc parameter.
          strictProtocolChecks: false,
        );

  static void _transformStream(
      _StreamManager streamManager, dynamic data, EventSink<String> sink) {
    if (data is String) {
      // Non-binary messages come in as Strings. Simply forward to the sink.
      sink.add(data);
    } else if (data is Uint8List) {
      // Only binary events will result in `data` being of type Uint8List. We
      // need to manually forward them here.
      final bytesView =
          ByteData.view(data.buffer, data.offsetInBytes, data.lengthInBytes);
      const metadataOffset = 4;
      final dataOffset = bytesView.getUint32(0, Endian.little);
      final metadataLength = dataOffset - metadataOffset;
      final metadata = Utf8Decoder().convert(Uint8List.view(bytesView.buffer,
          bytesView.offsetInBytes + metadataOffset, metadataLength));
      final decodedMetadata = json.decode(metadata);
      streamManager.streamNotify(decodedMetadata['params']['streamId'], data);
    }
  }
}
