// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';

/**
 * The object that allows a [ServerPlugin] to receive [Request]s and to return
 * both [Response]s and [Notification]s. It communicates with the analysis
 * server by passing data to the server's main isolate.
 */
class PluginIsolateChannel implements PluginCommunicationChannel {
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
  PluginIsolateChannel(this._sendPort) {
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

/**
 * The communication channel that allows an analysis server to send [Request]s
 * to, and to receive both [Response]s and [Notification]s from, a plugin.
 */
class ServerIsolateChannel implements ServerCommunicationChannel {
  /**
   * The URI for the plugin that will be run in the isolate that this channel
   * communicates with.
   */
  final Uri uri;

  /**
   * The isolate in which the plugin is running, or `null` if the plugin has
   * not yet been started by invoking [listen].
   */
  Isolate _isolate;

  /**
   * The port used to send requests to the plugin, or `null` if the plugin has
   * not yet been started by invoking [listen].
   */
  SendPort _sendPort;

  /**
   * Initialize a newly created channel to communicate with an isolate running
   * the code at the given [uri].
   */
  ServerIsolateChannel(this.uri);

  @override
  void close() {
    // TODO(brianwilkerson) Is there anything useful to do here?
    _isolate = null;
    _sendPort = null;
  }

  @override
  Future<Null> listen(void onResponse(Response response),
      void onNotification(Notification notification),
      {Function onError, void onDone()}) async {
    if (_isolate != null) {
      throw new StateError('Cannot listen to the same channel more than once.');
    }
    ReceivePort receivePort = new ReceivePort();
    ReceivePort errorPort;
    if (onError != null) {
      errorPort = new ReceivePort();
      errorPort.listen((error) {
        onError(error);
      });
    }
    ReceivePort exitPort;
    if (onDone != null) {
      exitPort = new ReceivePort();
      exitPort.listen((_) {
        onDone();
      });
    }
    _isolate = await Isolate.spawnUri(uri, <String>[], receivePort.sendPort,
        automaticPackageResolution: true,
        onError: errorPort?.sendPort,
        onExit: exitPort?.sendPort);
    _sendPort = await receivePort.first as SendPort;
    receivePort.listen((dynamic input) {
      if (input is Map) {
        if (input.containsKey('id') != null) {
          onResponse(new Response.fromJson(input));
        } else if (input.containsKey('event')) {
          onNotification(new Notification.fromJson(input));
        }
      }
    });
  }

  @override
  void sendRequest(Request request) {
    _sendPort.send(request.toJson());
  }
}
