// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:stream_channel/stream_channel.dart';
import 'package:web/web.dart' as web;

/// Returns a [StreamChannel] adapter that communicates JSON-RPC 2.0 over a
/// [web.MessagePort].
///
/// This will encode messages as:
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
/// This is an implementation of the "JSON-RPC 2.0 over MessagePort" as
/// specified in `doc/worker-protocol.md`.
StreamChannel<Object?> jsonRpcMessagePortChannel(web.MessagePort port) {
  final input = StreamController<Object?>();
  final output = StreamController<Object?>();

  port.onmessage = (web.MessageEvent event) {
    try {
      input.sink.add(_dartifyMessage(event.data));
    } on FormatException catch (e, st) {
      input.sink.addError(e, st);
    }
  }.toJS;

  // This happens if message can't be deserialized on this side of the port
  // usually a browser bug, or something like SharedBuffers or other corner
  // cases; not likely to happen in our code.
  port.onmessageerror = (web.MessageEvent event) {
    // Close any transferred port (just in case)
    for (final p in event.ports.toDart) {
      p.close();
    }

    // Include origin in error message, if there is one.
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
    (m) {
      final transferables = <JSObject>[];
      port.postMessage(_jsifyMessage(m, transferables), transferables.toJS);
    },
    onDone: () {
      unawaited(input.sink.close());
      port.close();
    },
  );

  return StreamChannel(input.stream, output.sink);
}

JSAny? _jsifyMessage(Object? m, List<JSObject> transferables) {
  web.MessagePort? port;
  Uint8List? bytes;
  if (m is Map) {
    // If params.port or result.port is a MessagePort, we transfer it!
    for (final k in ['params', 'result']) {
      if (m[k] case final Map v) {
        final p = v['port'] as Object?;
        if (p.isA<web.MessagePort>()) {
          port = p as web.MessagePort;
          v.remove('port');
        }
      }
    }
    if (port != null) {
      transferables.add(port);
    }

    // If params.bytes or result.bytes is a Uint8List, we move it to "bytes"
    for (final k in ['params', 'result']) {
      if (m[k] case final Map v) {
        final b = v['bytes'];
        if (b is Uint8List) {
          v.remove('bytes');
          bytes = b;
        }
      }
    }

    // package:json_rpc_2 will automatically add error.data.request.params to
    // error messages, if they contain port or bytes we strip them.
    if (m['error'] case final Map error) {
      if (error['data'] case final Map data) {
        if (data['request'] case final Map request) {
          if (request['params'] case final Map params) {
            if ((params['port'] as JSAny?).isA<web.MessagePort>()) {
              params.remove('port');
            }
            if (params['bytes'] is Uint8List) {
              params.remove('bytes');
            }
          }
        }
      }
    }
  }

  return {'payload': jsonEncode(m), 'port': ?port, 'bytes': ?bytes}.jsify();
}

Object? _dartifyMessage(JSAny? data) {
  if (!data.isA<JSObject>()) {
    return null;
  }
  data as JSObject;
  if (!data['payload'].isA<JSString>()) {
    return null;
  }
  final payload = jsonDecode((data['payload'] as JSString).toDart);

  if (data['port'].isA<web.MessagePort>()) {
    final port = data['port'] as web.MessagePort;
    if (payload is! Map) {
      throw const FormatException('port not allowed in batch mode');
    }
    for (final k in ['params', 'result']) {
      final v = payload[k];
      if (v is Map) {
        v['port'] = port;
      }
    }
  }

  if (data['bytes'].isA<JSUint8Array>()) {
    final bytes = (data['bytes'] as JSUint8Array).toDart;
    if (payload is! Map) {
      throw const FormatException('bytes not allowed in batch mode');
    }
    for (final k in ['params', 'result']) {
      final v = payload[k];
      if (v is Map) {
        v['bytes'] = bytes;
      }
    }
  }

  return payload;
}
