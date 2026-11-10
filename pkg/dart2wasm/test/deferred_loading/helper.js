// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const loadIdLookup = LOAD_ID_LOOKUP;
const moduleDir = "MODULE_DIR";

globalThis.loadDeferredId = (loadId, reader, handleWasmBytes) =>
  Promise.all(loadIdLookup[loadId].map((m) =>
    handleWasmBytes(m, reader(`${moduleDir}/${m}`))));
