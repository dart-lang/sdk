// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:async/async.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/connections/app_connection.dart';
import 'package:dwds/src/debugging/libraries.dart';
import 'package:dwds/src/debugging/metadata/provider.dart';
import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:dwds/src/utilities/shared.dart';
import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

/// An inspector for a running Dart application contained in the
/// [WipConnection].
///
/// Provides information about currently loaded scripts and objects and support
/// for eval.
abstract class AppInspector {
  var _scriptCacheMemoizer = AsyncMemoizer<List<ScriptRef>>();

  Future<List<ScriptRef>> getScriptRefs({
    ModifiedModuleReport? modifiedModuleReport,
  }) => _populateScriptCaches(modifiedModuleReport: modifiedModuleReport);

  /// Map of scriptRef ID to [ScriptRef].
  UnmodifiableMapView<String, ScriptRef> get scriptRefsById =>
      UnmodifiableMapView(_scriptRefsById);
  final _scriptRefsById = <String, ScriptRef>{};

  /// Map of Dart server path to [ScriptRef].
  final _serverPathToScriptRef = <String, ScriptRef>{};

  /// Map of [ScriptRef] id to containing [LibraryRef] id.
  UnmodifiableMapView<String, String> get scriptIdToLibraryId =>
      UnmodifiableMapView(_scriptIdToLibraryId);
  final _scriptIdToLibraryId = <String, String>{};

  /// Map of [Library] id to included [ScriptRef]s.
  final _libraryIdToScriptRefs = <String, List<ScriptRef>>{};

  final Isolate isolate;

  final IsolateRef isolateRef;

  final AppConnection appConnection;

  LibraryHelper get libraryHelper;

  /// The root URI from which the application is served.
  final String root;

  /// JavaScript expression that evaluates to the Dart stack trace mapper.
  static const stackTraceMapperExpression = '\$dartStackTraceUtility.mapper';

  /// Regex used to extract the message from an exception description.
  static final exceptionMessageRegex = RegExp(r'^.*$', multiLine: true);

  /// Flutter widget inspector library.
  Future<LibraryRef?> get flutterWidgetInspectorLibrary => libraryHelper
      .libraryRefFor('package:flutter/src/widgets/widget_inspector.dart');

  /// Regex used to extract a stack trace line from the exception description.
  static final stackTraceLineRegex = RegExp(r'^\s*at\s.*$', multiLine: true);

  AppInspector(this.appConnection, this.isolate, this.root)
    : isolateRef = _toIsolateRef(isolate);

  /// Reset all caches and recompute any mappings.
  ///
  /// Should be called across hot reloads with a valid [ModifiedModuleReport].
  @protected
  @mustCallSuper
  Future<void> initialize({ModifiedModuleReport? modifiedModuleReport}) async {
    _scriptCacheMemoizer = AsyncMemoizer<List<ScriptRef>>();

    // Invalidate `_libraryHelper` as we use it populate any script caches.
    libraryHelper.initialize(modifiedModuleReport: modifiedModuleReport);
    if (modifiedModuleReport == null) {
      _scriptRefsById.clear();
      _serverPathToScriptRef.clear();
      _scriptIdToLibraryId.clear();
      _libraryIdToScriptRefs.clear();
    }

    final libraries = await libraryHelper.libraryRefs;
    isolate.rootLib = await libraryHelper.rootLib;
    isolate.libraries?.clear();
    isolate.libraries?.addAll(libraries);

    final scripts = await getScriptRefs(
      modifiedModuleReport: modifiedModuleReport,
    );

    await DartUri.initialize();
    DartUri.recordAbsoluteUris(libraries.map((lib) => lib.uri).nonNulls);
    DartUri.recordAbsoluteUris(scripts.map((script) => script.uri).nonNulls);
  }

  static IsolateRef _toIsolateRef(Isolate isolate) => IsolateRef(
    id: isolate.id,
    name: isolate.name,
    number: isolate.number,
    isSystemIsolate: isolate.isSystemIsolate,
  );

  Future<LibraryRef?> libraryRefFor(String objectId) =>
      libraryHelper.libraryRefFor(objectId);

  /// Returns the [ScriptRef] for the provided Dart server path [uri].
  Future<ScriptRef?> scriptRefFor(String uri) async {
    await _populateScriptCaches();
    return _serverPathToScriptRef[uri];
  }

  /// Returns the [ScriptRef]s in the library with [libraryId].
  Future<List<ScriptRef>> scriptRefsForLibrary(String libraryId) async {
    await _populateScriptCaches();
    return _libraryIdToScriptRefs[libraryId] ?? [];
  }

  /// All the scripts in the isolate.
  Future<ScriptList> getScripts() async {
    return ScriptList(scripts: await getScriptRefs());
  }

  /// Request and cache `<ScriptRef>`s for all the scripts in the application.
  ///
  /// This populates [_scriptRefsById], [_scriptIdToLibraryId],
  /// [_libraryIdToScriptRefs] and [_serverPathToScriptRef].
  ///
  /// This will get repopulated on restarts and reloads.
  ///
  /// If [modifiedModuleReport] is provided, only invalidates and
  /// recalculates caches for the modified libraries.
  ///
  /// Returns the list of scripts refs cached.
  Future<List<ScriptRef>> _populateScriptCaches({
    ModifiedModuleReport? modifiedModuleReport,
  }) {
    return _scriptCacheMemoizer.runOnce(() async {
      final scripts = await globalToolConfiguration.loadStrategy
          .metadataProviderFor(appConnection.request.entrypointPath)
          .scripts;
      if (modifiedModuleReport != null) {
        // Invalidate any script caches that were computed for the now invalid
        // libraries. They will get repopulated below.
        for (final libraryUri in modifiedModuleReport.modifiedLibraries) {
          final libraryRef = await libraryHelper.libraryRefFor(libraryUri);
          final libraryId = libraryRef?.id;
          // If this was not a pre-existing library, nothing to invalidate.
          if (libraryId == null) continue;
          final scriptRefs = _libraryIdToScriptRefs.remove(libraryId);
          if (scriptRefs == null) continue;
          for (final scriptRef in scriptRefs) {
            final scriptId = scriptRef.id;
            final scriptUri = scriptRef.uri;
            if (scriptId != null && scriptUri != null) {
              _scriptRefsById.remove(scriptId);
              _scriptIdToLibraryId.remove(scriptId);
              _serverPathToScriptRef.remove(
                DartUri(scriptUri, root).serverPath,
              );
            }
          }
        }
      }
      // For all the non-dart: libraries, find their parts and create scriptRefs
      // for them.
      final userLibraries = _userLibraryUris(
        isolate.libraries ?? <LibraryRef>[],
      );
      for (final uri in userLibraries) {
        if (modifiedModuleReport?.modifiedLibraries.contains(uri) == false) {
          continue;
        }
        final parts = scripts[uri];
        final scriptRefs = [
          ScriptRef(uri: uri, id: createId()),
          if (parts != null)
            for (final String part in parts)
              ScriptRef(uri: part, id: createId()),
        ];
        final libraryRef = await libraryHelper.libraryRefFor(uri);
        final libraryId = libraryRef?.id;
        if (libraryId != null) {
          final libraryIdToScriptRefs = _libraryIdToScriptRefs.putIfAbsent(
            libraryId,
            () => <ScriptRef>[],
          );
          for (final scriptRef in scriptRefs) {
            final scriptId = scriptRef.id;
            final scriptUri = scriptRef.uri;
            if (scriptId != null && scriptUri != null) {
              _scriptRefsById[scriptId] = scriptRef;
              _scriptIdToLibraryId[scriptId] = libraryId;
              _serverPathToScriptRef[DartUri(scriptUri, root).serverPath] =
                  scriptRef;
              libraryIdToScriptRefs.add(scriptRef);
            }
          }
        }
      }
      return _scriptRefsById.values.toList();
    });
  }

  Iterable<String> _userLibraryUris(Iterable<LibraryRef> libraries) {
    return libraries
        .map((library) => library.uri ?? '')
        .where((uri) => uri.isNotEmpty && !uri.startsWith('dart:'));
  }

  /// Look up the script by id in an isolate.
  ScriptRef? scriptWithId(String? scriptId) =>
      scriptId == null ? null : _scriptRefsById[scriptId];

  /// Runs an eval on the page to compute all existing registered extensions.
  ///
  /// Combines this with the RPCs registered in the [isolate]. Use this over
  /// [Isolate.extensionRPCs] as this computes a live set.
  ///
  /// Updates [Isolate.extensionRPCs] to this set.
  Future<Set<String>> getExtensionRpcs();
}
