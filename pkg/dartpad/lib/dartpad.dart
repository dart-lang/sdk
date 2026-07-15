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

/// Reference to a _DartPad SDK_.
final class DartPadSdk {
  late final Uri _assetBaseUrl;

  /// Create a _DartPad SDK_ given an [assetBaseUrl] pointing to a folder
  /// containing the _DartPad SDK_ assets.
  ///
  /// A _DartPad SDK_ must contain entrypoints:
  ///  * `worker.js`, satisfying `doc/worker-protocol.md`, and,
  ///  * `sandbox.js`.
  ///
  /// A _DartPad SDK_ may contain additional assets that are also resolved from
  /// the [assetBaseUrl] by `worker.js` or `sandbox.js`.
  DartPadSdk({required Uri assetBaseUrl}) {
    if (!assetBaseUrl.path.endsWith('/')) {
      assetBaseUrl = assetBaseUrl.replace(path: '${assetBaseUrl.path}/');
    }
    _assetBaseUrl = Uri.base.resolveUri(assetBaseUrl);
  }

  Future<DartPad> dedicatedWorker({Uri? pubHostedUrl}) async {
    // The assetBaseUrl might be on a different origin, so we'll create a small
    // blob object URL importing worker.js and setting up a session.
    //
    // If we ever want to support using a SharedWorker, we have to ask the user
    // to host a shared-worker.js that import worker.js, read settings from
    // querystring, and creates a session for each 'connect' event.
    final script = _workerLoader(_assetBaseUrl.resolve('worker.js'), {
      'pubHostedUrl': ?pubHostedUrl?.toString(),
    });
    final blobUrl = web.URL.createObjectURL(
      web.Blob(
        [script.toJS].toJS,
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
    final session = Completer<web.MessagePort>();
    worker.onmessage = (web.MessageEvent event) {
      final data = event.data as JSObject?;
      final action = data?['action'] as JSString?;
      switch (action?.toDart) {
        case 'session':
          session.complete(event.ports[0]);
        case 'error':
          final m = (data?['message'] as JSString?)?.toDart ?? 'Unknown error';
          // TODO(jonasfj): Find an appropriate exception / error to throw!
          session.completeError(Exception('Failed loading worker: $m'));
      }
    }.toJS;

    return DartPad._(
      messagePortChannel(await session.future).cast(),
      worker,
      blobUrl,
    );
  }

  String _workerLoader(Uri workerJs, Map<String, Object?> options) =>
      '''
        import {Worker} from '$workerJs';
        try {
          const worker = await Worker.create(${jsonEncode(options)});
          const channel = new MessageChannel();
          worker.session(channel.port1);
          self.postMessage({action: 'session'}, [channel.port2]);
        } catch (e) {
          console.error(e);
          self.postMessage({action: 'error', message: e.toString()});
        }
    ''';
}

/// A client for interacting with a DartPad Web Worker.
final class DartPad extends WorkerClient {
  final web.Worker _worker;
  final String _blobUrl;

  DartPad._(super.channel, this._worker, this._blobUrl);

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
