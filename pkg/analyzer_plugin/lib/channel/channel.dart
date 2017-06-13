// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol.dart';

/**
 * A communication channel that allows a [ServerPlugin] to receive [Request]s
 * from, and to return both [Response]s and [Notification]s to, an analysis
 * server.
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

/**
 * A communication channel that allows an analysis server to send [Request]s
 * to, and to receive both [Response]s and [Notification]s from, a plugin.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ServerCommunicationChannel {
  /**
   * Close the communication channel.
   */
  void close();

  /**
   * Cause the plugin to terminate as soon as possible. This should only be used
   * when the plugin has failed to terminate after sending it a 'plugin.shutdown'
   * request.
   */
  void kill();

  /**
   * Listen to the channel for responses and notifications. If a response is
   * received, invoke the [onResponse] function. If a notification is received,
   * invoke the [onNotification] function. If an error is encountered while
   * trying to read from the socket, invoke the [onError] function. If the
   * socket is closed by the plugin, invoke the [onDone] function. Only one
   * listener is allowed per channel.
   */
  void listen(void onResponse(Response response),
      void onNotification(Notification notification),
      {Function onError, void onDone()});

  /**
   * Send the given [request] to the plugin.
   */
  void sendRequest(Request request);
}
