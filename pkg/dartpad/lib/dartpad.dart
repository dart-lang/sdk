// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// `package:dartpad` provides a client for launching and interacting with
/// a _Web Worker_ running a development environment with Dart SDK.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'src/util/message_port_channel.dart';
import 'src/worker_client.dart';

export 'src/dartpad_config.dart' show DartPadConfig;
export 'src/exceptions.dart' hide rethrowAsDartPadException;
export 'src/sandbox.dart' show Sandbox;
export 'src/worker_client.dart'
    show HotReloadCompiler, LanguageServer, Workspace;

/// A client for interacting with a DartPad Web Worker.
final class DartPad extends WorkerClient {
  final web.Worker _worker;
  final String _blobUrl;

  DartPad._(super.channel, this._worker, this._blobUrl);

  /// Create a _Web Worker_ running a DartPad development environment.
  ///
  /// The [assetBaseUrl] should point to the directory containing
  /// `worker.loader.js` and `worker.wasm`.
  /// The [sdkLocation] should point to the directory containing the `sdk.tar`
  /// to load (relative to the worker script, or an absolute URL).
  /// Defaults to `./dart/`.
  static Future<DartPad> create({
    required Uri assetBaseUrl,
    required Uri sdkLocation,
    Uri? pubHostedUrl,
  }) async {
    if (!assetBaseUrl.path.endsWith('/')) {
      assetBaseUrl = assetBaseUrl.replace(path: '${assetBaseUrl.path}/');
    }
    sdkLocation = assetBaseUrl.resolveUri(sdkLocation);
    if (!sdkLocation.path.endsWith('/')) {
      sdkLocation = sdkLocation.replace(path: '${sdkLocation.path}/');
    }

    var workerScript = assetBaseUrl.resolve('worker.loader.js');

    // Since we workerScript might be on a different origin we cannot just
    // create from it. So we must create a blob and start the worker from this
    // blob. We also cannot inject querystring parameters on a blob.
    // So we must inject these directly into the global scope, for the worker
    // to pick up.
    //
    // If in the future we want to make a SharedWorker, we have two options:
    // (A) We ask the user host a dartpad-worker.js file that imports
    //     our worker script. This file must be hosted on the users origin.
    //     Then the user will have a SharedWorker, that shared for instances
    //     of their origin. And querystring can be used for parameterization.
    //     Ensuring that there is one SharedWorker per set of parameters.
    // (B) We host a dartpad-worker.html page, which we then embed into the
    //     users page as a hidden iframe. Inside this iframe we create a
    //     SharedWorker and we can again use querystring parameters.
    //     This gives a single SharedWorker across all origins, and would allow
    //     a persisted PUB_CACHE to be shared across dartpads everywhere.
    //     Again, we could have a SharedWorker for each set of parameters.
    //
    // For now we don't support launching a SharedWorker, but in the future we
    // explore supporting a SharedWorker strategy. Option (B) would be rather
    // attractive, if we could use Origin-Private-File-System (OPFS) to retain
    // the PUB_CACHE. Granted to actually use OPFS with sync I/O, we can't use
    // SharedWorkers, so we'd have to make a SharedWorker that owns a
    // dedicated worker and forwards the port to this worker. The overhead of
    // this is probably not bad, it's just (B) does become a fairly complex
    // setup.
    final blobUrl = web.URL.createObjectURL(
      web.Blob(
        [
          [
            'import \'$workerScript\';',
            'self.assetBaseUrl = ${jsonEncode(assetBaseUrl.toString())};',
            'self.sdkLocation = ${jsonEncode(sdkLocation.toString())};',
            'self.pubHostedUrl = ${jsonEncode(pubHostedUrl?.toString())};',
            '',
          ].join('\n').toJS,
        ].toJS,
        web.BlobPropertyBag(type: 'application/javascript'),
      ),
    );
    final worker = web.Worker(
      blobUrl.toJS,
      web.WorkerOptions(name: 'dartpad-worker', type: 'module'),
    );
    worker.addEventListener(
      'error',
      (web.Event event) {
        web.console.error('Unhandled error from worker:'.toJS);
        web.console.error(event);
      }.toJS,
    );
    worker.onmessage = (web.MessageEvent event) {
      final data = event.data as JSObject;
      final action = data.getProperty<JSString>('action'.toJS).toDart;
      if (action == 'error') {
        final m = data.getProperty<JSString>('message'.toJS).toDart;
        throw StateError('Failed to start worker: $m');
      }
    }.toJS;

    final web.MessageChannel(:port1, :port2) = web.MessageChannel();
    worker.postMessage({'action': 'connect'}.jsify(), [port2].toJS);
    return DartPad._(messagePortChannel(port1).cast(), worker, blobUrl);
  }

  /// Terminates the underlying Web Worker.
  @override
  Future<void> dispose() async {
    try {
      await super.dispose();
      _worker.terminate();
    } finally {
      web.URL.revokeObjectURL(_blobUrl);
    }
  }
}
