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

  /// Handles a single JSON-RPC request line in machine mode.
  Future<void> handle(String line) async {
    try {
      final json = jsonDecode(line) as Map<String, Object?>;
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
          DevToolsUtils.printOutput('Unknown method: $method', {
            'id': id,
            'error': 'Unknown method: $method',
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
    final page = params['page'] as String?;

    if (vmServiceUriRaw == null) {
      DevToolsUtils.printOutput('Missing vmServiceUri', {
        'id': id,
        'error': 'Missing vmServiceUri',
      }, machineMode: machineMode);
      return;
    }

    final vmServiceUri = Uri.parse(vmServiceUriRaw);
    try {
      await server.launchDevToolsInBrowser(
        vmServiceUri: vmServiceUri,
        page: page,
      );
      DevToolsUtils.printOutput('Launched DevTools', {
        'id': id,
        'result': {'success': true},
      }, machineMode: machineMode);
    } catch (e) {
      DevToolsUtils.printOutput('Failed to launch DevTools: $e', {
        'id': id,
        'error': 'Failed to launch DevTools: $e',
      }, machineMode: machineMode);
    }
  }

  Future<void> _handleVmRegister(
    Object? id,
    Map<String, Object?> params,
  ) async {
    final uriRaw = params['uri'] as String?;
    if (uriRaw == null) {
      DevToolsUtils.printOutput('Missing uri', {
        'id': id,
        'error': 'Missing uri',
      }, machineMode: machineMode);
      return;
    }

    final uri = Uri.parse(uriRaw);
    final devToolsUrl = (params['devToolsUrl'] as String?) ?? '';
    final headless = (params['headless'] as bool?) ?? false;

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
    if (params case {'rootPaths': final List<dynamic> rootPaths}) {
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
