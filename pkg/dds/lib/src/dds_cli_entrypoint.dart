// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(bkonyi): move this file to lib/dds_cli_entrypoint.dart once package:dds
// is no longer shipped via pub.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../dds.dart';
import 'arg_parser.dart';
import 'bazel_uri_converter.dart';

Uri _getDevToolsAssetPath() {
  final dartDir = File(Platform.resolvedExecutable).parent.path;
  final fullSdk = dartDir.endsWith('bin');
  return Uri.file(
    fullSdk
        ? path.absolute(
            dartDir,
            'resources',
            'devtools',
          )
        : path.absolute(
            dartDir,
            'devtools',
          ),
  );
}

// TODO(bkonyi): allow for injection of custom DevTools handlers in google3.
Future<void> runDartDevelopmentServiceFromCLI(
  List<String> args, {
  String? Function(String)? uriConverter,
}) async {
  final argParser = DartDevelopmentServiceOptions.createArgParser(
    includeHelp: true,
  );
  final argResults = argParser.parse(args);
  if (args.isEmpty || argResults.wasParsed('help')) {
    print('''
Starts a Dart Development Service (DDS) instance.

Usage:
${argParser.usage}
    ''');
    return;
  }

  // Check if the remote VM Service address can be resolved to an IPv4 address.
  final remoteVmServiceUri = Uri.parse(
    argResults[DartDevelopmentServiceOptions.vmServiceUriOption],
  );
  bool doesVmServiceAddressResolveToIpv4Address = false;
  try {
    final addresses = await InternetAddress.lookup(remoteVmServiceUri.host);
    for (final address in addresses) {
      if (address.type == InternetAddressType.IPv4) {
        doesVmServiceAddressResolveToIpv4Address = true;
      }
    }
  } on SocketException catch (e, st) {
    writeErrorResponse(
      'Invalid --${DartDevelopmentServiceOptions.vmServiceUriOption} argument: '
      '$remoteVmServiceUri',
      st,
    );
    return;
  }

  // Ensure that the bind address, which is potentially provided by the user,
  // can be resolved at all, and check whether it can be resolved to an IPv4
  // address.
  final bindAddress =
      argResults[DartDevelopmentServiceOptions.bindAddressOption];
  bool doesBindAddressResolveToIpv4Address = false;
  try {
    final addresses = await InternetAddress.lookup(bindAddress);
    for (final address in addresses) {
      if (address.type == InternetAddressType.IPv4) {
        doesBindAddressResolveToIpv4Address = true;
      }
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
    host: bindAddress,
    port: port,
  );
  final disableServiceAuthCodes =
      argResults[DartDevelopmentServiceOptions.disableServiceAuthCodesFlag];

  final serveDevTools =
      argResults[DartDevelopmentServiceOptions.serveDevToolsFlag];
  final devToolsServerAddressStr =
      argResults[DartDevelopmentServiceOptions.devToolsServerAddressOption];
  Uri? devToolsBuildDirectory;
  final devToolsServerAddress = devToolsServerAddressStr == null
      ? null
      : Uri.parse(devToolsServerAddressStr);
  if (serveDevTools) {
    devToolsBuildDirectory = _getDevToolsAssetPath();
  }
  final enableServicePortFallback =
      argResults[DartDevelopmentServiceOptions.enableServicePortFallbackFlag];

  final google3WorkspaceRoot =
      argResults[DartDevelopmentServiceOptions.google3WorkspaceRootOption];
  if (google3WorkspaceRoot != null) {
    uriConverter = BazelUriConverter(google3WorkspaceRoot).uriToPath;
  }
  try {
    final dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
      serviceUri: serviceUri,
      enableAuthCodes: !disableServiceAuthCodes,
      // Only use IPv6 to serve DDS if either the remote VM Service address or
      // the bind address cannot be resolved to an IPv4 address.
      ipv6: !doesVmServiceAddressResolveToIpv4Address ||
          !doesBindAddressResolveToIpv4Address,
      devToolsConfiguration: serveDevTools && devToolsBuildDirectory != null
          ? DevToolsConfiguration(
              enable: serveDevTools,
              customBuildDirectoryPath: devToolsBuildDirectory,
              devToolsServerAddress: devToolsServerAddress,
            )
          : null,
      enableServicePortFallback: enableServicePortFallback,
      uriConverter: uriConverter,
    );
    final dtdInfo = dds.hostedDartToolingDaemon;
    stderr.write(json.encode({
      'state': 'started',
      'ddsUri': dds.uri.toString(),
      if (dds.devToolsUri != null) 'devToolsUri': dds.devToolsUri.toString(),
      if (dtdInfo != null)
        'dtd': {
          // For DDS-hosted DTD, there's only ever a local URI since there
          // is no mechanism for exposing URIs.
          'uri': dtdInfo.localUri.toString(),
        },
    }));
  } catch (e, st) {
    writeErrorResponse(e, st);
  } finally {
    // Always close stderr to notify tooling that DDS has finished writing
    // launch details.
    await stderr.close();
  }
}

void writeErrorResponse(Object e, StackTrace st) {
  stderr.write(json.encode({
    'state': 'error',
    'error': '$e',
    'stacktrace': '$st',
    if (e is DartDevelopmentServiceException) 'ddsExceptionDetails': e.toJson(),
  }));
}
