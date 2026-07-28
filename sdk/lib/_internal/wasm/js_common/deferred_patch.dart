// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop'
    show
        JSPromise,
        JSPromiseToFuture,
        JSString,
        ListToJSArray,
        StringToJSString;
import 'dart:_js_helper' show dartifyRaw, JSValue, JSAnyToExternRef;
import 'dart:_string' show JSStringImpl;
import 'dart:_wasm';
import 'dart:_js_interop_wasm';

/// Contains active futures for any entities (either module names or IDs)
/// currently being loaded.
final Map<int, Future<void>> _loading = {};

/// Contains the set of entities (either modules or IDs) already loaded.
final Set<int> _loaded = {};

/// Only used when loading modules directly, will get populated by the compiler.
///
/// Maps a loading id (aka deferred prefix) to the set of module ids that have
/// to be loaded.
external WasmArray<WasmArray<WasmI8>?> get _loadingMap;

/// Maps load id to (import uri, import prefix).
external ImmutableWasmArray<WasmExternRef> get _loadingMapNames;

/// The prefix of all module names.
///
/// For `test_module<id>.wasm` it will be `test_module`.
external WasmExternRef get _moduleNamePrefix;

@pragma("wasm:import", "moduleLoadingHelper.loadDeferredModules")
external WasmExternRef _loadDeferredModules(WasmExternRef moduleNames);

@pragma("wasm:import", "moduleLoadingHelper.loadDeferredId")
external WasmExternRef _loadDeferredId(WasmI32 loadId);

String _importUri(int loadId) =>
    JSStringImpl.fromRefUnchecked(_loadingMapNames[2 * loadId + 0]);
String _prefixName(int loadId) =>
    JSStringImpl.fromRefUnchecked(_loadingMapNames[2 * loadId + 1]);

class DeferredLoadIdNotLoadedError extends Error implements NoSuchMethodError {
  final int loadId;

  DeferredLoadIdNotLoadedError(this.loadId);

  String toString() {
    if (minify) {
      return 'Deferred load id $loadId has not loaded.';
    }
    return 'Deferred library ${_importUri(loadId)} has not '
        'loaded ${_prefixName(loadId)}.';
  }
}

// NOTE: We'll inject a `@pragma('wasm:entry-point')` before TFA if we need this
// method at runtime.
bool checkLibraryIsLoadedFromLoadId(int loadId) {
  if (_loaded.contains(loadId)) {
    return true;
  }
  throw DeferredLoadIdNotLoadedError(loadId);
}

// NOTE: We'll inject a `@pragma('wasm:entry-point')` before TFA if we need this
// method at runtime.
Future<void> loadLibraryFromLoadId(int loadId) {
  if (!deferredLoadingEnabled) {
    _loaded.add(loadId);
    return Future.value();
  }
  if (_loaded.contains(loadId)) {
    return Future.value();
  }
  final existingFuture = _loading[loadId];
  if (existingFuture != null) {
    return existingFuture;
  }
  final future = deferredLoadingViaEmbedderLoadId
      ? _loadLibraryViaEmbedderLoadId(loadId)
      : _loadLibraryViaEmbedderModuleNames(loadId);
  return _loading[loadId] = future.then(
    (_) {
      _loaded.add(loadId);
      _loading.remove(loadId);
    },
    onError: (e) {
      if (minify) {
        throw DeferredLoadException('Error loading load ID: $loadId\n$e');
      }
      throw DeferredLoadException(
        'Error loading ${_prefixName(loadId)} of library '
        '${_importUri(loadId)}\n$e',
      );
    },
  );
}

Future<void> _loadLibraryViaEmbedderLoadId(int loadId) {
  final promise = (_loadDeferredId(loadId.toWasmI32()).toJS as JSPromise);
  return promise.toDart;
}

Future<void> _loadLibraryViaEmbedderModuleNames(int loadId) {
  assert(loadId < _loadingMap.length);
  final WasmArray<WasmI8>? encodedModuleIds = _loadingMap[loadId];
  if (encodedModuleIds == null) {
    // No modules to load.
    return Future.value();
  }
  final moduleNamesAsList = _decodeEncodedModuleIds('test', encodedModuleIds);

  final promise =
      (_loadDeferredModules(moduleNamesAsList.toJS.toExternRef!).toJS
          as JSPromise);
  return promise.toDart;
}

/// Keep in sync with pkg/dart2wasm/lib/translator.dart:Translator._patchLoadingMapGetter`
List<JSString> _decodeEncodedModuleIds(
  String prefix,
  WasmArray<WasmI8> encoded,
) {
  int offset = 0;

  int nextULEB128() {
    int result = 0;
    int shift = 0;
    while (true) {
      final byte = encoded.readUnsigned(offset++);
      result |= (byte & 0x7F) << shift;
      shift += 7;
      if ((byte & 0x80) == 0) break;
    }
    return result;
  }

  final length = nextULEB128();
  final moduleIds = <JSString>[];
  int previousModuleId = 0;
  final prefix = JSStringImpl.fromRefUnchecked(_moduleNamePrefix);
  for (int i = 0; i < length; ++i) {
    int diff = nextULEB128();
    final moduleId = previousModuleId + diff;
    moduleIds.add('$prefix${moduleId.toString()}.wasm'.toJS);
    previousModuleId = moduleId;
  }
  return moduleIds;
}
