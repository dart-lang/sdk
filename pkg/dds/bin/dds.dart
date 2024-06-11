// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds/src/arg_parser.dart';
import 'package:dds/src/bazel_uri_converter.dart';

import 'package:path/path.dart' as path;

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

Future<void> main(List<String> args) async {
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
  final cachedUserTags =
      argResults[DartDevelopmentServiceOptions.cachedUserTagsOption];
  final google3WorkspaceRoot =
      argResults[DartDevelopmentServiceOptions.google3WorkspaceRootOption];

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
              devToolsServerAddress: devToolsServerAddress,
            )
          : null,
      enableServicePortFallback: enableServicePortFallback,
      cachedUserTags: cachedUserTags,
      uriConverter: google3WorkspaceRoot != null
          ? BazelUriConverter(google3WorkspaceRoot).uriToPath
          : null,
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
    stderr.close();
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
