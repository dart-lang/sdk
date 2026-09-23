// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:logging/logging.dart';

import 'arg_parser.dart';
import 'dds_backend.dart';

const _enableLoggingFlag = 'enable-logging';
const _helpFlag = 'help';

const _stateKey = 'state';
const _startedState = 'started';
const _errorState = 'error';
const _ddsUriKey = 'ddsUri';
const _errorKey = 'error';
const _stacktraceKey = 'stacktrace';

const _devToolsUriKey = 'devToolsUri';
const _dtdKey = 'dtd';
const _uriKey = 'uri';
const _nameKey = 'name';

/// Starts the Dart Development Service (DDS) from a command-line interface.
///
/// Parses [args], initializes the [DartRuntimeService] with a
/// [DartRuntimeServiceDdsBackend], and emits a JSON status message to [stderr]
/// once the service is listening or fails to start.
Future<void> runDartDevelopmentServiceFromCLI(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      DartDevelopmentServiceOptions.vmServiceUriOption,
      abbr: 'u',
      help: 'The VM service URI DDS will connect to.',
      mandatory: true,
    )
    ..addOption(
      DartDevelopmentServiceOptions.bindAddressOption,
      abbr: 'a',
      defaultsTo: 'localhost',
      help: 'The address DDS should bind to.',
    )
    ..addOption(
      DartDevelopmentServiceOptions.bindPortOption,
      abbr: 'p',
      defaultsTo: '0',
      help: 'The port DDS should be served on.',
    )
    ..addFlag(
      DartDevelopmentServiceOptions.disableServiceAuthCodesFlag,
      abbr: 'd',
      help: 'Disables authentication codes.',
      negatable: false,
    )
    ..addFlag(
      _enableLoggingFlag,
      abbr: 'l',
      help: 'Enable logging.',
      negatable: false,
    )
    ..addFlag(
      DartDevelopmentServiceOptions.enableServicePortFallbackFlag,
      help: 'Bind to a random port if DDS fails to bind to the provided port.',
      negatable: false,
    )
    ..addFlag(
      DartDevelopmentServiceOptions.serveDevToolsFlag,
      help:
          'If provided, DDS will serve DevTools. If not specified, '
          '"--${DartDevelopmentServiceOptions.devToolsServerAddressOption}" '
          'is ignored.',
      negatable: false,
    )
    ..addOption(
      DartDevelopmentServiceOptions.devToolsServerAddressOption,
      help:
          'Redirect to an existing DevTools server. Ignored if '
          '"--${DartDevelopmentServiceOptions.serveDevToolsFlag}" is not '
          'specified.',
    )
    ..addOption(
      DartDevelopmentServiceOptions.google3WorkspaceRootOption,
      help:
          'Sets the Google3 workspace root used for google3:// URI resolution.',
    )
    ..addOption(
      DartDevelopmentServiceOptions.appNameOption,
      help:
          'A short, user focused description of the application that DDS will '
          'connect to.',
    )
    ..addMultiOption(
      DartDevelopmentServiceOptions.cachedUserTagsOption,
      help: 'This option is deprecated and supplying it will cause no effect.',
      hide: true,
    )
    ..addFlag(
      _helpFlag,
      abbr: 'h',
      help: 'Print usage information.',
      negatable: false,
    );

  ArgResults argResults;
  try {
    argResults = parser.parse(args);
  } on FormatException catch (e) {
    _writeErrorResponse('Invalid arguments: ${e.message}');
    exitCode = 1;
    return;
  }

  if (argResults[_helpFlag] as bool) {
    print('''
Starts the Dart Development Service (DDS) based on dart_runtime_service.

Usage:
${parser.usage}''');
    return;
  }

  final remoteVmServiceUriStr =
      argResults[DartDevelopmentServiceOptions.vmServiceUriOption] as String;
  final remoteVmServiceUri = Uri.tryParse(remoteVmServiceUriStr);
  if (remoteVmServiceUri == null) {
    _writeErrorResponse('Invalid VM Service URI: $remoteVmServiceUriStr');
    exitCode = 1;
    return;
  }

  final bindAddress =
      argResults[DartDevelopmentServiceOptions.bindAddressOption] as String;
  final bindPortStr =
      argResults[DartDevelopmentServiceOptions.bindPortOption] as String;
  final bindPort = int.tryParse(bindPortStr);
  if (bindPort == null) {
    _writeErrorResponse('Invalid bind port: $bindPortStr');
    exitCode = 1;
    return;
  }

  final disableServiceAuthCodes =
      argResults[DartDevelopmentServiceOptions.disableServiceAuthCodesFlag]
          as bool;
  final enableLogging = argResults[_enableLoggingFlag] as bool;
  final enableServicePortFallback =
      argResults[DartDevelopmentServiceOptions.enableServicePortFallbackFlag]
          as bool;
  final serveDevTools =
      argResults[DartDevelopmentServiceOptions.serveDevToolsFlag] as bool;
  final devToolsServerAddressStr =
      argResults[DartDevelopmentServiceOptions.devToolsServerAddressOption]
          as String?;
  final devToolsServerAddress = devToolsServerAddressStr != null
      ? Uri.tryParse(devToolsServerAddressStr)
      : null;
  final appName =
      argResults[DartDevelopmentServiceOptions.appNameOption] as String?;

  if (enableLogging) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord record) {
      stderr.writeln(
        '${record.time}: ${record.level.name}: '
        '${record.loggerName}: ${record.message}',
      );
      if (record.error != null) {
        stderr.writeln(record.error);
      }
      if (record.stackTrace != null) {
        stderr.writeln(record.stackTrace);
      }
    });
  }

  DartRuntimeService? ddsService;
  try {
    ddsService = await DartRuntimeService.initialize(
      backendBuilder: (frontend) => DartRuntimeServiceDdsBackend(
        remoteVmServiceUri,
        appName: appName,
        devtoolsServerAddress: devToolsServerAddress,
        frontend: frontend,
        serveDevTools: serveDevTools,
      ),
      config: DartRuntimeServiceOptions(
        disableAuthCodes: disableServiceAuthCodes,
        enableLogging: enableLogging,
        enableServicePortFallback: enableServicePortFallback,
        host: bindAddress,
        port: bindPort,
        serveDevTools: serveDevTools,
      ),
    );

    final backend = ddsService.backend as DartRuntimeServiceDdsBackend;
    final devToolsUri = backend.devToolsUri;
    final dtd = backend.hostedDartToolingDaemon;

    stderr.writeln(
      json.encode(<String, Object?>{
        _ddsUriKey: ddsService.httpUri.toString(),
        _stateKey: _startedState,
        if (devToolsUri != null) _devToolsUriKey: devToolsUri.toString(),
        if (dtd != null)
          _dtdKey: <String, Object?>{_uriKey: dtd.localUri.toString()},
        _nameKey: ?appName,
      }),
    );
    await stderr.flush();
  } catch (e, st) {
    _writeErrorResponse(e, st);
    await ddsService?.shutdown();
    exit(1);
  }
}

void _writeErrorResponse(Object error, [StackTrace? stackTrace]) {
  stderr.writeln(
    json.encode(<String, Object?>{
      _errorKey: '$error',
      _stateKey: _errorState,
      if (stackTrace != null) _stacktraceKey: '$stackTrace',
    }),
  );
}
