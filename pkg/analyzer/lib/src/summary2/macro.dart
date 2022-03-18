// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:path/path.dart' as package_path;

export 'package:_fe_analyzer_shared/src/macros/executor.dart' show Arguments;

class BundleMacroExecutor {
  final macro.MacroExecutor executor;
  final Uint8List kernelBytes;
  Uri? _kernelUriCached;

  BundleMacroExecutor({
    required this.executor,
    required Uint8List kernelBytes,
  }) : kernelBytes = Uint8List.fromList(kernelBytes);

  Uri get _kernelUri {
    return _kernelUriCached ??=
        // ignore: avoid_dynamic_calls
        (Isolate.current as dynamic).createUriForKernelBlob(kernelBytes);
  }

  void dispose() {
    final kernelUriCached = _kernelUriCached;
    if (kernelUriCached != null) {
      // ignore: avoid_dynamic_calls
      (Isolate.current as dynamic).unregisterKernelBlobUri(kernelUriCached);
      _kernelUriCached = null;
    }
  }

  Future<MacroClassIdentifier> forClass({
    required Uri libraryUri,
    required String className,
  }) async {
    var classIdentifier = await executor.loadMacro(libraryUri, className,
        precompiledKernelUri: _kernelUri);
    return MacroClassIdentifier._(this, classIdentifier);
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

class MacroClassIdentifier {
  final BundleMacroExecutor _bundleExecutor;
  final macro.MacroClassIdentifier _identifier;

  MacroClassIdentifier._(
    this._bundleExecutor,
    this._identifier,
  );

  Future<MacroClassInstance> instantiate(
    macro.IdentifierResolver identifierResolver,
    macro.Declaration declaration,
    String constructorName,
    macro.Arguments arguments,
  ) async {
    var instanceIdentifier = await _bundleExecutor.executor
        .instantiateMacro(_identifier, constructorName, arguments);
    return MacroClassInstance._(
        this, identifierResolver, declaration, instanceIdentifier);
  }
}

class MacroClassInstance {
  final MacroClassIdentifier _classIdentifier;
  final macro.IdentifierResolver _identifierResolver;
  final macro.Declaration _declaration;
  final macro.MacroInstanceIdentifier _instanceIdentifier;

  MacroClassInstance._(
    this._classIdentifier,
    this._identifierResolver,
    this._declaration,
    this._instanceIdentifier,
  );

  Future<macro.MacroExecutionResult> executeTypesPhase() async {
    var executor = _classIdentifier._bundleExecutor.executor;
    return await executor.executeTypesPhase(
        _instanceIdentifier, _declaration, _identifierResolver);
  }
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

abstract class MacroKernelBuilder {
  Uint8List build({
    required MacroFileSystem fileSystem,
    required List<MacroLibrary> libraries,
  });
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
}
