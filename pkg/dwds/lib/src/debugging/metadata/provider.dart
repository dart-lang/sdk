// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:async/async.dart';
import 'package:dwds/src/debugging/metadata/module_metadata.dart';
import 'package:dwds/src/readers/asset_reader.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// A provider of metadata in which data is collected through DDC outputs.
class MetadataProvider {
  final AssetReader _assetReader;
  final _logger = Logger('MetadataProvider');
  final String entrypoint;
  final Set<String> _libraries = {};
  final Map<String, String> _scriptToModule = {};
  final Map<String, String> _moduleToSourceMap = {};
  final Map<String, String> _modulePathToModule = {};
  final Map<String, String> _moduleToModulePath = {};
  final Map<String, Set<String>> _moduleToLibraries = {};
  final Map<String, List<String>> _scripts = {};
  final _metadataMemoizer = AsyncMemoizer<void>();

  /// Implicitly imported libraries in any DDC component.
  ///
  /// Currently dart_sdk module does not come with the metadata.
  /// To allow evaluation of expressions that use libraries and
  /// types from the SDK (such as a dart Type object), add the
  /// metadata for dart_sdk manually.
  ///
  /// TODO: Generate sdk module metadata to be consumed by debugger.
  /// Issue: https://github.com/dart-lang/sdk/issues/45477
  List<String> get sdkLibraries => const [
    'dart:_runtime',
    'dart:_debugger',
    'dart:_foreign_helper',
    'dart:_interceptors',
    'dart:_internal',
    'dart:_isolate_helper',
    'dart:_js_helper',
    'dart:_js_primitives',
    'dart:_metadata',
    'dart:_native_typed_data',
    'dart:_rti',
    'dart:async',
    'dart:collection',
    'dart:convert',
    'dart:core',
    'dart:developer',
    'dart:io',
    'dart:isolate',
    'dart:js',
    'dart:js_util',
    'dart:math',
    'dart:typed_data',
    'dart:indexed_db',
    'dart:html',
    'dart:html_common',
    'dart:svg',
    'dart:web_audio',
    'dart:web_gl',
    'dart:ui',
  ];

  MetadataProvider(this.entrypoint, this._assetReader);

  /// A list of all libraries in the Dart application.
  ///
  /// Example:
  ///
  ///  [
  ///     dart:web_gl,
  ///     dart:math,
  ///     org-dartlang-app:///web/main.dart
  ///  ]
  ///
  Future<List<String>> get libraries async {
    await _initialize();
    return _libraries.toList();
  }

  /// A map of library uri to dart scripts.
  ///
  /// Example:
  ///
  /// {
  ///   org-dartlang-app:///web/main.dart :
  ///   { web/main.dart  }
  /// }
  ///
  Future<Map<String, List<String>>> get scripts async {
    await _initialize();
    return _scripts;
  }

  /// A map of script to containing module.
  ///
  /// Example:
  ///
  /// {
  ///   org-dartlang-app:///web/main.dart :
  ///   web/main
  /// }
  Future<Map<String, String>> get scriptToModule async {
    await _initialize();
    return _scriptToModule;
  }

  /// A map of module name to source map path.
  ///
  /// Example:
  ///
  /// {
  ///   org-dartlang-app:///web/main.dart :
  ///   web/main.ddc.js.map
  /// }
  Future<Map<String, String>> get moduleToSourceMap async {
    await _initialize();
    return _moduleToSourceMap;
  }

  /// A map of module path to module name.
  ///
  /// Example:
  ///
  /// {
  ///   web/main.ddc.js :
  ///   web/main
  /// }
  Future<Map<String, String>> get modulePathToModule async {
    await _initialize();
    return _modulePathToModule;
  }

  /// A map of module to module path.
  ///
  /// Example:
  ///
  /// {
  ///   web/main
  ///   web/main.ddc.js :
  /// }
  Future<Map<String, String>> get moduleToModulePath async {
    await _initialize();
    return _moduleToModulePath;
  }

  /// A list of module ids.
  ///
  /// Example:
  ///
  /// [
  ///   web/main,
  ///   web/foo/bar
  /// ]
  Future<List<String>> get modules async {
    await _initialize();
    return _moduleToModulePath.keys.toList();
  }

  /// Compute metadata information after reading the metadata contents and
  /// return a map from module names to their [ModuleMetadata].
  Future<Map<String, ModuleMetadata>> _processMetadata() async {
    final modules = <String, ModuleMetadata>{};
    // The merged metadata resides next to the entrypoint.
    // Assume that <name>.bootstrap.js has <name>.ddc_merged_metadata
    if (entrypoint.endsWith('.bootstrap.js')) {
      _logger.info('Loading debug metadata...');
      final serverPath = entrypoint.replaceAll(
        '.bootstrap.js',
        '.ddc_merged_metadata',
      );
      final merged = await _assetReader.metadataContents(serverPath);
      if (merged != null) {
        for (final contents in merged.split('\n')) {
          try {
            if (contents.isEmpty ||
                contents.startsWith('// intentionally empty:')) {
              continue;
            }
            final moduleJson = json.decode(contents);
            final metadata = ModuleMetadata.fromJson(
              moduleJson as Map<String, dynamic>,
            );
            final moduleName = metadata.name;
            modules[moduleName] = metadata;
            _logger.fine('Loaded debug metadata for module: $moduleName');
          } catch (e) {
            _logger.warning('Failed to read metadata: $e');
            rethrow;
          }
        }
      }
    }
    return modules;
  }

  /// Process all metadata, including SDK metadata, and compute caches once.
  Future<void> _initialize() async {
    await _metadataMemoizer.runOnce(() async {
      final metadata = await _processMetadata();
      _addSdkMetadata();
      metadata.values.forEach(_addMetadata);
    });
  }

  /// Given a map of hot reloaded modules mapped to their respective libraries,
  /// determines deleted and invalidated libraries and modules, invalidates them
  /// in any caches, and recomputes the necessary information.
  ///
  /// Returns a [ModifiedModuleReport] that can be used to invalidate other
  /// caches after a hot reload.
  Future<ModifiedModuleReport> reinitializeAfterHotReload(
    Map<String, List> reloadedModulesToLibraries,
  ) async {
    final modules = await _processMetadata();
    final invalidatedLibraries = <String>{};
    void invalidateLibrary(String libraryImportUri) {
      invalidatedLibraries.add(libraryImportUri);
      _libraries.remove(libraryImportUri);
      _scriptToModule.remove(libraryImportUri);
      _scripts[libraryImportUri]?.forEach(_scriptToModule.remove);
      _scripts.remove(libraryImportUri);
    }

    final deletedModules = <String>{};
    for (final module in _moduleToLibraries.keys) {
      final deletedModule = !modules.containsKey(module);
      final invalidatedModule = reloadedModulesToLibraries.containsKey(module);
      assert(!(deletedModule && invalidatedModule));
      // If the module was either deleted or reloaded, invalidate all previous
      // information both about the module and its libraries.
      if (deletedModule || invalidatedModule) {
        _modulePathToModule.remove(module);
        _moduleToLibraries[module]?.forEach(invalidateLibrary);
        _moduleToModulePath.remove(module);
        _moduleToSourceMap.remove(module);
      }
      if (deletedModule) deletedModules.add(module);
    }
    final reloadedModules = <String>{};
    final reloadedLibraries = <String>{};
    for (final module in reloadedModulesToLibraries.keys) {
      reloadedModules.add(module);
      reloadedLibraries.addAll(
        reloadedModulesToLibraries[module]!.cast<String>(),
      );
      _addMetadata(modules[module]!);
    }
    // The libraries that are removed from the program are those that we
    // invalidated but were never added again.
    final deletedLibraries = invalidatedLibraries
        .where((library) => !_libraries.contains(library))
        .toSet();
    return ModifiedModuleReport(
      deletedModules: deletedModules,
      deletedLibraries: deletedLibraries,
      reloadedModules: reloadedModules,
      reloadedLibraries: reloadedLibraries,
    );
  }

  void _addMetadata(ModuleMetadata metadata) {
    final modulePath = stripLeadingSlashes(metadata.moduleUri);
    final sourceMapPath = stripLeadingSlashes(metadata.sourceMapUri);
    final moduleName = metadata.name;

    _moduleToSourceMap[moduleName] = sourceMapPath;
    _modulePathToModule[modulePath] = moduleName;
    _moduleToModulePath[moduleName] = modulePath;

    final moduleLibraries = <String>{};
    for (final library in metadata.libraries.values) {
      if (library.importUri.startsWith('file:/')) {
        throw AbsoluteImportUriException(library.importUri);
      }
      moduleLibraries.add(library.importUri);
      _libraries.add(library.importUri);
      _scripts[library.importUri] = [];

      _scriptToModule[library.importUri] = moduleName;
      for (final path in library.partUris) {
        // Parts in metadata are relative to the library Uri directory.
        final partPath = p.url.join(p.dirname(library.importUri), path);
        _scripts[library.importUri]!.add(partPath);
        _scriptToModule[partPath] = moduleName;
      }
    }
    _moduleToLibraries[moduleName] = moduleLibraries;
  }

  void _addSdkMetadata() {
    final moduleName = 'dart_sdk';

    for (final lib in sdkLibraries) {
      _libraries.add(lib);
      _scripts[lib] = [];
      // TODO(srujzs): It feels weird that we add this mapping to only this map
      // and not any of the other module maps. We should maybe handle this
      // differently. This will become relevant if we ever support hot reload
      // for the Dart SDK.
      _scriptToModule[lib] = moduleName;
    }
  }
}

class AbsoluteImportUriException implements Exception {
  final String importUri;
  AbsoluteImportUriException(this.importUri);

  @override
  String toString() => "AbsoluteImportUriError: '$importUri'";
}

/// Computed after a hot reload using
/// [MetadataProvider.reinitializeAfterHotReload], represents the modules and
/// libraries in the program that were deleted, reloaded, and therefore,
/// modified.
///
/// Used to recompute caches throughout DWDS.
class ModifiedModuleReport {
  /// Module names that are no longer in the program.
  final Set<String> deletedModules;

  /// Library uris that are no longer in the program.
  final Set<String> deletedLibraries;

  /// Module names that were loaded during the hot reload.
  final Set<String> reloadedModules;

  /// Library uris that were loaded during the hot reload.
  final Set<String> reloadedLibraries;

  /// Module names that were either removed or modified, including additions.
  final Set<String> modifiedModules;

  /// Library uris that were either removed or modified, including additions.
  final Set<String> modifiedLibraries;
  ModifiedModuleReport({
    required this.deletedModules,
    required this.deletedLibraries,
    required this.reloadedModules,
    required this.reloadedLibraries,
  }) : modifiedModules = deletedModules.union(reloadedModules),
       modifiedLibraries = deletedLibraries.union(reloadedLibraries);
}
