// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'constants.dart';
import 'dtd_client.dart';
import 'dtd_client_manager.dart';
import 'dtd_stream_manager.dart';
import 'service/file_system_service.dart';
import 'service/internal_service.dart';
import 'service/unified_analytics_service.dart';

/// Contains all the flags and options used by the DTD argument parser.
enum DartToolingDaemonOptions {
  // Used when executing a training run while generating an AppJIT snapshot as
  // part of an SDK build.
  train.flag('train', negatable: false, hide: true),
  machine.flag(
    'machine',
    negatable: false,
    help: 'Sets output format to JSON for consumption in tools.',
  ),
  port.option(
    'port',
    defaultsTo: '0',
    help: 'Sets the port to bind DTD to (0 for automatic port).',
  ),
  unrestricted.flag(
    'unrestricted',
    negatable: false,
    help: 'Disables restrictions on services registered by DTD.',
  ),
  disableServiceAuthCodes.flag(
    'disable-service-auth-codes',
    negatable: false,
    // This text mirrors what's in dartdev/commands/run for VM Service.
    help: 'Disables the requirement for an authentication code to '
        'communicate with DTD. Authentication codes help '
        'protect against CSRF attacks, so it is not recommended to '
        'disable them unless behind a firewall on a secure device.',
    verbose: true,
  ),
  fakeAnalytics.flag(
    'fakeAnalytics',
    negatable: false,
    help: 'Uses fake analytics instances for the UnifiedAnalytics service.',
    hide: true,
  );

  const DartToolingDaemonOptions.flag(
    this.name, {
    this.negatable = true,
    this.verbose = false,
    this.hide = false,
    this.help,
  })  : _kind = _DartToolingDaemonOptionKind.flag,
        defaultsTo = null;

  const DartToolingDaemonOptions.option(
    this.name, {
    this.defaultsTo,
    this.help,
  })  : _kind = _DartToolingDaemonOptionKind.option,
        negatable = false,
        verbose = false,
        hide = false;

  final String name;
  final _DartToolingDaemonOptionKind _kind;
  final String? defaultsTo;
  final bool negatable;
  final bool hide;
  final String? help;

  /// Show in help only when --verbose passed.
  final bool verbose;

  /// Populates an argument parser that can be used to configure the daemon.
  static void populateArgOptions(
    ArgParser argParser, {
    bool verbose = false,
  }) {
    for (final entry in DartToolingDaemonOptions.values) {
      final hide = entry.hide || (entry.verbose && !verbose);
      switch (entry._kind) {
        case _DartToolingDaemonOptionKind.flag:
          argParser.addFlag(
            entry.name,
            negatable: entry.negatable,
            hide: hide,
            help: entry.help,
          );
        case _DartToolingDaemonOptionKind.option:
          argParser.addOption(
            entry.name,
            hide: hide,
            help: entry.help,
            defaultsTo: entry.defaultsTo,
          );
      }
    }
  }
}

/// The kind of command line argument.
enum _DartToolingDaemonOptionKind {
  flag,
  option,
}

/// TODO(https://github.com/dart-lang/sdk/issues/54429): Add shutdown behavior.

/// A service that facilitates communication between dart tools.
class DartToolingDaemon {
  DartToolingDaemon._({
    required this.secret,
    required bool unrestrictedMode,
    bool disableServiceAuthCodes = false,
    bool ipv6 = false,
    bool shouldLogRequests = false,
    bool useFakeAnalytics = false,
  })  : _ipv6 = ipv6,
        _uriAuthCode = disableServiceAuthCodes ? null : _generateSecret(),
        _shouldLogRequests = shouldLogRequests {
    streamManager = DTDStreamManager(this);
    clientManager = DTDClientManager();

    internalServices = Map.fromEntries(
      [
        FileSystemService(
          secret: secret,
          unrestrictedMode: unrestrictedMode,
        ),
        UnifiedAnalyticsService(fake: useFakeAnalytics),
      ].map((service) => MapEntry(service.serviceName, service)),
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

  /// A map of internal DTD services, keyed by the service name.
  late final Map<String, InternalService> internalServices;

  final String secret;

  /// If non-null, any requests to DTD must have this code as the first element
  /// of the uri path.
  ///
  /// This provides an obfuscation step to prevent bad actors from stumbling
  /// onto the dtd address.
  final String? _uriAuthCode;

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
      path: _uriAuthCode != null ? '/$_uriAuthCode' : '',
    );
  }

  /// Starts a [DartToolingDaemon] service.
  ///
  /// Set [ipv6] to true to have the service use ipv6 instead of ipv4.
  ///
  /// Set [shouldLogRequests] to true to enable logging.
  ///
  /// When [sendPort] is non-null, information about the DTD connection will be
  /// sent over [port] instead of being printed to stdout.
  static Future<DartToolingDaemon?> startService(
    List<String> args, {
    bool ipv6 = false,
    bool shouldLogRequests = false,
    SendPort? sendPort,
  }) async {
    final argParser = ArgParser();
    DartToolingDaemonOptions.populateArgOptions(argParser);
    final parsedArgs = argParser.parse(args);
    if (parsedArgs.wasParsed(DartToolingDaemonOptions.train.name)) {
      return null;
    }
    final machineMode = parsedArgs[DartToolingDaemonOptions.machine.name];
    final unrestrictedMode =
        parsedArgs[DartToolingDaemonOptions.unrestricted.name];
    final disableServiceAuthCodes =
        parsedArgs[DartToolingDaemonOptions.disableServiceAuthCodes.name];
    final useFakeAnalytics =
        parsedArgs[DartToolingDaemonOptions.fakeAnalytics.name];
    final port =
        int.tryParse(parsedArgs[DartToolingDaemonOptions.port.name]) ?? 0;

    final secret = _generateSecret();
    final dtd = DartToolingDaemon._(
      secret: secret,
      unrestrictedMode: unrestrictedMode,
      disableServiceAuthCodes: disableServiceAuthCodes,
      ipv6: ipv6,
      shouldLogRequests: shouldLogRequests,
      useFakeAnalytics: useFakeAnalytics,
    );
    await dtd._startService(port: port);
    if (machineMode) {
      final encoded = jsonEncode({
        'tooling_daemon_details': {
          'uri': dtd.uri.toString(),
          ...(!unrestrictedMode
              ? {'trusted_client_secret': secret}
              : <String, Object?>{}),
        },
      });
      if (sendPort == null) {
        print(encoded);
      } else {
        sendPort.send(encoded);
      }
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
        if (_uriAuthCode != null) {
          final forbidden =
              Response.forbidden('missing or invalid authentication code');
          final pathSegments = request.url.pathSegments;
          if (pathSegments.isEmpty) {
            return forbidden;
          }
          final clientProvidedCode = pathSegments[0];
          if (clientProvidedCode != _uriAuthCode) {
            return forbidden;
          }
        }
        return innerHandler(request);
      };

  // Note: the WebSocketChannel type below is needed for compatibility with
  // package:shelf_web_socket v2.
  Handler _webSocketHandler() => webSocketHandler((WebSocketChannel ws, _) {
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
    for (final service in internalServices.values) {
      service.register(client);
    }
  }

  static String _generateSecret() {
    final kTokenByteSize = 8;
    Uint8List bytes = Uint8List(kTokenByteSize);
    // Use a secure random number generator.
    Random rand = Random.secure();

    for (int i = 0; i < kTokenByteSize; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return base64Url.encode(bytes);
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
