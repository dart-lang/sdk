// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:dds/dds.dart';
import 'package:dds/dds_launcher.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

import '../dart_runtime_service.dart';

/// Manages the lifecycle of the [DartDevelopmentService] (DDS).
///
/// Services can use this class to either launch their own DDS instance using
/// [start], or wait for an external DDS connection (e.g., from Flutter Tools).
final class DartDevelopmentServiceManager {
  DartDevelopmentServiceManager({
    required this.frontend,
    required this.launchOnStart,
    required this.printDtd,
    required this.host,
    required this.port,
  });

  final DartRuntimeService frontend;

  /// `true` if a DDS instance should be started immediately after the service
  /// is initialized.
  final bool launchOnStart;

  /// `true` if the URI for the DTD instance associated with DDS should be
  /// made available.
  final bool printDtd;

  /// The host DDS should attempt to bind to.
  final String host;

  /// The port DDS should attempt to bind to.
  final int port;

  static const _kUri = 'uri';

  /// The HTTP URI pointing to a Dart Development Service (DDS) instance.
  ///
  /// If DDS is not running, [uri] returns null.
  Uri? get uri => _launcher?.uri;

  /// The HTTP [Uri] of the hosted DevTools instance.
  ///
  /// Returns `null` if DevTools is not running.
  Uri? get devToolsUri => _launcher?.devToolsUri;

  /// The [Uri] of the Dart Tooling Daemon instance that is hosted by DevTools.
  ///
  /// This will be null if DTD was not started by the DevTools server. For
  /// example, it may have been started by an IDE.
  Uri? get dtdUri => printDtd ? _launcher?.dtdUri : null;

  final _logger = Logger('$DartDevelopmentServiceManager');
  DartDevelopmentServiceLauncher? _launcher;

  /// The set of RPCs that must be registered for DDS to function.
  late final rpcs = UnmodifiableListView<ServiceRpcHandler>([
    ('_yieldControlToDDS', _yieldControlToDDS),
  ]);

  Future<Uri> get ddsConnected => _yieldCompleter.future;
  var _yieldCompleter = Completer<Uri>();

  /// Launches a Dart Development Service (DDS) instance that will attempt to
  /// connect to the VM service at [vmServiceUri].
  Future<void> start({required Uri vmServiceUri}) async {
    assert(launchOnStart);
    final ddsBindUri = Uri(scheme: 'http', host: host, port: port);
    try {
      _logger.info('Launching DDS at $ddsBindUri...');
      _launcher = await DartDevelopmentServiceLauncher.start(
        remoteVmServiceUri: vmServiceUri,
        enableAuthCodes: !frontend.config.disableAuthCodes,
        enableServicePortFallback: frontend.config.enableServicePortFallback,
        serveDevTools: frontend.config.serveDevTools,
        serviceUri: ddsBindUri,
      );
      unawaited(_launcher!.done.then((_) => _cleanup()));
      _logger.info('DDS is served at $uri');
    } on ExistingDartDevelopmentServiceException catch (e) {
      _logger.warning('A DDS instance already exists at ${e.ddsUri}.');
    } on DartDevelopmentServiceException catch (e) {
      switch (e.errorCode) {
        case DartDevelopmentServiceException.connectionError:
          _logger.warning('Failed to connect to the VM service: ${e.message}.');
        case DartDevelopmentServiceException.failedToStartError:
          _logger.warning('Failed to start DDS: ${e.message}');
      }
    }
  }

  /// Shuts down the Dart Development Service (DDS) instance, if it exists.
  Future<void> shutdown() async {
    if (_launcher == null) {
      return;
    }
    _logger.info('Shutting down DDS...');
    await _launcher?.shutdown();
    _cleanup();
    _logger.info('DDS shutdown.');
  }

  void _cleanup() {
    _launcher = null;
    _yieldCompleter = Completer<Uri>();
  }

  /// Invoked by DDS when it connects to the service to ensure that it's the
  /// only direct client of the service.
  ///
  /// DDS must be the only client as it takes over some of the responsibilities
  /// of the VM service, such as client-registered service extension routing,
  /// stream management, etc. In order for DDS to make some assumptions about
  /// the state of the service, all other clients must connect to the service
  /// through DDS.
  ///
  /// When invoked, new client connections to the service are disabled, with
  /// redirect responses pointing to the DDS instance sent when connections are
  /// attempted. An event is sent on the `Service` stream to each non-DDS
  /// client explaining why they're about to be disconnected before the service
  /// closes the client's connection.
  ///
  /// If the DDS client disconnects, the service will once again allow for
  /// direct connections.
  Future<RpcResponse> _yieldControlToDDS(
    json_rpc.Parameters params,
    Client client,
  ) async {
    var uri = _launcher?.uri;
    if (uri != null) {
      RpcException.featureDisabled.throwException(
        data: {
          'ddsUri': uri,
          'details': 'A DDS instance is already connected at $uri.',
        },
      );
    }
    uri = Uri.tryParse(params[_kUri].asString);
    if (uri == null) {
      RpcException.invalidParams.throwExceptionWithDetails(
        details: "'$_kUri' is not a valid URI.",
      );
    }
    _logger.info(
      'Rejecting future connections and disconnecting non-DDS clients.',
    );
    frontend.clientConnectionController.rejectConnections(redirectUri: uri);

    // Register a callback to cleanup state if DDS disconnects.
    unawaited(
      client.done.then((_) async {
        await _yieldCompleter.future;
        _cleanup();
        frontend.clientConnectionController.acceptConnections();
        _logger.info('DDS disconnected. Accepting future connections.');
      }),
    );

    client.setName('DDS');

    // Notify clients why they're being disconnected from the VM service.
    _DartDevelopmentServiceConnectedEvent(
      uri: uri,
    ).send(eventStreamMethods: frontend.eventStreams, excludedClient: client);

    await Future.wait([
      for (final client in frontend.clients.toList().where(
        (e) => e != client && !e.artificial,
      ))
        client.close(),
    ]);

    _logger.info('Non-DDS clients disconnected.');
    _yieldCompleter.complete(uri);
    return Success().toJson();
  }
}

/// An event notifying [Client]s that DDS has connected and their connection to
/// the service is about to be closed.
final class _DartDevelopmentServiceConnectedEvent extends StreamEvent {
  _DartDevelopmentServiceConnectedEvent({required this.uri})
    : super(
        streamId: EventStreams.kService,
        kind: 'DartDevelopmentServiceConnected',
      );

  final Uri uri;

  static const _kMessage = 'message';

  @override
  Map<String, Object?> toJson() => {
    StreamEvent.kStreamId: streamId,
    StreamEvent.kEvent: {
      ...Event(
        kind: kind,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ).toJson(),
      _kMessage:
          'A Dart Developer Service instance has connected and this direct '
          'connection to the VM service will now be closed. Please reconnect '
          'to the Dart Development Service at $uri.',
      DartDevelopmentServiceManager._kUri: uri.toString(),
    },
  };
}
