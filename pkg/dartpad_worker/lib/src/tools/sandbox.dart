// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:pool/pool.dart';

import '../shared.dart';
import '../util/message_port.dart';
import 'hot_reload_compiler.dart';
import 'sandbox_client.dart';

typedef CompilerFactory = FutureOr<HotReloadCompiler> Function(Uri path);

final class Sandbox {
  final SandboxClient _client;
  final CompilerFactory _createMainCompiler;
  final CompilerFactory _createAppCompiler;
  final _pool = Pool(1);

  HotReloadCompiler? _compiler;

  Sandbox({
    required MessagePort port,
    required void Function() onClosed,
    required CompilerFactory createMainCompiler,
    required CompilerFactory createAppCompiler,
  }) : _client = SandboxClient(port, onClosed),
       _createMainCompiler = createMainCompiler,
       _createAppCompiler = createAppCompiler;

  Future<T> _synced<T>(FutureOr<T> Function() fn) => _pool.withResource(fn);

  Stream<({String message})> get onConsole => _client.onConsole;
  Stream<({String message})> get onError => _client.onError;
  Stream<({String message})> get onUnhandledRejection =>
      _client.onUnhandledRejection;
  Stream<({String kind, Map<String, Object?> data})> get onExtensionEvent =>
      _client.onExtensionEvent;

  Future<({String log})> runMain(String target) async =>
      await _synced(() async {
        if (_compiler != null) {
          _compiler = null;
          await reset();
        }
        final c = _compiler = await _createMainCompiler(Uri.parse(target));

        final r = await c.compile();

        await _client.loadModule(code: r.code!);
        await _client.runMain(Uri.parse(r.entrypointLibraryUri));

        return (log: r.log);
      });

  Future<({String log})> runApp(String target) async => await _synced(() async {
    if (_compiler != null) {
      _compiler = null;
      await reset();
    }
    final c = _compiler = await _createAppCompiler(Uri.parse(target));

    final r = await c.compile();

    await _client.loadModule(code: r.code!);
    await _client.runApp(Uri.parse(r.entrypointLibraryUri));

    return (log: r.log);
  });

  Future<({String log})> hotRestart() async => await _synced(() async {
    final c = _compiler;
    if (c == null) {
      throw InvalidSandboxStateException(
        'runMain/runApp must be called before hotRestart()',
      );
    }

    final r = await c.compile();
    await _client.hotRestart(code: r.code!);

    return (log: r.log);
  });

  Future<({String log})> hotReload() async => await _synced(() async {
    final c = _compiler;
    if (c == null) {
      throw InvalidSandboxStateException(
        'runMain/runApp must be called before hotReload()',
      );
    }
    final r = await c.compile();
    await _client.hotReload(
      code: r.code!,
      librariesToReload: r.compiledLibraryUris.map(Uri.parse).toList(),
    );
    return (log: r.log);
  });

  Future<String> invokeExtension(
    String method,
    Map<String, String> args,
  ) async => await _synced(() => _client.invokeExtension(method, args));

  Future<void> reset() async => await _synced(() async {
    _compiler = null;
    await _client.hotRestart();
  });

  Future<void> close() async {
    _pool.close().ignore();
    await _client.close();
  }
}
