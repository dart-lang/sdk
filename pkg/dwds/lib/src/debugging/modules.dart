// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/debugging/debugger.dart';
import 'package:dwds/src/debugging/metadata/provider.dart';
import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:logging/logging.dart';

/// Tracks modules for the compiled application.
class Modules {
  final _logger = Logger('Modules');
  final String _root;

  // The Dart server path to containing module.
  final _sourceToModule = <String, String>{};

  // Module to Dart server paths.
  final _moduleToSources = <String, Set<String>>{};

  // The Dart server path to library import uri
  final _sourceToLibrary = <String, Uri>{};

  // The Dart server path to library/part import uri
  final _sourceToLibraryOrPart = <String, Uri>{};

  // Library import uri to list of script (parts) dart server path for the
  // library.
  final _scriptsForLibrary = <Uri, List<String>>{};

  var _moduleMemoizer = AsyncMemoizer<void>();

  final Map<String, String> _libraryToModule = {};

  late String _entrypoint;

  Modules(this._root);

  /// Initializes mappings after invalidating modified libraries/modules.
  ///
  /// Intended to be called multiple times throughout the development workflow,
  /// e.g. after a hot-reload.
  ///
  /// If [modifiedModuleReport] is not null, removes and recalculates caches for
  /// any modified modules and libraries.
  Future<void> initialize(
    String entrypoint, {
    ModifiedModuleReport? modifiedModuleReport,
  }) async {
    if (modifiedModuleReport != null) {
      assert(_entrypoint == entrypoint);
      for (final library in modifiedModuleReport.modifiedLibraries) {
        final libraryServerPath = _getLibraryServerPath(library);
        final libraryUri = _sourceToLibrary.remove(libraryServerPath);
        _sourceToLibraryOrPart.remove(libraryServerPath);
        if (libraryUri != null) {
          final scriptServerPaths = _scriptsForLibrary[libraryUri];
          if (scriptServerPaths != null) {
            for (final scriptServerPath in scriptServerPaths) {
              _sourceToLibraryOrPart.remove(scriptServerPath);
              _sourceToLibrary.remove(scriptServerPath);
            }
            _scriptsForLibrary.remove(libraryUri);
          }
        }
        _sourceToModule.remove(libraryServerPath);
        _libraryToModule.remove(library);
      }
      for (final module in modifiedModuleReport.modifiedModules) {
        _moduleToSources.remove(module);
      }
      await _initializeMapping(modifiedModuleReport);
      return;
    }
    _entrypoint = entrypoint;
    _sourceToLibrary.clear();
    _sourceToLibraryOrPart.clear();
    _scriptsForLibrary.clear();
    _sourceToModule.clear();
    _libraryToModule.clear();
    _moduleToSources.clear();
    _moduleMemoizer = AsyncMemoizer();
  }

  /// Returns the containing module for the provided Dart server path.
  Future<String?> moduleForSource(String serverPath) async {
    await _moduleMemoizer.runOnce(_initializeMapping);
    return _sourceToModule[serverPath];
  }

  /// Returns the Dart server paths for the provided module.
  Future<Set<String>?> sourcesForModule(String module) async {
    await _moduleMemoizer.runOnce(_initializeMapping);
    return _moduleToSources[module];
  }

  /// Returns the containing library importUri for the provided Dart server
  /// path.
  Future<Uri?> libraryForSource(String serverPath) async {
    await _moduleMemoizer.runOnce(_initializeMapping);
    return _sourceToLibrary[serverPath];
  }

  /// Returns the importUri of the library or part for the provided Dart server
  /// path.
  Future<Uri?> libraryOrPartForSource(String serverPath) async {
    await _moduleMemoizer.runOnce(_initializeMapping);
    return _sourceToLibraryOrPart[serverPath];
  }

  Future<String?> moduleForLibrary(String libraryUri) async {
    await _moduleMemoizer.runOnce(_initializeMapping);
    return _libraryToModule[libraryUri];
  }

  // Returns mapping from server paths to library paths
  Future<Map<String, String>> modules() async {
    await _moduleMemoizer.runOnce(_initializeMapping);
    return _sourceToModule;
  }

  Future<String?> getRuntimeScriptIdForModule(
    String entrypoint,
    String module,
  ) async {
    final serverPath = await globalToolConfiguration.loadStrategy
        .serverPathForModule(entrypoint, module);
    return chromePathToRuntimeScriptId[serverPath];
  }

  String _getLibraryServerPath(String library) => library.startsWith('dart:')
      ? library
      : DartUri(library, _root).serverPath;

  /// Initializes [_sourceToModule], [_moduleToSources], [_sourceToLibrary] and
  /// [_sourceToLibraryOrPart].
  ///
  /// If [modifiedModuleReport] is not null, only updates the maps for the
  /// modified libraries in the report.
  Future<void> _initializeMapping([
    ModifiedModuleReport? modifiedModuleReport,
  ]) async {
    final provider = globalToolConfiguration.loadStrategy.metadataProviderFor(
      _entrypoint,
    );

    final libraryToScripts = await provider.scripts;
    final scriptToModule = await provider.scriptToModule;

    for (final library in libraryToScripts.keys) {
      if (modifiedModuleReport?.modifiedLibraries.contains(library) == false) {
        // Note that every module will have at least one library associated with
        // it, so it's okay to only process the modified libraries.
        continue;
      }
      final libraryUri = Uri.parse(library);
      final scripts = libraryToScripts[library]!;
      final libraryServerPath = _getLibraryServerPath(library);

      if (scriptToModule.containsKey(library)) {
        final module = scriptToModule[library]!;

        _sourceToModule[libraryServerPath] = module;
        _moduleToSources.putIfAbsent(module, () => {}).add(libraryServerPath);
        _sourceToLibrary[libraryServerPath] = libraryUri;
        _sourceToLibraryOrPart[libraryServerPath] = libraryUri;
        _libraryToModule[library] = module;

        for (final script in scripts) {
          final scriptServerPath = _getLibraryServerPath(script);
          _sourceToModule[scriptServerPath] = module;
          _moduleToSources[module]!.add(scriptServerPath);
          _sourceToLibrary[scriptServerPath] = libraryUri;
          _sourceToLibraryOrPart[scriptServerPath] = Uri.parse(script);
          (_scriptsForLibrary[libraryUri] ??= []).add(scriptServerPath);
        }
      } else {
        _logger.warning('No module found for library $library');
      }
    }
  }
}
