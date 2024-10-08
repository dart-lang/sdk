// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dds.dart' hide DartDevelopmentService;
import 'src/arg_parser.dart';
import 'src/dds_impl.dart';

/// Spawns a Dart Development Service instance which will communicate with a
/// VM service. Requires the target VM service to have no other connected
/// clients.
///
/// [remoteVmServiceUri] is the address of the VM service that this
/// development service will communicate with.
///
/// If provided, [serviceUri] will determine the address and port of the
/// spawned Dart Development Service.
///
/// [enableAuthCodes] controls whether or not an authentication code must
/// be provided by clients when communicating with this instance of
/// DDS. Authentication codes take the form of a base64
/// encoded string provided as the first element of the DDS path and is meant
/// to make it more difficult for unintended clients to connect to this
/// service. Authentication codes are enabled by default.
///
/// If [serveDevTools] is enabled, DDS will serve a DevTools instance and act
/// as a DevTools Server. If not specified, [devToolsServerAddress] is ignored.
///
/// If provided, DDS will redirect DevTools requests to an existing DevTools
/// server hosted at [devToolsServerAddress]. Ignored if [serveDevTools] is not
/// true.
///
/// If [enableServicePortFallback] is enabled, DDS will attempt to bind to any
/// available port if the specified port is unavailable.
///
/// If set, the set of [cachedUserTags] will be used to determine which CPU
/// samples should be cached by DDS.
///
/// If provided, [dartExecutable] is the path to the 'dart' executable that
/// should be used to spawn the DDS instance. By default, `Platform.executable`
/// is used.
class DartDevelopmentServiceLauncher {
  static Future<DartDevelopmentServiceLauncher> start({
    required Uri remoteVmServiceUri,
    Uri? serviceUri,
    bool enableAuthCodes = true,
    bool serveDevTools = false,
    Uri? devToolsServerAddress,
    bool enableServicePortFallback = false,
    List<String> cachedUserTags = const <String>[],
    String? dartExecutable,
    String? google3WorkspaceRoot,
  }) async {
    final process = await Process.start(
      dartExecutable ?? Platform.executable,
      <String>[
        'development-service',
        '--${DartDevelopmentServiceOptions.vmServiceUriOption}=$remoteVmServiceUri',
        if (serviceUri != null) ...<String>[
          '--${DartDevelopmentServiceOptions.bindAddressOption}=${serviceUri.host}',
          '--${DartDevelopmentServiceOptions.bindPortOption}=${serviceUri.port}',
        ],
        if (!enableAuthCodes)
          '--${DartDevelopmentServiceOptions.disableServiceAuthCodesFlag}',
        if (serveDevTools)
          '--${DartDevelopmentServiceOptions.serveDevToolsFlag}',
        if (devToolsServerAddress != null)
          '--${DartDevelopmentServiceOptions.devToolsServerAddressOption}=$devToolsServerAddress',
        if (enableServicePortFallback)
          '--${DartDevelopmentServiceOptions.enableServicePortFallbackFlag}',
        for (final String tag in cachedUserTags)
          '--${DartDevelopmentServiceOptions.cachedUserTagsOption}=$tag',
        if (google3WorkspaceRoot != null)
          '--${DartDevelopmentServiceOptions.google3WorkspaceRootOption}=$google3WorkspaceRoot',
      ],
    );
    final completer = Completer<DartDevelopmentServiceLauncher>();
    late StreamSubscription<Object?> stderrSub;
    stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(json.decoder)
        .listen((Object? result) {
      if (result
          case {
            'state': 'started',
            'ddsUri': final String ddsUriStr,
          }) {
        final ddsUri = Uri.parse(ddsUriStr);
        final devToolsUriStr = result['devToolsUri'] as String?;
        final devToolsUri =
            devToolsUriStr == null ? null : Uri.parse(devToolsUriStr);
        final dtdUriStr =
            (result['dtd'] as Map<String, Object?>?)?['uri'] as String?;
        final dtdUri = dtdUriStr == null ? null : Uri.parse(dtdUriStr);

        completer.complete(
          DartDevelopmentServiceLauncher._(
            process: process,
            uri: ddsUri,
            devToolsUri: devToolsUri,
            dtdUri: dtdUri,
          ),
        );
      } else if (result
          case {
            'state': 'error',
            'error': final String error,
          }) {
        final Map<String, Object?>? exceptionDetails =
            result['ddsExceptionDetails'] as Map<String, Object?>?;
        completer.completeError(
          exceptionDetails != null
              ? DartDevelopmentServiceException.fromJson(exceptionDetails)
              : StateError(error),
        );
      } else {
        throw StateError('Unexpected result from DDS: $result');
      }
      stderrSub.cancel();
    });
    return completer.future;
  }

  DartDevelopmentServiceLauncher._({
    required Process process,
    required this.uri,
    required this.devToolsUri,
    required this.dtdUri,
  }) : _ddsInstance = process;

  final Process _ddsInstance;

  /// The [Uri] VM service clients can use to communicate with this
  /// DDS instance via HTTP.
  final Uri uri;

  /// The HTTP [Uri] of the hosted DevTools instance.
  ///
  /// Returns `null` if DevTools is not running.
  final Uri? devToolsUri;

  /// The [Uri] of the Dart Tooling Daemon instance that is hosted by DevTools.
  ///
  /// This will be null if DTD was not started by the DevTools server. For
  /// example, it may have been started by an IDE.
  final Uri? dtdUri;

  /// The [Uri] VM service clients can use to communicate with this
  /// DDS instance via server-sent events (SSE).
  Uri get sseUri => _toSse(uri)!;

  /// The [Uri] VM service clients can use to communicate with this
  /// DDS instance via a [WebSocket].
  Uri get wsUri => _toWebSocket(uri)!;

  List<String> _cleanupPathSegments(Uri uri) {
    final pathSegments = <String>[];
    if (uri.pathSegments.isNotEmpty) {
      pathSegments.addAll(
        uri.pathSegments.where(
          // Strip out the empty string that appears at the end of path segments.
          // Empty string elements will result in an extra '/' being added to the
          // URI.
          (s) => s.isNotEmpty,
        ),
      );
    }
    return pathSegments;
  }

  Uri? _toWebSocket(Uri? uri) {
    if (uri == null) {
      return null;
    }
    final pathSegments = _cleanupPathSegments(uri);
    pathSegments.add('ws');
    return uri.replace(scheme: 'ws', pathSegments: pathSegments);
  }

  Uri? _toSse(Uri? uri) {
    if (uri == null) {
      return null;
    }
    final pathSegments = _cleanupPathSegments(uri);
    pathSegments.add(DartDevelopmentServiceImpl.kSseHandlerPath);
    return uri.replace(scheme: 'sse', pathSegments: pathSegments);
  }

  /// Completes when the DDS instance has shutdown.
  Future<void> get done => _ddsInstance.exitCode;

  /// Shutdown the DDS instance.
  Future<void> shutdown() {
    _ddsInstance.kill();
    return _ddsInstance.exitCode;
  }
}
