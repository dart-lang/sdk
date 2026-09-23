// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:pool/pool.dart';

import '../shared.dart';
import '../util/message_port.dart';
import 'frontend_server_compiler.dart';
import 'sandbox_client.dart';

typedef CompilerFactory =
    FutureOr<FrontendServerCompiler> Function(Uri path, DartPadRunMode mode);

final class Sandbox {
  final SandboxClient _client;
  final CompilerFactory _createCompiler;
  final _pool = Pool(1);

  /// Compiler for the program running in this sandbox, `null` until [run] has
  /// successfully started one. Doubles as the "already used" marker for [run].
  FrontendServerCompiler? _compiler;

  Sandbox({
    required MessagePort port,
    required void Function() onClosed,
    required CompilerFactory createCompiler,
  }) : _client = SandboxClient(port, onClosed),
       _createCompiler = createCompiler;

  Future<T> _synced<T>(FutureOr<T> Function() fn) => _pool.withResource(fn);

  Stream<({String message})> get onConsole => _client.onConsole;
  Stream<({String message})> get onError => _client.onError;
  Stream<({String message})> get onUnhandledRejection =>
      _client.onUnhandledRejection;
  Stream<({String kind, Map<String, Object?> data})> get onExtensionEvent =>
      _client.onExtensionEvent;

  /// Compiles [target] and starts running it in this sandbox.
  ///
  /// Can only be called once per sandbox: the program owns the one Dart runtime
  /// the `<iframe>` has and cannot be stopped again. Use [hotReload] /
  /// [hotRestart] to pick up changes, or a new sandbox for another program.
  Future<({String log})> run(String target, DartPadRunMode mode) async =>
      await _synced(() async {
        if (_compiler != null) {
          throw InvalidSandboxStateException(
            'run() can only be called once per sandbox, use hotRestart() to '
            'restart the program, or connect a new sandbox to run another '
            'program',
          );
        }

        final c = await _createCompiler(Uri.parse(target), mode);
        try {
          final r = await c.compile();

          await _client.loadModules(modules: r.modules);
          await _client.run(Uri.parse(r.entrypointLibraryUri), mode: mode.mode);

          // Only retain the compiler once the program is actually running, such
          // that a failed run() -- most often a compilation error -- can be
          // retried once the problem has been fixed.
          _compiler = c;

          return (log: r.log);
        } catch (_) {
          await c.close().onError((_, _) {});
          rethrow;
        }
      });

  Future<({String log})> hotRestart() async => await _synced(() async {
    final c = _compiler;
    if (c == null) {
      throw InvalidSandboxStateException(
        'run() must be called before hotRestart()',
      );
    }

    final r = await c.compile(restart: true);
    await _client.hotRestart(modules: r.modules);

    return (log: r.log);
  });

  Future<({String log})> hotReload() async => await _synced(() async {
    final c = _compiler;
    if (c == null) {
      throw InvalidSandboxStateException(
        'run() must be called before hotReload()',
      );
    }
    final r = await c.compile();
    await _client.hotReload(modules: r.modules);
    return (log: r.log);
  });

  Future<String> invokeExtension(
    String method,
    Map<String, String> args,
  ) async => await _synced(() => _client.invokeExtension(method, args));

  Future<void> close() async {
    _pool.close().ignore();
    final c = _compiler;
    _compiler = null;
    await c?.close();
    await _client.close();
  }
}
