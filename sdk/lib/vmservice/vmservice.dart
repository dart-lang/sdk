// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._vmservice;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' show ServiceProtocolInfo;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

part 'asset.dart';
part 'client.dart';
part 'devfs.dart';
part 'constants.dart';
part 'running_isolate.dart';
part 'running_isolates.dart';
part 'message.dart';
part 'message_router.dart';

final RawReceivePort isolateControlPort = new RawReceivePort();
final RawReceivePort scriptLoadPort = new RawReceivePort();

abstract class IsolateEmbedderData {
  void cleanup();
}

String _makeAuthToken() {
  final kTokenByteSize = 8;
  Uint8List bytes = new Uint8List(kTokenByteSize);
  Random random = new Random.secure();
  for (int i = 0; i < kTokenByteSize; i++) {
    bytes[i] = random.nextInt(256);
  }
  return BASE64URL.encode(bytes);
}

// The randomly generated auth token used to access the VM service.
final String serviceAuthToken = _makeAuthToken();

// TODO(johnmccutchan): Enable the auth token and drop the origin check.
final bool useAuthToken = const bool.fromEnvironment('DART_SERVICE_USE_AUTH');

// This is for use by the embedder. It is a map from the isolateId to
// anything implementing IsolateEmbedderData. When an isolate goes away,
// the cleanup method will be invoked after being removed from the map.
final Map<int, IsolateEmbedderData> isolateEmbedderData =
    new Map<int, IsolateEmbedderData>();

// These must be kept in sync with the declarations in vm/json_stream.h.
const kInvalidParams             = -32602;
const kInternalError             = -32603;
const kFeatureDisabled           = 100;
const kStreamAlreadySubscribed   = 103;
const kStreamNotSubscribed       = 104;
const kFileSystemAlreadyExists   = 1001;
const kFileSystemDoesNotExist    = 1002;
const kFileDoesNotExist          = 1003;

var _errorMessages = {
  kInvalidParams: 'Invalid params',
  kInternalError: 'Internal error',
  kFeatureDisabled: 'Feature is disabled',
  kStreamAlreadySubscribed: 'Stream already subscribed',
  kStreamNotSubscribed: 'Stream not subscribed',
  kFileSystemAlreadyExists: 'File system already exists',
  kFileSystemDoesNotExist: 'File system does not exist',
  kFileDoesNotExist: 'File does not exist',
};

String encodeRpcError(Message message, int code, {String details}) {
  var response = {
    'jsonrpc': '2.0',
    'id' : message.serial,
    'error' : {
      'code': code,
      'message': _errorMessages[code],
    },
  };
  if (details != null) {
    response['error']['data'] = {
      'details': details,
    };
  }
  return JSON.encode(response);
}

String encodeMissingParamError(Message message, String param) {
  return encodeRpcError(
      message, kInvalidParams,
      details: "${message.method} expects the '${param}' parameter");
}

String encodeInvalidParamError(Message message, String param) {
  var value = message.params[param];
  return encodeRpcError(
      message, kInvalidParams,
      details: "${message.method}: invalid '${param}' parameter: ${value}");
}

String encodeResult(Message message, Map result) {
  var response = {
    'jsonrpc': '2.0',
    'id' : message.serial,
    'result' : result,
  };
  return JSON.encode(response);
}

String encodeSuccess(Message message) {
  return encodeResult(message, { 'type': 'Success' });
}

const shortDelay = const Duration(milliseconds: 10);

/// Called when the server should be started.
typedef Future ServerStartCallback();

/// Called when the server should be stopped.
typedef Future ServerStopCallback();

/// Called when the service is exiting.
typedef Future CleanupCallback();

/// Called to create a temporary directory
typedef Future<Uri> CreateTempDirCallback(String base);

/// Called to delete a directory
typedef Future DeleteDirCallback(Uri path);

/// Called to write a file.
typedef Future WriteFileCallback(Uri path, List<int> bytes);

/// Called to write a stream into a file.
typedef Future WriteStreamFileCallback(Uri path, Stream<List<int>> bytes);

/// Called to read a file.
typedef Future<List<int>> ReadFileCallback(Uri path);

/// Called to list all files under some path.
typedef Future<List<Map<String,String>>> ListFilesCallback(Uri path);

/// Called when we need information about the server.
typedef Future<Uri> ServerInformationCallback();

/// Called when we want to [enable] or disable the web server.
typedef Future<Uri> WebServerControlCallback(bool enable);

/// Hooks that are setup by the embedder.
class VMServiceEmbedderHooks {
  static ServerStartCallback serverStart;
  static ServerStopCallback serverStop;
  static CleanupCallback cleanup;
  static CreateTempDirCallback createTempDir;
  static DeleteDirCallback deleteDir;
  static WriteFileCallback writeFile;
  static WriteStreamFileCallback writeStreamFile;
  static ReadFileCallback readFile;
  static ListFilesCallback listFiles;
  static ServerInformationCallback serverInformation;
  static WebServerControlCallback webServerControl;
}

class VMService extends MessageRouter {
  static VMService _instance;

  /// Collection of currently connected clients.
  final Set<Client> clients = new Set<Client>();

  /// Collection of currently running isolates.
  RunningIsolates runningIsolates = new RunningIsolates();

  /// A port used to receive events from the VM.
  final RawReceivePort eventPort;

  final devfs = new DevFS();

  void _addClient(Client client) {
    assert(client.streams.isEmpty);
    clients.add(client);
  }

  void _removeClient(Client client) {
    clients.remove(client);
    for (var streamId in client.streams) {
      if (!_isAnyClientSubscribed(streamId)) {
        _vmCancelStream(streamId);
      }
    }
  }

  void _eventMessageHandler(List eventMessage) {
    var streamId = eventMessage[0];
    var event = eventMessage[1];
    for (var client in clients) {
      if (client.sendEvents && client.streams.contains(streamId)) {
        client.post(event);
      }
    }
  }

  void _controlMessageHandler(int code,
                              int portId,
                              SendPort sp,
                              String name) {
    switch (code) {
      case Constants.ISOLATE_STARTUP_MESSAGE_ID:
        runningIsolates.isolateStartup(portId, sp, name);
      break;
      case Constants.ISOLATE_SHUTDOWN_MESSAGE_ID:
        runningIsolates.isolateShutdown(portId, sp);
        IsolateEmbedderData ied = isolateEmbedderData.remove(portId);
        if (ied != null) {
          ied.cleanup();
        }
      break;
    }
  }

  Future<Null> _serverMessageHandler(int code, SendPort sp, bool enable) async {
    switch (code) {
      case Constants.WEB_SERVER_CONTROL_MESSAGE_ID:
        if (VMServiceEmbedderHooks.webServerControl == null) {
          sp.send(null);
          return;
        }
        Uri uri = await VMServiceEmbedderHooks.webServerControl(enable);
        sp.send(uri);
      break;
      case Constants.SERVER_INFO_MESSAGE_ID:
        if (VMServiceEmbedderHooks.serverInformation == null) {
          sp.send(null);
          return;
        }
        Uri uri = await VMServiceEmbedderHooks.serverInformation();
        sp.send(uri);
      break;
    }
  }

  Future _exit() async {
    // Stop the server.
    if (VMServiceEmbedderHooks.serverStop != null) {
      await VMServiceEmbedderHooks.serverStop();
    }

    // Close receive ports.
    isolateControlPort.close();
    scriptLoadPort.close();

    // Create a copy of the set as a list because client.disconnect() will
    // alter the connected clients set.
    var clientsList = clients.toList();
    for (var client in clientsList) {
      client.disconnect();
    }
    devfs.cleanup();
    if (VMServiceEmbedderHooks.cleanup != null) {
      await VMServiceEmbedderHooks.cleanup();
    }
    // Notify the VM that we have exited.
    _onExit();
  }

  void messageHandler(message) {
    if (message is List) {
      if (message.length == 2) {
        // This is an event.
        assert(message[0] is String);
        assert(message[1] is String || message[1] is Uint8List);
        _eventMessageHandler(message);
        return;
      }
      if (message.length == 1) {
        // This is a control message directing the vm service to exit.
        assert(message[0] == Constants.SERVICE_EXIT_MESSAGE_ID);
        _exit();
        return;
      }
      if (message.length == 3) {
        // This is a message interacting with the web server.
        assert((message[0] == Constants.WEB_SERVER_CONTROL_MESSAGE_ID) ||
               (message[0] == Constants.SERVER_INFO_MESSAGE_ID));
        _serverMessageHandler(message[0], message[1], message[2]);
        return;
      }
      if (message.length == 4) {
        // This is a message informing us of the birth or death of an
        // isolate.
        _controlMessageHandler(message[0], message[1], message[2], message[3]);
        return;
      }
    }
    print('Internal vm-service error: ignoring illegal message: $message');
  }

  VMService._internal()
      : eventPort = isolateControlPort {
    eventPort.handler = messageHandler;
  }

  factory VMService() {
    if (VMService._instance == null) {
      VMService._instance = new VMService._internal();
      _onStart();
    }
    return _instance;
  }

  bool _isAnyClientSubscribed(String streamId) {
    for (var client in clients) {
      if (client.streams.contains(streamId)) {
        return true;
      }
    }
    return false;
  }

  Future<String> _streamListen(Message message) async {
    var client = message.client;
    var streamId = message.params['streamId'];

    if (client.streams.contains(streamId)) {
      return encodeRpcError(message, kStreamAlreadySubscribed);
    }
    if (!_isAnyClientSubscribed(streamId)) {
      if (!_vmListenStream(streamId)) {
        return encodeRpcError(
            message, kInvalidParams,
            details:"streamListen: invalid 'streamId' parameter: ${streamId}");
      }
    }
    client.streams.add(streamId);

    return encodeSuccess(message);
  }

  Future<String> _streamCancel(Message message) async {
    var client = message.client;
    var streamId = message.params['streamId'];

    if (!client.streams.contains(streamId)) {
      return encodeRpcError(message, kStreamNotSubscribed);
    }
    client.streams.remove(streamId);
    if (!_isAnyClientSubscribed(streamId)) {
      _vmCancelStream(streamId);
    }

    return encodeSuccess(message);
  }

  Future<String> _spawnUri(Message message) async {
    var token = message.params['token'];
    if (token == null) {
      return encodeMissingParamError(message, 'token');
    }
    if (token is! String) {
      return encodeInvalidParamError(message, 'token');
    }
    var uri = message.params['uri'];
    if (uri == null) {
      return encodeMissingParamError(message, 'uri');
    }
    if (uri is! String) {
      return encodeInvalidParamError(message, 'uri');
    }
    var args = message.params['args'];
    if (args != null &&
        args is! List<String>) {
      return encodeInvalidParamError(message, 'args');
    }
    var msg = message.params['message'];

    Isolate.spawnUri(Uri.parse(uri), args, msg).then((isolate) {
      _spawnUriNotify(isolate.controlPort, token);
    }).catchError((e) {
      _spawnUriNotify(e.toString(), token);
    });

    return encodeSuccess(message);
  }

  static responseAsJson(portResponse) {
    if (portResponse is String) {
      return JSON.decode(portResponse);
    } else {
      var cstring = portResponse[0];
      return JSON.fuse(UTF8).decode(cstring);
    }
  }

  // TODO(johnmccutchan): Turn this into a command line tool that uses the
  // service library.
  Future<String> _getCrashDump(Message message) async {
    var client = message.client;
    final perIsolateRequests = [
        // ?isolateId=<isolate id> will be appended to each of these requests.
        // Isolate information.
        Uri.parse('getIsolate'),
        // State of heap.
        Uri.parse('_getAllocationProfile'),
        // Call stack + local variables.
        Uri.parse('getStack?_full=true'),
    ];

    // Snapshot of running isolates.
    var isolates = runningIsolates.isolates.values.toList();

    // Collect the mapping from request uris to responses.
    var responses = {
    };

    // Request VM.
    var getVM = Uri.parse('getVM');
    var getVmResponse = responseAsJson(
        await new Message.fromUri(client, getVM).sendToVM());
    responses[getVM.toString()] = getVmResponse['result'];

    // Request command line flags.
    var getFlagList = Uri.parse('getFlagList');
    var getFlagListResponse = responseAsJson(
        await new Message.fromUri(client, getFlagList).sendToVM());
    responses[getFlagList.toString()] = getFlagListResponse['result'];

    // Make requests to each isolate.
    for (var isolate in isolates) {
      for (var request in perIsolateRequests) {
        var message = new Message.forIsolate(client, request, isolate);
        // Decode the JSON and and insert it into the map. The map key
        // is the request Uri.
        var response = responseAsJson(await isolate.route(message));
        responses[message.toUri().toString()] = response['result'];
      }
      // Dump the object id ring requests.
      var message =
          new Message.forIsolate(client, Uri.parse('_dumpIdZone'), isolate);
      var response = responseAsJson(await isolate.route(message));
      // Insert getObject requests into responses map.
      for (var object in response['result']['objects']) {
        final requestUri =
            'getObject&isolateId=${isolate.serviceId}?objectId=${object["id"]}';
        responses[requestUri] = object;
      }
    }

    // Encode the entire crash dump.
    return encodeResult(message, responses);
  }

  Future<String> route(Message message) {
    if (message.completed) {
      return message.response;
    }
    // TODO(turnidge): Update to json rpc.  BEFORE SUBMIT.
    if (message.method == '_getCrashDump') {
      return _getCrashDump(message);
    }
    if (message.method == 'streamListen') {
      return _streamListen(message);
    }
    if (message.method == 'streamCancel') {
      return _streamCancel(message);
    }
    if (message.method == '_spawnUri') {
      return _spawnUri(message);
    }
    if (devfs.shouldHandleMessage(message)) {
      return devfs.handleMessage(message);
    }
    if (message.params['isolateId'] != null) {
      return runningIsolates.route(message);
    }
    return message.sendToVM();
  }
}

RawReceivePort boot() {
  // Return the port we expect isolate control messages on.
  return isolateControlPort;
}

void _registerIsolate(int port_id, SendPort sp, String name) {
  var service = new VMService();
  service.runningIsolates.isolateStartup(port_id, sp, name);
}

/// Notify the VM that the service is running.
external void _onStart();

/// Notify the VM that the service is no longer running.
external void _onExit();

/// Notify the VM that the server's address has changed.
external void onServerAddressChange(String address);

/// Subscribe to a service stream.
external bool _vmListenStream(String streamId);

/// Cancel a subscription to a service stream.
external void _vmCancelStream(String streamId);

/// Get the bytes to the tar archive.
external Uint8List _requestAssets();

/// Notify the vm service that an isolate has been spawned via rpc.
external void _spawnUriNotify(obj, String token);
