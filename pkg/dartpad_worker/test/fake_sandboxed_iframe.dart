// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:dartpad/src/worker_client.dart';
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartpad/src/message_port/json_rpc_binary_channel.dart';
import 'package:dartpad/src/message_port/message_port.dart';
import 'package:dartpad_worker/src/shared.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'checks_ext.dart';

sealed class SandboxEvent {}

/// An event carrying DDC library bundles.
sealed class ModulesEvent extends SandboxEvent {
  final List<CompiledModule> modules;
  ModulesEvent._(this.modules);

  /// The names of the bundles, in the order they were sent.
  List<String> get moduleNames => [
    for (final module in modules) module.moduleName,
  ];
}

/// Triggered by [Sandbox.run].
final class LoadModulesEvent extends ModulesEvent {
  LoadModulesEvent._(super.modules) : super._();
}

/// Triggered by [Sandbox.run].
final class RunEvent extends SandboxEvent {
  final String libraryUri;
  final String mode;
  RunEvent._({required this.libraryUri, required this.mode});
}

/// Triggered by [Sandbox.hotReload].
final class HotReloadEvent extends ModulesEvent {
  HotReloadEvent._(super.modules) : super._();
}

/// Triggered by [Sandbox.hotRestart].
final class HotRestartEvent extends ModulesEvent {
  HotRestartEvent._(super.modules) : super._();
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

    _peer.registerMethod('loadModules', (Parameters params) {
      _addEvent(LoadModulesEvent._(_decodeModules(params)));
      return <String, dynamic>{};
    });

    _peer.registerMethod('run', (Parameters params) {
      final mode = params['mode'].asString;
      final libraryUri = params['libraryUri'].asString;

      _addEvent(RunEvent._(libraryUri: libraryUri, mode: mode));
      return <String, dynamic>{};
    });

    _peer.registerMethod('hotReload', (Parameters params) {
      _addEvent(HotReloadEvent._(_decodeModules(params)));
      _hotReloadGeneration++;
      return {'generation': _hotReloadGeneration, 'success': true};
    });

    _peer.registerMethod('hotRestart', (Parameters params) {
      _addEvent(HotRestartEvent._(_decodeModules(params)));
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
    if (events.any((e) => condition.softCheckSync(e) == null)) {
      return;
    }
    await _eventStreamController.stream
        .firstWhere((e) => condition.softCheckSync(e) == null)
        .timeout(
          timeLimit,
          onTimeout: () => throw TestFailure(
            'Expected SandboxEvent within $timeLimit that '
            '${condition.describeSync().join('\n')}',
          ),
        );
  }

  void emitConsole(String level, String message) {
    _peer.sendNotification('console', {'level': level, 'message': message});
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

List<CompiledModule> _decodeModules(Parameters params) => [
  for (final module in params['modules'].asList)
    (
      moduleName: (module as Map)['moduleName'] as String,
      code: module['code'] as String,
      libraries: [
        for (final lib in (module['libraries'] as List?) ?? const [])
          lib as String,
      ],
    ),
];

extension ModulesEventChecks on Subject<ModulesEvent> {
  Subject<List<CompiledModule>> get modules => has((e) => e.modules, 'modules');
  Subject<List<String>> get moduleNames =>
      has((e) => e.moduleNames, 'moduleNames');

  /// Some bundle contains [pattern].
  ///
  /// Bundles are per strongly connected component of the import graph, so
  /// which bundle a given library lands in is an implementation detail.
  void anyModuleContains(Pattern pattern) =>
      modules.any(.it()..code.contains(pattern));
}

extension RunMainEventChecks on Subject<RunEvent> {
  Subject<String> get libraryUri => has((e) => e.libraryUri, 'libraryUri');
  Subject<String> get mode => has((e) => e.mode, 'mode');
}

extension InvokeExtensionEventChecks on Subject<InvokeExtensionEvent> {
  Subject<String> get method => has((e) => e.method, 'method');
  Subject<Map<String, dynamic>> get parameters =>
      has((e) => e.parameters, 'parameters');
}
