// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const loadIdLookup = LOAD_ID_LOOKUP;
const moduleDir = "MODULE_DIR";

globalThis.loadDeferredId = async function (loadId, reader, handleWasmBytes) {
  return Promise.all(loadIdLookup[loadId].map((m) =>
    Promise.resolve(reader(`${moduleDir}/${m}`))
      .then((b) => handleWasmBytes(m, b))));
}
