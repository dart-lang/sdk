// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show IOSink;
import 'dart:isolate';

import 'package:analysis_server/src/channel/byte_stream_channel.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:stream_channel/isolate_channel.dart';

/// This class translates messages sent across an [IsolateChannel] into
/// a [ByteStreamServerChannel] for the analysis server.
class IsolateAnalysisServer {
  /// An object that can handle either a WebSocket connection or a connection
  /// to the client over stdio.
  SocketServer socketServer;

  /// Initialize a newly created isolate server.
  IsolateAnalysisServer(this.socketServer);

  /// Initializes an [IsolateChannel] with [clientSendPort] and starts a server
  /// with it.
  Future<void> serveIsolate(SendPort clientSendPort) async {
    var serverIsolateChannel =
        IsolateChannel<List<int>>.connectSend(clientSendPort);
    var serverChannel = ByteStreamServerChannel(
      serverIsolateChannel.stream,
      IOSink(serverIsolateChannel.sink),
      socketServer.instrumentationService,
      requestStatistics: socketServer.requestStatistics,
    );
    socketServer.createAnalysisServer(serverChannel);
    await serverChannel.closed;
  }
}
