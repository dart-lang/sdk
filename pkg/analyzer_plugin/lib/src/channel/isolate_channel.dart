// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:analyzer/instrumentation/instrumentation.dart';
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
//      print('[plugin] Received request: ${JSON.encode(requestMap)}');
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
    Map<String, Object> json = notification.toJson();
//    print('[plugin] Send notification: ${JSON.encode(json)}');
    _sendPort.send(json);
  }

  @override
  void sendResponse(Response response) {
    Map<String, Object> json = response.toJson();
//    print('[plugin] Send response: ${JSON.encode(json)}');
    _sendPort.send(json);
  }
}

/**
 * The communication channel that allows an analysis server to send [Request]s
 * to, and to receive both [Response]s and [Notification]s from, a plugin.
 */
class ServerIsolateChannel implements ServerCommunicationChannel {
  /**
   * The URI for the Dart file that will be run in the isolate that this channel
   * communicates with.
   */
  final Uri pluginUri;

  /**
   * The URI for the '.packages' file that will control how 'package:' URIs are
   * resolved.
   */
  final Uri packagesUri;

  /**
   * The instrumentation service that is being used by the analysis server.
   */
  final InstrumentationService instrumentationService;

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
   * The port used to receive responses and notifications from the plugin.
   */
  ReceivePort _receivePort;

  /**
   * The port used to receive unhandled exceptions thrown in the plugin.
   */
  ReceivePort _errorPort;

  /**
   * The port used to receive notification when the plugin isolate has exited.
   */
  ReceivePort _exitPort;

  /**
   * Initialize a newly created channel to communicate with an isolate running
   * the code at the given [uri].
   */
  ServerIsolateChannel(
      this.pluginUri, this.packagesUri, this.instrumentationService);
  @override
  void close() {
    _receivePort?.close();
    _errorPort?.close();
    _exitPort?.close();
    _isolate = null;
  }

  @override
  Future<Null> listen(void onResponse(Response response),
      void onNotification(Notification notification),
      {Function onError, void onDone()}) async {
    if (_isolate != null) {
      throw new StateError('Cannot listen to the same channel more than once.');
    }
    _receivePort = new ReceivePort();
    if (onError != null) {
      _errorPort = new ReceivePort();
      _errorPort.listen((error) {
        onError(error);
      });
    }
    if (onDone != null) {
      _exitPort = new ReceivePort();
      _exitPort.listen((_) {
        onDone();
      });
    }
    _isolate = await Isolate.spawnUri(
        pluginUri, <String>[], _receivePort.sendPort,
        onError: _errorPort?.sendPort,
        onExit: _exitPort?.sendPort,
        packageConfig: packagesUri);
    Completer<Null> channelReady = new Completer<Null>();
    _receivePort.listen((dynamic input) {
      if (input is SendPort) {
//        print('[server] Received send port');
        _sendPort = input;
        channelReady.complete(null);
      } else if (input is Map) {
        if (input.containsKey('id') != null) {
          String encodedInput = JSON.encode(input);
//          print('[server] Received response: $encodedInput');
          instrumentationService.logPluginResponse(pluginUri, encodedInput);
          onResponse(new Response.fromJson(input));
        } else if (input.containsKey('event')) {
          String encodedInput = JSON.encode(input);
//          print('[server] Received notification: $encodedInput');
          instrumentationService.logPluginNotification(pluginUri, encodedInput);
          onNotification(new Notification.fromJson(input));
        }
      }
    });
    return channelReady.future;
  }

  @override
  void sendRequest(Request request) {
    Map<String, Object> json = request.toJson();
    String encodedRequest = JSON.encode(json);
//    print('[server] Send request: $encodedRequest');
    instrumentationService.logPluginRequest(pluginUri, encodedRequest);
    _sendPort.send(json);
  }
}
