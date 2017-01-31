// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol.dart';

/**
 * The object that allows a [ServerPlugin] to receive [Request]s and to return
 * both [Response]s and [Notification]s.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class PluginCommunicationChannel {
  /**
   * Close the communication channel.
   */
  void close();

  /**
   * Listen to the channel for requests. If a request is received, invoke the
   * [onRequest] function. If an error is encountered while trying to read from
   * the socket, invoke the [onError] function. If the socket is closed by the
   * client, invoke the [onDone] function. Only one listener is allowed per
   * channel.
   */
  void listen(void onRequest(Request request),
      {Function onError, void onDone()});

  /**
   * Send the given [notification] to the server.
   */
  void sendNotification(Notification notification);

  /**
   * Send the given [response] to the server.
   */
  void sendResponse(Response response);
}
