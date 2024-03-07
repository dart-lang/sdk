// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'src/constants.dart';
import 'src/dtd_client.dart';
import 'src/dtd_client_manager.dart';
import 'src/dtd_stream_manager.dart';
import 'src/file_system_service.dart';

/// Contains all the flags and options used by the DTD argument parser.
enum DartToolingDaemonOptions {
  // Used when executing a training run while generating an AppJIT snapshot as
  // part of an SDK build.
  train(isFlag: true, negatable: false, hide: true),
  machine(
    isFlag: true,
    negatable: false,
    help: 'Sets output format to JSON for consumption in tools.',
  ),
  unrestricted(
    isFlag: true,
    negatable: false,
    help: 'Disables restrictions on services registered by DTD.',
  );

  const DartToolingDaemonOptions({
    required this.isFlag,
    this.negatable = true,
    this.hide = false,
    this.help,
  });

  final bool isFlag;
  final bool negatable;
  final bool hide;
  final String? help;

  /// Returns an argument parser that can be used to configure the daemon.
  static ArgParser createArgParser({
    int? usageLineLength,
  }) {
    final argParser = ArgParser(usageLineLength: usageLineLength);
    for (final entry in DartToolingDaemonOptions.values) {
      if (entry.isFlag) {
        argParser.addFlag(
          entry.name,
          negatable: entry.negatable,
          hide: entry.hide,
          help: entry.help,
        );
      } else {
        throw UnimplementedError('Add support for options');
      }
    }
    return argParser;
  }
}

/// TODO(https://github.com/dart-lang/sdk/issues/54429): Add shutdown behavior.

/// A service that facilitates communication between dart tools.
class DartToolingDaemon {
  DartToolingDaemon._({
    required this.secret,
    required bool unrestrictedMode,
    bool ipv6 = false,
    bool shouldLogRequests = false,
  })  : _ipv6 = ipv6,
        _shouldLogRequests = shouldLogRequests {
    streamManager = DTDStreamManager(this);
    clientManager = DTDClientManager();
    fileSystemService = FileSystemService(
      secret: secret,
      unrestrictedMode: unrestrictedMode,
    );
  }
  static const _kSseHandlerPath = '\$debugHandler';

  /// Manages the streams for the current [DartToolingDaemon] service.
  late final DTDStreamManager streamManager;

  /// Manages the connected clients of the current [DartToolingDaemon] service.
  late final DTDClientManager clientManager;
  final bool _ipv6;
  late HttpServer _server;
  final bool _shouldLogRequests;
  late final FileSystemService fileSystemService;

  final String secret;

  /// Any requests to DTD must have this token as the first element of the
  /// uri path.
  ///
  /// This provides an obfuscation step to prevent bad actors from stumbling
  /// onto the dtd address.
  final String _uriToken = _generateSecret();

  /// The uri of the current [DartToolingDaemon] service.
  Uri? get uri => _uri;
  Uri? _uri;

  Future<void> _startService({required int port}) async {
    final host =
        (_ipv6 ? InternetAddress.loopbackIPv6 : InternetAddress.loopbackIPv4)
            .host;

    // Start the DTD server. Run in an error Zone to ensure that asynchronous
    // exceptions encountered during request handling are handled, as exceptions
    // thrown during request handling shouldn't take down the entire service.
    late String errorMessage;
    final tmpServer = await runZonedGuarded(
      () async {
        Future<HttpServer?> startServer() async {
          try {
            return await io.serve(_handlers(), host, port);
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
      path: '/$_uriToken',
    );
  }

  /// Starts a [DartToolingDaemon] service.
  ///
  /// Set [ipv6] to true to have the service use ipv6 instead of ipv4.
  ///
  /// Set [shouldLogRequests] to true to enable logging.
  static Future<DartToolingDaemon?> startService(
    List<String> args, {
    bool ipv6 = false,
    bool shouldLogRequests = false,
    int port = 0,
  }) async {
    final argParser = DartToolingDaemonOptions.createArgParser();
    final parsedArgs = argParser.parse(args);
    if (parsedArgs.wasParsed(DartToolingDaemonOptions.train.name)) {
      return null;
    }
    final machineMode = parsedArgs[DartToolingDaemonOptions.machine.name];
    final unrestrictedMode =
        parsedArgs[DartToolingDaemonOptions.unrestricted.name];

    final secret = _generateSecret();
    final dtd = DartToolingDaemon._(
      secret: secret,
      unrestrictedMode: unrestrictedMode,
      ipv6: ipv6,
      shouldLogRequests: shouldLogRequests,
    );
    await dtd._startService(port: port);
    if (machineMode) {
      print(
        jsonEncode({
          'tooling_daemon_details': {
            'uri': dtd.uri.toString(),
            ...(!unrestrictedMode ? {'trusted_client_secret': secret} : {}),
          },
        }),
      );
    } else {
      print(
        'The Dart Tooling Daemon is listening on '
        '${dtd.uri.toString()}',
      );

      if (!unrestrictedMode) {
        print('Trusted Client Secret: $secret');
      }
    }
    return dtd;
  }

  // Attempt to upgrade HTTP requests to a websocket before processing them as
  // standard HTTP requests. The websocket handler will fail quickly if the
  // request doesn't appear to be a websocket upgrade request.
  Handler _handlers() {
    return Pipeline().addMiddleware(_uriTokenHandler).addHandler(
          Cascade().add(_webSocketHandler()).add(_sseHandler()).handler,
        );
  }

  Handler _uriTokenHandler(Handler innerHandler) => (Request request) {
        final forbidden =
            Response.forbidden('missing or invalid authentication code');
        final pathSegments = request.url.pathSegments;
        if (pathSegments.isEmpty) {
          return forbidden;
        }
        final token = pathSegments[0];
        if (token != _uriToken) {
          return forbidden;
        }
        return innerHandler(request);
      };

  Handler _webSocketHandler() => webSocketHandler((WebSocketChannel ws) {
        final client = DTDClient.fromWebSocket(
          this,
          ws,
        );
        _registerInternalServiceMethods(client);
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
      _registerInternalServiceMethods(client);
      clientManager.addClient(client);
    });

    return handler.handler;
  }

  void _registerInternalServiceMethods(DTDClient client) {
    fileSystemService.register(client);
  }

  static String _generateSecret() {
    String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String lower = 'abcdefghijklmnopqrstuvwxyz';
    String numbers = '1234567890';
    int secretLength = 16;
    String seed = upper + lower + numbers;
    String password = '';
    List<String> list = seed.split('').toList();
    Random rand = Random();

    for (int i = 0; i < secretLength; i++) {
      int index = rand.nextInt(list.length);
      password += list[index];
    }
    return password;
  }

  Future<void> close() async {
    await clientManager.shutdown();
    await _server.close(force: true);
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
