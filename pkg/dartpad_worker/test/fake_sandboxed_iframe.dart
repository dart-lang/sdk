// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:dartpad/src/worker_client.dart';
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:checks/context.dart';
import 'package:dartpad/src/message_port/json_rpc_binary_channel.dart';
import 'package:dartpad/src/message_port/message_port.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

sealed class SandboxEvent {}

/// Triggered by [Sandbox.runMain] or [Sandbox.runApp].
final class LoadModuleEvent extends SandboxEvent {
  final String moduleName;
  final String code;
  LoadModuleEvent._({required this.moduleName, required this.code});
}

/// Triggered by [Sandbox.runMain].
final class RunMainEvent extends SandboxEvent {
  final String libraryUri;
  RunMainEvent._({required this.libraryUri});
}

/// Triggered by [Sandbox.runApp].
final class RunAppEvent extends SandboxEvent {
  final String libraryUri;
  RunAppEvent._({required this.libraryUri});
}

/// Triggered by [Sandbox.hotReload].
final class HotReloadEvent extends SandboxEvent {
  final String? code;
  final String? moduleName;
  final List<dynamic> librariesToReload;
  HotReloadEvent._({
    this.code,
    this.moduleName,
    required this.librariesToReload,
  });
}

/// Triggered by [Sandbox.hotRestart].
final class HotRestartEvent extends SandboxEvent {
  final String? code;
  final String? moduleName;
  HotRestartEvent._({this.code, this.moduleName});
}

/// Triggered by [Sandbox.invokeExtension].
final class InvokeExtensionEvent extends SandboxEvent {
  final String method;
  final Map<String, dynamic> parameters;
  InvokeExtensionEvent._({required this.method, required this.parameters});
}

/// A fake implementation of a sandboxed iframe for testing.
final class FakeSandboxedIframe {
  late final MessagePort port;
  late final Peer _peer;

  final List<SandboxEvent> events = [];
  final _eventStreamController = StreamController<SandboxEvent>.broadcast();

  int _hotReloadGeneration = 0;
  int _hotRestartGeneration = 0;

  FakeSandboxedIframe() {
    final controller = StreamChannelController<Uint8List>();
    port = MessagePort.fromBinaryChannel(controller.local);

    final jsonRpcChannel = controller.foreign.transform(
      binaryChannelToJsonRpcChannelTransformer,
    );

    _peer = Peer.withoutJson(jsonRpcChannel.cast<dynamic>());

    _peer.registerMethod('loadModule', (Parameters params) {
      final event = LoadModuleEvent._(
        moduleName: params['moduleName'].asString,
        code: params['code'].asString,
      );
      _addEvent(event);
      return <String, dynamic>{};
    });

    _peer.registerMethod('runMain', (Parameters params) {
      final event = RunMainEvent._(libraryUri: params['libraryUri'].asString);
      _addEvent(event);
      return <String, dynamic>{};
    });

    _peer.registerMethod('runApp', (Parameters params) {
      final event = RunAppEvent._(libraryUri: params['libraryUri'].asString);
      _addEvent(event);
      return <String, dynamic>{};
    });

    _peer.registerMethod('hotReload', (Parameters params) {
      final event = HotReloadEvent._(
        code: params['code'].value as String?,
        moduleName: params['moduleName'].value as String?,
        librariesToReload: params['librariesToReload'].asList,
      );
      _addEvent(event);
      _hotReloadGeneration++;
      return {'generation': _hotReloadGeneration, 'success': true};
    });

    _peer.registerMethod('hotRestart', (Parameters params) {
      final event = HotRestartEvent._(
        code: params['code'].value as String?,
        moduleName: params['moduleName'].value as String?,
      );
      _addEvent(event);
      _hotRestartGeneration++;
      return {'generation': _hotRestartGeneration, 'success': true};
    });

    _peer.registerMethod('getHotRestartGeneration', (Parameters params) {
      return {'generation': _hotRestartGeneration};
    });

    _peer.registerMethod('getHotReloadGeneration', (Parameters params) {
      return {'generation': _hotReloadGeneration};
    });

    _peer.registerMethod('appMetrics', (Parameters params) {
      return <String, dynamic>{
        'dartSize': 0,
        'jsSize': 0,
        'sourceMapSize': 0,
        'evaluatedModules': 0,
        'loadTimeMs': 0,
      };
    });

    _peer.registerMethod('invokeExtension', (Parameters params) {
      final event = InvokeExtensionEvent._(
        method: params['method'].asString,
        parameters: params['args'].asMap.cast<String, dynamic>(),
      );
      _addEvent(event);
      return 'success';
    });

    unawaited(_peer.listen());
  }

  void _addEvent(SandboxEvent event) {
    events.add(event);
    _eventStreamController.add(event);
  }

  /// Check that an event satisfying [condition] has occurred or will occur.
  Future<void> checkEvent(
    Condition<SandboxEvent> condition, {
    Duration timeLimit = const Duration(seconds: 5),
  }) async {
    if (events.any((e) => softCheck(e, condition) == null)) {
      return;
    }
    await _eventStreamController.stream
        .firstWhere((e) => softCheck(e, condition) == null)
        .timeout(
          timeLimit,
          onTimeout: () => throw TestFailure(
            'Expected SandboxEvent within $timeLimit that '
            '${describe(condition).join('\n')}',
          ),
        );
  }

  void emitConsole(String level, String message) {
    _peer.sendNotification('console', {'level': level, 'message': message});
  }

  void emitError(String message, String stackTrace) {
    _peer.sendNotification('error', {
      'message': message,
      'stackTrace': stackTrace,
    });
  }

  void emitUnhandledRejection(String message) {
    _peer.sendNotification('unhandledRejection', {'message': message});
  }

  void emitExtensionEvent(String kind, Map<String, dynamic> data) {
    _peer.sendNotification('extensionEvent', {
      'kind': kind,
      'data': jsonEncode(data),
    });
  }

  Future<void> close() async {
    await _peer.close();
    await _eventStreamController.close();
  }
}

extension LoadModuleEventChecks on Subject<LoadModuleEvent> {
  Subject<String> get moduleName => has((e) => e.moduleName, 'moduleName');
  Subject<String> get code => has((e) => e.code, 'code');
}

extension RunMainEventChecks on Subject<RunMainEvent> {
  Subject<String> get libraryUri => has((e) => e.libraryUri, 'libraryUri');
}

extension RunAppEventChecks on Subject<RunAppEvent> {
  Subject<String> get libraryUri => has((e) => e.libraryUri, 'libraryUri');
}

extension HotReloadEventChecks on Subject<HotReloadEvent> {
  Subject<String?> get code => has((e) => e.code, 'code');
  Subject<String?> get moduleName => has((e) => e.moduleName, 'moduleName');
  Subject<List<dynamic>> get librariesToReload =>
      has((e) => e.librariesToReload, 'librariesToReload');
}

extension HotRestartEventChecks on Subject<HotRestartEvent> {
  Subject<String?> get code => has((e) => e.code, 'code');
  Subject<String?> get moduleName => has((e) => e.moduleName, 'moduleName');
}

extension InvokeExtensionEventChecks on Subject<InvokeExtensionEvent> {
  Subject<String> get method => has((e) => e.method, 'method');
  Subject<Map<String, dynamic>> get parameters =>
      has((e) => e.parameters, 'parameters');
}
