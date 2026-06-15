// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:dwds/data/build_result.dart';
import 'package:dwds/data/connect_request.dart';
import 'package:dwds/data/debug_event.dart';
import 'package:dwds/data/debug_info.dart';
import 'package:dwds/data/devtools_request.dart';
import 'package:dwds/data/error_response.dart';
import 'package:dwds/data/extension_request.dart';
import 'package:dwds/data/hot_reload_request.dart';
import 'package:dwds/data/hot_reload_response.dart';
import 'package:dwds/data/hot_restart_request.dart';
import 'package:dwds/data/hot_restart_response.dart';
import 'package:dwds/data/ping_request.dart';
import 'package:dwds/data/register_event.dart';
import 'package:dwds/data/run_request.dart';
import 'package:dwds/data/service_extension_request.dart';
import 'package:dwds/data/service_extension_response.dart';
import 'package:dwds/shared/batched_stream.dart';
import 'package:dwds/src/sockets.dart';
import 'package:dwds/src/utilities/uuid.dart';
import 'package:http/browser_client.dart';
import 'package:sse/client/sse_client.dart';
import 'package:web/web.dart';

import 'reloader/ddc_library_bundle_restarter.dart';
import 'reloader/ddc_restarter.dart';
import 'reloader/manager.dart';
import 'reloader/require_restarter.dart';
import 'run_main.dart';
import 'web_utils.dart';

const _batchDelayMilliseconds = 1000;

// GENERATE:
// pub run build_runner build web
Future<void>? main() {
  return runZonedGuarded(
    () async {
      // Set the unique id for this instance of the app.
      // Test apps may already have this set.
      const dartAppInstanceIdKey = 'dartAppInstanceId';
      if (dartAppInstanceId == null) {
        // Check the session storage for the instance id.
        final storedInstanceId = window.sessionStorage.getItem(
          dartAppInstanceIdKey,
        );
        if (storedInstanceId != null) {
          dartAppInstanceId = storedInstanceId;
        } else {
          dartAppInstanceId = const Uuid().v4();
          window.sessionStorage.setItem(
            dartAppInstanceIdKey,
            dartAppInstanceId!,
          );
        }
      }

      final fixedPath = _fixProtocol(dwdsDevHandlerPath);
      final fixedUri = Uri.parse(fixedPath);
      final client = fixedUri.isScheme('ws') || fixedUri.isScheme('wss')
          ? WebSocketClient(
              await PersistentWebSocket.connect(
                fixedUri,
                onReconnect: initializeConnection,
              ),
            )
          : SseSocketClient(SseClient(fixedPath, debugKey: 'InjectedClient'));

      final restarter = switch (dartModuleStrategy) {
        'require-js' => await RequireRestarter.create(),
        'ddc-library-bundle' => DdcLibraryBundleRestarter(),
        'ddc' || 'legacy' => DdcRestarter(),
        _ => throw StateError('Unknown module strategy: $dartModuleStrategy'),
      };

      final manager = ReloadingManager(client, restarter);

      hotReloadStartJs = () {
        return manager.hotReloadStart(hotReloadReloadedSourcesPath).toJS;
      }.toJS;

      hotReloadEndJs = () {
        return manager.hotReloadEnd().toJS;
      }.toJS;

      Completer? readyToRunMainCompleter;

      hotRestartJs = (String runId, [bool? pauseIsolatesOnStart]) {
        if (pauseIsolatesOnStart ?? false) {
          readyToRunMainCompleter = Completer();
          return manager
              .hotRestart(
                runId: runId,
                readyToRunMain: readyToRunMainCompleter!.future,
                reloadedSourcesPath: hotRestartReloadedSourcesPath,
              )
              .toJS;
        } else {
          return manager
              .hotRestart(
                runId: runId,
                reloadedSourcesPath: hotRestartReloadedSourcesPath,
              )
              .toJS;
        }
      }.toJS;

      requestHotRestartJs = (String runId) {
        _trySendEvent(
          client.sink,
          jsonEncode([
            'HotRestartRequest',
            HotRestartRequest(id: runId).toJson(),
          ]),
        );
      }.toJS;

      readyToRunMainJs = () {
        if (readyToRunMainCompleter == null) return;
        if (readyToRunMainCompleter!.isCompleted) return;
        readyToRunMainCompleter!.complete();
        readyToRunMainCompleter = null;
      }.toJS;

      final debugEventController = BatchedStreamController<DebugEvent>(
        delay: _batchDelayMilliseconds,
      );
      debugEventController.stream.listen((events) {
        if (dartEmitDebugEvents) {
          _trySendEvent(
            client.sink,
            jsonEncode([
              'BatchedDebugEvents',
              BatchedDebugEvents(events: events).toJson(),
            ]),
          );
        }
      });

      emitDebugEvent = (String kind, String eventData) {
        if (dartEmitDebugEvents) {
          _trySendEvent(
            debugEventController.sink,
            DebugEvent(
              kind: kind,
              eventData: eventData,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
      }.toJS;

      emitRegisterEvent = (String eventData) {
        _trySendEvent(
          client.sink,
          jsonEncode([
            'RegisterEvent',
            RegisterEvent(
              eventData: eventData,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ).toJson(),
          ]),
        );
      }.toJS;

      launchDevToolsJs = () {
        if (!_isChromium) {
          window.alert(
            'Dart DevTools is only supported on Chromium based browsers.',
          );
          return;
        }
        _trySendEvent(
          client.sink,
          jsonEncode(
            DevToolsRequest(appId: dartAppId, instanceId: dartAppInstanceId!),
          ),
        );
      }.toJS;

      var mainRun = false;
      client.stream.listen(
        (serialized) async {
          final event = _deserializeEvent(jsonDecode(serialized));
          if (event is BuildResult) {
            if (reloadConfiguration == 'ReloadConfiguration.liveReload') {
              manager.reloadPage();
            } else if (reloadConfiguration ==
                'ReloadConfiguration.hotRestart') {
              await manager.hotRestart(
                reloadedSourcesPath: hotRestartReloadedSourcesPath,
              );
            } else if (reloadConfiguration == 'ReloadConfiguration.hotReload') {
              await manager.hotReloadStart(hotReloadReloadedSourcesPath);
              await manager.hotReloadEnd();
            }
          } else if (event is DevToolsResponse) {
            if (!event.success) {
              final alert = 'DevTools failed to open with:\n${event.error}';
              if (event.promptExtension && window.confirm(alert)) {
                window.open(
                  'https://dart.dev/to/web-debug-extension',
                  '_blank',
                );
              } else {
                window.alert(alert);
              }
            }
          } else if (event is RunRequest) {
            // If main has already been run (e.g., in the situation where we
            // lost connection to DWDS and reattached), don't try and run main
            // again.
            if (!mainRun) {
              mainRun = true;
              runMain();
            }
          } else if (event is ErrorResponse) {
            window.reportError(
              'Error from backend:\n\n'
                      'Error: ${event.error}\n\n'
                      'Stack Trace:\n${event.stackTrace}'
                  .toJS,
            );
          } else if (event is HotReloadRequest) {
            await handleWebSocketHotReloadRequest(event, manager, client.sink);
          } else if (event is HotRestartRequest) {
            await handleWebSocketHotRestartRequest(event, manager, client.sink);
          } else if (event is ServiceExtensionRequest) {
            await handleServiceExtensionRequest(event, client.sink, manager);
          }
        },
        onError: (error) {
          // An error is propagated on a full page reload as Chrome presumably
          // forces the SSE connection to close in a bad state. This does not
          // cause any adverse effects so simply swallow this error as to not
          // print the misleading unhandled error message.
        },
      );

      if (dwdsEnableDevToolsLaunch) {
        window.onKeyDown.listen((Event e) {
          if (e.isA<KeyboardEvent>()) {
            final event = e as KeyboardEvent;
            if (const [
                  'd',
                  'D',
                  '∂', // alt-d output on Mac
                  'Î', // shift-alt-D output on Mac
                ].contains(event.key) &&
                event.altKey &&
                !event.ctrlKey &&
                !event.metaKey) {
              event.preventDefault();
              launchDevToolsJs.callAsFunction();
            }
          }
        });
      }
      initializeConnection(client.sink);
    },
    (error, stackTrace) {
      print('''
Unhandled error detected in the injected client.js script.

You can disable this script in webdev by passing --no-injected-client if it
is preventing your app from loading, but note that this will also prevent
all debugging and hot reload/restart functionality from working.

The original error is below, please file an issue at
https://github.com/dart-lang/webdev/issues/new and attach this output:

$error
$stackTrace
''');
    },
  );
}

void initializeConnection(StreamSink clientSink) {
  if (dartModuleStrategy != 'ddc-library-bundle') {
    if (_isChromium) {
      _sendConnectRequest(clientSink);
    } else {
      // If not Chromium we just invoke main, devtools aren't supported.
      runMain();
    }
  } else {
    _sendConnectRequest(clientSink);
  }
  _launchCommunicationWithDebugExtension();
}

void _trySendEvent<T>(StreamSink<T> sink, T serialized) {
  try {
    sink.add(serialized);
    // ignore: avoid_catching_errors
  } on StateError catch (_) {
    // An error is propagated on a full page reload as Chrome presumably
    // forces the SSE connection to close in a bad state.
    print(
      'Cannot send event $serialized. '
      'Injected client connection is closed.',
    );
  }
}

/// Deserializes incoming events from the server.
/// Handles wire format ['TypeName', json] for plain Dart types.
Object? _deserializeEvent(dynamic decoded) {
  if (decoded case [final String typeName, ...]) {
    // For Map-based RPC data types, the second element is the JSON map.
    final jsonData = switch (decoded) {
      [_, final Map<String, dynamic> map] => map,
      _ => const <String, dynamic>{},
    };

    return switch (typeName) {
      // List-based RPC data types:
      'DevToolsResponse' => DevToolsResponse.fromJson(decoded),
      // Map-based RPC data types:
      'ConnectRequest' => ConnectRequest.fromJson(jsonData),
      'RunRequest' => RunRequest.fromJson(jsonData),
      'HotReloadRequest' => HotReloadRequest.fromJson(jsonData),
      'HotRestartRequest' => HotRestartRequest.fromJson(jsonData),
      'ServiceExtensionRequest' => ServiceExtensionRequest.fromJson(jsonData),
      'BuildResult' => BuildResult.fromJson(jsonData),
      'ErrorResponse' => ErrorResponse.fromJson(jsonData),
      'PingRequest' => PingRequest.fromJson(jsonData),
      _ => null,
    };
  }
  return null;
}

void _sendConnectRequest(StreamSink clientSink) {
  final request = ConnectRequest(
    appId: dartAppId,
    instanceId: dartAppInstanceId!,
    entrypointPath: dartEntrypointPath,
  );
  _trySendEvent(clientSink, jsonEncode(['ConnectRequest', request.toJson()]));
}

/// Returns [url] modified if necessary so that, if the current page is served
/// over `https`, then the URL is converted to `https`.
String _fixProtocol(String url) {
  var uri = Uri.parse(url);
  if (window.location.protocol == 'https:' &&
      uri.scheme == 'http' &&
      // Chrome allows mixed content on localhost. It is not safe to assume the
      // server is also listening on https.
      uri.host != 'localhost') {
    uri = uri.replace(scheme: 'https');
  } else if (window.location.protocol == 'wss:' &&
      uri.scheme == 'ws' &&
      uri.host != 'localhost') {
    uri = uri.replace(scheme: 'wss');
  }
  return uri.toString();
}

void _launchCommunicationWithDebugExtension() {
  // Listen for an event from the Dart Debug Extension to authenticate the
  // user (sent once the extension receives the dart-app-read event):
  _listenForDebugExtensionAuthRequest();

  // Send the dart-app-ready event along with debug info to the Dart Debug
  // Extension so that it can debug the Dart app:
  final debugInfoJson = jsonEncode(
    DebugInfo(
      appEntrypointPath: dartEntrypointPath,
      appId: windowContext.$dartAppId,
      appInstanceId: dartAppInstanceId,
      appOrigin: window.location.origin,
      appUrl: window.location.href,
      authUrl: _authUrl,
      extensionUrl: windowContext.$dartExtensionUri,
      isInternalBuild: windowContext.$isInternalBuild,
      isFlutterApp: windowContext.$isFlutterApp,
      workspaceName: dartWorkspaceName,
    ),
  );
  _dispatchEvent('dart-app-ready', debugInfoJson);
}

void _dispatchEvent(String message, String detail) {
  final event = CustomEvent(message, CustomEventInit(detail: detail.toJS));
  document.dispatchEvent(event);
}

void _listenForDebugExtensionAuthRequest() {
  window.addEventListener('message', _handleAuthRequest.toJS);
}

void _handleAuthRequest(Event event) {
  final messageEvent = event as MessageEvent;
  final data = messageEvent.data;

  if (!data.typeofEquals('string')) return;
  if ((data as JSString).toDart != 'dart-auth-request') return;

  // Notify the Dart Debug Extension of authentication status:
  if (_authUrl != null) {
    _authenticateUser(_authUrl!).then(
      (isAuthenticated) =>
          _dispatchEvent('dart-auth-response', '$isAuthenticated'),
    );
  }
}

Future<bool> _authenticateUser(String authUrl) async {
  final client = BrowserClient()..withCredentials = true;
  final response = await client.get(Uri.parse(authUrl));
  final responseText = response.body;
  return responseText.contains('Dart Debug Authentication Success!');
}

void _sendResponse<T>(
  StreamSink clientSink,
  T Function(String, bool, String?) constructor,
  String requestId, {
  bool success = true,
  String? errorMessage,
}) {
  final response = constructor(requestId, success, errorMessage);
  final encoded = switch (response) {
    HotReloadResponse() => ['HotReloadResponse', response.toJson()],
    HotRestartResponse() => ['HotRestartResponse', response.toJson()],
    _ => throw UnsupportedError('Unknown response type: $response'),
  };

  _trySendEvent(clientSink, jsonEncode(encoded));
}

void _sendHotReloadResponse(
  StreamSink clientSink,
  String requestId, {
  bool success = true,
  String? errorMessage,
}) {
  _sendResponse<HotReloadResponse>(
    clientSink,
    (id, success, errorMessage) =>
        HotReloadResponse(id: id, success: success, errorMessage: errorMessage),
    requestId,
    success: success,
    errorMessage: errorMessage,
  );
}

void _sendHotRestartResponse(
  StreamSink clientSink,
  String requestId, {
  bool success = true,
  String? errorMessage,
}) {
  _sendResponse<HotRestartResponse>(
    clientSink,
    (id, success, errorMessage) => HotRestartResponse(
      id: id,
      success: success,
      errorMessage: errorMessage,
    ),
    requestId,
    success: success,
    errorMessage: errorMessage,
  );
}

void _sendServiceExtensionResponse(
  StreamSink clientSink,
  String requestId, {
  bool success = true,
  String? errorMessage,
  int? errorCode,
  Map<String, dynamic>? result,
}) {
  final response = ServiceExtensionResponse.fromResult(
    id: requestId,
    success: success,
    errorMessage: errorMessage,
    errorCode: errorCode,
    result: result,
  );
  _trySendEvent(
    clientSink,
    jsonEncode(['ServiceExtensionResponse', response.toJson()]),
  );
}

Future<void> handleWebSocketHotReloadRequest(
  HotReloadRequest event,
  ReloadingManager manager,
  StreamSink clientSink,
) async {
  final requestId = event.id;
  try {
    await manager.hotReloadStart(hotReloadReloadedSourcesPath);
    await manager.hotReloadEnd();
    _sendHotReloadResponse(clientSink, requestId, success: true);
  } catch (e) {
    _sendHotReloadResponse(
      clientSink,
      requestId,
      success: false,
      errorMessage: e.toString(),
    );
  }
}

Future<void> handleWebSocketHotRestartRequest(
  HotRestartRequest event,
  ReloadingManager manager,
  StreamSink clientSink,
) async {
  final requestId = event.id;
  try {
    final runId = const Uuid().v4();
    await manager.hotRestart(
      runId: runId,
      reloadedSourcesPath: hotRestartReloadedSourcesPath,
    );
    _sendHotRestartResponse(clientSink, requestId, success: true);
  } catch (e) {
    _sendHotRestartResponse(
      clientSink,
      requestId,
      success: false,
      errorMessage: e.toString(),
    );
  }
}

Future<void> handleServiceExtensionRequest(
  ServiceExtensionRequest request,
  StreamSink clientSink,
  ReloadingManager manager,
) async {
  try {
    final result = await manager.handleServiceExtension(
      request.method,
      request.args,
    );

    if (result != null) {
      _sendServiceExtensionResponse(
        clientSink,
        request.id,
        success: true,
        result: result,
      );
    } else {
      // Service extension not supported by this restarter type
      _sendServiceExtensionResponse(
        clientSink,
        request.id,
        success: false,
        errorMessage: 'Service extension not supported',
        errorCode: -32601, // Method not found
      );
    }
  } catch (e) {
    _sendServiceExtensionResponse(
      clientSink,
      request.id,
      success: false,
      errorMessage: e.toString(),
    );
  }
}

@JS(r'$dartAppId')
external String get dartAppId;

@JS(r'$dartAppInstanceId')
external String? get dartAppInstanceId;

@JS(r'$dwdsDevHandlerPath')
external String get dwdsDevHandlerPath;

@JS(r'$dartAppInstanceId')
external set dartAppInstanceId(String? id);

@JS(r'$dartModuleStrategy')
external String get dartModuleStrategy;

@JS(r'$dartHotReloadStartDwds')
external set hotReloadStartJs(JSFunction cb);

@JS(r'$dartHotReloadEndDwds')
external set hotReloadEndJs(JSFunction cb);

@JS(r'$reloadedSourcesPath')
external String? get _reloadedSourcesPath;

String? get hotRestartReloadedSourcesPath => _reloadedSourcesPath;

String get hotReloadReloadedSourcesPath {
  final path = _reloadedSourcesPath;
  assert(
    path != null,
    "Expected 'reloadedSourcesPath' to not be null in a hot reload.",
  );
  return path!;
}

/// Debugger-initiated hot restart.
@JS(r'$dartHotRestartDwds')
external set hotRestartJs(JSFunction cb);

/// App-initiated hot restart.
///
/// When there's no debugger attached, the DWDS dev handler sends the request
/// back, and it will be handled by the client stream listener.
@JS(r'$dartRequestHotRestartDwds')
external set requestHotRestartJs(JSFunction cb);

@JS(r'$dartReadyToRunMain')
external set readyToRunMainJs(JSFunction cb);

@JS(r'$launchDevTools')
external JSFunction get launchDevToolsJs;

@JS(r'$launchDevTools')
external set launchDevToolsJs(JSFunction cb);

@JS(r'$dartReloadConfiguration')
external String get reloadConfiguration;

@JS(r'$dartEntrypointPath')
external String get dartEntrypointPath;

@JS(r'$dwdsEnableDevToolsLaunch')
external bool get dwdsEnableDevToolsLaunch;

@JS(r'$dartEmitDebugEvents')
external bool get dartEmitDebugEvents;

@JS(r'$emitDebugEvent')
external set emitDebugEvent(JSFunction func);

@JS(r'$emitRegisterEvent')
external set emitRegisterEvent(JSFunction func);

@JS(r'$dartWorkspaceName')
external String? get dartWorkspaceName;

bool get _isChromium => window.navigator.vendor.contains('Google');

String? get _authUrl {
  final extensionUrl = windowContext.$dartExtensionUri;
  if (extensionUrl == null) return null;
  final authUrl = Uri.parse(extensionUrl).replace(path: authenticationPath);
  switch (authUrl.scheme) {
    case 'ws':
      return authUrl.replace(scheme: 'http').toString();
    case 'wss':
      return authUrl.replace(scheme: 'https').toString();
    default:
      return authUrl.toString();
  }
}
