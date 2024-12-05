// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../lsp/server_abstract.dart';

/// Creates a [StreamChannel] for a connection to a WebSocket at [wsUri] that
/// prints all communication if [debugPrintCommunication] is `true`.
Future<StreamChannel<String>> createLoggedWebSocketChannel(Uri wsUri) async {
  var rawChannel = WebSocketChannel.connect(wsUri);
  await rawChannel.ready;
  var rawStringChannel = rawChannel.cast<String>();

  /// A helper to create a function that can be used in stream.map() to log
  /// traffic with a prefix.
  String Function(String) logTraffic(String prefix) {
    return (String data) {
      if (debugPrintCommunication) {
        print('$prefix $data'.trim());
      }
      return data;
    };
  }

  // Create a channel that logs the data going through it.
  var loggedInput = rawStringChannel.stream.map(logTraffic('DTD ==>'));
  var loggedOutputController = StreamController<String>();
  unawaited(
    loggedOutputController.stream
        .map(logTraffic('DTD <=='))
        .pipe(rawStringChannel.sink),
  );

  return StreamChannel<String>(
    loggedInput,
    loggedOutputController.sink,
  );
}
