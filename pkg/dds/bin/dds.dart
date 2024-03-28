// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dds/dds.dart';

abstract class DartDevelopmentServiceOptions {
  static const vmServiceUriOption = 'vm-service-uri';
  static const bindAddressOption = 'bind-address';
  static const bindPortOption = 'bind-port';
  static const disableServiceAuthCodesFlag = 'disable-service-auth-codes';
  static const serveDevToolsFlag = 'serve-devtools';
  static const enableServicePortFallbackFlag = 'enable-service-port-fallback';

  static ArgParser createArgParser() {
    return ArgParser()
      ..addOption(
        vmServiceUriOption,
        help: 'The VM service URI DDS will connect to.',
        valueHelp: 'uri',
        mandatory: true,
      )
      ..addOption(bindAddressOption,
          help: 'The address DDS should bind to.',
          valueHelp: 'address',
          defaultsTo: 'localhost')
      ..addOption(
        bindPortOption,
        help: 'The port DDS should be served on.',
        valueHelp: 'port',
        defaultsTo: '0',
      )
      ..addFlag(
        disableServiceAuthCodesFlag,
        help: 'Disables authentication codes.',
      )
      ..addFlag(
        serveDevToolsFlag,
        help: 'If provided, DDS will serve DevTools.',
      )
      ..addFlag(
        enableServicePortFallbackFlag,
        help: 'Bind to a random port if DDS fails to bind to the provided '
            'port.',
      )
      ..addFlag('help', negatable: false);
  }
}

Uri _getDevToolsAssetPath() {
  final dartPath = Uri.parse(Platform.resolvedExecutable);
  final dartDir = [
    '', // Include leading '/'
    ...dartPath.pathSegments.sublist(
      0,
      dartPath.pathSegments.length - 1,
    ),
  ].join('/');
  final fullSdk = dartDir.endsWith('bin');
  return Uri.parse(
    [
      dartDir,
      if (fullSdk) 'resources',
      'devtools',
    ].join('/'),
  );
}

Future<void> main(List<String> args) async {
  final argParser = DartDevelopmentServiceOptions.createArgParser();
  final argResults = argParser.parse(args);
  if (args.isEmpty || argResults.wasParsed('help')) {
    print('''
Starts a Dart Development Service (DDS) instance.

Usage:
${argParser.usage}
    ''');
    return;
  }

  // This URI is provided by the VM service directly so don't bother doing a
  // lookup.
  final remoteVmServiceUri = Uri.parse(
    argResults[DartDevelopmentServiceOptions.vmServiceUriOption],
  );

  // Resolve the address which is potentially provided by the user.
  late InternetAddress address;
  final bindAddress =
      argResults[DartDevelopmentServiceOptions.bindAddressOption];
  try {
    final addresses = await InternetAddress.lookup(bindAddress);
    // Prefer IPv4 addresses.
    for (int i = 0; i < addresses.length; i++) {
      address = addresses[i];
      if (address.type == InternetAddressType.IPv4) break;
    }
  } on SocketException catch (e, st) {
    writeErrorResponse('Invalid bind address: $bindAddress', st);
    return;
  }

  final portString = argResults[DartDevelopmentServiceOptions.bindPortOption];
  int port;
  try {
    port = int.parse(portString);
  } on FormatException catch (e, st) {
    writeErrorResponse('Invalid port: $portString', st);
    return;
  }
  final serviceUri = Uri(
    scheme: 'http',
    host: address.address,
    port: port,
  );
  final disableServiceAuthCodes =
      argResults[DartDevelopmentServiceOptions.disableServiceAuthCodesFlag];

  final serveDevTools =
      argResults[DartDevelopmentServiceOptions.serveDevToolsFlag];
  Uri? devToolsBuildDirectory;
  if (serveDevTools) {
    devToolsBuildDirectory = _getDevToolsAssetPath();
  }
  final enableServicePortFallback =
      argResults[DartDevelopmentServiceOptions.enableServicePortFallbackFlag];

  try {
    final dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
      serviceUri: serviceUri,
      enableAuthCodes: !disableServiceAuthCodes,
      ipv6: address.type == InternetAddressType.IPv6,
      devToolsConfiguration: serveDevTools && devToolsBuildDirectory != null
          ? DevToolsConfiguration(
              enable: serveDevTools,
              customBuildDirectoryPath: devToolsBuildDirectory,
            )
          : null,
      enableServicePortFallback: enableServicePortFallback,
    );
    final dtdInfo = dds.hostedDartToolingDaemon;
    stderr.write(json.encode({
      'state': 'started',
      'ddsUri': dds.uri.toString(),
      if (dds.devToolsUri != null) 'devToolsUri': dds.devToolsUri.toString(),
      if (dtdInfo != null)
        'dtd': {
          'uri': dtdInfo.uri,
        },
    }));
  } catch (e, st) {
    writeErrorResponse(e, st);
  }
}

void writeErrorResponse(Object e, StackTrace st) {
  stderr.write(json.encode({
    'state': 'error',
    'error': '$e',
    'stacktrace': '$st',
  }));
}
