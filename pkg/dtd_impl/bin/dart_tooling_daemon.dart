// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dart_service_protocol_shared/dart_service_protocol_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:dtd/dtd.dart' as dtd;
import 'package:dtd/dtd_file_system_service.dart';

import 'constants.dart';
import 'dtd_client.dart';
import 'dtd_client_manager.dart';
import 'dtd_stream_manager.dart';

/// TODO(https://github.com/dart-lang/sdk/issues/54429): Add shutdown behavior.

/// A service that facilitates communication between dart tools.
class DartToolingDaemon {
  DartToolingDaemon._({
    bool ipv6 = false,
    bool shouldLogRequests = false,
  })  : _ipv6 = ipv6,
        _shouldLogRequests = shouldLogRequests {
    streamManager = DTDStreamManager(this);
    clientManager = DTDClientManager();
  }
  static const _kSseHandlerPath = '\$debugHandler';

  /// Manages the streams for the current [DartToolingDaemon] service.
  late final DTDStreamManager streamManager;

  /// Manages the connected clients of the current [DartToolingDaemon] service.
  late final ClientManager clientManager;

  final bool _ipv6;
  late HttpServer _server;
  final bool _shouldLogRequests;

  /// The uri of the current [DartToolingDaemon] service.
  Uri? get uri => _uri;
  Uri? _uri;

  Future<void> _startService() async {
    final host =
        (_ipv6 ? InternetAddress.loopbackIPv6 : InternetAddress.loopbackIPv4)
            .host;
    var port = 0;

    // Start the DTD server. Run in an error Zone to ensure that asynchronous
    // exceptions encountered during request handling are handled, as exceptions
    // thrown during request handling shouldn't take down the entire service.
    late String errorMessage;
    final tmpServer = await runZonedGuarded(
      () async {
        Future<HttpServer?> startServer() async {
          try {
            return await io.serve(_handlers().handler, host, port);
          } on SocketException catch (e) {
            errorMessage = e.message;
            if (e.osError != null) {
              errorMessage += ' (${e.osError!.message})';
            }
            errorMessage += ': ${e.address?.host}:${e.port}';
            return null;
          }
        }

        return await startServer();
      },
      (error, stack) {
        if (_shouldLogRequests) {
          print('Asynchronous error: $error\n$stack');
        }
      },
    );
    if (tmpServer == null) {
      throw DartToolingDaemonException.connectionIssue(errorMessage);
    }
    _server = tmpServer;

    _uri = Uri(
      scheme: 'ws',
      host: host,
      port: _server.port,
      path: '/',
    );
  }

  /// Starts a [DartToolingDaemon] service.
  ///
  /// Set [ipv6] to true to have the service use ipv6 instead of ipv4.
  ///
  /// Set [shouldLogRequests] to true to enable logging.
  static Future<DartToolingDaemon> startService({
    bool ipv6 = false,
    bool shouldLogRequests = false,
  }) async {
    final dtd = DartToolingDaemon._(
      ipv6: ipv6,
      shouldLogRequests: shouldLogRequests,
    );
    await dtd._startService();
    await dtd._startAuxilliaryServices();
    return dtd;
  }

  // Attempt to upgrade HTTP requests to a websocket before processing them as
  // standard HTTP requests. The websocket handler will fail quickly if the
  // request doesn't appear to be a websocket upgrade request.
  Cascade _handlers() {
    return Cascade().add(_webSocketHandler()).add(_sseHandler());
  }

  Handler _webSocketHandler() => webSocketHandler((WebSocketChannel ws) {
        final client = DTDClient.fromWebSocket(
          this,
          ws,
        );
        clientManager.addClient(client);
      });

  Handler _sseHandler() {
    final handler = SseHandler(
      Uri.parse('/$_kSseHandlerPath'),
      keepAlive: sseKeepAlive,
    );

    handler.connections.rest.listen((sseConnection) {
      final client = DTDClient.fromSSEConnection(
        this,
        sseConnection,
      );
      clientManager.addClient(client);
    });

    return handler.handler;
  }

  /// Starts any services that DTD is responsible for starting.
  Future<void> _startAuxilliaryServices() async {
    final fileService = await dtd.DartToolingDaemon.connect(_uri!);
    await DTDFileService.register(fileService);
  }
}

// TODO(danchevalier): clean up these exceptions so they are more relevant to
// DTD. Also add docs to the factories that remain.
class DartToolingDaemonException implements Exception {
  // TODO(danchevalier): add a relevant dart doc here
  static const int existingDtdInstanceError = 1;

  /// Set when the connection to the remote VM service terminates unexpectedly
  /// during Dart Development Service startup.
  static const int failedToStartError = 2;

  /// Set when a connection error has occurred after startup.
  static const int connectionError = 3;

  factory DartToolingDaemonException.existingDtdInstance(
    String message, {
    Uri? dtdUri,
  }) {
    return ExistingDTDImplException._(message, dtdUri: dtdUri);
  }

  factory DartToolingDaemonException.failedToStart() {
    return DartToolingDaemonException._(
      failedToStartError,
      'Failed to start Dart Development Service',
    );
  }

  factory DartToolingDaemonException.connectionIssue(String message) {
    return DartToolingDaemonException._(connectionError, message);
  }

  DartToolingDaemonException._(this.errorCode, this.message);

  @override
  String toString() => 'DartDevelopmentServiceException: $message';

  final int errorCode;
  final String message;
}

class ExistingDTDImplException extends DartToolingDaemonException {
  ExistingDTDImplException._(
    String message, {
    this.dtdUri,
  }) : super._(
          DartToolingDaemonException.existingDtdInstanceError,
          message,
        );

  /// The URI of the existing DTD instance, if available.
  ///
  /// This URL is the base HTTP URI such as `http://127.0.0.1:1234/AbcDefg=/`,
  /// not the WebSocket URI (which can be obtained by mapping the scheme to
  /// `ws` (or `wss`) and appending `ws` to the path segments).
  final Uri? dtdUri;
}
