// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:stream_channel/stream_channel.dart';
import 'package:web/web.dart' as web;

/// Returns a [StreamChannel] adapter that communicates JSON-RPC 2.0 over a
/// [web.MessagePort].
///
/// The channel will dartify incoming messages and jsify outgoing messages, and
/// allow [Uint8List] in messages and transfer [web.MessagePort] objects so long
/// as they are in `params.port` or `result.port`.
///
/// This is an implementation of the "JSON-RPC 2.0 over MessagePort" as
/// specified in `doc/worker-protocol.md`.
StreamChannel<Object?> jsonRpcMessagePortChannel(web.MessagePort port) {
  final input = StreamController<Object?>();
  final output = StreamController<Object?>();

  port.onmessage = (web.MessageEvent event) {
    input.sink.add(_dartifyMessage(event.data));
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
  if (m is List) {
    return m.map((m) => _jsifyMessage(m, transferables)).toList().toJS;
  }

  if (m is Map) {
    // If params.port or result.port is a MessagePort, we transfer it!
    for (final k in ['params', 'result']) {
      if (m[k] case final Map value) {
        final port = value['port'] as Object?;
        if (port.isA<web.MessagePort>()) {
          transferables.add(port as web.MessagePort);
        }
      }
    }

    // If error.data.request.params.port is a MessagePort, we remove it!
    // This is automatically added by package:json_rpc_2 when an error is
    // returned.
    if (m['error'] case final Map error) {
      if (error['data'] case final Map data) {
        if (data['request'] case final Map request) {
          if (request['params'] case final Map params) {
            if ((params['port'] as JSAny?).isA<web.MessagePort>()) {
              params.remove('port');
            }
          }
        }
      }
    }
  }

  return m.jsify();
}

Object? _dartifyMessage(JSAny? data) {
  if (data.isA<JSArray>()) {
    return (data as JSArray).toDartIterable.map(_dartifyMessage).toList();
  }

  if (data.isA<JSObject>()) {
    final jsObj = data as JSObject;

    // We extract and delete params.port and result.port, then reinject after
    // .dartify(), because behavior is undefined for MessagePort in .dartify()
    web.MessagePort? paramsPort;
    web.MessagePort? resultPort;

    final params = jsObj.getProperty('params'.toJS);
    if (params.isA<JSObject>()) {
      final pObj = params as JSObject;
      final port = pObj.getProperty('port'.toJS);
      if (port.isA<web.MessagePort>()) {
        paramsPort = port as web.MessagePort;
        pObj.delete('port'.toJS); // hide from .dartify()
      }
    }

    final result = jsObj.getProperty('result'.toJS);
    if (result.isA<JSObject>()) {
      final rObj = result as JSObject;
      final port = rObj.getProperty('port'.toJS);
      if (port.isA<web.MessagePort>()) {
        resultPort = port as web.MessagePort;
        rObj.delete('port'.toJS);
      }
    }

    // Inject params.port and result.port again
    final message = jsObj.dartify() as Map;
    if (paramsPort != null && message['params'] is Map) {
      (message['params'] as Map)['port'] = paramsPort;
    }
    if (resultPort != null && message['result'] is Map) {
      (message['result'] as Map)['port'] = resultPort;
    }

    return _restoreIntegers(message);
  }

  return _restoreIntegers(data.dartify());
}

/// Walk a JSON-like structure converting [double] to [int] whenever feasible.
///
/// When numbers move from JavaScript to dart2wasm they always become [double].
/// This is different from how `jsonDecode` behaves and breaks expectations in
/// `package:json_rpc_2`, to keep compatibility (and sanity) we restore ints.
Object? _restoreIntegers(Object? v) {
  if (v is double && v.isFinite && v == v.truncateToDouble()) {
    return v.toInt();
  } else if (v is List && v is! TypedData) {
    // Traverse standard lists (but skip TypedData like Uint8List!)
    for (var i = 0; i < v.length; i++) {
      v[i] = _restoreIntegers(v[i]);
    }
  } else if (v is Map) {
    for (final entry in v.entries) {
      v[entry.key] = _restoreIntegers(entry.value);
    }
  }
  return v;
}
