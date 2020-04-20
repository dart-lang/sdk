// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';

/// The type of the function used to run a built-in plugin in an isolate.
typedef EntryPoint = void Function(SendPort sendPort);

/// A communication channel appropriate for built-in plugins.
class BuiltInServerIsolateChannel extends ServerIsolateChannel {
  /// The entry point
  final EntryPoint entryPoint;

  @override
  final String pluginId;

  /// Initialize a newly created channel to communicate with an isolate running
  /// the given [entryPoint].
  BuiltInServerIsolateChannel(this.entryPoint, this.pluginId,
      InstrumentationService instrumentationService)
      : super._(instrumentationService);

  @override
  Future<Isolate> _spawnIsolate() {
    return Isolate.spawn(
        (message) => entryPoint(message as SendPort), _receivePort.sendPort,
        onError: _errorPort?.sendPort, onExit: _exitPort?.sendPort);
  }
}

/// A communication channel appropriate for discovered plugins.
class DiscoveredServerIsolateChannel extends ServerIsolateChannel {
  /// The URI for the Dart file that will be run in the isolate that this
  /// channel communicates with.
  final Uri pluginUri;

  /// The URI for the '.packages' file that will control how 'package:' URIs are
  /// resolved.
  final Uri packagesUri;

  /// Initialize a newly created channel to communicate with an isolate running
  /// the code at the given [uri].
  DiscoveredServerIsolateChannel(this.pluginUri, this.packagesUri,
      InstrumentationService instrumentationService)
      : super._(instrumentationService);

  @override
  String get pluginId => pluginUri.toString();

  @override
  Future<Isolate> _spawnIsolate() {
    return Isolate.spawnUri(pluginUri, <String>[], _receivePort.sendPort,
        onError: _errorPort?.sendPort,
        onExit: _exitPort?.sendPort,
        packageConfig: packagesUri);
  }
}

/// The object that allows a [ServerPlugin] to receive [Request]s and to return
/// both [Response]s and [Notification]s. It communicates with the analysis
/// server by passing data to the server's main isolate.
class PluginIsolateChannel implements PluginCommunicationChannel {
  /// The port used to send notifications and responses to the server.
  final SendPort _sendPort;

  /// The port used to receive requests from the server.
  ReceivePort _receivePort;

  /// The subscription that needs to be cancelled when the channel is closed.
  StreamSubscription _subscription;

  /// Initialize a newly created channel to communicate with the server.
  PluginIsolateChannel(this._sendPort) {
    _receivePort = ReceivePort();
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
  void listen(void Function(Request request) onRequest,
      {Function onError, void Function() onDone}) {
    void onData(data) {
      var requestMap = data as Map<String, Object>;
      var request = Request.fromJson(requestMap);
      if (request != null) {
        onRequest(request);
      }
    }

    if (_subscription != null) {
      throw StateError('Only one listener is allowed per channel');
    }
    _subscription = _receivePort.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: false);
  }

  @override
  void sendNotification(Notification notification) {
    var json = notification.toJson();
    _sendPort.send(json);
  }

  @override
  void sendResponse(Response response) {
    var json = response.toJson();
    _sendPort.send(json);
  }
}

/// A communication channel that allows an analysis server to send [Request]s
/// to, and to receive both [Response]s and [Notification]s from, a plugin.
abstract class ServerIsolateChannel implements ServerCommunicationChannel {
  /// The instrumentation service that is being used by the analysis server.
  final InstrumentationService instrumentationService;

  /// The isolate in which the plugin is running, or `null` if the plugin has
  /// not yet been started by invoking [listen].
  Isolate _isolate;

  /// The port used to send requests to the plugin, or `null` if the plugin has
  /// not yet been started by invoking [listen].
  SendPort _sendPort;

  /// The port used to receive responses and notifications from the plugin.
  ReceivePort _receivePort;

  /// The port used to receive unhandled exceptions thrown in the plugin.
  ReceivePort _errorPort;

  /// The port used to receive notification when the plugin isolate has exited.
  ReceivePort _exitPort;

  /// Return a communication channel appropriate for communicating with a
  /// built-in plugin.
  factory ServerIsolateChannel.builtIn(EntryPoint entryPoint, String pluginId,
          InstrumentationService instrumentationService) =
      BuiltInServerIsolateChannel;

  /// Return a communication channel appropriate for communicating with a
  /// discovered plugin.
  factory ServerIsolateChannel.discovered(Uri pluginUri, Uri packagesUri,
          InstrumentationService instrumentationService) =
      DiscoveredServerIsolateChannel;

  /// Initialize a newly created channel.
  ServerIsolateChannel._(this.instrumentationService);

  /// Return the id of the plugin running in the isolate, used to identify the
  /// plugin to the instrumentation service.
  String get pluginId;

  @override
  void close() {
    _receivePort?.close();
    _errorPort?.close();
    _exitPort?.close();
    _isolate = null;
  }

  @override
  void kill() {
    _isolate?.kill(priority: Isolate.immediate);
  }

  @override
  Future<void> listen(void Function(Response response) onResponse,
      void Function(Notification notification) onNotification,
      {void Function(dynamic error) onError, void Function() onDone}) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (_isolate != null) {
      throw StateError('Cannot listen to the same channel more than once.');
    }
    _receivePort = ReceivePort();
    if (onError != null) {
      _errorPort = ReceivePort();
      _errorPort.listen((error) {
        onError(error);
      });
    }
    if (onDone != null) {
      _exitPort = ReceivePort();
      _exitPort.listen((_) {
        onDone();
      });
    }
    try {
      _isolate = await _spawnIsolate();
    } catch (exception, stackTrace) {
      instrumentationService.logPluginError(
          PluginData(pluginId, null, null),
          RequestErrorCode.PLUGIN_ERROR.toString(),
          exception.toString(),
          stackTrace.toString());
      if (onError != null) {
        onError([exception.toString(), stackTrace.toString()]);
      }
      if (onDone != null) {
        onDone();
      }
      close();
      return null;
    }
    var channelReady = Completer<void>();
    _receivePort.listen((dynamic input) {
      if (input is SendPort) {
        _sendPort = input;
        channelReady.complete(null);
      } else if (input is Map) {
        if (input.containsKey('id')) {
          var encodedInput = json.encode(input);
          instrumentationService.logPluginResponse(pluginId, encodedInput);
          onResponse(Response.fromJson(input));
        } else if (input.containsKey('event')) {
          var encodedInput = json.encode(input);
          instrumentationService.logPluginNotification(pluginId, encodedInput);
          onNotification(Notification.fromJson(input));
        }
      }
    });
    return channelReady.future;
  }

  @override
  void sendRequest(Request request) {
    if (_sendPort != null) {
      var jsonData = request.toJson();
      var encodedRequest = json.encode(jsonData);
      instrumentationService.logPluginRequest(pluginId, encodedRequest);
      _sendPort.send(jsonData);
    }
  }

  /// Spawn the isolate in which the plugin is running.
  Future<Isolate> _spawnIsolate();
}
