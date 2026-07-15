// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:dartpad/src/util/message_port_channel.dart';
import 'package:dartpad_worker/src/util/log.dart';
import 'package:dartpad_worker/src/worker.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart' as http;
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
  external String get assetBaseUrl;
  external String? get pubHostedUrl;

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
      worker = await _createWorker(_workerOptions);
    } catch (e) {
      options.reject(e.toString().toJS);
      return;
    }

    options.resolve(
      ((web.MessagePort port) => worker.session(
        messagePortChannel(port).cast(),
      )).toJS,
    );
  }, (e, st) => logError('uncaught exception: $e\n$st'));
}

Future<Worker> _createWorker(DartPadOptions options) async {
  final assetBaseUrl = Uri.parse(options.assetBaseUrl);
  final c = http.RetryClient(http.Client());
  try {
    final sdkTar = assetBaseUrl.resolve('sdk.tar');
    final r = await c.send(http.Request('GET', sdkTar));
    if (r.statusCode != 200) {
      logError('Failed to fetch sdk.tar from: "$sdkTar"');
      throw Exception('unable to fetch sdk.tar');
    }
    return await Worker.create(r.stream, pubHostedUrl: options.pubHostedUrl);
  } finally {
    c.close();
  }
}
