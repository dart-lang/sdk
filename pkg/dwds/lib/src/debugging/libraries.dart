// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/debugging/chrome_inspector.dart';
import 'package:dwds/src/debugging/inspector.dart';
import 'package:dwds/src/debugging/metadata/class.dart';
import 'package:dwds/src/debugging/metadata/provider.dart';
import 'package:dwds/src/services/chrome/chrome_debug_exception.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

/// Keeps track of Dart libraries available in the running application.
class LibraryHelper<T extends AppInspector> {
  final Logger _logger = Logger('LibraryHelper');

  /// Map of library ID to [Library].
  final _librariesById = <String, Library>{};

  /// Map of libraryRef ID to [LibraryRef].
  final _libraryRefsById = <String, LibraryRef>{};

  LibraryRef? _rootLib;

  final T inspector;

  LibraryHelper(this.inspector);

  /// Initialize any caches.
  ///
  /// If [modifiedModuleReport] is not null, invalidates only modified libraries
  /// from the cache and recomputes values for any eager caches.
  @mustCallSuper
  void initialize({ModifiedModuleReport? modifiedModuleReport}) {
    _rootLib = null;
    if (modifiedModuleReport != null) {
      for (final library in modifiedModuleReport.modifiedLibraries) {
        // These will later be initialized by `libraryFor` if needed.
        _librariesById.remove(library);
        _libraryRefsById.remove(library);
      }
      for (final library in modifiedModuleReport.reloadedLibraries) {
        // These need to be recomputed here as `libraryRefs` only checks if this
        // map is empty before returning.
        _libraryRefsById[library] = _createLibraryRef(library);
      }
      return;
    }
    _librariesById.clear();
    _libraryRefsById.clear();
  }

  Future<LibraryRef> get rootLib async {
    if (_rootLib != null) return _rootLib!;
    final libraries = await libraryRefs;
    final mainLibrary =
        globalToolConfiguration.loadStrategy.buildSettings.appEntrypoint;
    if (mainLibrary != null) {
      _rootLib = libraries.firstWhereOrNull(
        (lib) => Uri.parse(lib.uri ?? '') == mainLibrary,
      );
    }
    _rootLib =
        _rootLib ??
        libraries.firstWhereOrNull(
          (lib) => lib.name?.contains('org-dartlang') ?? false,
        );
    _rootLib =
        _rootLib ??
        libraries.firstWhereOrNull(
          (lib) => lib.name?.contains('main') ?? false,
        );
    _rootLib = _rootLib ?? (libraries.isNotEmpty ? libraries.last : null);
    return _rootLib!;
  }

  LibraryRef _createLibraryRef(String library) =>
      LibraryRef(id: library, name: library, uri: library);

  /// Returns all libraryRefs in the app.
  ///
  /// Note this can return a cached result that can be selectively reinitialized
  /// using [initialize].
  Future<List<LibraryRef>> get libraryRefs async {
    if (_libraryRefsById.isNotEmpty) return _libraryRefsById.values.toList();
    final libraries = await globalToolConfiguration.loadStrategy
        .metadataProviderFor(inspector.appConnection.request.entrypointPath)
        .libraries;
    for (final library in libraries) {
      _libraryRefsById[library] = _createLibraryRef(library);
    }
    return _libraryRefsById.values.toList();
  }

  Future<LibraryRef?> libraryRefFor(String objectId) async {
    if (_libraryRefsById.isEmpty) await libraryRefs;
    return _libraryRefsById[objectId];
  }
}

class ChromeLibraryHelper extends LibraryHelper<ChromeAppInspector> {
  ChromeLibraryHelper(super.inspector);

  Future<Library?> libraryFor(LibraryRef libraryRef) async {
    final libraryId = libraryRef.id;
    if (libraryId == null) return null;
    final library =
        _librariesById[libraryId] ?? await _constructLibrary(libraryRef);
    if (library == null) return null;
    return _librariesById[libraryId] = library;
  }

  Future<Library?> _constructLibrary(LibraryRef libraryRef) async {
    final libraryId = libraryRef.id;
    final libraryUri = libraryRef.uri;
    if (libraryId == null || libraryUri == null) return null;
    // Fetch information about all the classes in this library.
    final expression = globalToolConfiguration.loadStrategy.dartRuntimeDebugger
        .getClassesInLibraryJsExpression(libraryUri);

    RemoteObject? result;
    try {
      result = await inspector.jsEvaluate(expression, returnByValue: true);
    } on ChromeDebugException catch (_) {
      // Unreferenced libraries are not loaded at runtime,
      // return empty library object for consistency among
      // VM Service implementations.
      // TODO: Collect library and class information from debug symbols.
      _logger.warning(
        'Library ${libraryRef.uri} is not loaded. '
        'This can happen for unreferenced libraries.',
      );
    }
    final classRefs = <ClassRef>[];
    if (result != null) {
      final classNames = result.value as List;

      for (final className in classNames) {
        final classMetaData = ClassMetaData(
          runtimeKind: RuntimeObjectKind.type,
          classRef: classRefFor(libraryRef.id, className),
        );
        classRefs.add(classMetaData.classRef);
      }
    }
    return Library(
      name: libraryRef.name,
      uri: libraryRef.uri,
      debuggable: true,
      dependencies: [],
      scripts: await inspector.scriptRefsForLibrary(libraryId),
      variables: [],
      functions: [],
      classes: classRefs,
      id: libraryId,
    );
  }
}
