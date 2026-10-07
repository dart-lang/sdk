// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

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
/// [cachedUserTags] is deprecated and supplying an argument to it will cause no
/// effect.
///
/// If provided, [dartExecutable] is the path to the 'dart' executable that
/// should be used to spawn the DDS instance. By default, `Platform.executable`
/// is used.
///
/// If provided, [appName] is a short user focused description of the
/// application, used to help identify it.
class DartDevelopmentServiceLauncher {
  static Future<DartDevelopmentServiceLauncher> start({
    required Uri remoteVmServiceUri,
    String? appName,
    Uri? serviceUri,
    bool enableAuthCodes = true,
    bool serveDevTools = false,
    Uri? devToolsServerAddress,
    bool enableServicePortFallback = false,
    List<String> cachedUserTags = const <String>[],
    String? dartExecutable,
    String? google3WorkspaceRoot,
  }) async {
    var args = <String>[
      '--${DartDevelopmentServiceOptions.vmServiceUriOption}=$remoteVmServiceUri',
      if (serviceUri != null) ...<String>[
        '--${DartDevelopmentServiceOptions.bindAddressOption}=${serviceUri.host}',
        '--${DartDevelopmentServiceOptions.bindPortOption}=${serviceUri.port}',
      ],
      if (!enableAuthCodes)
        '--${DartDevelopmentServiceOptions.disableServiceAuthCodesFlag}',
      if (serveDevTools) '--${DartDevelopmentServiceOptions.serveDevToolsFlag}',
      if (devToolsServerAddress != null)
        '--${DartDevelopmentServiceOptions.devToolsServerAddressOption}=$devToolsServerAddress',
      if (enableServicePortFallback)
        '--${DartDevelopmentServiceOptions.enableServicePortFallbackFlag}',
      if (google3WorkspaceRoot != null)
        '--${DartDevelopmentServiceOptions.google3WorkspaceRootOption}=$google3WorkspaceRoot',
      if (appName != null)
        '--${DartDevelopmentServiceOptions.appNameOption}=$appName',
    ];
    late String executable;
    if (dartExecutable == null) {
      // If a dart executable is not specified and we are able to locate
      // the 'dartaotruntime' executable and the AOT snapshot for dds
      // then invoke it directly as it would avoid the additional hop
      // of going through the dart CLI process to invoke dds.
      executable = Platform.executable;
      var sdkPath =
          path.absolute(path.dirname(path.dirname(executable)), 'bin');
      var snapshotsDir = path.join(sdkPath, 'snapshots');
      final type = FileSystemEntity.typeSync(snapshotsDir);
      if (type != FileSystemEntityType.directory &&
          type != FileSystemEntityType.link) {
        // This is the less common case where the user is in
        // the checked out Dart SDK, and is executing `dart` via:
        // ./out/ReleaseX64/dart ... or in google3.
        sdkPath = path.absolute(path.dirname(executable));
        snapshotsDir = sdkPath;
      }
      final dartAotRuntime = path.absolute(sdkPath,
          Platform.isWindows ? 'dartaotruntime.exe' : 'dartaotruntime');
      final ddsAotSnapshot =
          path.absolute(snapshotsDir, 'dds_aot.dart.snapshot');
      if (File(dartAotRuntime).existsSync() &&
          File(ddsAotSnapshot).existsSync()) {
        executable = dartAotRuntime;
        args = [ddsAotSnapshot, ...args];
      } else {
        args = ['development-service', ...args];
      }
    } else {
      executable = dartExecutable;
      args = ['development-service', ...args];
    }
    final process = await Process.start(
      executable,
      args,
      mode: ProcessStartMode.detachedWithStdio,
    );
    final exitCompleter = Completer<void>();
    // We must drain stdout to prevent the process from deadlocking if the
    // OS pipe buffer fills up.
    process.stdout.listen(
      (_) {},
      onDone: () => exitCompleter.complete(),
      onError: (_) => exitCompleter.complete(),
    );
    final completer = Completer<DartDevelopmentServiceLauncher>();
    final stderrBuffer = StringBuffer();
    late StreamSubscription<Object?> stderrSub;
    stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      if (line.isEmpty) return;
      stderrBuffer.writeln(line);
      Object? result;
      try {
        result = json.decode(line);
      } on FormatException {
        // Not a JSON message (e.g. process error or startup log).
        return;
      }
      if (result
          case {
            'state': 'started',
            'ddsUri': final String ddsUriStr,
          }) {
        final ddsUri = Uri.parse(ddsUriStr);
        final devToolsUri = switch (result['devToolsUri']) {
          final String s => Uri.parse(s),
          _ => null,
        };
        final dtdUri = switch (result['dtd']) {
          {'uri': final String s} => Uri.parse(s),
          _ => null,
        };

        final launcher = DartDevelopmentServiceLauncher._(
          appName: appName,
          devToolsUri: devToolsUri,
          dtdUri: dtdUri,
          exitCompleter: exitCompleter,
          process: process,
          uri: ddsUri,
        );
        completer.complete(launcher);
      } else if (result
          case {
            'state': 'error',
            'error': final String error,
          }) {
        final exceptionDetails =
            result['ddsExceptionDetails'] as Map<String, Object?>?;
        completer.completeError(
          exceptionDetails != null
              ? DartDevelopmentServiceException.fromJson(exceptionDetails)
              : StateError(error),
        );
      } else {
        throw StateError('Unexpected result from DDS: $result');
      }
      // Drain stderr to prevent process from blocking.
      stderrSub.onData((_) {});
    }, onError: (Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        final errorDetails = stderrBuffer.toString().trim();
        completer.completeError(
          DartDevelopmentServiceException.failedToStart(
            errorDetails.isNotEmpty ? errorDetails : error.toString(),
          ),
          stackTrace,
        );
      }
      stderrSub.cancel();
    }, onDone: () {
      if (!completer.isCompleted) {
        final errorDetails = stderrBuffer.toString().trim();
        completer.completeError(
          DartDevelopmentServiceException.failedToStart(
            errorDetails.isNotEmpty
                ? 'Process terminated without starting: $errorDetails'
                : null,
          ),
        );
      }
    });
    return completer.future;
  }

  DartDevelopmentServiceLauncher._({
    required Process process,
    required this.uri,
    required this.devToolsUri,
    required this.dtdUri,
    required this.appName,
    required Completer<void> exitCompleter,
  })  : _ddsInstance = process,
        _exitCompleter = exitCompleter;

  final Process _ddsInstance;
  final Completer<void> _exitCompleter;

  /// A short, user focused description of the application that DDS will
  /// connect to.
  final String? appName;

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

  List<String> _cleanupPathSegments(Uri uri) => <String>[
        for (final s in uri.pathSegments)
          if (s.isNotEmpty) s,
      ];

  Uri? _toWebSocket(Uri? uri) {
    if (uri == null) return null;
    final isSecure = uri.isScheme('https') || uri.isScheme('wss');
    return uri.replace(
      scheme: isSecure ? 'wss' : 'ws',
      pathSegments: <String>[..._cleanupPathSegments(uri), 'ws'],
    );
  }

  Uri? _toSse(Uri? uri) {
    if (uri == null) return null;
    final isSecure = uri.isScheme('https') || uri.isScheme('sses');
    return uri.replace(
      scheme: isSecure ? 'sses' : 'sse',
      pathSegments: <String>[
        ..._cleanupPathSegments(uri),
        DartDevelopmentServiceImpl.kSseHandlerPath,
      ],
    );
  }

  /// Completes when the DDS instance has shutdown.
  Future<void> get done => _exitCompleter.future;

  /// Shutdown the DDS instance.
  Future<void> shutdown() async {
    _ddsInstance.kill();
    await done;
  }
}
