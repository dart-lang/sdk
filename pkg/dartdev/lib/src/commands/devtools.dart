// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:dds/devtools_server.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../core.dart';
import '../dds_runner.dart';
import '../sdk.dart';
import '../utils.dart';

class DevToolsCommand extends DartdevCommand {
  DevToolsCommand({
    this.customDevToolsPath,
    bool verbose = false,
  })  : argParser = DevToolsServer.buildArgParser(
          verbose: verbose,
          includeHelpOption: false,
          usageLineLength: dartdevUsageLineLength,
        ),
        super(
          'devtools',
          DevToolsServer.commandDescription,
          verbose,
        );

  final String? customDevToolsPath;

  @override
  final ArgParser argParser;

  @override
  String get name => 'devtools';

  @override
  String get description => DevToolsServer.commandDescription;

  @override
  String get invocation => '${super.invocation} [service protocol uri]';

  @override
  Future<int> run() async {
    final args = argResults!;

    final sdkDir = path.dirname(sdk.dart);
    final fullSdk = sdkDir.endsWith('bin');
    final devToolsBinaries =
        fullSdk ? sdk.devToolsBinaries : path.absolute(sdkDir, 'devtools');

    final argList = await _performDDSCheck(args);
    final server = await DevToolsServer().serveDevToolsWithArgs(
      argList,
      customDevToolsPath: devToolsBinaries,
    );
    return server == null ? -1 : 0;
  }

  /// Attempts to start a DDS instance if there isn't one running for the
  /// target application.
  ///
  /// Returns the argument list from [args], which is modified to include the
  /// DDS URI instead of the VM service URI if DDS is started by this method
  /// or a redirect to DDS would be followed.
  Future<List<String>> _performDDSCheck(ArgResults args) async {
    String? serviceProtocolUri;
    bool positionalServiceUri = false;
    if (args.rest.isNotEmpty) {
      serviceProtocolUri = args.rest.first;
      positionalServiceUri = true;
    } else if (args.wasParsed(DevToolsServer.argVmUri)) {
      serviceProtocolUri = args.option(DevToolsServer.argVmUri)!;
    }

    final argList = args.arguments.toList();

    // No VM service URI was provided, so the user is going to manually connect
    // to their application from DevTools or only use offline tooling.
    //
    // TODO(bkonyi): we should consider having devtools_server try and spawn
    // DDS if users try to connect to an application without a DDS instance.
    if (serviceProtocolUri == null) {
      return argList;
    }

    final originalUri = Uri.parse(serviceProtocolUri);
    var uri = originalUri;
    // The VM service doesn't like it when there's no trailing forward slash at
    // the end of the path. Add one if it's missing.
    uri = _ensureUriHasTrailingForwardSlash(uri);

    // Check to see if the URI is a VM service URI for a VM service instance
    // that already has a DDS instance connected.
    uri = await checkForRedirectToExistingDDSInstance(uri);

    // If this isn't a URI for a VM service with an active DDS instance,
    // check to see if this URI points to a running DDS instance. If not, try
    // and start DDS.
    if (uri == originalUri) {
      uri = await maybeStartDDS(
        uri: uri,
        ddsHost: args.option(DevToolsServer.argDdsHost)!,
        ddsPort: args.option(DevToolsServer.argDdsPort)!,
        machineMode: args.wasParsed(DevToolsServer.argMachine),
      );
    }

    // If we ended up starting DDS or redirecting to an existing instance,
    // update the argument list to include the actual URI for DevTools to
    // connect to.
    if (uri != originalUri) {
      if (positionalServiceUri) {
        argList.removeLast();
      }
      argList.add(uri.toString());
    }

    return argList;
  }

  Uri _ensureUriHasTrailingForwardSlash(Uri uri) {
    if (uri.pathSegments.isNotEmpty) {
      final pathSegments = uri.pathSegments.toList();
      if (pathSegments.last.isNotEmpty) {
        pathSegments.add('');
      }
      uri = uri.replace(pathSegments: pathSegments);
    }
    return uri;
  }

  @visibleForTesting
  static Future<Uri> checkForRedirectToExistingDDSInstance(Uri uri) async {
    final request = http.Request('GET', uri)..followRedirects = false;
    final response = await request.send();
    await response.stream.drain();

    // If we're redirected that means that we attempted to speak directly to
    // the VM service even though there's an active DDS instance already
    // connected to it. In this case, DevTools will fail to connect to the VM
    // service directly so we need to modify the target URI in the args list to
    // instead point to the DDS instance.
    if (response.isRedirect) {
      final redirectUri = Uri.parse(response.headers['location']!);
      final ddsWsUri = Uri.parse(redirectUri.queryParameters['uri']!);

      // Remove '/ws' from the path, add a trailing '/'
      var pathSegments = ddsWsUri.pathSegments.toList()
        ..removeLast()
        ..add('');
      if (pathSegments.length == 1) {
        pathSegments.add('');
      }
      uri = ddsWsUri.replace(
        scheme: 'http',
        pathSegments: pathSegments,
      );
    }
    return uri;
  }

  @visibleForTesting
  static Future<Uri> maybeStartDDS({
    required Uri uri,
    required String ddsHost,
    required String ddsPort,
    bool machineMode = false,
  }) async {
    final pathSegments = uri.pathSegments.toList();
    if (pathSegments.isNotEmpty && pathSegments.last.isEmpty) {
      // There's a trailing '/' at the end of the parsed URI, so there's an
      // empty string at the end of the path segments list that needs to be
      // removed.
      pathSegments.removeLast();
    }

    final authCodesEnabled = pathSegments.isNotEmpty;
    final wsUri = uri.replace(
      scheme: 'ws',
      pathSegments: [
        ...pathSegments,
        'ws',
      ],
    );

    final vmService = await vmServiceConnectUri(wsUri.toString());

    try {
      // If this request throws a RPC error, DDS isn't running and we should
      // try and start it.
      await vmService.getDartDevelopmentServiceVersion();
    } on RPCError {
      // If the user wants to start a debugging session we need to do some extra
      // work and spawn a Dart Development Service (DDS) instance. DDS is a VM
      // service intermediary which implements the VM service protocol and
      // provides non-VM specific extensions (e.g., log caching, client
      // synchronization).
      final debugSession = DDSRunner();
      if (await debugSession.start(
        vmServiceUri: uri,
        ddsHost: ddsHost,
        ddsPort: ddsPort,
        debugDds: false,
        disableServiceAuthCodes: !authCodesEnabled,
        // TODO(bkonyi): should we just have DDS serve its own duplicate
        // DevTools instance? It shouldn't add much, if any, overhead but will
        // allow for developers to access DevTools directly through the VM
        // service URI at a later point. This would probably be a fairly niche
        // workflow.
        enableDevTools: false,
        enableServicePortFallback: true,
      )) {
        uri = debugSession.ddsUri!;
        if (!machineMode) {
          print(
            'Started the Dart Development Service (DDS) at $uri',
          );
        }
      } else if (!machineMode) {
        print(
          'WARNING: Failed to start the Dart Development Service (DDS). '
          'Some development features may be disabled or degraded.',
        );
      }
    } finally {
      await vmService.dispose();
    }
    return uri;
  }
}
