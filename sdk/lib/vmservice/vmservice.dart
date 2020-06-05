// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

library dart._vmservice;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
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
part 'named_lookup.dart';

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
  return base64Url.encode(bytes);
}

// The randomly generated auth token used to access the VM service.
final String serviceAuthToken = _makeAuthToken();

// This is for use by the embedder. It is a map from the isolateId to
// anything implementing IsolateEmbedderData. When an isolate goes away,
// the cleanup method will be invoked after being removed from the map.
final Map<int, IsolateEmbedderData> isolateEmbedderData =
    new Map<int, IsolateEmbedderData>();

// These must be kept in sync with the declarations in vm/json_stream.h and
// pkg/dds/lib/src/stream_manager.dart.
const kParseError = -32700;
const kInvalidRequest = -32600;
const kMethodNotFound = -32601;
const kInvalidParams = -32602;
const kInternalError = -32603;

const kExtensionError = -32000;

const kFeatureDisabled = 100;
const kCannotAddBreakpoint = 102;
const kStreamAlreadySubscribed = 103;
const kStreamNotSubscribed = 104;
const kIsolateMustBeRunnable = 105;
const kIsolateMustBePaused = 106;
const kCannotResume = 107;
const kIsolateIsReloading = 108;
const kIsolateReloadBarred = 109;
const kIsolateMustHaveReloaded = 110;
const kServiceAlreadyRegistered = 111;
const kServiceDisappeared = 112;
const kExpressionCompilationError = 113;
const kInvalidTimelineRequest = 114;

// Experimental (used in private rpcs).
const kFileSystemAlreadyExists = 1001;
const kFileSystemDoesNotExist = 1002;
const kFileDoesNotExist = 1003;

var _errorMessages = {
  kInvalidParams: 'Invalid params',
  kInternalError: 'Internal error',
  kFeatureDisabled: 'Feature is disabled',
  kStreamAlreadySubscribed: 'Stream already subscribed',
  kStreamNotSubscribed: 'Stream not subscribed',
  kFileSystemAlreadyExists: 'File system already exists',
  kFileSystemDoesNotExist: 'File system does not exist',
  kFileDoesNotExist: 'File does not exist',
  kServiceAlreadyRegistered: 'Service already registered',
  kServiceDisappeared: 'Service has disappeared',
  kExpressionCompilationError: 'Expression compilation error',
  kInvalidTimelineRequest: 'The timeline related request could not be completed'
      'due to the current configuration',
};

String encodeRpcError(Message message, int code, {String details}) {
  var response = {
    'jsonrpc': '2.0',
    'id': message.serial,
    'error': {
      'code': code,
      'message': _errorMessages[code],
    },
  };
  if (details != null) {
    response['error']['data'] = {
      'details': details,
    };
  }
  return json.encode(response);
}

String encodeMissingParamError(Message message, String param) {
  return encodeRpcError(message, kInvalidParams,
      details: "${message.method} expects the '${param}' parameter");
}

String encodeInvalidParamError(Message message, String param) {
  var value = message.params[param];
  return encodeRpcError(message, kInvalidParams,
      details: "${message.method}: invalid '${param}' parameter: ${value}");
}

String encodeCompilationError(Message message, String diagnostic) {
  return encodeRpcError(message, kExpressionCompilationError,
      details: diagnostic);
}

String encodeResult(Message message, Map result) {
  var response = {
    'jsonrpc': '2.0',
    'id': message.serial,
    'result': result,
  };
  return json.encode(response);
}

String encodeSuccess(Message message) {
  return encodeResult(message, {'type': 'Success'});
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
typedef Future<List<Map<String, dynamic>>> ListFilesCallback(Uri path);

/// Called when we need information about the server.
typedef Future<Uri> ServerInformamessage_routertionCallback();

/// Called when we need information about the server.
typedef Future<Uri> ServerInformationCallback();

/// Called when we want to [enable] or disable the web server.
typedef Future<Uri> WebServerControlCallback(bool enable);

/// Called when we want to [enable] or disable new websocket connections to the
/// server.
typedef void WebServerAcceptNewWebSocketConnectionsCallback(bool enable);

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
  static WebServerAcceptNewWebSocketConnectionsCallback
      acceptNewWebSocketConnections;
}

class _ClientResumePermissions {
  final List<Client> clients = [];
  int permissionsMask = 0;
}

class VMService extends MessageRouter {
  static VMService _instance;

  static const serviceNamespace = 's';

  /// Collection of currently connected clients.
  final NamedLookup<Client> clients =
      new NamedLookup<Client>(prologue: serviceNamespace);
  final IdGenerator _serviceRequests = new IdGenerator(prologue: 'sr');

  /// Mapping of client names to all clients of that name and their resume
  /// permissions.
  final Map<String, _ClientResumePermissions> clientResumePermissions = {};

  /// Collection of currently running isolates.
  RunningIsolates runningIsolates = new RunningIsolates();

  /// Flag to indicate VM service is exiting.
  bool isExiting = false;

  /// A port used to receive events from the VM.
  final RawReceivePort eventPort;

  final devfs = new DevFS();

  Uri get ddsUri => _ddsUri;
  Uri _ddsUri;

  Future<String> _yieldControlToDDS(Message message) async {
    final acceptNewWebSocketConnections =
        VMServiceEmbedderHooks.acceptNewWebSocketConnections;
    if (acceptNewWebSocketConnections == null) {
      return encodeRpcError(message, kFeatureDisabled,
          details:
              'Embedder does not support yielding to a VM service intermediary.');
    }
    final uri = message.params['uri'];
    if (uri == null) {
      return encodeMissingParamError(message, 'uri');
    }
    // DDS can only take control if there is no other clients connected
    // directly to the VM service.
    if (clients.length > 1) {
      return encodeRpcError(message, kFeatureDisabled,
          details:
              'Existing VM service clients prevent DDS from taking control.');
    }
    acceptNewWebSocketConnections(false);
    _ddsUri = Uri.parse(uri);
    return encodeSuccess(message);
  }

  void _clearClientName(Client client) {
    final name = client.name;
    client.name = null;
    final clientsForName = clientResumePermissions[name];
    if (clientsForName != null) {
      clientsForName.clients.remove(client);
      // If this was the last client with a given name, cleanup resume
      // permissions.
      if (clientsForName.clients.isEmpty) {
        clientResumePermissions.remove(name);

        // Check to see if we need to resume any isolates now that the last
        // client of a given name has disconnected or changed names.
        //
        // An isolate will be resumed in this situation if:
        //
        // 1) This client required resume approvals for the current pause event
        // associated with the isolate and all other required resume approvals
        // have been provided by other clients.
        //
        // OR
        //
        // 2) This client required resume approvals for the current pause event
        // associated with the isolate, no other clients require resume approvals
        // for the current pause event, and at least one client has issued a resume
        // request.
        runningIsolates.isolates.forEach((_, isolate) async =>
            await isolate.maybeResumeAfterClientChange(this, name));
      }
    }
  }

  /// Sets the name associated with a [Client].
  ///
  /// If any resume approvals were set for this client previously they will
  /// need to be reset after a name change.
  String _setClientName(Message message) {
    final client = message.client;
    if (!message.params.containsKey('name')) {
      return encodeRpcError(message, kInvalidParams,
          details: "setClientName: missing required parameter 'name'");
    }
    final name = message.params['name'];
    if (name is! String) {
      return encodeRpcError(message, kInvalidParams,
          details: "setClientName: invalid 'name' parameter: $name");
    }
    _setClientNameHelper(client, name);
    return encodeSuccess(message);
  }

  void _setClientNameHelper(Client client, String name) {
    _clearClientName(client);
    client.name = name.isEmpty ? client.defaultClientName : name;
    clientResumePermissions.putIfAbsent(
        client.name, () => _ClientResumePermissions());
    clientResumePermissions[client.name].clients.add(client);
  }

  String _getClientName(Message message) => encodeResult(message, {
        'type': 'ClientName',
        'name': message.client.name,
      });

  String _requirePermissionToResume(Message message) {
    bool parsePermission(String argName) {
      final arg = message.params[argName];
      if (arg == null) {
        return false;
      }
      if (arg is! bool) {
        throw encodeRpcError(message, kInvalidParams,
            details: "requirePermissionToResume: invalid '$argName': $arg");
      }
      return arg;
    }

    final client = message.client;
    int pauseTypeMask = 0;
    try {
      if (parsePermission('onPauseStart')) {
        pauseTypeMask |= RunningIsolate.kPauseOnStartMask;
      }
      if (parsePermission('onPauseReload')) {
        pauseTypeMask |= RunningIsolate.kPauseOnReloadMask;
      }
      if (parsePermission('onPauseExit')) {
        pauseTypeMask |= RunningIsolate.kPauseOnExitMask;
      }
    } catch (rpcError) {
      return rpcError;
    }

    clientResumePermissions[client.name].permissionsMask = pauseTypeMask;
    return encodeSuccess(message);
  }

  void _addClient(Client client) {
    assert(client.streams.isEmpty);
    assert(client.services.isEmpty);
    _setClientNameHelper(client, client.defaultClientName);
    clients.add(client);
  }

  void _removeClient(Client client) {
    final namespace = clients.keyOf(client);
    clients.remove(client);
    for (var streamId in client.streams) {
      if (!_isAnyClientSubscribed(streamId)) {
        _vmCancelStream(streamId);
      }
    }

    // Clean up client approvals state.
    _clearClientName(client);

    for (var service in client.services.keys) {
      _eventMessageHandler(
          'Service',
          new Response.json({
            'jsonrpc': '2.0',
            'method': 'streamNotify',
            'params': {
              'streamId': 'Service',
              'event': {
                "type": "Event",
                "kind": "ServiceUnregistered",
                'timestamp': new DateTime.now().millisecondsSinceEpoch,
                'service': service,
                'method': namespace + '.' + service,
              }
            }
          }));
    }
    // Complete all requests as failed
    for (var handle in client.serviceHandles.values) {
      handle(null);
    }
    if (clients.isEmpty) {
      // If DDS was connected, we are in single client mode and need to
      // allow for new websocket connections.
      final acceptNewWebSocketConnections =
          VMServiceEmbedderHooks.acceptNewWebSocketConnections;
      if (_ddsUri != null && acceptNewWebSocketConnections != null) {
        acceptNewWebSocketConnections(true);
        _ddsUri = null;
      }
    }
  }

  void _eventMessageHandler(String streamId, Response event) {
    for (var client in clients) {
      if (client.sendEvents && client.streams.contains(streamId)) {
        client.post(event);
      }
    }
  }

  void _controlMessageHandler(int code, int portId, SendPort sp, String name) {
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

  Future<Null> _handleNativeRpcCall(message, SendPort replyPort) async {
    // Keep in sync with "runtime/vm/service_isolate.cc:InvokeServiceRpc".
    Response response;

    try {
      final Message rpc = new Message.fromJsonRpc(
          null, json.decode(utf8.decode(message as List<int>)));
      if (rpc.type != MessageType.Request) {
        response = new Response.internalError(
            'The client sent a non-request json-rpc message.');
      } else {
        response = await routeRequest(this, rpc);
      }
    } catch (exception) {
      response = new Response.internalError(
          'The rpc call resulted in exception: $exception.');
    }
    List<int> bytes;
    switch (response.kind) {
      case ResponsePayloadKind.String:
        bytes = utf8.encode(response.payload);
        bytes = bytes is Uint8List ? bytes : new Uint8List.fromList(bytes);
        break;
      case ResponsePayloadKind.Binary:
      case ResponsePayloadKind.Utf8String:
        bytes = response.payload as Uint8List;
        break;
    }
    replyPort.send(bytes);
  }

  Future _exit() async {
    isExiting = true;

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
        _eventMessageHandler(message[0], new Response.from(message[1]));
        return;
      }
      if (message.length == 1) {
        // This is a control message directing the vm service to exit.
        assert(message[0] == Constants.SERVICE_EXIT_MESSAGE_ID);
        _exit();
        return;
      }
      if (message.length == 3) {
        final opcode = message[0];
        if (opcode == Constants.METHOD_CALL_FROM_NATIVE) {
          _handleNativeRpcCall(message[1], message[2]);
          return;
        } else {
          // This is a message interacting with the web server.
          assert((opcode == Constants.WEB_SERVER_CONTROL_MESSAGE_ID) ||
              (opcode == Constants.SERVER_INFO_MESSAGE_ID));
          _serverMessageHandler(message[0], message[1], message[2]);
          return;
        }
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

  VMService._internal() : eventPort = isolateControlPort {
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

  Client _findFirstClientThatHandlesService(String service) {
    if (clients != null) {
      for (Client c in clients) {
        if (c.services.containsKey(service)) {
          return c;
        }
      }
    }
    return null;
  }

  static const kServiceStream = 'Service';
  static const serviceStreams = const [kServiceStream];

  Future<String> _streamListen(Message message) async {
    var client = message.client;
    var streamId = message.params['streamId'];

    if (client.streams.contains(streamId)) {
      return encodeRpcError(message, kStreamAlreadySubscribed);
    }
    if (!_isAnyClientSubscribed(streamId)) {
      if (!serviceStreams.contains(streamId) && !_vmListenStream(streamId)) {
        return encodeRpcError(message, kInvalidParams,
            details: "streamListen: invalid 'streamId' parameter: ${streamId}");
      }
    }

    // Some streams can generate events or side effects after registration
    switch (streamId) {
      case kServiceStream:
        for (Client c in clients) {
          if (c == client) continue;
          for (String service in c.services.keys) {
            _sendServiceRegisteredEvent(c, service, target: client);
          }
        }
        ;
        break;
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
    if (!serviceStreams.contains(streamId) &&
        !_isAnyClientSubscribed(streamId)) {
      _vmCancelStream(streamId);
    }

    return encodeSuccess(message);
  }

  static bool _hasNamespace(String method) =>
      method.contains('.') &&
      _getNamespace(method).startsWith(serviceNamespace);
  static String _getNamespace(String method) => method.split('.').first;
  static String _getMethod(String method) => method.split('.').last;

  Future<String> _registerService(Message message) async {
    final client = message.client;
    final service = message.params['service'];
    final alias = message.params['alias'];

    if (service is! String || service == '') {
      return encodeRpcError(message, kInvalidParams,
          details: "registerService: invalid 'service' parameter: ${service}");
    }
    if (alias is! String || alias == '') {
      return encodeRpcError(message, kInvalidParams,
          details: "registerService: invalid 'alias' parameter: ${alias}");
    }
    if (client.services.containsKey(service)) {
      return encodeRpcError(message, kServiceAlreadyRegistered);
    }
    client.services[service] = alias;

    bool removed;
    try {
      // Do not send streaming events to the client which registers the service
      removed = client.streams.remove(kServiceStream);
      await _sendServiceRegisteredEvent(client, service);
    } finally {
      if (removed) client.streams.add(kServiceStream);
    }

    return encodeSuccess(message);
  }

  _sendServiceRegisteredEvent(Client client, String service,
      {Client target}) async {
    final namespace = clients.keyOf(client);
    final alias = client.services[service];
    final event = new Response.json({
      'jsonrpc': '2.0',
      'method': 'streamNotify',
      'params': {
        'streamId': kServiceStream,
        'event': {
          "type": "Event",
          "kind": "ServiceRegistered",
          'timestamp': new DateTime.now().millisecondsSinceEpoch,
          'service': service,
          'method': namespace + '.' + service,
          'alias': alias
        }
      }
    });
    if (target == null) {
      _eventMessageHandler(kServiceStream, event);
    } else {
      target.post(event);
    }
  }

  Future<String> _handleService(Message message) async {
    final namespace = _getNamespace(message.method);
    final method = _getMethod(message.method);
    final client = clients[namespace];
    if (client != null) {
      if (client.services.containsKey(method)) {
        final id = _serviceRequests.newId();
        final oldId = message.serial;
        final completer = new Completer<String>();
        client.serviceHandles[id] = (Message m) {
          if (m != null) {
            completer.complete(json.encode(m.forwardToJson({'id': oldId})));
          } else {
            completer.complete(encodeRpcError(message, kServiceDisappeared));
          }
        };
        client.post(new Response.json(
            message.forwardToJson({'id': id, 'method': method})));
        return completer.future;
      }
    }
    return encodeRpcError(message, kMethodNotFound,
        details: "Unknown service: ${message.method}");
  }

  Future<String> _getSupportedProtocols(Message message) async {
    final version = json.decode(
      utf8.decode(
        (await Message.forMethod('getVersion').sendToVM()).payload,
      ),
    )['result'];
    final protocols = {
      'type': 'ProtocolList',
      'protocols': [
        {
          'protocolName': 'VM Service',
          'major': version['major'],
          'minor': version['minor'],
        },
      ],
    };
    return encodeResult(message, protocols);
  }

  Future<Response> routeRequest(VMService _, Message message) async {
    final response = await _routeRequestImpl(message);
    if (response == null) {
      // We should only have a null response for Notifications.
      assert(message.type == MessageType.Notification);
      return null;
    }
    return new Response.from(response);
  }

  Future _routeRequestImpl(Message message) async {
    try {
      if (message.completed) {
        return await message.response;
      }
      if (message.method == '_yieldControlToDDS') {
        return await _yieldControlToDDS(message);
      }
      if (message.method == 'streamListen') {
        return await _streamListen(message);
      }
      if (message.method == 'streamCancel') {
        return await _streamCancel(message);
      }
      if (message.method == 'registerService') {
        return await _registerService(message);
      }
      if (message.method == 'setClientName') {
        return _setClientName(message);
      }
      if (message.method == 'getClientName') {
        return _getClientName(message);
      }
      if (message.method == 'requirePermissionToResume') {
        return _requirePermissionToResume(message);
      }
      if (message.method == 'getSupportedProtocols') {
        return await _getSupportedProtocols(message);
      }
      if (devfs.shouldHandleMessage(message)) {
        return await devfs.handleMessage(message);
      }
      if (_hasNamespace(message.method)) {
        return await _handleService(message);
      }
      if (message.params['isolateId'] != null) {
        return await runningIsolates.routeRequest(this, message);
      }
      return await message.sendToVM();
    } catch (e, st) {
      message.setErrorResponse(kInternalError, 'Unexpected exception:$e\n$st');
      return message.response;
    }
  }

  void routeResponse(message) {
    final client = message.client;
    if (client.serviceHandles.containsKey(message.serial)) {
      client.serviceHandles.remove(message.serial)(message);
      _serviceRequests.release(message.serial);
    }
  }
}

@pragma("vm:entry-point",
    const bool.fromEnvironment("dart.vm.product") ? false : "call")
RawReceivePort boot() {
  // Return the port we expect isolate control messages on.
  return isolateControlPort;
}

@pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
void _registerIsolate(int port_id, SendPort sp, String name) {
  var service = new VMService();
  service.runningIsolates.isolateStartup(port_id, sp, name);
}

/// Notify the VM that the service is running.
void _onStart() native "VMService_OnStart";

/// Notify the VM that the service is no longer running.
void _onExit() native "VMService_OnExit";

/// Notify the VM that the server's address has changed.
void onServerAddressChange(String address)
    native "VMService_OnServerAddressChange";

/// Subscribe to a service stream.
bool _vmListenStream(String streamId) native "VMService_ListenStream";

/// Cancel a subscription to a service stream.
void _vmCancelStream(String streamId) native "VMService_CancelStream";

/// Get the bytes to the tar archive.
Uint8List _requestAssets() native "VMService_RequestAssets";
