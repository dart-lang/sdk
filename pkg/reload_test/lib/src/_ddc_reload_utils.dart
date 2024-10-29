// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helper functions for the hot reload test suite.
//
// The structure here reflects interfaces defined in DDC's
// `ddc_module_loader.js`.

import 'dart:js_interop';

extension type _DartLoader(JSObject _) implements JSObject {
  external _DDCLoader get loader;
}

extension type _DDCLoader(JSObject _) implements JSObject {
  external JSPromise hotReload();
  external void hotRestart();
  external int get hotReloadGeneration;
  external int get hotRestartGeneration;
  external int intendedHotRestartGeneration;
}

extension type _DartDevEmbedder(JSObject _) implements JSObject {
  external JSFunction hotReload;
  external JSFunction hotRestart;
  external JSNumber get hotReloadGeneration;
  external JSNumber get hotRestartGeneration;
}

@JS('dartDevEmbedder')
external _DartDevEmbedder get _dartDevEmbedder;

@JS('\$injectedFilesAndLibrariesToReload')
external JSFunction injectedFilesAndLibrariesToReload;

@JS('\$dartLoader')
external _DartLoader get _dartLoader;

final _ddcLoader = _dartLoader.loader;

int get hotRestartGeneration => _dartDevEmbedder.hotRestartGeneration.toDartInt;

Future<void> hotRestart() async {
  _ddcLoader.intendedHotRestartGeneration++;
  await (_dartDevEmbedder.hotRestart.callAsFunction() as JSPromise).toDart;
}

int get hotReloadGeneration => _dartDevEmbedder.hotReloadGeneration.toDartInt;

Future<void> hotReload() async {
  var hotReloadArgs =
      injectedFilesAndLibrariesToReload.callAsFunction() as JSArray;
  await (_dartDevEmbedder.hotReload.callAsFunction(
          null, hotReloadArgs[0], hotReloadArgs[1]) as JSPromise)
      .toDart;
}
