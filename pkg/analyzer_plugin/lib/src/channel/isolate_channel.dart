// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';

/**
 * The object that allows a [ServerPlugin] to receive [Request]s and to return
 * both [Response]s and [Notification]s.
 */
class IsolateChannel implements PluginCommunicationChannel {
  /**
   * The port used to send notifications and responses to the server.
   */
  SendPort _sendPort;

  /**
   * The port used to receive requests from the server.
   */
  ReceivePort _receivePort;

  /**
   * The subscription that needs to be cancelled when the channel is closed.
   */
  StreamSubscription _subscription;

  /**
   * Initialize a newly created channel to communicate with the server.
   */
  IsolateChannel(this._sendPort) {
    _receivePort = new ReceivePort();
    _sendPort.send(_receivePort.sendPort);
  }

  @override
  void close() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }

  @override
  void listen(void onRequest(Request request),
      {Function onError, void onDone()}) {
    void onData(data) {
      Map<String, Object> requestMap = data;
      Request request = new Request.fromJson(requestMap);
      if (request != null) {
        onRequest(request);
      }
    }

    if (_subscription != null) {
      throw new StateError('Only one listener is allowed per channel');
    }
    _subscription = _receivePort.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: false);
  }

  @override
  void sendNotification(Notification notification) {
    _sendPort.send(notification.toJson());
  }

  @override
  void sendResponse(Response response) {
    _sendPort.send(response.toJson());
  }
}
