// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:browser_launcher/browser_launcher.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf;

import 'src/devtools/client.dart';
import 'src/devtools/handler.dart';
import 'src/devtools/machine_mode_command_handler.dart';
import 'src/devtools/memory_profile.dart';
import 'src/devtools/utils.dart';
import 'src/utils/console.dart';

class DevToolsServer {
  static const protocolVersion = '1.1.0';
  static const defaultTryPorts = 10;

  MachineModeCommandHandler? _machineModeCommandHandler;
  late ClientManager clientManager;
  final bool _isChromeOS = File('/dev/.cros_milestone').existsSync();

  /// Serves DevTools.
  ///
  /// `handler` is the [shelf.Handler] that the server will use for all requests.
  /// If null, [defaultHandler] will be used. Defaults to null.
  ///
  /// `customDevToolsPath` is a path to a directory containing a pre-built
  /// DevTools application.
  ///
  // Note: this method is used by the Dart CLI and by package:dwds.
  Future<HttpServer?> serveDevTools({
    bool enableStdinCommands = true,
    bool machineMode = false,
    bool debugMode = false,
    bool launchBrowser = false,
    bool enableNotifications = false,
    bool allowEmbedding = false,
    bool headlessMode = false,
    bool verboseMode = false,
    String? hostname,
    String? customDevToolsPath,
    int port = 0,
    int numPortsToTry = defaultTryPorts,
    shelf.Handler? handler,
    String? serviceProtocolUri,
    String? profileFilename,
    String? appSizeBase,
    String? appSizeTest,
  }) async {
    hostname ??= 'localhost';

    // Collect profiling information.
    if (profileFilename != null && serviceProtocolUri != null) {
      final Uri? vmServiceUri = Uri.tryParse(serviceProtocolUri);
      if (vmServiceUri != null) {
        await _hookupMemoryProfiling(
          vmServiceUri,
          profileFilename,
          verboseMode,
        );
      }
      return null;
    }

    if (machineMode) {
      assert(
        enableStdinCommands,
        'machineMode only works with enableStdinCommands.',
      );
    }

    clientManager = ClientManager(
      requestNotificationPermissions: enableNotifications,
    );
    handler ??= await defaultHandler(
      buildDir: customDevToolsPath!,
      clientManager: clientManager,
    );

    HttpServer? server;
    SocketException? ex;
    while (server == null && numPortsToTry >= 0) {
      // If we have tried [numPortsToTry] ports and still have not been able to
      // connect, try port 0 to find a random available port.
      if (numPortsToTry == 0) port = 0;

      try {
        server = await HttpMultiServer.bind(hostname, port);
      } on SocketException catch (e) {
        ex = e;
        numPortsToTry--;
        port++;
      }
    }

    // Re-throw the last exception if we failed to bind.
    if (server == null && ex != null) {
      throw ex;
    }

    final _server = server!;
    if (allowEmbedding) {
      _server.defaultResponseHeaders.remove('x-frame-options', 'SAMEORIGIN');
    }

    // Ensure browsers don't cache older versions of the app.
    _server.defaultResponseHeaders.add(
      HttpHeaders.cacheControlHeader,
      'max-age=900',
    );

    // Serve requests in an error zone to prevent failures
    // when running from another error zone.
    runZonedGuarded(
      () => shelf.serveRequests(_server, handler!),
      (e, _) => print('Error serving requests: $e'),
    );

    final devToolsUrl = 'http://${_server.address.host}:${_server.port}';

    if (launchBrowser) {
      if (serviceProtocolUri != null) {
        serviceProtocolUri =
            _normalizeVmServiceUri(serviceProtocolUri).toString();
      }

      final queryParameters = {
        if (serviceProtocolUri != null) 'uri': serviceProtocolUri,
        if (appSizeBase != null) 'appSizeBase': appSizeBase,
        if (appSizeTest != null) 'appSizeTest': appSizeTest,
      };
      String url = Uri.parse(devToolsUrl)
          .replace(queryParameters: queryParameters)
          .toString();

      // If app size parameters are present, open to the standalone `appsize`
      // page, regardless if there is a vm service uri specified. We only check
      // for the presence of [appSizeBase] here because [appSizeTest] may or may
      // not be specified (it should only be present for diffs). If [appSizeTest]
      // is present without [appSizeBase], we will ignore the parameter.
      if (appSizeBase != null) {
        final startQueryParamIndex = url.indexOf('?');
        if (startQueryParamIndex != -1) {
          url = '${url.substring(0, startQueryParamIndex)}'
              '/#/appsize'
              '${url.substring(startQueryParamIndex)}';
        }
      }

      try {
        await Chrome.start([url]);
      } catch (e) {
        print('Unable to launch Chrome: $e\n');
      }
    }

    if (enableStdinCommands) {
      String message = '''Serving DevTools at $devToolsUrl.

          Hit ctrl-c to terminate the server.''';
      if (!machineMode && debugMode) {
        // Add bold to help find the correct url to open.
        message = ConsoleUtils.bold('$message\n');
      }

      DevToolsUtils.printOutput(
        message,
        {
          'event': 'server.started',
          // TODO(dantup): Remove this `method` field when we're sure VS Code
          // users are all on a newer version that uses `event`. We incorrectly
          // used `method` for the original releases.
          'method': 'server.started',
          'params': {
            'host': _server.address.host,
            'port': _server.port,
            'pid': pid,
            'protocolVersion': protocolVersion,
          }
        },
        machineMode: machineMode,
      );

      if (machineMode) {
        _machineModeCommandHandler = MachineModeCommandHandler(server: this);
        await _machineModeCommandHandler!.initialize(
          devToolsUrl: devToolsUrl,
          headlessMode: headlessMode,
        );
      }
    }

    return server;
  }

  Future<Map<String, dynamic>> launchDevTools(
      Map<String, dynamic> params,
      Uri vmServiceUri,
      String devToolsUrl,
      bool headlessMode,
      bool machineMode) async {
    // First see if we have an existing DevTools client open that we can
    // reuse.
    final canReuse =
        params.containsKey('reuseWindows') && params['reuseWindows'] == true;
    final shouldNotify =
        params.containsKey('notify') && params['notify'] == true;
    final page = params['page'];
    if (canReuse &&
        _tryReuseExistingDevToolsInstance(
          vmServiceUri,
          page,
          shouldNotify,
        )) {
      _emitLaunchEvent(
          reused: true,
          notified: shouldNotify,
          pid: null,
          machineMode: machineMode);
      return {
        'reused': true,
        'notified': shouldNotify,
      };
    }

    final uriParams = <String, dynamic>{};

    // Copy over queryParams passed by the client
    params['queryParams']?.forEach((key, value) => uriParams[key] = value);

    // Add the URI to the VM service
    uriParams['uri'] = vmServiceUri.toString();

    final devToolsUri = Uri.parse(devToolsUrl);
    final uriToLaunch = _buildUriToLaunch(uriParams, page, devToolsUri);

    // TODO(dantup): When ChromeOS has support for tunneling all ports we can
    // change this to always use the native browser for ChromeOS and may wish to
    // handle this inside `browser_launcher`; https://crbug.com/848063.
    final useNativeBrowser = _isChromeOS &&
        _isAccessibleToChromeOSNativeBrowser(devToolsUri) &&
        _isAccessibleToChromeOSNativeBrowser(vmServiceUri);
    int? browserPid;
    if (useNativeBrowser) {
      await Process.start('x-www-browser', [uriToLaunch.toString()]);
    } else {
      final args = headlessMode
          ? [
              '--headless',
              // When running headless, Chrome will quit immediately after loading
              // the page unless we have the debug port open.
              '--remote-debugging-port=9223',
              '--disable-gpu',
              '--no-sandbox',
            ]
          : <String>[];
      final proc = await Chrome.start([uriToLaunch.toString()], args: args);
      browserPid = proc.pid;
    }
    _emitLaunchEvent(
        reused: false,
        notified: false,
        pid: browserPid!,
        machineMode: machineMode);
    return {
      'reused': false,
      'notified': false,
      'pid': browserPid,
    };
  }

  Future<void> _hookupMemoryProfiling(
    Uri observatoryUri,
    String profileFile, [
    bool verboseMode = false,
  ]) async {
    final service = await DevToolsUtils.connectToVmService(observatoryUri);
    if (service == null) {
      return;
    }

    final memoryProfiler = MemoryProfile(service, profileFile, verboseMode);
    memoryProfiler.startPolling();

    print('Writing memory profile samples to $profileFile...');
  }

  bool _tryReuseExistingDevToolsInstance(
    Uri vmServiceUri,
    String page,
    bool notifyUser,
  ) {
    // First try to find a client that's already connected to this VM service,
    // and just send the user a notification for that one.
    final existingClient =
        clientManager.findExistingConnectedReusableClient(vmServiceUri);
    if (existingClient != null) {
      try {
        existingClient.showPage(page);
        if (notifyUser) {
          existingClient.notify();
        }
        return true;
      } catch (e) {
        print('Failed to reuse existing connected DevTools client');
        print(e);
      }
    }

    final reusableClient = clientManager.findReusableClient();
    if (reusableClient != null) {
      try {
        reusableClient.connectToVmService(vmServiceUri, notifyUser);
        return true;
      } catch (e) {
        print('Failed to reuse existing DevTools client');
        print(e);
      }
    }
    return false;
  }

  String _buildUriToLaunch(
    Map<String, dynamic> uriParams,
    page,
    Uri devToolsUri,
  ) {
    final queryStringNameValues = [];
    uriParams.forEach((key, value) => queryStringNameValues.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}'));

    if (page != null) {
      queryStringNameValues.add('page=${Uri.encodeQueryComponent(page)}');
    }

    return devToolsUri
        .replace(
            path: '${devToolsUri.path.isEmpty ? '/' : devToolsUri.path}',
            fragment: '?${queryStringNameValues.join('&')}')
        .toString();
  }

  /// Prints a launch event to stdout so consumers of the DevTools server
  /// can see when clients are being launched/reused.
  void _emitLaunchEvent(
      {required bool reused,
      required bool notified,
      required int? pid,
      required bool machineMode}) {
    DevToolsUtils.printOutput(
      null,
      {
        'event': 'client.launch',
        'params': {
          'reused': reused,
          'notified': notified,
          'pid': pid,
        },
      },
      machineMode: machineMode,
    );
  }

  bool _isAccessibleToChromeOSNativeBrowser(Uri uri) {
    const tunneledPorts = {
      8000,
      8008,
      8080,
      8085,
      8888,
      9005,
      3000,
      4200,
      5000
    };
    return uri.hasPort && tunneledPorts.contains(uri.port);
  }

  // TODO(https://github.com/flutter/devtools/issues/3571): move to devtools_shared.
  // Note: please keep this copy of normalizeVmServiceUri() in sync with the one
  // in devtools_app.
  Uri? _normalizeVmServiceUri(String value) {
    value = value.trim();

    // Cleanup encoded urls likely copied from the uri of an existing running
    // DevTools app.
    if (value.contains('%3A%2F%2F')) {
      value = Uri.decodeFull(value);
    }
    final uri = Uri.parse(value.trim()).removeFragment();
    if (!uri.isAbsolute) {
      return null;
    }
    if (uri.path.endsWith('/')) return uri;
    return uri.replace(path: uri.path);
  }
}
