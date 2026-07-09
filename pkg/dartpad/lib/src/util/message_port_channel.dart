// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:stream_channel/stream_channel.dart';
import 'package:web/web.dart' as web;

/// Returns a [StreamChannel] adapter that communicates over [port].
///
/// The channel will dartify incoming messages and jsify outgoing messages.
StreamChannel<Object?> messagePortChannel(web.MessagePort port) {
  final input = StreamController<Object?>();
  final output = StreamController<Object?>();

  port.onmessage = (web.MessageEvent event) {
    input.sink.add(event.data.dartify());
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
      port.postMessage(m.jsify());
    },
    onDone: () {
      unawaited(input.sink.close());
      port.close();
    },
  );

  return StreamChannel(input.stream, output.sink);
}
