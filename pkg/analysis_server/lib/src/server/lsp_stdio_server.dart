// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/lsp/channel/lsp_byte_stream_channel.dart';
import 'package:analysis_server/src/lsp/lsp_socket_server.dart';

/// Instances of the class [StdioServer] implement a simple server operating
/// over standard input and output. The primary responsibility of this server
/// is to split incoming messages on newlines and pass them along to the
/// analysis server.
class LspStdioAnalysisServer {
  /// An object that can handle either a WebSocket connection or a connection
  /// to the client over stdio.
  LspSocketServer socketServer;

  /// Initialize a newly created stdio server.
  LspStdioAnalysisServer(this.socketServer);

  /// Begin serving requests over stdio.
  ///
  /// Return a future that will be completed when stdin closes.
  Future serveStdio() {
    var serverChannel = LspByteStreamServerChannel(
        stdin, stdout.nonBlocking, socketServer.instrumentationService);
    socketServer.createAnalysisServer(serverChannel);
    return serverChannel.closed;
  }
}
