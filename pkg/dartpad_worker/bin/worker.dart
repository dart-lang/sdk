// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:dartpad/src/util/json_rpc_message_port_channel.dart';
import 'package:dartpad_worker/src/util/environment.dart';
import 'package:dartpad_worker/src/util/log.dart';
import 'package:dartpad_worker/src/worker.dart';
import 'package:web/web.dart' as web;

/// Options set by `worker.js`.
///
/// The public API for launching a worker lives in `worker.js`, the
/// [_workerOptions] property is merely a communication bridge between
/// `worker.js` and [main] in this wasm module.
///
/// The public API for launching a worker is specified in:
/// `pkg/dartpad/doc/worker-protocol.md`.
@JS()
external DartPadOptions get _workerOptions;

extension type DartPadOptions._(JSObject _) implements JSObject {
  external String? get pubHostedUrl;
  external JSPromise<web.Response> fetchSdkTar();

  /// Callback when creating the worker is successful
  external void resolve(JSFunction createSession);

  /// Callback when creating the worker fails
  external void reject(JSString message);
}

void main() async {
  final options = _workerOptions;

  await runZonedGuarded(() async {
    final Worker worker;
    try {
      worker = await _createWorker(options);
    } catch (e) {
      options.reject(e.toString().toJS);
      return;
    }

    options.resolve(
      ((web.MessagePort port) => worker.session(
        jsonRpcMessagePortChannel(port),
      )).toJS,
    );
  }, (e, st) => logError('uncaught exception: $e\n$st'));
}

class _FetchException implements Exception {
  final String message;
  _FetchException(this.message);
  @override
  String toString() => message;
}

Stream<Uint8List> _readStream(web.ReadableStream stream) async* {
  final reader = stream.getReader() as web.ReadableStreamDefaultReader;
  try {
    while (true) {
      final web.ReadableStreamReadResult result;
      try {
        result = await reader.read().toDart;
      } catch (e) {
        throw _FetchException('Failed while reading sdk.tar stream: $e');
      }
      if (result.done) break;
      final chunk = (result.value as JSUint8Array).toDart;
      // Materialize JS typed-array views from Fetch into native Wasm Uint8Lists
      // once per network chunk so TarReader doesn't slice across JS interop.
      yield isDart2Wasm ? Uint8List.fromList(chunk) : chunk;
    }
  } finally {
    try {
      await reader.cancel().toDart;
    } catch (e) {
      throw _FetchException('Failed while cancelling sdk.tar stream: $e');
    }
  }
}

Future<Worker> _createWorker(DartPadOptions options) async {
  const maxAttempts = 4;
  for (var attempt = 0; ; attempt++) {
    try {
      final web.Response response;
      try {
        response = await options.fetchSdkTar().toDart;
      } catch (e) {
        throw _FetchException('Failed to fetch sdk.tar: $e');
      }
      if (response.status != 200) {
        throw _FetchException('Failed to fetch sdk.tar (${response.status})');
      }
      final body = response.body;
      if (body == null) {
        throw _FetchException('Failed to fetch sdk.tar: response body is null');
      }
      return await Worker.create(
        _readStream(body),
        pubHostedUrl: options.pubHostedUrl,
      );
    } on _FetchException catch (e) {
      if (attempt + 1 >= maxAttempts) {
        logError('$e');
        rethrow;
      }
      final delay = Duration(milliseconds: 100 * (1 << attempt));
      web.console.log(
        'worker.dart: $e, retrying in ${delay.inMilliseconds}ms...'.toJS,
      );
      await Future<void>.delayed(delay);
    }
  }
}
