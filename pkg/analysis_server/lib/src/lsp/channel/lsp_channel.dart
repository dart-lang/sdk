// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

/// The abstract class [LspServerCommunicationChannel] defines the behavior of
/// objects that allow an [LspAnalysisServer] to receive [RequestMessage]s and
/// [NotificationMessage]s and to return both [ResponseMessage]s and
/// [NotificationMessage]s.
abstract class LspServerCommunicationChannel {
  Future get closed;

  /// Close the communication channel.
  void close();

  /// Listen to the channel for messages. If a message is received, invoke the
  /// [onMessage] function. If an error is encountered while trying to read from
  /// the socket, invoke the [onError] function. If the socket is closed by the
  /// client, invoke the [onDone] function.
  /// Only one listener is allowed per channel.
  void listen(void Function(Message message) onMessage,
      {Function onError, void Function() onDone});

  /// Send the given [notification] to the client.
  void sendNotification(NotificationMessage notification);

  /// Send the given [request] to the client.
  void sendRequest(RequestMessage request);

  /// Send the given [response] to the client.
  void sendResponse(ResponseMessage response);
}
