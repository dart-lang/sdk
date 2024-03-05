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
  external void hotReload();
  external void hotRestart();
  external int get hotReloadGeneration;
  external int get hotRestartGeneration;
}

@JS('\$dartLoader')
external _DartLoader get _dartLoader;

final _ddcLoader = _dartLoader.loader;

int get hotRestartGeneration => _ddcLoader.hotRestartGeneration;

void hotRestart() => _ddcLoader.hotRestart();

int get hotReloadGeneration => _ddcLoader.hotReloadGeneration;

void hotReload() => _ddcLoader.hotReload();
