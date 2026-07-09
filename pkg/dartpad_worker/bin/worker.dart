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

const _defaultSdkLocation = 'dart/';

void main() async {
  await runZonedGuarded(_startWorker, (e, st) {
    logError('uncaught exception: $e\n$st');
  });
}

@JS('assetBaseUrl')
external String? get assetBaseUrl;

@JS('sdkLocation')
external String? get sdkLocation;

@JS('pubHostedUrl')
external String? get pubHostedUrl;

Future<void> _startWorker() async {
  final workerFuture = _createWorker();

  // Check if we are running in a SharedWorker environment
  if (globalContext.isA<web.SharedWorkerGlobalScope>()) {
    final scope = globalContext as web.SharedWorkerGlobalScope;

    scope.onconnect = (web.MessageEvent event) {
      final port = event.ports.toDart[0];
      _handleConnect(port, workerFuture);
    }.toJS;
  } else {
    // Running as a standard DedicatedWorker
    final scope = globalContext as web.DedicatedWorkerGlobalScope;

    scope.onmessage = (web.MessageEvent event) {
      if (event.ports.toDart.isEmpty) {
        logError('Message missing MessagePort');
        return;
      }
      if (!event.data.isA<JSObject>()) {
        logError('Message data is not a JS Object');
        return;
      }

      final message = event.data as HandshakeMessage;

      // Check for the explicit handshake action
      if (message.action == 'connect') {
        final port = event.ports.toDart[0];
        _handleConnect(port, workerFuture);
      } else {
        logError('Unknown action "${message.action}"');
      }
    }.toJS;
  }

  try {
    await workerFuture;
  } catch (e, st) {
    logError('startup failed: $e\n$st');
  }
}

Future<void> _handleConnect(
  web.MessagePort port,
  Future<Worker> workerFuture,
) async {
  // TODO(jonasfj): Consider tracking and sending progress events
  final worker = await workerFuture;
  worker.connect(messagePortChannel(port).cast());
}

Future<Worker> _createWorker() async {
  final assetBaseUrl_ = assetBaseUrl;
  var assetBaseUri = assetBaseUrl_ != null
      ? Uri.tryParse(assetBaseUrl_) ?? Uri.base
      : Uri.base;

  if (!assetBaseUri.path.endsWith('/')) {
    assetBaseUri = assetBaseUri.replace(path: '${assetBaseUri.path}/');
  }
  var sdkLocation_ = assetBaseUri.resolve(sdkLocation ?? _defaultSdkLocation);
  if (!sdkLocation_.path.endsWith('/')) {
    sdkLocation_ = sdkLocation_.replace(path: '${sdkLocation_.path}/');
  }

  final c = http.RetryClient(http.Client());
  try {
    final sdkTar = sdkLocation_.resolve('sdk.tar');
    final r = await c.send(http.Request('GET', sdkTar));
    if (r.statusCode != 200) {
      logError('Failed to fetch sdk.tar from: "$sdkTar"');
      throw Exception('unable to fetch sdk.tar');
    }
    return await Worker.create(r.stream, pubHostedUrl: pubHostedUrl);
  } finally {
    c.close();
  }
}

extension type HandshakeMessage._(JSObject _) implements JSObject {
  external String? get action;
}
