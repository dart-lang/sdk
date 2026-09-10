// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// `package:dartpad` provides a client for launching and interacting with
/// a _Web Worker_ running a development environment with Dart SDK.
///
/// {@example /example/hello_world.dart}
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'src/message_port/message_port.dart';
import 'src/util/json_rpc_message_port_channel.dart';
import 'src/worker_client.dart';

export 'src/dartpad_config.dart' show DartPadConfig;
export 'src/exceptions.dart' hide rethrowAsDartPadException;
export 'src/message_port/message_port.dart' show MessagePort;

export 'src/worker_client.dart'
    show
        FileAddedEvent,
        FileChangeEvent,
        FileModifiedEvent,
        FileRemovedEvent,
        LanguageServer,
        Sandbox,
        Workspace,
        WorkspaceWatcher;

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
      jsonRpcMessagePortChannel(await session.future),
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

  static const _defaultHeadHtml = '''
<style>
  body { margin: 0; overflow: hidden; background: transparent; }
</style>
''';

  static String _iframeHtml({
    required Uri sandboxJs,
    required String headHtml,
    required String bodyHtml,
  }) =>
      '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <script src="$sandboxJs" defer></script>
  $headHtml
</head>
<body>$bodyHtml</body>
</html>
''';

  /// Create a sandboxed iframe inside [container] for running code from a
  /// [Workspace].
  ///
  /// The returned [SandboxedIframe] has a [SandboxedIframe.port] which can be
  /// connected to a [Workspace] using [Workspace.connectSandboxedIframe].
  /// A [SandboxedIframe] can only be connected to one [Workspace].
  ///
  /// Once connected, [Workspace.connectSandboxedIframe] returns a [Sandbox]
  /// object that lets you run and hot-reload Dart code from the [Workspace]
  /// inside the sandboxed iframe.
  ///
  /// The [SandboxedIframe] object owns the life-cycle of the `<iframe>`, while
  /// the [Sandbox] object controls what goes on inside the `<iframe>`.
  ///
  /// The protocol for communication over [SandboxedIframe.port] is internal to
  /// the DartPad SDK loaded. Instead the [SandboxedIframe.port] must be passed
  /// to a [Workspace] through which communication with the sandbox takes place.
  ///
  /// The [MessagePort] on [SandboxedIframe.port] can be proxied using
  /// [MessagePort.asBinaryChannel] and [MessagePort.fromBinaryChannel].
  Future<SandboxedIframe> createSandboxedIframe(
    web.Element container, {
    String headHtml = _defaultHeadHtml,
    String bodyHtml = '',
  }) async {
    final iframe = web.HTMLIFrameElement();
    // TODO: Consider if we want allow-same-origin, it might be needed for
    // source maps, but it decidedly breaks the security sandbox!
    iframe.setAttribute('sandbox', 'allow-scripts allow-same-origin');
    iframe.srcdoc = _iframeHtml(
      sandboxJs: _assetBaseUrl.resolve('sandbox.js'),
      headHtml: headHtml,
      bodyHtml: bodyHtml,
    ).toJS;
    container.appendChild(iframe);

    return await Future(() async {
      await for (final event in web.window.onMessage) {
        if (event.source != iframe.contentWindow ||
            !event.data.isA<JSObject>()) {
          continue;
        }

        final m = event.data as JSObject;
        final action = m['action'];
        if (!action.isA<JSString>()) {
          continue;
        }
        switch ((action as JSString).toDart) {
          case 'connect':
            final port = m['port'];
            if (port.isA<web.MessagePort>()) {
              return SandboxedIframe._(
                iframe,
                MessagePortExt.fromMessagePort(port as web.MessagePort),
              );
            }
          case 'error':
            final message = m['message'];
            if (message.isA<JSString>()) {
              final msg = (message as JSString).toDart;
              throw Exception('Failed to load sandboxed iframe: $msg');
            }
            throw Exception('Failed to load sandboxed iframe');
        }
      }
      throw AssertionError('unreachable');
    }).timeout(
      const Duration(seconds: 120),
      onTimeout: () => throw TimeoutException('Sandbox creation timed out'),
    );
  }
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

/// A [sandboxed iframe][1] for running Dart code from a [Workspace].
///
/// A [SandboxedIframe] must be connected to a [Workspace] by passing
/// [SandboxedIframe.port] to [Workspace.connectSandboxedIframe] returning a
/// [Sandbox] which can be used to run code inside the `<iframe>`.
/// A [SandboxedIframe] may only be connected to one [Workspace]!
///
/// The [SandboxedIframe] object owns the life-cycle of the `<iframe>` and
/// neither destruction of the [Sandbox] or [Workspace] will remove the
/// `<iframe>`, though nothing will happen inside it.
///
/// [1]: https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/iframe#sandbox
final class SandboxedIframe {
  final web.HTMLIFrameElement _iframe;

  /// [MessagePort] to be passed to [Workspace.connectSandboxedIframe].
  ///
  /// The protocol used to communicate over this [port] is internal to the
  /// DartPad SDK. However, messages may be proxied using
  /// [MessagePort.asBinaryChannel] and [MessagePort.fromBinaryChannel].
  final MessagePort port;

  SandboxedIframe._(this._iframe, this.port);

  /// Removes the iframe and cleanups associated resources.
  ///
  /// This removes the `<iframe>` and will invalidate the [Sandbox] returned
  /// from [Workspace.connectSandboxedIframe].
  Future<void> close() async {
    _iframe.remove();
  }
}
