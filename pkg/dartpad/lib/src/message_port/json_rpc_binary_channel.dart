import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';

import 'package:stream_channel/stream_channel.dart';

/// Transforms a binary encoding for a JSON-RPC 2.0 channel to a [StreamChannel]
/// suitable for `package:json_rpc_2`.
final binaryChannelToJsonRpcChannelTransformer = StreamChannelTransformer(
  _decodingStreamTransformer,
  StreamSinkTransformer.fromStreamTransformer(_encodingStreamTransform),
);

/// Transforms a JSON-RPC 2.0 channel to a binary encoding for a JSON-RPC 2.0
/// channel.
final jsonRpcChannelToBinaryChannelTransformer = StreamChannelTransformer(
  _encodingStreamTransform,
  StreamSinkTransformer.fromStreamTransformer(_decodingStreamTransformer),
);

final _decodingStreamTransformer = StreamTransformer.fromBind((
  Stream<Uint8List> messages,
) async* {
  await for (final m in messages) {
    final v = ByteData.sublistView(m);
    final jsonSize = v.getUint32(0);
    final jsonBytes = Uint8List.sublistView(m, 4, jsonSize + 4);
    final bytesSize = v.getInt32(jsonSize + 4);
    final decoded = json.fuse(utf8).decode(jsonBytes);

    if (bytesSize >= 0) {
      final bytes = Uint8List.sublistView(
        m,
        jsonSize + 4 + 4,
        bytesSize + jsonSize + 4,
      );
      if (decoded is Map) {
        for (final prop in ['params', 'result']) {
          final v = decoded[prop];
          if (v is Map) {
            v['bytes'] = bytes;
          }
        }
      }
    }
    yield decoded;
  }
});

final _encodingStreamTransform = StreamTransformer.fromBind((
  Stream<Object?> messages,
) async* {
  await for (final m in messages) {
    Uint8List? bytes;
    if (m is Map) {
      for (final prop in ['params', 'result']) {
        if (m[prop] case final Map v) {
          if (v['bytes'] case final Uint8List b) {
            bytes = b;
            v.remove('bytes');
          }
        }
      }
    }

    final jsonBytes = JsonUtf8Encoder().convert(m);
    final jsonSize = jsonBytes.length;
    final bytesSize = bytes?.length ?? -1;

    final encoded = Uint8List(4 + jsonSize + 4 + (bytes?.length ?? 0));
    final v = ByteData.sublistView(encoded);
    v.setUint32(0, jsonSize);
    encoded.setAll(4, jsonBytes);
    v.setInt32(jsonSize + 4, bytesSize);
    if (bytes != null) {
      encoded.setAll(jsonSize + 4 + 4, bytes);
    }

    yield encoded;
  }
});
