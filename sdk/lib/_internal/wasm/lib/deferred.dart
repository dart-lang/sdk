// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "internal_patch.dart";

/// Contains active futures for any entities (either module names or IDs)
/// currently being loaded.
final Map<String, Future<void>> _loading = {};

/// Contains the set of entities (either modules or IDs) already loaded.
final Set<String> _loaded = {};

/// Only used when loading modules directly, contains the set of loaded
/// prefixes for each importing library.
final Map<String, Set<String>> _loadedLibraries = {};

/// Only used when loading modules directly, will get populated by the compiler.
/// Maps importing library -> import prefix -> module set.
Map<String, Map<String, List<String>>> get _importMapping => {};

@pragma("wasm:import", "moduleLoadingHelper.loadDeferredModule")
external WasmExternRef _loadDeferredModule(WasmExternRef moduleName);

@pragma("wasm:import", "moduleLoadingHelper.loadDeferredId")
external WasmExternRef _loadDeferredId(WasmExternRef loadId);

class DeferredNotLoadedError extends Error implements NoSuchMethodError {
  final String libraryName;
  final String prefix;

  DeferredNotLoadedError(this.libraryName, this.prefix);

  String toString() {
    return 'Deferred library $libraryName has not loaded $prefix.';
  }
}

class DeferredLoadIdNotLoadedError extends Error implements NoSuchMethodError {
  final String loadId;

  DeferredLoadIdNotLoadedError(this.loadId);

  String toString() {
    return 'Deferred load id $loadId has not loaded.';
  }
}

// NOTE: We'll inject a `@pragma('wasm:entry-point')` before TFA if we need this
// method at runtime.
Future<void> loadLibraryFromLoadId(String loadId) {
  return _loading.putIfAbsent(loadId, () {
    // Start module load
    final promise =
        (_loadDeferredId(loadId.toJS.toExternRef!).toJS as JSPromise);
    return promise.toDart.then(
      (_) {
        // Module loaded
        _loaded.add(loadId);
        _loading.remove(loadId);
      },
      onError: (e) {
        throw DeferredLoadException('Error loading load ID: $loadId\n$e');
      },
    );
  });
}

// NOTE: We'll inject a `@pragma('wasm:entry-point')` before TFA if we need this
// method at runtime.
bool checkLibraryIsLoadedFromLoadId(String loadId) {
  if (!_loaded.contains(loadId)) {
    throw DeferredLoadIdNotLoadedError(loadId);
  }
  return true;
}

// NOTE: We'll inject a `@pragma('wasm:entry-point')` before TFA if we need this
// method at runtime.
Future<void> loadLibrary(String enclosingLibraryOrLoadId, String importPrefix) {
  if (_importMapping.isEmpty) {
    // Only contains one unit.
    (_loadedLibraries[enclosingLibraryOrLoadId] ??= {}).add(importPrefix);
    return Future.value();
  }
  final loadedImports = _loadedLibraries[enclosingLibraryOrLoadId];
  if (loadedImports != null && loadedImports.contains(importPrefix)) {
    // Import already loaded.
    return Future.value();
  }
  final importNameMapping = _importMapping[enclosingLibraryOrLoadId];
  final moduleNames = importNameMapping?[importPrefix];

  if (moduleNames == null) {
    // Since loadLibrary calls get lowered to static invocations of this method,
    // TFA will tree-shake libraries (and their associated imports) that are
    // only referenced via a loadLibrary call. In this case, we won't have an
    // import mapping for the lowered loadLibrary call.
    // This can also occur in module test mode where all imports are deferred
    // but loaded eagerly.
    (_loadedLibraries[enclosingLibraryOrLoadId] ??= {}).add(importPrefix);
    return Future.value();
  }

  if (!deferredLoadingEnabled) {
    throw DeferredLoadException('Compiler did not enable deferred loading.');
  }

  // Start loading modules
  final List<Future> loadFutures = [];
  for (final moduleName in moduleNames) {
    if (_loaded.contains(moduleName)) {
      // Already loaded module
      continue;
    }
    final existingLoad = _loading[moduleName];
    if (existingLoad != null) {
      // Already loading module
      loadFutures.add(existingLoad);
      continue;
    }

    // Start module load
    final promise =
        (_loadDeferredModule(moduleName.toJS.toExternRef!).toJS as JSPromise);
    final future = promise.toDart.then(
      (_) {
        // Module loaded
        _loaded.add(moduleName);
        _loading.remove(moduleName);
      },
      onError: (e) {
        throw DeferredLoadException('Error loading module: $moduleName\n$e');
      },
    );
    loadFutures.add(future);
    _loading[moduleName] = future;
  }
  return Future.wait(loadFutures).then((_) {
    (_loadedLibraries[enclosingLibraryOrLoadId] ??= {}).add(importPrefix);
  });
}

// NOTE: We'll inject a `@pragma('wasm:entry-point')` before TFA if we need this
// method at runtime.
bool checkLibraryIsLoaded(
  String enclosingLibraryOrLoadId,
  String importPrefix,
) {
  final loadedImports = _loadedLibraries[enclosingLibraryOrLoadId];
  if (loadedImports == null || !loadedImports.contains(importPrefix)) {
    throw DeferredNotLoadedError(enclosingLibraryOrLoadId, importPrefix);
  }
  return true;
}
