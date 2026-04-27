// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/handlers/injected_client_js.dart';
import 'package:dwds/src/loaders/ddc_library_bundle.dart';
import 'package:dwds/src/version.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

/// File extension that build_web_compilers will place the
/// [entrypointExtensionMarker] in.
const bootstrapJsExtension = '.bootstrap.js';

/// Marker placed by build_web_compilers for where to put injected JS code.
const entrypointExtensionMarker = '/* ENTRYPOINT_EXTENTION_MARKER */';

/// Marker placed by build_web_compilers for where to put injected JS code.
const mainExtensionMarker = '/* MAIN_EXTENSION_MARKER */';

const _clientScript = 'dwds/src/injected/client';

/// This class is responsible for modifying the served JavaScript files
/// to include the injected DWDS client, enabling debugging capabilities
/// and source mapping when running in a browser environment.
class DwdsInjector {
  final Future<String>? _extensionUri;
  final _devHandlerPaths = StreamController<String>();
  final _logger = Logger('DwdsInjector');

  DwdsInjector({this._extensionUri});

  /// Returns the embedded dev handler paths.
  ///
  /// This will be next to the requested entrypoints.
  Stream<String> get devHandlerPaths => _devHandlerPaths.stream;

  Middleware get middleware => (innerHandler) {
    return (Request request) async {
      if (request.url.path.endsWith('$_clientScript.js')) {
        return Response.ok(
          injectedClientJs,
          headers: {
            HttpHeaders.contentTypeHeader: 'application/javascript',
            HttpHeaders.cacheControlHeader: 'no-cache',
          },
        );
      } else if (request.url.path.endsWith(bootstrapJsExtension)) {
        final ifNoneMatch = request.headers[HttpHeaders.ifNoneMatchHeader];
        if (ifNoneMatch != null) {
          // Disable caching of the inner handler by manually modifying the
          // if-none-match header before forwarding the request.
          request = request.change(
            headers: {HttpHeaders.ifNoneMatchHeader: '$ifNoneMatch\$injected'},
          );
        }
        final response = await innerHandler(request);
        if (response.statusCode == HttpStatus.notFound) return response;
        var body = await response.readAsString();
        var etag = response.headers[HttpHeaders.etagHeader];
        final newHeaders = Map.of(response.headers);
        if (body.startsWith(entrypointExtensionMarker)) {
          // The requestedUri contains the hostname and port which guarantees
          // uniqueness.
          final requestedUri = request.requestedUri;
          final appId = _base64Md5('$requestedUri');
          var scheme = request.requestedUri.scheme;
          if (!globalToolConfiguration.debugSettings.useSseForInjectedClient) {
            // Switch http->ws and https->wss.
            scheme = scheme.replaceFirst('http', 'ws');
          }
          final requestedUriBase =
              '$scheme'
              '://${request.requestedUri.authority}';
          var devHandlerPath = '\$dwdsSseHandler';
          final subPath = request.url.pathSegments.toList()..removeLast();
          if (subPath.isNotEmpty) {
            devHandlerPath = '${subPath.join('/')}/$devHandlerPath';
          }
          _logger.info('Received request for entrypoint at $requestedUri');
          devHandlerPath = '$requestedUriBase/$devHandlerPath';
          _devHandlerPaths.add(devHandlerPath);
          final entrypoint = request.url.path;
          await globalToolConfiguration.loadStrategy.trackEntrypoint(
            entrypoint,
          );
          // Always inject the debugging client and hoist the main function.
          body = await _injectClientAndHoistMain(
            body,
            appId,
            devHandlerPath,
            entrypoint,
            await _extensionUri,
          );
          body += await globalToolConfiguration.loadStrategy.bootstrapFor(
            entrypoint,
          );
          _logger.info(
            'Injected debugging metadata for '
            'entrypoint at $requestedUri',
          );
          etag = _base64Md5(body);
          newHeaders[HttpHeaders.etagHeader] = etag;
        }
        if (ifNoneMatch == etag) {
          return Response.notModified(headers: newHeaders);
        }
        return response.change(body: body, headers: newHeaders);
      } else {
        final loadResponse = await globalToolConfiguration.loadStrategy.handler(
          request,
        );
        if (loadResponse.statusCode != HttpStatus.notFound) {
          return loadResponse;
        }
        return innerHandler(request);
      }
    };
  };
}

/// Returns the provided body with the main function hoisted into a global
/// variable and a snippet of JS that loads the injected client.
Future<String> _injectClientAndHoistMain(
  String body,
  String appId,
  String devHandlerPath,
  String entrypointPath,
  String? extensionUri,
) async {
  final bodyLines = body.split('\n');
  final extensionIndex = bodyLines.indexWhere(
    (line) => line.contains(mainExtensionMarker),
  );
  var result = bodyLines.sublist(0, extensionIndex).join('\n');
  // The line after the marker calls `main`. We prevent `main` from
  // being called and make it runnable through a global variable.
  final mainFunction = bodyLines[extensionIndex + 1]
      .replaceAll('main();', 'main')
      .trim();
  // We inject the client in the entry point module as the client expects the
  // application to be in a ready state, that is the main function is hoisted
  // and the Dart SDK is loaded.
  final injectedClientSnippet = await _injectedClientSnippet(
    appId,
    devHandlerPath,
    entrypointPath,
    extensionUri,
  );
  result +=
      '''
  // Injected by dwds for debugging support.
  if(!window.\$dwdsInitialized) {
    window.\$dwdsInitialized = true;
    window.\$dartMainTearOffs = [$mainFunction];
    window.\$dartRunMain = function() {
      window.\$dartMainExecuted = true;
      window.\$dartMainTearOffs.forEach(function(main){
         main();
      });
    }
    $injectedClientSnippet
  } else {
    if(window.\$dartMainExecuted){
     $mainFunction();
    }else {
     window.\$dartMainTearOffs.push($mainFunction);
    }
  }
  ''';
  result += bodyLines.sublist(extensionIndex + 2).join('\n');
  return result;
}

/// JS snippet which includes global variables required for debugging.
Future<String> _injectedClientSnippet(
  String appId,
  String devHandlerPath,
  String entrypointPath,
  String? extensionUri,
) async {
  final loadStrategy = globalToolConfiguration.loadStrategy;
  final buildSettings = loadStrategy.buildSettings;
  final appMetadata = globalToolConfiguration.appMetadata;
  final debugSettings = globalToolConfiguration.debugSettings;
  final reloadedSourcesPath = loadStrategy is DdcLibraryBundleStrategy
      ? 'window.\$reloadedSourcesPath = "${loadStrategy.reloadedSourcesUri}";\n'
      : '';

  var injectedBody =
      'window.\$dartAppId = "$appId";\n'
      'window.\$dartReloadConfiguration = '
      '"${loadStrategy.reloadConfiguration}";\n'
      'window.\$dartModuleStrategy = "${loadStrategy.id}";\n'
      'window.\$loadModuleConfig = ${loadStrategy.loadModuleSnippet};\n'
      'window.\$dwdsVersion = "$packageVersion";\n'
      'window.\$dwdsDevHandlerPath = "$devHandlerPath";\n'
      'window.\$dwdsEnableDevToolsLaunch = '
      '${debugSettings.enableDevToolsLaunch};\n'
      'window.\$dartEntrypointPath = "$entrypointPath";\n'
      'window.\$dartEmitDebugEvents = ${debugSettings.emitDebugEvents};\n'
      'window.\$isInternalBuild = ${appMetadata.isInternalBuild};\n'
      'window.\$isFlutterApp = ${buildSettings.isFlutterApp};\n'
      '$reloadedSourcesPath'
      '${loadStrategy.loadClientSnippet(_clientScript)}';

  if (extensionUri != null) {
    injectedBody += 'window.\$dartExtensionUri = "$extensionUri";\n';
  }

  final workspaceName = appMetadata.workspaceName;
  if (workspaceName != null) {
    injectedBody += 'window.\$dartWorkspaceName = "$workspaceName";\n';
  }

  return injectedBody;
}

final _utf8FusedConverter = utf8.encoder.fuse(md5);

String _base64Md5(String input) {
  final bytes = _utf8FusedConverter.convert(input).bytes;
  return base64.encode(bytes);
}
