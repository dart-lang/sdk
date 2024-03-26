// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../dtd.dart';

typedef DTDServiceCallback = Future<Map<String, Object?>> Function(
  Parameters params,
);

// TODO(danchevalier): add a serviceMethodIsAvailable experience. it will listen
// to a stream that announces servicemethods getting registered and
// unregistered. The state can then be presented as a listenable so that clients
// can gate their behaviour on a serviceMethod going up/down.

/// A connection to a Dart Tooling Daemon instance.
///
/// The base interactions for Dart Tooling Daemon are found here.
class DartToolingDaemon {
  DartToolingDaemon._(StreamChannel connectionChannel)
      : _clientPeer = Peer(connectionChannel.cast<String>()) {
    _clientPeer.registerMethod('streamNotify', (Parameters params) {
      final streamId = params['streamId'].asString;
      final eventKind = params['eventKind'].asString;
      final eventData = params['eventData'].asMap as Map<String, Object?>;
      final timestamp = params['timestamp'].asInt;

      _subscribedStreamControllers[streamId]?.add(
        DTDEvent(
          streamId,
          eventKind,
          eventData,
          timestamp,
        ),
      );
    });

    _done = _clientPeer.listen();
  }

  /// Connects to a Dart Tooling Daemon instance.
  ///
  /// ```dart
  /// final uri = Uri.parse('ws://127.0.0.1:59247/em6ZgeqMpvV8tOKg');
  /// final client = DartToolingDaemon.connectToDaemonAt(uri);
  /// ```
  static Future<DartToolingDaemon> connect(Uri uri) async {
    final channel = WebSocketChannel.connect(uri);
    return DartToolingDaemon._(channel);
  }

  late final Peer _clientPeer;
  late final Future _done;
  final _subscribedStreamControllers = <String, StreamController<DTDEvent>>{};

  /// Terminates the connection with the Dart Tooling Daemon.
  Future<void> close() => _clientPeer.close();

  /// A [Future] that completes when the connection with the Dart Tooling Daemon
  /// is terminated.
  Future<void> get done => _done;

  /// Registers this client as the handler for the [service].[method] service
  /// method.
  ///
  /// If the [service] has already been registered by another client, then an
  /// [RpcException] with [RpcErrorCodes.kServiceAlreadyRegistered] is thrown.
  /// Only one client at a time may register to a [service]. Once a client
  /// disconnects then another client may register services under than name.
  ///
  /// If the [method] has already been registered on the [service], then an
  /// [RpcException] with [RpcErrorCodes.kServiceMethodAlreadyRegistered] is
  /// thrown.
  Future<void> registerService(
    String service,
    String method,
    DTDServiceCallback callback,
  ) async {
    final combinedName = '$service.$method';
    await _clientPeer.sendRequest('registerService', {
      'service': service,
      'method': method,
    });

    _clientPeer.registerMethod(
      combinedName,
      callback,
    );
  }

  /// Subscribes this client to events posted on [streamId].
  ///
  /// Once called, the Dart Tooling Daemon will then send any events on the
  /// [streamId] to this instance of [DartToolingDaemon]. See [onEvent] for
  /// details on how to get access to that [Stream] of [DTDEvent]s.
  ///
  /// If this client is already subscribed to [streamId], an [RpcException] with
  /// [RpcErrorCodes.kStreamAlreadySubscribed] will be thrown.
  Future<void> streamListen(String streamId) {
    return _clientPeer.sendRequest(
      'streamListen',
      {
        'streamId': streamId,
      },
    );
  }

  /// Cancel the subscription to [streamId].
  ///
  /// Once called, this connection will no longer receive events posted on
  /// [streamId].
  ///
  /// If this client was not subscribed to [streamId], an [RpcException] with
  /// [RpcErrorCodes.kStreamNotSubscribed] will be thrown.
  Future<void> streamCancel(String streamId) {
    return _clientPeer.sendRequest(
      'streamCancel',
      {
        'streamId': streamId,
      },
    );
  }

  /// Creates a [Stream] for events received on [streamId].
  ///
  /// This method should be called before calling [streamListen] to ensure
  /// events aren't dropped.
  Stream<DTDEvent> onEvent(String streamId) {
    return _subscribedStreamControllers
        .putIfAbsent(
          streamId,
          StreamController<DTDEvent>.new,
        )
        .stream;
  }

  /// Posts a [DTDEvent] with [eventData] to [streamId].
  ///
  /// The Dart Tooling Daemon will forward the [DTDEvent] to all clients that
  /// have subscribed to [streamId] by calling [streamListen].
  ///
  /// If no clients are listening to [streamId], the event will be dropped.
  Future<void> postEvent(
    String streamId,
    String eventKind,
    Map<String, Object?> eventData,
  ) async {
    await _clientPeer.sendRequest(
      'postEvent',
      {
        'streamId': streamId,
        'eventKind': eventKind,
        'eventData': eventData,
      },
    );
  }

  /// Invokes the service method registered with the name
  /// `[serviceName].[methodName]`.
  ///
  /// If provided, [params] will be sent as the set of parameters used when
  /// invoking the service.
  ///
  /// If `[serviceName].[methodName]` is not a registered service method, an
  /// [RpcException] will be thrown with [RpcErrorCodes.kMethodNotFound].
  ///
  /// If the parameters included in [params] are invalid, an [RpcException] will
  /// be thrown with [RpcErrorCodes.kInvalidParams].
  Future<DTDResponse> call(
    String serviceName,
    String methodName, {
    Map<String, Object>? params,
  }) async {
    final json = await _clientPeer.sendRequest(
      '$serviceName.$methodName',
      params ?? <String, dynamic>{},
    ) as Map<String, Object?>;

    final type = json['type'] as String?;
    if (type == null) {
      throw DartToolingDaemonConnectionException.callResponseMissingType(json);
    }

    //TODO(danchevalier): Find out how to get access to the id.
    return DTDResponse('-1', type, json);
  }

  /// Reads the file at [uri] from disk in the environment where the Dart
  /// Tooling Daemon is running.
  ///
  /// If [uri] is not contained in the IDE workspace roots, then an
  /// [RpcException] with [RpcErrorCodes.kPermissionDenied] is thrown.
  ///
  /// If [uri] does not exist, then an [RpcException] exception with error
  /// code [RpcErrorCodes.kFileDoesNotExist] is thrown.
  ///
  /// If [uri] does not have a file scheme, then an [RpcException] with
  /// [RpcErrorCodes.kExpectsUriParamWithFileScheme] is thrown.
  Future<FileContent> readFileAsString(
    Uri uri, {
    Encoding encoding = utf8,
  }) async {
    final result = await call(
      kFileSystemServiceName,
      'readFileAsString',
      params: {
        'uri': uri.toString(),
        'encoding': encoding.name,
      },
    );
    return FileContent.fromDTDResponse(result);
  }

  /// Writes [contents] to the file at [uri] in the environment where the Dart
  /// Tooling Daemon is running.
  ///
  /// The file will be created if it does not exist, and it will be overwritten
  /// if it already exist.
  ///
  /// If [uri] is not contained in the IDE workspace roots, then an
  /// [RpcException] with [RpcErrorCodes.kPermissionDenied] is thrown.
  ///
  /// If [uri] does not have a file scheme, then an [RpcException] with
  /// [RpcErrorCodes.kExpectsUriParamWithFileScheme] is thrown.
  Future<void> writeFileAsString(
    Uri uri,
    String contents, {
    Encoding encoding = utf8,
  }) async {
    await call(
      kFileSystemServiceName,
      'writeFileAsString',
      params: {
        'uri': uri.toString(),
        'contents': contents,
        'encoding': encoding.name,
      },
    );
  }

  /// Lists the directories and files under the directory at [uri] in the
  /// environment where the Dart Tooling Daemon is running.
  ///
  /// If [uri] is not a directory, throws an [RpcException] exception with error
  /// code [RpcErrorCodes.kDirectoryDoesNotExist].
  ///
  /// If [uri] is not contained in the IDE workspace roots, then an
  /// [RpcException] with [RpcErrorCodes.kPermissionDenied] is thrown.
  ///
  /// If [uri] does not have a file scheme, then an [RpcException] with
  /// [RpcErrorCodes.kExpectsUriParamWithFileScheme] is thrown.
  Future<UriList> listDirectoryContents(Uri uri) async {
    final result = await call(
      kFileSystemServiceName,
      'listDirectoryContents',
      params: {
        'uri': uri.toString(),
      },
    );
    return UriList.fromDTDResponse(result);
  }

  /// Sets the IDE workspace roots for the FileSystem service.
  ///
  /// This is a privileged RPC that require's a [secret], which is provided by
  /// the Dart Tooling Daemon, to be called successfully. This secret is
  /// generated by the daemon and provided to its spawner to ensure only trusted
  /// clients can set workspace roots. If [secret] is invalid, an [RpcException]
  /// with error code [RpcErrorCodes.kPermissionDenied] is thrown.
  ///
  /// If [secret] does not match the secret created when Dart Tooling Daemon was
  /// created, then an [RpcException] with [RpcErrorCodes.kPermissionDenied] is
  /// thrown.
  ///
  /// If one of the [roots] is missing a "file" scheme then an [RpcException]
  /// with [RpcErrorCodes.kExpectsUriParamWithFileScheme] is thrown.
  Future<void> setIDEWorkspaceRoots(String secret, List<Uri> roots) async {
    await call(
      kFileSystemServiceName,
      'setIDEWorkspaceRoots',
      params: {
        'roots': roots.map<String>((e) => e.toString()).toList(),
        'secret': secret,
      },
    );
  }

  /// Gets the IDE workspace roots for the FileSystem service.
  Future<IDEWorkspaceRoots> getIDEWorkspaceRoots() async {
    final result = await call(
      kFileSystemServiceName,
      'getIDEWorkspaceRoots',
    );
    return IDEWorkspaceRoots.fromDTDResponse(result);
  }

  /// Gets the project roots contained within the current set of IDE workspace
  /// roots.
  ///
  /// A project root is any directory that contains a 'pubspec.yaml' file. If
  /// IDE workspace roots are not set, or if there are no project roots within
  /// the IDE workspace roots, this method will return an empty [UriList].
  ///
  /// [depth] is the maximum depth that each IDE workspace root directory tree
  /// will be searched for project roots.
  Future<UriList> getProjectRoots({
    int depth = defaultGetProjectRootsDepth,
  }) async {
    final result = await call(
      kFileSystemServiceName,
      'getProjectRoots',
      params: {'depth': depth},
    );
    return UriList.fromDTDResponse(result);
  }
}

/// Represents the response of an RPC call to the Dart Tooling Daemon.
class DTDResponse {
  DTDResponse(this._id, this._type, this._result);

  DTDResponse.fromDTDResponse(DTDResponse other)
      : this(
          other.id,
          other.type,
          other.result,
        );
  final String _id;
  final String _type;
  final Map<String, Object?> _result;

  String get id => _id;

  String get type => _type;

  Map<String, Object?> get result => _result;
}

/// A Dart Tooling Daemon stream event.
class DTDEvent {
  DTDEvent(this.stream, this.kind, this.data, this.timestamp);
  String stream;
  int timestamp;
  String kind;
  Map<String, Object?> data;

  @override
  String toString() {
    return jsonEncode({
      'stream': stream,
      'timestamp': timestamp,
      'kind': kind,
      'data': data,
    });
  }
}

class DartToolingDaemonConnectionException implements Exception {
  static const int callParamsMissingTypeError = 1;

  /// The response to a call method is missing the top level type parameter.
  factory DartToolingDaemonConnectionException.callResponseMissingType(
    Map<String, Object?> json,
  ) {
    return DartToolingDaemonConnectionException._(
      callParamsMissingTypeError,
      'call received an invalid response, '
      "it is missing the 'type' param. Got: $json",
    );
  }
  DartToolingDaemonConnectionException._(this.errorCode, this.message);

  @override
  String toString() => 'DartToolingDaemonConnectionException: $message';

  final int errorCode;
  final String message;
}
