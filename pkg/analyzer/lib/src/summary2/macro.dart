// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:analyzer/src/summary2/kernel_compilation_service.dart';
import 'package:macros/src/bootstrap.dart' as macro;
import 'package:macros/src/executor.dart' as macro;
import 'package:macros/src/executor/isolated_executor.dart'
    as isolated_executor;
import 'package:macros/src/executor/multi_executor.dart' as macro;
import 'package:macros/src/executor/process_executor.dart' as process_executor;
import 'package:macros/src/executor/serialization.dart' as macro;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as package_path;

/// The interface for a bundle of macros.
abstract class BundleMacroExecutor {
  void dispose();

  Future<macro.MacroInstanceIdentifier> instantiate({
    required Uri libraryUri,
    required String className,
    required String constructorName,
    required macro.Arguments arguments,
  });
}

/// [BundleMacroExecutor] that runs pre-compiled native executables.
class ExecutableBundleMacroExecutor extends BundleMacroExecutor {
  final ExecutableMacroSupport support;
  late final macro.ExecutorFactoryToken _executorFactoryToken;

  ExecutableBundleMacroExecutor({
    required this.support,
    required io.File executable,
    required Set<Uri> libraries,
  }) {
    _executorFactoryToken = support.executor.registerExecutorFactory(
      () => process_executor.start(
        macro.SerializationMode.byteData,
        process_executor.CommunicationChannel.socket,
        executable.path,
      ),
      libraries,
    );
  }

  @override
  void dispose() {
    support.executor.unregisterExecutorFactory(_executorFactoryToken);
  }

  @override
  Future<macro.MacroInstanceIdentifier> instantiate({
    required Uri libraryUri,
    required String className,
    required String constructorName,
    required macro.Arguments arguments,
  }) async {
    return await support.executor
        .instantiateMacro(libraryUri, className, constructorName, arguments);
  }
}

/// [MacroSupport] that can runs macros from native executables.
///
/// It does not support compilation, because it happens outside.
class ExecutableMacroSupport extends MacroSupport {
  void add({
    required io.File executable,
    required Set<Uri> libraries,
  }) {
    var bundleExecutor = ExecutableBundleMacroExecutor(
      support: this,
      executable: executable,
      libraries: libraries,
    );

    for (var libraryUri in libraries) {
      _bundleExecutors[libraryUri] = bundleExecutor;
    }
  }
}

final class ExecutableMacroSupportFactory extends MacroSupportFactory {
  final void Function(ExecutableMacroSupport macroSupport) configure;
  final List<ExecutableMacroSupport> _instances = [];

  ExecutableMacroSupportFactory({
    required this.configure,
  });

  @override
  Future<void> dispose() async {
    for (var instance in _instances) {
      await instance.dispose();
    }
  }

  @override
  MacroSupport newInstance() {
    var instance = ExecutableMacroSupport();
    configure(instance);
    _instances.add(instance);
    return instance;
  }
}

/// [BundleMacroExecutor] that runs macros from kernels.
class KernelBundleMacroExecutor extends BundleMacroExecutor {
  final KernelMacroSupport support;
  late final macro.ExecutorFactoryToken _executorFactoryToken;
  final Uint8List kernelBytes;
  Uri? _kernelUriCached;

  KernelBundleMacroExecutor({
    required this.support,
    required Uint8List kernelBytes,
    required Set<Uri> libraries,
  }) : kernelBytes = Uint8List.fromList(kernelBytes) {
    _executorFactoryToken = support.executor.registerExecutorFactory(
      () => isolated_executor.start(
        macro.SerializationMode.byteData,
        _kernelUri,
      ),
      libraries,
    );
  }

  Uri get _kernelUri {
    return _kernelUriCached ??=
        // ignore: avoid_dynamic_calls
        (Isolate.current as dynamic).createUriForKernelBlob(kernelBytes) as Uri;
  }

  @override
  void dispose() {
    support.executor.unregisterExecutorFactory(_executorFactoryToken);
    var kernelUriCached = _kernelUriCached;
    if (kernelUriCached != null) {
      // ignore: avoid_dynamic_calls
      (Isolate.current as dynamic).unregisterKernelBlobUri(kernelUriCached);
      _kernelUriCached = null;
    }
  }

  @override
  Future<macro.MacroInstanceIdentifier> instantiate({
    required Uri libraryUri,
    required String className,
    required String constructorName,
    required macro.Arguments arguments,
  }) async {
    return await support.executor
        .instantiateMacro(libraryUri, className, constructorName, arguments);
  }
}

/// [MacroSupport] that can compile and run macros from kernels.
class KernelMacroSupport extends MacroSupport {
  final MacroKernelBuilder builder = MacroKernelBuilder();

  void add({
    required Uint8List kernelBytes,
    required Set<Uri> libraries,
  }) {
    var bundleExecutor = KernelBundleMacroExecutor(
      support: this,
      kernelBytes: kernelBytes,
      libraries: libraries,
    );

    for (var libraryUri in libraries) {
      _bundleExecutors[libraryUri] = bundleExecutor;
    }
  }
}

final class KernelMacroSupportFactory extends MacroSupportFactory {
  final List<KernelMacroSupport> _instances = [];

  @override
  Future<void> dispose() async {
    for (var instance in _instances) {
      await instance.dispose();
    }
  }

  @override
  MacroSupport newInstance() {
    var instance = KernelMacroSupport();
    _instances.add(instance);
    return instance;
  }
}

class MacroClass {
  final String name;
  final List<String> constructors;

  MacroClass({
    required this.name,
    required this.constructors,
  });
}

abstract class MacroFileEntry {
  String get content;

  /// When CFE searches for `package_config.json` we need to check this.
  bool get exists;
}

abstract class MacroFileSystem {
  /// Used to convert `file:` URIs into paths.
  package_path.Context get pathContext;

  MacroFileEntry getFile(String path);
}

class MacroKernelBuilder {
  const MacroKernelBuilder();

  Future<Uint8List> build({
    required MacroFileSystem fileSystem,
    required String packageFilePath,
    required List<MacroLibrary> libraries,
  }) async {
    var macroMainContent = macro.bootstrapMacroIsolate(
      {
        for (var library in libraries)
          library.uri.toString(): {
            for (var c in library.classes) c.name: c.constructors
          },
      },
      macro.SerializationMode.byteData,
    );

    var macroMainPath = '${libraries.first.path}.macro';
    var overlayFileSystem = _OverlayMacroFileSystem(fileSystem);
    overlayFileSystem.overlays[macroMainPath] = macroMainContent;

    return KernelCompilationService.compile(
      fileSystem: overlayFileSystem,
      packageFilePath: packageFilePath,
      path: macroMainPath,
    );
  }
}

class MacroLibrary {
  final Uri uri;
  final String path;
  final List<MacroClass> classes;

  MacroLibrary({
    required this.uri,
    required this.path,
    required this.classes,
  });

  String get uriStr => uri.toString();
}

/// The interface for tracking macro executors for libraries.
class MacroSupport {
  /// The instance of macro executor that is used for all macros.
  final macro.MultiMacroExecutor executor = macro.MultiMacroExecutor();

  final Map<Uri, BundleMacroExecutor> _bundleExecutors = {};

  /// Disposes the whole macro support, with all its executors.
  @mustCallSuper
  Future<void> dispose() async {
    await executor.close();
  }

  /// Returns the executor registered for this library.
  BundleMacroExecutor? forLibrary(Uri uri) {
    return _bundleExecutors[uri];
  }

  /// Removes and disposes executors for all libraries.
  void removeLibraries() {
    for (var bundleExecutor in _bundleExecutors.values) {
      bundleExecutor.dispose();
    }
    _bundleExecutors.clear();
  }

  /// Removes and disposes the executor for the library.
  void removeLibrary(Uri uri) {
    var bundleExecutor = _bundleExecutors.remove(uri);
    bundleExecutor?.dispose();
  }
}

/// Each analysis context has to have its own [MacroSupport] instance.
/// The content collection is configured with this factory.
sealed class MacroSupportFactory {
  Future<void> dispose();

  MacroSupport newInstance();
}

// TODO(scheglov): remove after migration.
final class SingleInstanceMacroSupportFactory extends MacroSupportFactory {
  final MacroSupport instance;

  SingleInstanceMacroSupportFactory({
    required this.instance,
  });

  @override
  Future<void> dispose() async {
    await instance.dispose();
  }

  @override
  MacroSupport newInstance() {
    return instance;
  }
}

/// [MacroFileEntry] for a file with overridden content.
class _OverlayMacroFileEntry implements MacroFileEntry {
  @override
  final String content;

  _OverlayMacroFileEntry(this.content);

  @override
  bool get exists => true;
}

/// Wrapper around another [MacroFileSystem] that can be configured to
/// provide (or override) content of files.
class _OverlayMacroFileSystem implements MacroFileSystem {
  final MacroFileSystem _fileSystem;

  /// The mapping from the path to the file content.
  final Map<String, String> overlays = {};

  _OverlayMacroFileSystem(this._fileSystem);

  @override
  package_path.Context get pathContext => _fileSystem.pathContext;

  @override
  MacroFileEntry getFile(String path) {
    var overlayContent = overlays[path];
    if (overlayContent != null) {
      return _OverlayMacroFileEntry(overlayContent);
    }
    return _fileSystem.getFile(path);
  }
}
