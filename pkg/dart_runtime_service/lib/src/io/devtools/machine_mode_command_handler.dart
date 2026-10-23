// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:devtools_shared/devtools_server.dart';
import 'package:devtools_shared/devtools_shared.dart';
import 'package:meta/meta.dart';
import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart';

import 'client.dart';
import 'utils.dart';
import 'vs_code.dart';

/// Abstract interface for a server that hosts DevTools and handles launch
/// requests from machine mode.
abstract class DevToolsServer {
  DevToolsClientManager? get clientManager;
  String? get devToolsUrl;
  bool get headlessMode;

  Future<void> launchDevToolsInBrowser({
    required Uri vmServiceUri,
    String? page,
  });

  Future<Map<String, Object?>> launchDevTools(
    Map<String, Object?> params,
    Uri vmServiceUri,
    String devToolsUrl,
    bool headlessMode,
    bool machineMode,
  );
}

/// Handles machine mode commands from stdout/stdin JSON-RPC.
class MachineModeCommandHandler {
  MachineModeCommandHandler(this.server, {required this.machineMode});

  static const launchDevToolsService = 'launchDevTools';
  static const copyAndCreateDevToolsFile = 'copyAndCreateDevToolsFile';
  static const restoreDevToolsFile = 'restoreDevToolsFile';
  static const errorLaunchingBrowserCode = 500;

  final DevToolsServer server;
  final bool machineMode;

  DevToolsUsage? _devToolsUsage;
  File? _devToolsBackup;

  static bool _isValidVmServiceUri(Uri uri) {
    return uri.isAbsolute &&
        (uri.isScheme('ws') ||
            uri.isScheme('wss') ||
            uri.isScheme('http') ||
            uri.isScheme('https'));
  }

  /// Handles a single JSON-RPC request line in machine mode.
  Future<void> handle(String line) async {
    final trimmed = line.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
      return;
    }
    try {
      final json = jsonDecode(trimmed) as Map<String, Object?>;
      final method = json['method'] as String?;
      final id = json['id'];
      final params =
          (json['params'] as Map<String, Object?>?) ?? <String, Object?>{};

      switch (method) {
        case 'devTools.launch':
          await _handleDevToolsLaunch(id, params);
        case 'vm.register':
          await _handleVmRegister(id, params);
        case 'client.list':
          _handleClientList(id);
        case 'vscode.extensions.discover':
          await _handleVsCodeExtensionsDiscover(id, params);
        case 'devTools.survey':
          _handleDevToolsSurvey(id, params);
        default:
          final message = 'Unknown method $method';
          DevToolsUtils.printOutput(message, {
            'id': id,
            'error': message,
          }, machineMode: machineMode);
      }
    } catch (e) {
      stderr.writeln('Error handling machine command: $e');
    }
  }

  Future<void> _handleDevToolsLaunch(
    Object? id,
    Map<String, Object?> params,
  ) async {
    final vmServiceUriRaw = params['vmServiceUri'] as String?;
    if (vmServiceUriRaw == null) {
      final message =
          "Invalid input: $params does not contain the key 'vmServiceUri'";
      DevToolsUtils.printOutput(message, {
        'id': id,
        'error': message,
      }, machineMode: machineMode);
      return;
    }

    final vmServiceUri = Uri.tryParse(vmServiceUriRaw);
    if (vmServiceUri == null || !_isValidVmServiceUri(vmServiceUri)) {
      const message =
          'VM Service URI must be absolute with a http, https, ws or wss '
          'scheme';
      DevToolsUtils.printOutput(message, {
        'id': id,
        'error': message,
      }, machineMode: machineMode);
      return;
    }

    try {
      final result = await server.launchDevTools(
        params,
        vmServiceUri,
        server.devToolsUrl ?? '',
        server.headlessMode,
        machineMode,
      );
      DevToolsUtils.printOutput('DevTools launched', {
        'id': id,
        'result': result,
      }, machineMode: machineMode);
    } catch (e, s) {
      final message = 'Failed to launch browser: $e\n$s';
      DevToolsUtils.printOutput(message, {
        'id': id,
        'error': message,
      }, machineMode: machineMode);
    }
  }

  Future<void> _handleVmRegister(
    Object? id,
    Map<String, Object?> params,
  ) async {
    final uriRaw = params['uri'] as String?;
    if (uriRaw == null) {
      final message = "Invalid input: $params does not contain the key 'uri'";
      DevToolsUtils.printOutput(message, {
        'id': id,
        'error': message,
      }, machineMode: machineMode);
      return;
    }

    final uri = Uri.tryParse(uriRaw);
    if (uri == null || !_isValidVmServiceUri(uri)) {
      const message =
          'Uri must be absolute with a http, https, ws or wss scheme';
      DevToolsUtils.printOutput(message, {
        'id': id,
        'error': message,
      }, machineMode: machineMode);
      return;
    }

    final devToolsUrl =
        (params['devToolsUrl'] as String?) ?? server.devToolsUrl ?? '';
    final headless = (params['headless'] as bool?) ?? server.headlessMode;

    await registerLaunchDevToolsService(uri, id, devToolsUrl, headless);
  }

  void _handleClientList(Object? id) {
    final manager = server.clientManager;
    DevToolsUtils.printOutput(
      manager?.toString() ?? '',
      manager?.toJson(id) ??
          <String, Object?>{
            'id': id,
            'result': <String, Object?>{'clients': []},
          },
      machineMode: machineMode,
    );
  }

  Future<void> _handleVsCodeExtensionsDiscover(
    Object? id,
    Map<String, Object?> params,
  ) async {
    if (params case {'rootPaths': final List<Object?> rootPaths}) {
      final manager = VsCodeExtensionsManager();

      DevToolsUtils.printOutput('Extensions', {
        'id': id,
        'result': {
          for (final rootPath in rootPaths.cast<String>())
            rootPath: await manager.findVsCodeExtensions(rootPath),
        },
      }, machineMode: machineMode);
    } else {
      final errorMessage =
          "Invalid input: $params does not contain 'List<String> rootPaths'";
      DevToolsUtils.printOutput(errorMessage, {
        'id': id,
        'error': errorMessage,
      }, machineMode: machineMode);
    }
  }

  void _handleDevToolsSurvey(Object? id, Map<String, Object?> params) {
    _devToolsUsage ??= DevToolsUsage();
    final surveyRequest = (params['surveyRequest'] as String?) ?? '';
    final value = (params['value'] as String?) ?? '';

    switch (surveyRequest) {
      case copyAndCreateDevToolsFile:
        backupAndCreateDevToolsStore();
        _devToolsUsage = null;
        DevToolsUtils.printOutput('DevTools Survey', {
          'id': id,
          'result': {'success': true},
        }, machineMode: machineMode);
      case restoreDevToolsFile:
        _devToolsUsage = null;
        final content = restoreDevToolsStore();
        if (content != null) {
          DevToolsUtils.printOutput('DevTools Survey', {
            'id': id,
            'result': {'success': true, 'content': content},
          }, machineMode: machineMode);

          _devToolsUsage = null;
        }
      case SurveyApi.setActiveSurvey:
        _devToolsUsage!.activeSurvey = value;
        DevToolsUtils.printOutput('DevTools Survey', {
          'id': id,
          'result': {
            'success': _devToolsUsage!.activeSurvey == value,
            'activeSurvey': _devToolsUsage!.activeSurvey,
          },
        }, machineMode: machineMode);
      case SurveyApi.getSurveyActionTaken:
        DevToolsUtils.printOutput('DevTools Survey', {
          'id': id,
          'result': {
            'activeSurvey': _devToolsUsage!.activeSurvey,
            'surveyActionTaken': _devToolsUsage!.surveyActionTaken,
          },
        }, machineMode: machineMode);
      case SurveyApi.setSurveyActionTaken:
        _devToolsUsage!.surveyActionTaken =
            (jsonDecode(value) as bool?) ?? false;
        DevToolsUtils.printOutput('DevTools Survey', {
          'id': id,
          'result': {
            'activeSurvey': _devToolsUsage!.activeSurvey,
            'surveyActionTaken': _devToolsUsage!.surveyActionTaken,
          },
        }, machineMode: machineMode);
      case SurveyApi.getSurveyShownCount:
        DevToolsUtils.printOutput('DevTools Survey', {
          'id': id,
          'result': {
            'activeSurvey': _devToolsUsage!.activeSurvey,
            'surveyShownCount': _devToolsUsage!.surveyShownCount,
          },
        }, machineMode: machineMode);
      case SurveyApi.incrementSurveyShownCount:
        _devToolsUsage!.incrementSurveyShownCount();
        DevToolsUtils.printOutput('DevTools Survey', {
          'id': id,
          'result': {
            'activeSurvey': _devToolsUsage!.activeSurvey,
            'surveyShownCount': _devToolsUsage!.surveyShownCount,
          },
        }, machineMode: machineMode);
      default:
        DevToolsUtils.printOutput(
          'Unknown DevTools Survey Request $surveyRequest',
          {
            'id': id,
            'result': {
              'activeSurvey': _devToolsUsage!.activeSurvey,
              'surveyActionTaken': _devToolsUsage!.surveyActionTaken,
              'surveyShownCount': _devToolsUsage!.surveyShownCount,
            },
          },
          machineMode: machineMode,
        );
    }
  }

  @visibleForTesting
  void backupAndCreateDevToolsStore() {
    assert(_devToolsBackup == null);
    final devToolsStore = File(FileSystemExtension.devToolsStoreLocation);
    if (devToolsStore.existsSync()) {
      _devToolsBackup = devToolsStore.copySync(
        '${FileSystemExtension.devToolsDir}/.devtools_backup_test',
      );
      devToolsStore.deleteSync();
    }
  }

  String? restoreDevToolsStore() {
    if (_devToolsBackup != null) {
      fileSystem.maybeMoveLegacyDevToolsStore();
      final devToolsStore = File(FileSystemExtension.devToolsStoreLocation);
      final content = devToolsStore.readAsStringSync();
      devToolsStore.deleteSync();
      if (_devToolsBackup!.existsSync()) {
        _devToolsBackup!.copySync(FileSystemExtension.devToolsStoreLocation);
        _devToolsBackup!.deleteSync();
        _devToolsBackup = null;
      }
      return content;
    }
    return null;
  }

  /// Registers the `launchDevTools` service callback on the target VM Service.
  Future<void> registerLaunchDevToolsService(
    Uri vmServiceUri,
    Object? id,
    String devToolsUrl,
    bool headlessMode,
  ) async {
    try {
      final wsUri = convertToWebSocketUrl(serviceProtocolUrl: vmServiceUri);
      final ws = await WebSocket.connect(wsUri.toString());
      final service = VmService(ws.asBroadcastStream(), ws.add);

      service.registerServiceCallback(launchDevToolsService, (
        Map<String, Object?> params,
      ) async {
        try {
          await server.launchDevTools(
            params,
            vmServiceUri,
            devToolsUrl,
            headlessMode,
            machineMode,
          );
          return {'result': Success().toJson()};
        } catch (e, s) {
          return {
            'error': {
              'code': errorLaunchingBrowserCode,
              'message': 'Failed to launch browser: $e\n$s',
            },
          };
        }
      });

      await service.callMethod(
        'registerService',
        args: {'service': launchDevToolsService, 'alias': 'DevTools Server'},
      );

      DevToolsUtils.printOutput(
        'Successfully registered launchDevTools service',
        {
          'id': id,
          'result': {'success': true},
        },
        machineMode: machineMode,
      );
    } catch (e) {
      DevToolsUtils.printOutput(
        'Unable to connect to VM service at $vmServiceUri: $e',
        {
          'id': id,
          'error': 'Unable to connect to VM service at $vmServiceUri: $e',
        },
        machineMode: machineMode,
      );
    }
  }
}
