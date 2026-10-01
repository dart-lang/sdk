// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:async/async.dart';
import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:pool/pool.dart';
import 'package:stream_channel/stream_channel.dart';

import '../shared.dart';
import '../util/log.dart';
import '../util/message_port.dart';
import 'frontend_server_compiler.dart';
import 'sandbox_client.dart';
import 'vm_service/vm_service.dart';

final class Sandbox {
  final SandboxClient _client;
  final ResourceProvider _rp;
  final DartPadConfig _config;
  final _pool = Pool(1);
  final DartRuntimeService _vmService;

  /// Compiler for the program running in this sandbox, `null` until [run] has
  /// successfully started one. Doubles as the "already used" marker for [run].
  FrontendServerCompiler? _compiler;

  /// Path to `.dart_tool/package_config.json` for the running program, or
  /// `null` if no program is running.
  String? get packageConfigPath => _compiler?.packageConfig;

  Sandbox._(this._client, this._vmService, this._rp, this._config);

  static Future<Sandbox> create({
    required MessagePort port,
    required ResourceProvider resourceProvider,
    required DartPadConfig config,
    required void Function() onClosed,
  }) async {
    Sandbox? sandbox;
    final client = SandboxClient(port, () {
      onClosed();
      sandbox?.close().ignore();
    });
    final DartRuntimeService vmService;
    try {
      vmService = await createDartPadVmService(
        client: client,
        resourceProvider: resourceProvider,
        config: config,
        packageConfigPath: () => sandbox?.packageConfigPath,
        onHotRestart: () => sandbox!.hotRestart(),
        onHotReload: () => sandbox!.hotReload(),
      );
    } catch (_) {
      await client.close().onError((_, _) {});
      rethrow;
    }
    return sandbox = Sandbox._(client, vmService, resourceProvider, config);
  }

  Future<T> _synced<T>(FutureOr<T> Function() fn) => _pool.withResource(fn);

  Stream<({String level, String message})> get onConsole => _client.onConsole;

  /// Connects a VM Service Protocol client on [port].
  void connectServiceProtocol(MessagePort port) {
    _vmService.addArtificialClient(
      connection: port.vmServiceChannel().transform(
        StreamChannelTransformer<String, Object?>(
          StreamTransformer<Object?, String>.fromHandlers(
            handleData: (data, sink) {
              if (data is String) {
                sink.add(data);
              } else {
                logWarning(
                  'Ignoring non-String message on VM Service channel: '
                  '${data.runtimeType}',
                );
              }
            },
          ),
          StreamSinkTransformer<String, Object?>.fromHandlers(
            handleData: (data, sink) => sink.add(data),
          ),
        ),
      ),
      name: 'dartpad-client',
    );
  }

  String _findPackageConfigFromEntrypoint(String entrypoint) {
    var parent = _rp.getFile(entrypoint).parent;
    do {
      final pkgConfig = parent
          .getFolder('.dart_tool')
          .getFile('package_config.json');

      if (pkgConfig.exists) {
        return pkgConfig.path;
      }

      parent = parent.parent;
    } while (!parent.isRoot);
    throw PackageConfigNotFoundException(
      'Unable to find `.dart_tool/package_config.json` in any '
      'parent directory of `$entrypoint`.',
      data: {'entrypoint': entrypoint},
    );
  }

  FrontendServerCompiler _createCompiler(
    String entrypoint,
    DartPadRunMode mode,
  ) {
    // Test if the file we're compiling exists.
    // Otherwise, we get really ugly errors if there is a bootstrap file in play
    if (!_rp.getFile(entrypoint).exists) {
      throw CompilationFailedException(
        'Compilation entrypoint "$entrypoint" not found',
        data: {'entrypoint': entrypoint},
      );
    }

    var rp = _rp;
    final entrypointWrapperTemplate = mode.entrypointWrapperTemplate;
    if (entrypointWrapperTemplate != null) {
      final originalEntrypoint = entrypoint;
      entrypoint = '$originalEntrypoint.${mode.mode}-wrapper.dart';

      final overlay = rp = OverlayResourceProvider(_rp);
      overlay.setOverlay(
        entrypoint,
        content: entrypointWrapperTemplate.replaceAll(
          '{{entrypoint}}',
          _rp.pathContext.basename(originalEntrypoint),
        ),
        modificationStamp: 0,
      );
    }

    return FrontendServerCompiler(
      resourceProvider: rp,
      packageConfig: _findPackageConfigFromEntrypoint(entrypoint),
      targetPath: entrypoint,
      config: _config,
    );
  }

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

        final c = _createCompiler(target, mode);
        try {
          final r = await c.compile();
          _compiler = c;

          await _client.loadModules(modules: r.modules);
          await _client.run(Uri.parse(r.entrypointLibraryUri), mode: mode.mode);

          return (log: r.log);
        } catch (_) {
          _compiler = null;
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

  bool _isClosed = false;
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    _pool.close().ignore();
    final c = _compiler;
    _compiler = null;
    await Future.wait<void>([
      _vmService.shutdown(),
      if (c != null) c.close(),
      _client.close(),
    ]);
  }
}
